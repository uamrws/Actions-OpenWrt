#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# ============ 第三方插件源（为兼容官方 OpenWrt 精挑的来源）============
# 原则：官方源能提供的，一律走官方；官方没有的，才用口碑好的专门源。
#   - AdGuard Home / 网络唤醒WOL / Watchcat / 动态DNS → 官方 luci + packages 源（feeds.conf.default 自带，无需加）
#   - OpenClash → 上游官方仓库 vernesong/OpenClash（专为官方 OpenWrt 设计，最兼容）
#   - ddns-go   → sirpdboy/luci-app-ddns-go（独立维护，含 ddns-go 本体 + LuCI 界面）
#
# 幂等处理：本地断点续跑会复用同一个 openwrt/ 与 feeds.conf.default，
# 先清掉可能已存在的旧行再追加，避免 "Duplicate feed name" 报错。
sed -i '/vernesong\/OpenClash\.git/d;/sirpdboy\/luci-app-ddns-go\.git/d' feeds.conf.default
echo 'src-git OpenClash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default
echo 'src-git ddns_go https://github.com/sirpdboy/luci-app-ddns-go.git' >> feeds.conf.default
