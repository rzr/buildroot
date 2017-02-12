WDPACKAGE_RESTAPI_VERSION = 2.4.0-807
WDPACKAGE_RESTAPI_RELEASE_DATE = 2014-09-11
WDPACKAGE_RESTAPI_SOURCE = admin-rest-api-$(WDPACKAGE_RESTAPI_VERSION).deb

define WDPACKAGE_RESTAPI_EXTRACT_CMDS
	dpkg-deb -R $(DL_DIR)/$(WDPACKAGE_RESTAPI_SOURCE) $(TARGET_DIR)/
endef

define WDPACKAGE_RESTAPI_INSTALL_TARGET_CMDS
	tr -d '\r' < $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_get.php > $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_get.php.unix
	mv $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_get.php.unix $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_get.php
	tr -d '\r' < $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_set.php > $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_set.php.unix
	mv $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_set.php.unix $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_set.php
	ln -sf /var/www/rest-api/api/Filesystem/src/Filesystem/Cli/volume_mount.php $(TARGET_DIR)/usr/local/sbin/volume_mount.sh
	ln -sf /var/www/rest-api/api/Storage/src/Storage/Transfer/Cli/storage_transfer_job_start.php $(TARGET_DIR)/usr/local/sbin/storage_transfer_job_start.sh
	chmod 775 $(TARGET_DIR)/var/www/rest-api/api/Storage/src/Storage/Transfer/Cli/storage_transfer_job_start.php
	chmod 775 $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_get.php
	ln -sf /var/www/rest-api/api/System/src/System/Device/Cli/update_count_get.php $(TARGET_DIR)/usr/local/sbin/update_count_get.sh
	chmod 775 $(TARGET_DIR)/var/www/rest-api/api/System/src/System/Device/Cli/update_count_set.php
	ln -sf /var/www/rest-api/api/System/src/System/Device/Cli/update_count_set.php $(TARGET_DIR)/usr/local/sbin/update_count_set.sh
	chmod 775 $(TARGET_DIR)/var/www/rest-api/api/Filesystem/src/Filesystem/Cli/volume_mount.php
	ln -sf /var/www/rest-api/api/Shares/src/Shares/Cli/crud_share_db.php $(TARGET_DIR)/usr/local/sbin/crud_share_db.sh
	chmod 775 $(TARGET_DIR)/var/www/rest-api/api/Shares/src/Shares/Cli/crud_share_db.php
	chmod 775 $(TARGET_DIR)/var/www/rest-api/api/Jobs/src/Jobs/Cli/jobs_clean_up.php
	rm -Rf $(TARGET_DIR)/DEBIAN
	find  $(TARGET_DIR)/var/www/rest-api -name tests -type d | xargs -n 1 rm -rf
	sed -i 's/RESTAPI_.*/RESTAPI_'$(WDPACKAGE_RESTAPI_VERSION):$(WDPACKAGE_RESTAPI_RELEASE_DATE)'/' $(TARGET_DIR)/etc/version.packages
endef

define WDPACKAGE_RESTAPI_INSTALL_INIT_SYSV
	[ -f $(TARGET_DIR)/etc/init.d/S95RestAPI ] || \
		$(INSTALL) -D -m 755 package/wdpackage_RestAPI/S95RestAPI \
		$(TARGET_DIR)/etc/init.d/S95RestAPI
endef

define WDPACKAGE_RESTAPI_UNINSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/var/local/bin
	rm -f $(TARGET_DIR)/var/local/sbin
endef

$(eval $(generic-package))
