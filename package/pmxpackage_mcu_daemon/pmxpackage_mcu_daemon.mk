#############################################################
#
# mcu_daemon 
#
#############################################################

PMXPACKAGE_MCU_DAEMON_VERSION = 0.0.1
PMXPACKAGE_MCU_DAEMON_SITE_METHOD = local
PMXPACKAGE_MCU_DAEMON_SITE = $(TOPDIR)/primax_packages/mcu_daemon

define PMXPACKAGE_MCU_DAEMON_EXTRACT_CMDS
	 cp -Ra $(DL_DIR)/$(PMXPACKAGE_MCU_DAEMON_SOURCE)/* $(@D)
endef

define PMXPACKAGE_MCU_DAEMON_INSTALL_TARGET_CMDS
	cp -a $(@D)/mcu_daemon $(TARGET_DIR)/bin/
	cp -a $(@D)/stm32isp $(TARGET_DIR)/sbin/
	cp -Ra $(@D)/firmware/* $(BINARIES_DIR)/
endef

$(eval $(generic-package))
