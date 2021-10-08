# RRO Overlays
PRODUCT_PACKAGES += \
    IconPackCircularPixelLauncherOverlay \
    IconPackCircularPixelThemePickerOverlay \
    IconPackFilledPixelLauncherOverlay \
    IconPackFilledPixelThemePickerOverlay \
    IconPackRoundedPixelLauncherOverlay \
    IconPackRoundedPixelThemePickerOverlay \
    FontArbutusSourceOverlay \
    FontArvoLatoOverlay \
    FontKaiOverlay \
    FontRubikRubikOverlay \
    FontSamOverlay \
    FontVictorOverlay


ifeq ($(BLASTER_BUILD_VARIANT), GAPPS)
PRODUCT_PACKAGES += \
    PixelSetupWizardAodOverlay \
    FilesOverlay \
    PixelDocumentsUIGoogleOverlay \
    GBoardOverlay
endif