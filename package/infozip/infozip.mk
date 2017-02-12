#############################################################
#
# infozip
#
#############################################################
INFOZIP_VERSION = 30
INFOZIP_SOURCE = zip$(INFOZIP_VERSION).tgz
INFOZIP_SITE = ftp://ftp.info-zip.org/pub/infozip/src
INFOZIP_LICENSE = Info-ZIP
INFOZIP_LICENSE_FILES = LICENSE

define INFOZIP_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) \
		CFLAGS="$(TARGET_CFLAGS) -I. -DUNIX -DLARGE_FILE_SUPPORT" \
		AS="$(TARGET_CC) -c" \
		-f unix/Makefile generic
endef

define INFOZIP_INSTALL_TARGET_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) -f unix/Makefile install \
		prefix=$(TARGET_DIR)/usr
endef

$(eval $(generic-package))
