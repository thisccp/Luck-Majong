[app]

# Metadata
title = Lucky Mahjong
package.name = luckymahjong
package.domain = com.luckymahjong
source.dir = .
source.include_exts = py,png,jpg,kv,atlas
version = 0.1

# Requirements
requirements = python3,kivy

# Android
android.permissions = INTERNET
android.api = 33
android.minapi = 21
android.ndk_api = 21
android.archs = arm64-v8a, armeabi-v7a

# Orientation
orientation = portrait

# Fullscreen
fullscreen = 0

# Entry point
entrypoint = main.py

# (str) Presplash of the application (image shown during loading)
#presplash.filename = %(source.dir)s/data/presplash.png

# (str) Icon of the application
#icon.filename = %(source.dir)s/data/icon.png

[buildozer]
log_level = 2
warn_on_root = 1
