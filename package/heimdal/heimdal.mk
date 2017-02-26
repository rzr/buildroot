################################################################################
#
# heimdal
#
################################################################################

HEIMDAL_VERSION = 1.5.3
HEIMDAL_SITE = http://www.h5l.org/dist/src
# host-e2fsprogs for compile_et, e2fsprogs for libcom_err
HEIMDAL_DEPENDENCIES = host-e2fsprogs host-heimdal host-pkgconf e2fsprogs ncurses sqlite
# No host-sqlite, use builtin
HOST_HEIMDAL_DEPENDENCIES = host-e2fsprogs host-pkgconf
HEIMDAL_INSTALL_STAGING = YES
HEIMDAL_CONF_OPT = --with-cross-tools=$(HOST_DIR)/usr/libexec/heimdal \
	--with-x=no
# -fPIC issues with e2fsprogs on x86_64 host :-/
HOST_HEIMDAL_CONF_OPT = --with-x=no --disable-shared --enable-static
HEIMDAL_MAKE = $(MAKE1)
# For heimdal-0004-compile_et.patch
HEIMDAL_AUTORECONF = YES
HEIMDAL_LICENSE = BSD-3c
HEIMDAL_LICENSE_FILES = LICENSE

# krb5-config from $(HOST_DIR) gets picked up from PATH
define HEIMDAL_HOST_KRB5_CONFIG_FIXUP
	$(SED) "s,^includedir=.*,includedir=\'$(STAGING_DIR)/usr/include\',g" $(HOST_DIR)/usr/bin/krb5-config
	$(SED) "s,^libdir=.*,libdir=\'$(STAGING_DIR)/usr/lib\',g" $(HOST_DIR)/usr/bin/krb5-config
endef

HEIMDAL_POST_INSTALL_TARGET_HOOKS += HEIMDAL_HOST_KRB5_CONFIG_FIXUP

# We need asn1_compile in the PATH for samba 4
# We also need compile_et for the target heimdal (via --cross-tools)
define HOST_HEIMDAL_MAKE_SYMLINK
	ln -sf $(HOST_DIR)/usr/libexec/heimdal/asn1_compile \
		$(HOST_DIR)/usr/bin/asn1_compile
	ln -sf $(HOST_DIR)/usr/bin/compile_et \
		$(HOST_DIR)/usr/libexec/heimdal/compile_et
endef

HOST_HEIMDAL_POST_INSTALL_HOOKS += HOST_HEIMDAL_MAKE_SYMLINK

$(eval $(autotools-package))
$(eval $(host-autotools-package))
