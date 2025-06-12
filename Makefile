export THEOS_PACKAGE_SCHEME=rootless
export TARGET = iphone:clang:13.7:13.0

export THEOS_DEVICE_IP=192.168.86.33

PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = dig3st

dig3st_FILES = src/PushNotification.xm src/Tweak.x src/DigestPrefsManager.m src/Alert.m ./src/OpenAI/OpenAI.m ./src/OpenAI/Config.m ./src/OpenAI/ChatQuery.m ./src/DigestLogger.m
dig3st_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk