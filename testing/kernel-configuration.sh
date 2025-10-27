#!/bin/bash
#Execute in the linux folder.

# Preface
rm -f .config
make defconfig

# General setup
./scripts/config --disable WERROR
./scripts/config --enable PSI
./scripts/config --disable PSI_DEFAULT_DISABLED
./scripts/config --disable IKHEADERS
./scripts/config --enable CGROUPS
./scripts/config --enable MEMCG
./scripts/config --enable CGROUP_SCHED
./scripts/config --disable RT_GROUP_SCHED
./scripts/config --disable EXPERT

# Processor type and features
./scripts/config --enable RELOCATABLE
./scripts/config --enable RANDOMIZE_BASE
./scripts/config --enable X86_X2APIC
./scripts/config --enable EFI
./scripts/config --enable EFI_STUB

# General architecture-dependent options
./scripts/config --enable STACKPROTECTOR
./scripts/config --enable STACKPROTECTOR_STRONG

# Networking support
./scripts/config --enable NET
./scripts/config --enable INET
./scripts/config --enable IPV6

# Device Drivers - Generic
./scripts/config --disable UEVENT_HELPER
./scripts/config --enable DEVTMPFS
./scripts/config --enable DEVTMPFS_MOUNT
./scripts/config --enable FW_LOADER
./scripts/config --disable FW_LOADER_USER_HELPER
./scripts/config --enable DMIID
./scripts/config --enable SYSFB_SIMPLEFB

# Graphics support
./scripts/config --enable DRM
./scripts/config --enable DRM_PANIC
./scripts/config --set-str DRM_PANIC_SCREEN kmsg
./scripts/config --enable DRM_FBDEV_EMULATION
./scripts/config --enable DRM_SIMPLEDRM
./scripts/config --enable FRAMEBUFFER_CONSOLE

# File systems
./scripts/config --enable INOTIFY_USER
./scripts/config --enable TMPFS
./scripts/config --enable TMPFS_POSIX_ACL
./scripts/config --enable VFAT_FS
./scripts/config --enable EFIVAR_FS
./scripts/config --enable XFS_FS
./scripts/config --enable JFS_FS

# NLS
./scripts/config --enable NLS
./scripts/config --enable NLS_CODEPAGE_437
./scripts/config --enable NLS_ISO8859_1

# Block layer
./scripts/config --enable BLOCK
./scripts/config --enable PARTITION_ADVANCED
./scripts/config --enable EFI_PARTITION

# Block devices
./scripts/config --enable BLK_DEV
./scripts/config --enable BLK_DEV_RAM

# Multiple devices (RAID/LVM)
./scripts/config --enable MD
./scripts/config --enable BLK_DEV_DM
./scripts/config --enable DM_CRYPT
./scripts/config --enable DM_SNAPSHOT
./scripts/config --enable DM_THIN_PROVISIONING
./scripts/config --enable DM_CACHE
./scripts/config --enable DM_MIRROR
./scripts/config --enable DM_ZERO
./scripts/config --enable DM_DELAY

# PCI
./scripts/config --enable PCI
./scripts/config --enable PCI_MSI

# IOMMU
./scripts/config --enable IOMMU_SUPPORT
./scripts/config --enable IRQ_REMAP

# Cryptographic API
./scripts/config --enable CRYPTO
./scripts/config --enable CRYPTO_AES
./scripts/config --enable CRYPTO_TWOFISH
./scripts/config --enable CRYPTO_XTS
./scripts/config --enable CRYPTO_SHA256
./scripts/config --enable CRYPTO_USER_API_SKCIPHER

# Netfilter
./scripts/config --enable NETFILTER
./scripts/config --enable NETFILTER_ADVANCED
./scripts/config --enable NF_CONNTRACK
./scripts/config --enable NETFILTER_XTABLES
./scripts/config --enable NETFILTER_XT_TARGET_LOG
./scripts/config --enable IP_NF_IPTABLES

# Auditing
./scripts/config --enable AUDIT

# Kernel hacking
./scripts/config --enable MAGIC_SYSRQ
