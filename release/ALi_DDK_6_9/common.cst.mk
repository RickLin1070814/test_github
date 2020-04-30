
# Added by ALi for creating USER customized file system images
# $(1) --> filesystem format, ext2, cramfs, yaffs2, ubi, ubifs, etc
# $(2) --> UPPERCASE of filesystem format.
# $(3) --> filesystem directory (example: usr/mnt1)
# $(4) --> usr.mnt1
# $(5) --> USR_MNT1
# The output filesystem image shall be usr.mnt1.ext4 (suffix is named by format)

BR2_TARGET_CSTFS_P1_PATH ?= 1
BR2_TARGET_CSTFS_P2_PATH ?= 2
BR2_TARGET_CSTFS_P3_PATH ?= 3
BR2_TARGET_CSTFS_P4_PATH ?= 4
BR2_TARGET_CSTFS_P5_PATH ?= 5
BR2_TARGET_CSTFS_P6_PATH ?= 6

define CSTFS_TARGET_INTERNAL

# extra deps
$(5)_$(2)_DEPENDENCIES += host-fakeroot host-makedevs \
	$(if $(PACKAGES_USERS),host-mkpasswd)

ifeq ($$(BR2_TARGET_$(5)_$(2)_GZIP),y)
$(5)_$(2)_COMPRESS_EXT = .gz
$(5)_$(2)_COMPRESS_CMD = gzip -9 -c
endif
ifeq ($$(BR2_TARGET_$(5)_$(2)_BZIP2),y)
$(5)_$(2)_COMPRESS_EXT = .bz2
$(5)_$(2)_COMPRESS_CMD = bzip2 -9 -c
endif
ifeq ($$(BR2_TARGET_$(5)_$(2)_LZMA),y)
$(5)_$(2)_DEPENDENCIES += host-lzma
$(5)_$(2)_COMPRESS_EXT = .lzma
$(5)_$(2)_COMPRESS_CMD = $$(LZMA) -9 -c
endif
ifeq ($$(BR2_TARGET_$(5)_$(2)_LZO),y)
$(5)_$(2)_DEPENDENCIES += host-lzop
$(5)_$(2)_COMPRESS_EXT = .lzo
$(5)_$(2)_COMPRESS_CMD = $$(LZOP) -9 -c
endif
ifeq ($$(BR2_TARGET_$(5)_$(2)_XZ),y)
$(5)_$(2)_DEPENDENCIES += host-xz
$(5)_$(2)_COMPRESS_EXT = .xz
$(5)_$(2)_COMPRESS_CMD = $$(XZ) -9 -C crc32 -c
endif

$$(BINARIES_DIR)/$(4).$(1): target-finalize $$($(5)_$(2)_DEPENDENCIES)
	cp -rf fs/88x2bu.ko $(TARGET_DIR)/etc
	@$$(call MESSAGE,"Generating user filesystem image $(4).$(1)")
	$$(foreach hook,$$($(5)_$(2)_PRE_GEN_HOOKS),$$(call $$(hook))$$(sep))
	rm -f $$(FAKEROOT_SCRIPT)
	rm -f $$(TARGET_DIR_WARNING_FILE)
	mkdir -p $(TARGET_DIR)/$(3)/NO_USAGE
	mkdir -p $(BASE_DIR)/$(4)
	cp -rf $(TARGET_DIR)/$(3)/* $$(BASE_DIR)/$(4)/
	rm -rf $(BASE_DIR)/$(4)/NO_USAGE
	rm -rf $(TARGET_DIR)/$(3)/*
	echo "chown -R 0:0 $$(BASE_DIR)/$(4)" >> $$(FAKEROOT_SCRIPT)
	echo "$$($(5)_$(2)_CMD)" >> $$(FAKEROOT_SCRIPT)
	chmod a+x $$(FAKEROOT_SCRIPT)
ifeq ($(BR2_ENABLE_FILE_SIGNATURE_ALIASIX),y)
ifeq ($$($(5)_$(2)_MOUNT_ATTR),ro)
	$(call ALIASIX_FILE_SIGNATURE,sign,$(BASE_DIR)/$(4))
endif
endif
	$$(HOST_DIR)/usr/bin/fakeroot -- $$(FAKEROOT_SCRIPT)
	-@rm -f $$(FAKEROOT_SCRIPT)
	echo 'mkdir -p $(BASE_DIR)/$(4)/NO_USAGE' >> $(BASE_DIR)/RECOVER_CSTFS
	echo 'cp -rf $(BASE_DIR)/$(4)/* $(TARGET_DIR)/$(3)/' >> $(BASE_DIR)/RECOVER_CSTFS
	echo 'rm -rf $(BASE_DIR)/$(4)' >> $(BASE_DIR)/RECOVER_CSTFS
	echo 'rm -rf $(TARGET_DIR)/$(3)/NO_USAGE' >> $(BASE_DIR)/RECOVER_CSTFS
ifneq ($$($(5)_$(2)_COMPRESS_CMD),)
	$$($(5)_$(2)_COMPRESS_CMD) $$@ > $$@$$($(5)_$(2)_COMPRESS_EXT)
endif
ifeq ($$($(5)_$(2)_DM_CRYPT),y)
	$(call ALIAS_DM_CRYPT,$$@)
endif
	
	@if test -f $(TOPDIR)/fs/check_partition_size.sh; then \
		$(TOPDIR)/fs/check_partition_size.sh $$($(5)_$(2)_MTD_PARTITION_SIZE) $(BASE_DIR)/$(4) ; \
	else \
		$(call MESSAGE,"Error: there is no $(1)"); \
	fi	

$(4)-$(1)-show-depends:
	@echo $$($(5)_$(2)_DEPENDENCIES)

$(4)-$(1): $$(BINARIES_DIR)/$(4).$(1) $$($(5)_$(2)_POST_TARGETS)
ifeq ($(BR2_ENABLE_FILE_SIGNATURE_ALIASIX),y)
ifeq ($$($(5)_$(2)_MOUNT_ATTR),ro)
	$(call ALIASIX_FILE_SIGNATURE,clean,$(BASE_DIR)/$(4))
endif
endif

ifeq ($$(BR2_TARGET_$(5)_$(2)),y)
TARGETS_CSTFS += $(4)-$(1)
endif
endef

define CSTFS_TARGET
$(call CSTFS_TARGET_INTERNAL,$(1),$(call UPPERCASE,$(1)),$(call qstrip,$(2)),$(call qstrip,$(subst /,.,$(2))),$(call qstrip,$(call UPPERCASE,$(subst /,.,$(2)))))
endef
