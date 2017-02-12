#############################################################
#
# lsb
#
#############################################################

LSB_VERSION = 4.1+Debian8+deb7u1
LSB_SOURCE = lsb_$(LSB_VERSION).tar.bz2
LSB_SITE = $(BR2_DEBIAN_MIRROR)/debian/pool/main/l/lsb
LSB_INSTALL_STAGING = YES
LSB_LICENSE = GPLv2
LSB_LICENSE_FILES = COPYING

define LSB_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/lib/lsb
	(cd $(@D); chmod +x init-functions; cp init-functions $(TARGET_DIR)/lib/lsb)
	(cd $(@D); cp -a init-functions.d $(TARGET_DIR)/lib/lsb)
endef

$(eval $(generic-package))
