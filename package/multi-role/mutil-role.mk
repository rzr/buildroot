#############################################################
#
# multi-role
#
#############################################################

MULTI_ROLE_SOURCE = multi-role-empty.tgz
MULTI_ROLE_INSTALL_STAGING = YES
MULTI_ROLE_LICENSE = MIT
MULTI_ROLE_LICENSE_FILES = COPYING

define MULTI_ROLE_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D package/multi-role/wifi-restart \
		$(TARGET_DIR)/usr/sbin/wifi-restart
#	$(INSTALL) -D -m 644 package/multi-role/wifi-config \
#		$(TARGET_DIR)/etc/config/wifi-config
	$(INSTALL) -D -m 755 package/multi-role/S40network \
		$(TARGET_DIR)/etc/init.d/S40network
	$(INSTALL) -D -m 755 package/multi-role/S80dhcp-server \
		$(TARGET_DIR)/etc/init.d/S80dhcp-server
	$(INSTALL) -D -m 755 package/multi-role/S90multi-role \
		$(TARGET_DIR)/etc/init.d/S90multi-role
endef

$(eval $(generic-package))
