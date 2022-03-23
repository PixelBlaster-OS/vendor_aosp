# Gapps
ifeq ($(BUILD_GAPPS),Gapps)
$(call inherit-product, vendor/gms/products/gms.mk)

BLASTER_BUILD_VARIANT := Gapps

# Common Overlay
DEVICE_PACKAGE_OVERLAYS += \
    vendor/aosp/overlay-gapps/common

# Exclude RRO Enforcement
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS +=  \
    vendor/aosp/overlay-gapps

else
$(call inherit-product, packages/apps/Lawnchair/lawnchair.mk)
BLASTER_BUILD_VARIANT := Vanilla
endif
