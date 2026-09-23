# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2026 sirpdboy  <herboy2008@gmail.com>
#
# 本文件由 sirpdboy/luci-app-ddns-go 提取并固定版本:
#   - 上游最新(6.17+/6.13+)的 go.mod 要求 Go>=1.25, OpenWrt v24.10.8 仅带 Go 1.23.12
#   - 故钉到 v6.12.5 (其 go.mod 要求 go 1.23.12, 完全匹配), 解决编译失败
#   - luci-app-ddns-go (UI) 仍用 feed 最新版

include $(TOPDIR)/rules.mk

PKG_NAME:=ddns-go
PKG_VERSION:=6.12.5
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/jeessy2/ddns-go/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=b3fff8b758ac6a1bb3b6e463248009e3fb55148ed7f618213f79f6261d120338

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=sirpdboy <herboy2008@gmail.com>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/jeessy2/ddns-go/v6
GO_PKG_LDFLAGS_X:=main.Version=$(PKG_VERSION)
GO_PKG_LDFLAGS:=$(GO_PKG_LDFLAGS_X)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/ddns-go
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  TITLE:=Support IPV4 and IPV6 simple and easy-to-use IP binding domain name tool
  URL:=https://github.com/jeessy2/ddns-go
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle
  USERID:=ddns-go:ddns-go
endef

define Package/ddns-go/description
  A simple and easy-to-use IP binding domain name tool that supports IPV4 and IPV6.
endef

define Package/ddns-go/conffiles
/etc/config/ddns-go
/etc/ddns-go/ddns-go-config.yaml
endef


define Package/ddns-go/install
	$(call GoPackage/Package/Install/Bin,$(1))

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) $(CURDIR)/files/ddns-go.init $(1)/etc/init.d/ddns-go
	$(INSTALL_CONF) $(CURDIR)/files/ddns-go.conf $(1)/etc/config/ddns-go
endef

$(eval $(call GoBinPackage,ddns-go))
$(eval $(call BuildPackage,ddns-go))
