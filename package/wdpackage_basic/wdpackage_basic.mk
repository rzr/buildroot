WDPACKAGE_BASIC_VERSION = 0.01.124
WDPACKAGE_BASIC_RELEASE_DATE = 2016-09-23
WDPACKAGE_BASIC_SITE_METHOD = local
WDPACKAGE_BASIC_SITE = $(TOPDIR)/primax_packages/wdcore_avatar
WDPACKAGE_BASIC_DEPENDENCIES = tzdata

define WDPACKAGE_BASIC_EXTRACT_CMDS
	cp -Ra $(DL_DIR)/$(WDPACKAGE_BASIC_SOURCE)/* $(@D)
endef

define WDPACKAGE_BASIC_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/local/bin
	mkdir -p $(TARGET_DIR)/usr/local/sbin
	mkdir -p $(TARGET_DIR)/var/www/htdocs/ui
	mkdir -p $(TARGET_DIR)/var/lib/dpkg/info
	mkdir -p $(TARGET_DIR)/var/lib/dpkg/status
	mkdir -p $(TARGET_DIR)/etc/netatalk
	mkdir -p $(TARGET_DIR)/DataVolume
	ln -sf /media/sdb1/.wdcache $(TARGET_DIR)/CacheVolume
	ln -sf /tmp/netatalk-db $(TARGET_DIR)/usr/var/netatalk
	ln -sf update_count_get.sh $(TARGET_DIR)/usr/local/sbin/getUpdateCounts.pm
	ln -sf update_count_set.sh $(TARGET_DIR)/usr/local/sbin/incUpdateCount.pm
	ln -sf incUpdateCount.pm $(TARGET_DIR)/usr/local/sbin/update_counts_inc.sh
	cp -Ra $(@D)/*  $(TARGET_DIR)/

	ln -sf Sydney $(TARGET_DIR)/usr/share/zoneinfo/Australia/Canberra
	mkdir -p $(TARGET_DIR)/usr/share/zoneinfo/Brazil
	ln -sf ../posix/America/Noronha $(TARGET_DIR)/usr/share/zoneinfo/Brazil/DeNoronha
	ln -sf ../posix/America/Sao_Paulo $(TARGET_DIR)/usr/share/zoneinfo/Brazil/East
	ln -sf ../posix/America/Manaus $(TARGET_DIR)/usr/share/zoneinfo/Brazil/West
	mkdir -p $(TARGET_DIR)/usr/share/zoneinfo/Canada
	ln -sf ../posix/America/St_Johns $(TARGET_DIR)/usr/share/zoneinfo/Canada/Newfoundland
	ln -sf ../posix/America/Regina $(TARGET_DIR)/usr/share/zoneinfo/Canada/Saskatchewan
	rm $(TARGET_DIR)/usr/share/zoneinfo/Pacific/Guam
	ln -sf Port_Moresby $(TARGET_DIR)/usr/share/zoneinfo/Pacific/Guam
	ln -sf Sydney $(TARGET_DIR)/usr/share/zoneinfo/posix/Australia/Canberra
	ln -sf ../America/Anchorage $(TARGET_DIR)/usr/share/zoneinfo/posix/US/Alaska
	ln -sf ../America/Phoenix $(TARGET_DIR)/usr/share/zoneinfo/posix/US/Arizona
	ln -sf ../America/Chicago $(TARGET_DIR)/usr/share/zoneinfo/posix/US/Central
	ln -sf ../America/New_York $(TARGET_DIR)/usr/share/zoneinfo/posix/US/Eastern
	ln -sf ../America/Indiana/Indianapolis $(TARGET_DIR)/usr/share/zoneinfo/posix/US/East-Indiana
	ln -sf ../Pacific/Honolulu $(TARGET_DIR)/usr/share/zoneinfo/posix/US/Hawaii
	ln -sf ../America/Denver $(TARGET_DIR)/usr/share/zoneinfo/posix/US/Mountain
	ln -sf ../America/Los_Angeles $(TARGET_DIR)/usr/share/zoneinfo/posix/US/Pacific
	[ -f $(TARGET_DIR)/etc/version ] || \
		$(INSTALL) -D -m 755 package/wdpackage_basic/version \
		$(TARGET_DIR)/etc/version

	cp -a package/wdpackage_basic/version $(TARGET_DIR)/etc/
	[ -f $(TARGET_DIR)/etc/version.packages ] || \
		$(INSTALL) -D -m 755 package/wdpackage_basic/version.packages \
		$(TARGET_DIR)/etc/version.packages
	
	sed -i 's/PMXAC_.*/PMXAC_'$(WDPACKAGE_BASIC_VERSION):$(WDPACKAGE_BASIC_RELEASE_DATE)'/' $(TARGET_DIR)/etc/version.packages

endef

define WDPACKAGE_BASIC_UNINSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/var/local/bin
	rm -f $(TARGET_DIR)/var/local/sbin
	rm -f $(TARGET_DIR)/var/www/htdocs/ui
	rm -f $(TARGET_DIR)/usr/local/wdmpserver
	rm -f $(TARGET_DIR)/etc/netatalk
	rm -f $(TARGET_DIR)/CacheVolume
endef

$(eval $(generic-package))
