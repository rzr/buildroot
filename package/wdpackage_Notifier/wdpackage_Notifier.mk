WDPACKAGE_NOTIFIER_VERSION = 1.0.3-53
WDPACKAGE_NOTIFIER_SOURCE = wdnotifier-av-$(WDPACKAGE_NOTIFIER_VERSION).deb

define WDPACKAGE_NOTIFIER_EXTRACT_CMDS
	dpkg-deb -R $(DL_DIR)/$(WDPACKAGE_NOTIFIER_SOURCE) $(TARGET_DIR)/
endef

define WDPACKAGE_NOTIFIER_INSTALL_TARGET_CMDS
	mv $(TARGET_DIR)/etc/init.d/wdnotifierd $(TARGET_DIR)/etc/init.d/S92wdnotifierd
	chmod 755 $(TARGET_DIR)/etc/init.d/S92wdnotifierd
	chmod 755 $(TARGET_DIR)/usr/local/bin/wdnotifier
	chmod 755 $(TARGET_DIR)/usr/local/sbin/wdmc_rescan_volume.py
endef

define WDPACKAGE_NOTIFIER_UNINSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/etc/init.d/S92wdnotifierd
	rm -f $(TARGET_DIR)/etc/nas/wdnotifier.conf
	rm -f $(TARGET_DIR)/etc/nas/notify.d/wdnotifier.conf
	rm -f $(TARGET_DIR)/etc/cron.d/rescan_internal_volumes
	rm -f $(TARGET_DIR)/usr/local/bin/wdnotifier
	rm -f $(TARGET_DIR)/usr/local/sbin/wdmc_rescan_volume.py
endef

$(eval $(generic-package))
