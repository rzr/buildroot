#############################################################
#
# pskill
#
#############################################################

PSKILL_VERSION = 0.1
PSKILL_SOURCE = pskill-$(PSKILL_VERSION).tgz
PSKILL_INSTALL_STAGING = YES
PSKILL_LICENSE = GPLv2
PSKILL_LICENSE_FILES = COPYING

define PSKILL_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/$(PSKILL_SUBDIR)/pskill.sh \
		$(TARGET_DIR)/usr/sbin/pskill.sh
endef

$(eval $(generic-package))
