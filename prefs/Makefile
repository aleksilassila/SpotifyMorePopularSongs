ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SpotifyMorePopularSongsPrefs

SpotifyMorePopularSongsPrefs_FILES = ALERootListController.m
SpotifyMorePopularSongsPrefs_FRAMEWORKS = UIKit
SpotifyMorePopularSongsPrefs_PRIVATE_FRAMEWORKS = Preferences
SpotifyMorePopularSongsPrefs_EXTRA_FRAMEWORKS = Cephei CepheiPrefs
SpotifyMorePopularSongsPrefs_INSTALL_PATH = /Library/PreferenceBundles
SpotifyMorePopularSongsPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
