# Copyright (C) 2017 Unlegacy-Android
# Copyright (C) 2017,2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -----------------------------------------------------------------
# PixelBlaster OTA update package

BLASTER_TARGET_PACKAGE := $(PRODUCT_OUT)/PixelBlaster-$(BLASTER_VERSION)-$(BLASTER_BUILD)-$(BLASTER_BUILD_VARIANT)-$(BLASTER_BUILD_TYPE)-$(BLASTER_BUILD_DATE).zip

SHA256 := prebuilts/build-tools/path/$(HOST_PREBUILT_TAG)/sha256sum

.PHONY: bacon
bacon: $(INTERNAL_OTA_PACKAGE_TARGET)
	$(hide) ln -f $(INTERNAL_OTA_PACKAGE_TARGET) $(BLASTER_TARGET_PACKAGE)
	$(hide) $(SHA256) $(BLASTER_TARGET_PACKAGE) | sed "s|$(PRODUCT_OUT)/||" > $(BLASTER_TARGET_PACKAGE).sha256sum
	$(hide) $(shell echo $(BLASTER_TARGET_PACKAGE) >> blaster_zip)
	@echo -e ${CL_CYN}"=============================-Package Details-============================"${CL_RST}
	@echo -e ${CL_CYN}"File           : "${CL_MAG} $(BLASTER_TARGET_PACKAGE)${CL_RST}
	@echo -e ${CL_CYN}"ZipName        : "${CL_MAG} PixelBlaster-$(BLASTER_VERSION)-$(BLASTER_BUILD)-$(BLASTER_BUILD_VARIANT)-$(BLASTER_BUILD_TYPE)-$(BLASTER_BUILD_DATE).zip${CL_RST}
	@echo -e ${CL_CYN}"Build ID       : $(shell md5sum $(BLASTER_TARGET_PACKAGE) | awk '{print $$1}')"${CL_RST}
	@echo -e ${CL_CYN}"Size           : "${CL_MAG}"$(shell du -hs $(BLASTER_TARGET_PACKAGE) | awk '{print $$1}')"${CL_RST}
	@echo -e ${CL_CYN}"Size(Bytes)    : "${CL_MAG}"$(shell wc -c $(BLASTER_TARGET_PACKAGE) | awk '{print $$1}')"${CL_RST}
	@echo -e ${CL_CYN}"DateTime       : "${CL_MAG}"$(shell grep "ro.build.date.utc=" $(PRODUCT_OUT)/system/build.prop | cut -d "=" -f 2)"${CL_RST}
	@echo -e ${CL_CYN}"Build Type     : "${CL_MAG} $(BLASTER_BUILD_TYPE)${CL_RST}
	@echo -e ${CL_CYN}"==========================================================================="${CL_RST}