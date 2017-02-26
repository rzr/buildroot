#############################################################
#
# rxdsk 
#
#############################################################

RXDSK_VERSION = 2.11
RXDSK_SOURCE = rxdsk-$(RXDSK_VERSION).tgz
RXDSK_DEPENDENCIES = linux
RXDSK_CFLAGS = \
				 -I$(LINUX_HEADERS_DIR)/include \
				 -I$(LINUX_DIR)/include 
RXDSK_MAKE_ENV = \
			   	 LINUX_MAKE=FLAGS=""$(LINUX_MAKE_FLAGS)"" \
				 CFLAGS="$(RXDSK_CFLAGS)" \
				 TD="$(TARGET_DIR)" \
				 LINUX_DIR="$(LINUX_DIR)"


define RXDSK_BUILD_CMDS
	$(MAKE) -C $(@D) $(RXDSK_MAKE_ENV) V=1
endef

define RXDSK_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) $(RXDSK_MAKE_ENV) V=1 install
endef

$(eval $(generic-package))
