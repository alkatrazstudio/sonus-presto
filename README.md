# SonusPresto

A bare-bones music player.
Intended to utilize a filesystem to browse your music instead of automatically grouping by artist, album or genre.
Focused on gesture controls.
Supports CUE sheets, M3U playlists and Internet radio.

Minimum supported Android version: 5.0 (Lollipop, API 21)


## WARNING: The app will soon be removed from Google Play!

SonusPresto will be removed from Google Play at the end of January 2025.
You will probably be able to continue to use this app if it's already installed,
but if you want to receive further updates you should migrate to the version from GitHub releases.

You can remove your current version and install
[the latest app version](https://github.com/alkatrazstudio/sonus-presto/releases/latest)
from GitHub releases.


## Features

Here's what you can do in SonusPresto:

* play music

* browse your music in the way you have structured it, using the filesystem

* play all files in a selected folder and sub-folders recursively

* open CUE sheets and M3U playlists as folders

* gapless playback

* play Internet radio from M3U playlists

* change a visual theme and language (English/Russian)

* control a playback using touch and swipe gestures on a single button

* listen to the audio from the video files

* delete files and folders


## Non-features

Here's what SonusPresto can't do:

* view audio tags or cover art

* quickly set a precise playback position

* view the current playback position in seconds

* use a separate buttons to control a playback (i.e. there's no separate prev/stop/next/... buttons)

* create custom playlists or manage a playback queue

* basically, anything else that is not listed in the "Features" section :)

**Disclaimer:** new features will most likely never be added.


## Specifics

Here are some quirks:

* the swiping of the bottom button may not work on some devices with specific Android gesture settings

* since SonusPresto doesn't read tags, it can't determine actual artist and album name of a music track and instead it just uses folder names for that (except for playlist items)

* SonusPresto may not be compatible with LastFM scrobblers, i.e. it will most likely send incorrect info because it does not use tags

* SonusPresto doesn't know what formats your device supports, so it will just show every file that has any of the supported extensions
  (i.e. not all displayed files can actually be played)


## Screenshots

<img src="fastlane/metadata/android/en-US/images/phoneScreenshots/1_en-US.png?raw=true" alt="Dark theme with a regular music track" title="Dark theme with a regular music track" width="250" /> <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/2_en-US.png?raw=true" alt="Options popup and a folder highlight" title="Options popup and a folder highlight" width="250" /> <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/3_en-US.png?raw=true" alt="Light theme with Internet radio" title="Light theme with Internet radio" width="250" />


## Download

Download the latest app version [here](https://github.com/alkatrazstudio/sonus-presto/releases/latest).

Google Play version [will be removed soon](#warning-the-app-will-soon-be-removed-from-google-play).

If you still want to install the Google Play version:

<a target='_blank' rel='noopener noreferrer nofollow' href='https://play.google.com/store/apps/details?id=net.alkatrazstudio.sonuspresto'><img alt='Get it on Google Play' src='https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png' width='240'/></a>

Google Play and the Google Play logo are trademarks of Google LLC.


## Build

SonusPresto is made with [Flutter](https://flutter.dev).

To build this application do the following:

1. Download this repository.

2. Install Flutter and Android SDK. It's easier to do it from [Android Studio](https://developer.android.com/studio).

3. At this point you can already debug the application from Android Studio.
   To build the release version follow the next steps.

4. Go inside the repository root and create the file
   `android/key.properties` based on [android/key.template.properties](android/key.template.properties).
   Fill in all fields.
   For more information see the official "[Signing the app](https://flutter.dev/docs/deployment/android#signing-the-app)" tutorial.

5. To build the release APK run `./build-apk.sh` inside the repository root.
   To build the release Android App Bundle run `./build-bundle.sh`.
   These scripts will remove the entire `build` directory before building,
   so e.g. `./build-bundle.sh` will remove the APK file that was built by `./build-apk.sh`.


## Upload to Google Play

For uploading production releases this project uses [fastlane](https://fastlane.tools).

1. Create `fastlane/Appfile` file using [fastlane/Appfile.template](fastlane/Appfile.template) as a template.

2. Use the following instructions to obtain `api-secret.json` file: https://docs.fastlane.tools/actions/supply/#setup.

3. Install [Bundler](https://bundler.io), e.g. on Ubuntu: `sudo apt install ruby-bundler`.

4. Run `bundle install`. It will install fastlane.

5. Make appropriate changes in `fastlane/metadata/android`.

6. Build and deploy a new release: `./build-bundle.sh --upload`.

Repeat `5` and `6` for each new release.
These steps are not exhaustive. Consult [fastlane docs](https://docs.fastlane.tools) for more information.


## License

GPLv3
