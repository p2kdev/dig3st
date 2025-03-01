TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Preferences
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = dig3st

dig3st_FILES = $(wildcard *.m CustomCells/*.m ../src/DigestPrefsManager.m ../src/CheckApiKey.m ../src/Alert.m)
dig3st_FRAMEWORKS = UIKit
dig3st_PRIVATE_FRAMEWORKS = Preferences
dig3st_INSTALL_PATH = /Library/PreferenceBundles

ifeq ($(THEOS_PACKAGE_SCHEME),)
    PKG = rootful
endif


dig3st_CFLAGS = -fobjc-arc -DPACKAGE_VERSION='@"$(THEOS_PACKAGE_BASE_VERSION)"' -DPACKAGE_SCHEME='@"$(PKG)"' -DTHEOS_SCHEMA='@"$(THEOS_SCHEMA)"'

include $(THEOS_MAKE_PATH)/bundle.mk
