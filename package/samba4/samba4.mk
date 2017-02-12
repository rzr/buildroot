################################################################################
#
# samba4
#
################################################################################

SAMBA4_VERSION = 4.1.3
SAMBA4_SITE = http://ftp.samba.org/pub/samba/stable
SAMBA4_SOURCE = samba-$(SAMBA4_VERSION).tar.gz
SAMBA4_LICENSE = GPLv3+
SAMBA4_LICENSE_FILES = COPYING
SAMBA4_DEPENDENCIES = host-e2fsprogs host-heimdal e2fsprogs popt python zlib \
	$(if $(BR2_PACKAGE_LIBCAP),libcap)
#SAMBA4_DEPENDENCIES = host-e2fsprogs e2fsprogs popt python zlib  \
#	$(if $(BR2_PACKAGE_LIBCAP),libcap)

ifeq ($(BR2_PACKAGE_ACL),y)
	SAMBA4_CONF_OPT += --with-acl-support
	SAMBA4_DEPENDENCIES += acl
else
	SAMBA4_CONF_OPT += --without-acl-support
endif

ifeq ($(BR2_PACKAGE_LIBAIO),y)
	SAMBA4_CONF_OPT += --with-aio-support
	SAMBA4_DEPENDENCIES += libaio
else
	SAMBA4_CONF_OPT += --without-aio-support
endif

ifeq ($(BR2_PACKAGE_DBUS)$(BR2_PACKAGE_AVAHI_DAEMON),yy)
	SAMBA4_CONF_OPT += --enable-avahi
	SAMBA4_DEPENDENCIES += avahi
else
	SAMBA4_CONF_OPT += --disable-avahi
endif

ifeq ($(BR2_PACKAGE_GAMIN),y)
	SAMBA4_CONF_OPT += --with-fam
	SAMBA4_DEPENDENCIES += gamin
else
	SAMBA4_CONF_OPT += --without-fam
endif

ifeq ($(BR2_PACKAGE_GNUTLS),y)
	SAMBA4_CONF_OPT += --enable-gnutls
	SAMBA4_DEPENDENCIES += gnutls
else
	SAMBA4_CONF_OPT += --disable-gnutls
endif

define SAMBA4_CONFIGURE_CMDS
	cp package/samba4/$(call qstrip,$(BR2_ARCH))-cache.txt $(@D)/cache.txt;
	(cd $(@D); \
		PYTHON_CONFIG="$(STAGING_DIR)/usr/bin/python-config" \
		$(TARGET_CONFIGURE_OPTS) \
		./buildtools/bin/waf configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--localstatedir=/var \
			--with-libiconv=$(STAGING_DIR)/usr \
			--enable-fhs \
			--cross-compile \
			--cross-answers=$(@D)/cache.txt \
			--hostcc=gcc \
			--disable-rpath \
			--disable-rpath-install \
			--disable-cups \
			--without-dmapi \
			--without-gettext \
			--disable-glusterfs \
			--without-ldap \
			$(SAMBA4_CONF_OPT) \
	)
endef

define SAMBA4_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -I$(HOST_DIR)/usr/include -C $(@D)
endef

define SAMBA4_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) install
endef

define SAMBA4_INSTALL_INITSCRIPT
	@if [ ! -f $(TARGET_DIR)/etc/init.d/S91smb ]; then \
		$(INSTALL) -m 0755 -D package/samba4/S91smb \
			$(TARGET_DIR)/etc/init.d/S91smb; \
	fi
	# install config
	@if [ ! -f $(TARGET_DIR)/etc/samba/smb.conf ]; then \
		$(INSTALL) -m 0755 -D package/samba4/simple.conf $(TARGET_DIR)/etc/samba/smb.conf; \
	fi
	
endef

# uClibc-based builds don't like libtalloc in /usr/lib/samba
# The proper fix is to add a proper talloc package
define SAMBA4_MOVE_TALLOC
	mv -f $(TARGET_DIR)/usr/lib/samba/libtalloc* $(TARGET_DIR)/usr/lib
endef

SAMBA4_POST_INSTALL_TARGET_HOOKS += SAMBA4_INSTALL_INITSCRIPT SAMBA4_MOVE_TALLOC

$(eval $(generic-package))
