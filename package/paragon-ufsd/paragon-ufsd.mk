#############################################################
#
# paragon-ufsd
#
#############################################################

PARAGON_UFSD_VERSION = k3.2.0_2013-10-15_lke_9.0.0_r232673_b26
PARAGON_UFSD_SOURCE = ufsd_driver_package_Build_for__WD_Passport_wireless_$(PARAGON_UFSD_VERSION).tar.gz
PARAGON_UFSD_DEPENDENCIES = linux
PARAGON_UFSD_INSTALL_STAGING = YES

define PARAGON_UFSD_EXTRACT_CMDS
	tar xvfz $(DL_DIR)/$(PARAGON_UFSD_SOURCE) -C $(@D)
endef

define PARAGON_UFSD_BUILD_CMDS
	(cd $(@D); \
		./configure CFLAGS="-I$(LINUX_DIR)/arch/arm/include -I$(LINUX_DIR)/arch/arm/include/generated -I$(LINUX_DIR)/include -mlittle-endian -I$(LINUX_DIR)/arch/arm/mach-omap2/include -I$(LINUX_DIR)/arch/arm/plat-omap/include -fno-strict-aliasing -fno-common -fno-delete-null-pointer-checks -O2 -marm -fno-dwarf2-cfi-asm -fno-omit-frame-pointer -mapcs -mno-sched-prolog -mabi=aapcs-linux -mno-thumb-interwork -D__LINUX_ARM_ARCH__=7 -march=armv7-a -msoft-float -Uarm -fno-stack-protector -fno-omit-frame-pointer -fno-optimize-sibling-calls -fno-strict-overflow -fconserve-stack -DCC_HAVE_ASM_GOTO  -O1" CC=$(TARGET_CROSS)gcc STRIP=$(TARGET_CROSS)strip --target=arm --host=$(TARGET_CROSS) --with-ks-dir=$(LINUX_DIR) --with-kb-dir=$(LINUX_DIR) --enable-check-without-libc;	\
		make PACKAGE_TAG="lke_9.0.0_r232673_b26" ARCH="arm" CROSS_COMPILE=$(TARGET_CROSS) CROSSCOMPILE=$(TARGET_CROSS) TARGET="arm" CFLAGS="" driver	\
	)
endef

define PARAGON_UFSD_INSTALL_TARGET_CMDS
	cp -a $(@D)/*.ko $(TARGET_DIR)/lib/modules/
endef

define PARAGON_UFSD_INSTALL_INIT_SYSV
endef

$(eval $(generic-package))
