#
# Copyright (C) 2013-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=Openwrt-api
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define Package/Openwrt-api
	SECTION:=Openwrt-api
	CATEGORY:=Openwrt-api
	TITLE:=Openwrt-api
	DEPENDS :=+luci +luci-mod-rpc
	PKGARCH:=all
endef

define Package/Openwrt-api/description
	This package provides api to remote control.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/Openwrt-api/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/domy_encode $(1)/usr/sbin/
	$(CP) ./files/luci/* $(1)/usr/lib/lua/luci/
	$(CP) ./files/etc/config/* $(1)/etc/config/
	$(CP) ./files/usr/bin/* $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,Openwrt-api))

