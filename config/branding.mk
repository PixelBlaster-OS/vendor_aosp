# Set all versions
BLASTER_BUILD_DATE := $(shell date -u +%Y%m%d-%H%M)
BLASTER_VERSION := 4.5
TARGET_PRODUCT_SHORT := $(subst aosp_,,$(BLASTER_BUILD))
ROM_FINGERPRINT := PixelBlaster/$(PLATFORM_VERSION)/$(TARGET_PRODUCT_SHORT)/$(BLASTER_BUILD_DATE)

PRODUCT_COPY_FILES += vendor/aosp/prebuilt/common/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip

BLASTER_DEVICE := $(shell echo "$(TARGET_PRODUCT)" | cut -d'_' -f 2,3)
LIST := $(shell cat vendor/aosp/blaster_devices)

ifeq ($(BLASTER_BUILD_TYPE),OFFICIAL)
    ifeq ($(filter $(BLASTER_DEVICE), $(LIST)), $(BLASTER_DEVICE))
        BLASTER_BUILD_TYPE := OFFICIAL
else
      $(error "Device is not officially supported!")
endif
endif

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    BUILD_DISPLAY_ID=$(BUILD_ID) \
    ro.pb.version=$(BLASTER_VERSION) \
    ro.pb.build_date=$(BLASTER_BUILD_DATE) \
    ro.pb.build_type=$(BLASTER_BUILD_TYPE) \
    ro.pb.fingerprint=$(ROM_FINGERPRINT)