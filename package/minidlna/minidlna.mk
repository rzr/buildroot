################################################################################
#
# minidlna
#
################################################################################

MINIDLNA_VERSION = 1.1.4
MINIDLNA_SITE = http://downloads.sourceforge.net/project/minidlna/minidlna/$(MINIDLNA_VERSION)
MINIDLNA_LICENSE = GPLv2 BSD-3c
MINIDLNA_LICENSE_FILES = COPYING LICENCE.miniupnpd

MINIDLNA_DEPENDENCIES = \
	$(if $(BR2_NEEDS_GETTEXT_IF_LOCALE),gettext) host-gettext \
	ffmpeg flac libvorbis libogg libid3tag libexif jpeg-turbo sqlite \
	host-xutil_makedepend

ifeq ($(BR2_PREFER_STATIC_LIB),y)
# the configure script / Makefile forgets to link with some of the dependent
# libraries breaking static linking, so help it along
MINIDLNA_CONF_ENV = \
	LIBS='-lavformat -lavcodec -lavutil -logg -lz -lpthread -lm'
else
MINIDLNA_CONF_OPT = \
	--disable-static
endif

define MINIDLNA_INSTALL_INITSCRIPTS_CONFIG
	# install start/stop script
	@if [ ! -f $(TARGET_DIR)/etc/init.d/S92minidlna ]; then \
		$(INSTALL) -m 0755 -D package/minidlna/S92minidlna $(TARGET_DIR)/etc/init.d/S92minidlna; \
	fi
	# install config
	@if [ ! -f $(TARGET_DIR)/etc/minidlna.conf ]; then \
		$(INSTALL) -m 0755 -D package/minidlna/minidlna.conf $(TARGET_DIR)/etc/minidlna.conf; \
	fi
endef

MINIDLNA_POST_INSTALL_TARGET_HOOKS += MINIDLNA_INSTALL_INITSCRIPTS_CONFIG

$(eval $(autotools-package))
