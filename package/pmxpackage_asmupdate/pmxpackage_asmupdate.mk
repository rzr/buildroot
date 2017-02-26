#############################################################
#
# asmupdate 
#
#############################################################

PMXPACKAGE_ASMUPDATE_VERSION = 0.0.1
PMXPACKAGE_ASMUPDATE_SITE_METHOD = local
PMXPACKAGE_ASMUPDATE_SITE = $(TOPDIR)/primax_packages/asmupdate
ASMEDIA_FIRMWARE_VERSION = 1009-20141015

define PMXPACKAGE_ASMUPDATE_EXTRACT_CMDS
	 cp -Ra $(DL_DIR)/$(PMXPACKAGE_ASMUPDATE_SOURCE)/* $(@D)
endef

define PMXPACKAGE_ASMUPDATE_INSTALL_TARGET_CMDS
	cp -a $(@D)/asmupdate $(TARGET_DIR)/sbin/
	ln -sf /sbin/asmupdate $(TARGET_DIR)/bin/stbtool
	cp -Ra $(@D)/firmware/Release-VS-$(ASMEDIA_FIRMWARE_VERSION).bin $(BINARIES_DIR)/AsmSataFw.bin
endef

$(eval $(generic-package))
