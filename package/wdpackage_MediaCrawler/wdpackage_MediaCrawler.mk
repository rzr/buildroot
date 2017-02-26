WDPACKAGE_MEDIACRAWLER_VERSION = 2.3.3-14
WDPACKAGE_MEDIACRAWLER_RELEASE_DATE = 2014-06-03
WDPACKAGE_MEDIACRAWLER_SOURCE = wdmpserver-av-release-$(WDPACKAGE_MEDIACRAWLER_VERSION).deb

define WDPACKAGE_MEDIACRAWLER_EXTRACT_CMDS
	dpkg-deb -R $(DL_DIR)/$(WDPACKAGE_MEDIACRAWLER_SOURCE) $(TARGET_DIR)/
endef

define WDPACKAGE_MEDIACRAWLER_INSTALL_TARGET_CMDS
	#mv $(TARGET_DIR)/etc/init.d/wdmcserverd $(TARGET_DIR)/etc/init.d/S85wdmcserverd
	chmod 755 $(TARGET_DIR)/etc/init.d/S85wdmcserverd
	chmod 755 $(TARGET_DIR)/usr/local/wdmcserver/bin/*
	sed -i 's/CRAWLER_.*/CRAWLER_'$(WDPACKAGE_MEDIACRAWLER_VERSION):$(WDPACKAGE_MEDIACRAWLER_RELEASE_DATE)'/' $(TARGET_DIR)/etc/version.packages
endef

define WDPACKAGE_MEDIACRAWLER_UNINSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/usr/local/wdmcserver/bin/*
	rm -f $(TARGET_DIR)/etc/nas/notify.d/wdmcserver.conf
endef

$(eval $(generic-package))
