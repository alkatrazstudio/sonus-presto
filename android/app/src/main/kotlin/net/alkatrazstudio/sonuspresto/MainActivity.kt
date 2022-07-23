// SPDX-License-Identifier: GPL-3.0-only
// 🄯 2021, Alexey Parfenov <zxed@alkatrazstudio.net>

package net.alkatrazstudio.sonuspresto

import android.app.Activity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.plugin.common.MethodChannel
import java.io.PrintWriter
import java.io.StringWriter
import java.lang.Exception

class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "sonuspresto.alkatrazstudio.net/documentTree"
        private const val REQUEST_CODE = 1
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    private fun stackTraceFromException(e: Throwable): String {
        val sw = StringWriter()
        e.printStackTrace(PrintWriter(sw))
        val result = sw.toString()
        return result
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // don't call super() since the plugins are already loaded AudioServicePlugin

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result -> try {
                val arg = call.arguments() ?: ""
                when (call.method) {
                    "requestAccess" -> requestDocumentTreeAccess(result)
                    "hasAccess" -> result.success(hasAccessToDocumentTree(arg))
                    "releaseAccess" -> {
                        releaseDocumentTreeAccess()
                        result.success(null)
                    }

                    "listChildren" -> result.success(listDocumentTreeChildren(arg))
                    "getDoc" -> result.success(getDocByUriStr(arg))
                    "readLines" -> result.success(readLines(arg))

                    "deleteDoc" -> result.success(deleteDoc(arg))

                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                Log.wtf("MethodChannel", "${call.method} error [${e.javaClass.name}]: ${e.message}", e)
                result.error(e.javaClass.name, e.message, stackTraceFromException(e))
            }
        }
    }

    // based on https://github.com/miguelpruivo/flutter_file_picker/issues/721#issuecomment-900100134
    private fun requestDocumentTreeAccess(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("pending", "There's already a pending request", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        intent.addFlags(
            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        )
        startActivityForResult(intent, REQUEST_CODE)
        pendingResult = result
    }

    private fun hasAccessToDocumentTree(uri: String): Boolean {
        val result = queryUri(Uri.parse(uri), false)
        return result.isNotEmpty()
    }

    private fun releaseDocumentTreeAccess(exceptUri: Uri? = null) {
        contentResolver.persistedUriPermissions.forEach {
            if (exceptUri != null && exceptUri == it.uri)
                return
            contentResolver.releasePersistableUriPermission(it.uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun queryUri(uri: Uri, getChildren: Boolean): List<Map<String, Any>> {
        val docId = DocumentsContract.getDocumentId(uri)

        val finalUri = if(getChildren) DocumentsContract.buildChildDocumentsUriUsingTree(uri, docId) else uri
        val result = mutableListOf<Map<String, Any>>()
        contentResolver.query(finalUri, arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_MIME_TYPE
        ), null, null, null)?.use {
            while(it.moveToNext()) {
                val id = it.getString(0)
                val itemUri = DocumentsContract.buildDocumentUriUsingTree(uri, id)
                val flags = it.getString(1)
                val isDir = flags == DocumentsContract.Document.MIME_TYPE_DIR
                val item = mapOf(
                    "uri" to itemUri.toString(),
                    "isDirectory" to isDir
                )
                result.add(item)
            }
        } ?: throw Exception("Cannot get the query cursor")
        return result
    }

    private fun listDocumentTreeChildren(uriStr: String): List<Map<String, Any>> {
        val uri = Uri.parse(uriStr)
        val children = queryUri(uri, true)
        return children
    }

    private fun getDoc(uri: Uri): Map<String, Any> {
        val result = queryUri(uri, false)
        val doc = result.firstOrNull() ?: throw Exception("No document found")
        return doc
    }

    private fun getDocByUriStr(uriStr: String): Map<String, Any> {
        val uri = Uri.parse(uriStr)
        val doc = getDoc(uri)
        return doc
    }

    private fun readLines(uri: String): List<String> {
        val stream = contentResolver.openInputStream(Uri.parse(uri)) ?: throw Exception("openInputStream returned null")
        val result = stream.bufferedReader().use { it.readLines() }
        return result
    }

    private fun deleteDoc(uri: String): Boolean {
        val result = DocumentsContract.deleteDocument(contentResolver, Uri.parse(uri))
        return result
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val result = pendingResult
        if (result == null || requestCode != REQUEST_CODE)
            return super.onActivityResult(requestCode, resultCode, data)
        pendingResult = null

        try {
            val uri = data?.data
            if (resultCode == Activity.RESULT_OK && uri != null) {
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                val docId = DocumentsContract.getTreeDocumentId(uri)
                val docUri = DocumentsContract.buildDocumentUriUsingTree(uri, docId)
                val doc = getDoc(docUri)
                result.success(doc)
                releaseDocumentTreeAccess(exceptUri = uri)
            } else {
                result.error("canceled", "Document tree access was not granted", null)
            }
        } catch (e: Throwable) {
            result.error(e.javaClass.name, e.message, stackTraceFromException(e))
        }
    }
}
