TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Spotify


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpotifyMorePopularSongs

SpotifyMorePopularSongs_FILES = Tweak.xm
SpotifyMorePopularSongs_EXTRA_FRAMEWORKS += Cephei
SpotifyMorePopularSongs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
