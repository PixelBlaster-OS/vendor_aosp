#!/usr/bin/env bash
# Automatic OTA Script
# Copyright (C) 2022 PixelBlaster-OS

VERSION="5.2"
DEVICE_NAME=$(awk -F'/PixelBlaster-5.2-|-G' '{print $2}' <<< "$BUILD_ZIP")
ZIP_NAME=$(awk -F$DEVICE_NAME/ '{print $2}' <<< "$BUILD_ZIP")
ID=$(md5sum $BUILD_ZIP | awk '{print $1}')
Date=$(grep "ro.build.date.utc=" out/target/product/$DEVICE_NAME/system/build.prop | cut -d "=" -f 2)
Size=$(wc -c $BUILD_ZIP | awk '{print $1}')
git clone https://github.com/PixelBlaster-releases/$DEVICE_NAME
cp $BUILD_ZIP $DEVICE_NAME/
cd $DEVICE_NAME
OTA_URL=$(gh release create v$VERSION -n "" -t "PixelBlaster v$VERSION | $DEVICE_NAME" $ZIP_NAME)
cd ..
git clone https://github.com/PixelBlaster-OS/OTA
cd OTA/$DEVICE_NAME
rm $DEVICE_NAME.json
OTA_JSON='{\n"response": [\n{\n"datetime": %s,\n"filename": "%s",\n"id": "%s", \n"romtype": "OFFICIAL", \n"size": %s, \n"url": "https://github.com/PixelBlaster-Releases/%s/releases/download/v%s/%s", \n"version": "%s"\n}\n        ]\n}'
printf "$OTA_JSON" "$Date" "$ZIP_NAME" "$ID" "$Size" "$DEVICE_NAME" "$VERSION" "$ZIP_NAME" "$VERSION" > $DEVICE_NAME.json
git add $DEVICE_NAME.json
git commit -m "Update $DEVICE_NAME"
git push