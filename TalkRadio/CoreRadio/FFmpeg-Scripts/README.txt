## Modified by Yakamoz Labs ##

These scripts are taken from https://github.com/gabriel/ffmpeg-iphone-build and modified to suit our needs.
RadioKit uses ffmpeg for the mms protocol and for decoding wma audio streams. If you want you can enable
support for other codecs by modifying the ffmpeg-conf file.

## Gas preprocessor
Uses a gas preprocessor via http://github.com/yuvi/gas-preprocessor. Download the gas-preprocessor.pl script 
from this website and place it under /usr/local/bin.

## Scripts
- `build-ffmpeg`: Build script for ffmpeg; Run this first and then `combine-libs`
- `combine-libs`: Creates universal binaries; Runs lipo -create on each of the ffmpeg static libs

## Build FFmpeg
1) Run the ./build-ffmpeg script. This will download the 0.8.5 version of FFmpeg and build static libraries for
the armv6, armv7 and i386 platforms.
2) Run the ./combine-libs script to create universal FFmpeg static libraries. These libraries will be placed in 
the dist-uarch folder.

