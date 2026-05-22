ARCHS = arm64 arm64e
TARGET := iphone:clang:16.5:13.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PaywallBypass
$(TWEAK_NAME)_FILES = PaywallBypass.x
$(TWEAK_NAME)_FRAMEWORKS = Foundation
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
