#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# ============ 自定义配置（可按需改）============

# 修改默认管理 IP / 网关（把 192.168.1.1 改成你想要的网段）
sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# 修改默认主机名
sed -i "s/hostname='OpenWrt'/hostname='MyRouter'/" package/base-files/files/bin/config_generate

# （可选）更换默认主题：官方源自带 luci-theme-openwrt-2020；argon 需额外装包，勿直接替换
# sed -i 's/luci-theme-bootstrap/luci-theme-openwrt-2020/g' feeds/luci/collections/luci/Makefile

# ============ 预置内核网络参数（写入固件 sysctl.d）============
mkdir -p package/base-files/files/etc/sysctl.d
# TCP BBR 拥塞控制
echo 'net.ipv4.tcp_congestion_control=bbr' >> package/base-files/files/etc/sysctl.d/99-bbr.conf
# IPsec NAT-T（UDP 4500）空闲时长连接优化：
# 默认 nf_conntrack_udp_timeout_stream≈120s，隧道一空闲映射就被清掉 → 连久了劣化。
# 调高后空闲映射存活更久（根治仍建议在 VPN 服务器开启 NAT-T keepalive）。
echo 'net.netfilter.nf_conntrack_udp_timeout_stream=600' >> package/base-files/files/etc/sysctl.d/99-bbr.conf
echo 'net.netfilter.nf_conntrack_udp_timeout=60' >> package/base-files/files/etc/sysctl.d/99-bbr.conf

# ============ 放入自编译的自定义包（见 custom/）============
mkdir -p package/custom
cp -r "$GITHUB_WORKSPACE/custom/vlmcsd" package/custom/
cp -r "$GITHUB_WORKSPACE/custom/luci-app-vlmcsd" package/custom/
# 覆盖 feed 的 ddns-go：sirpdboy 最新版(6.13+)的 go.mod 要 Go>=1.25，OpenWrt 24.10 只带 Go 1.23.12
# 钉到 v6.12.5（go.mod 要求 go 1.23.12，完全匹配）；luci-app-ddns-go UI 仍用 feed 最新版
rm -rf package/feeds/ddns_go/ddns-go
cp -r "$GITHUB_WORKSPACE/custom/ddns-go" package/custom/ddns-go

# ============ 把插件写进 .config（make defconfig 会自动补全依赖）============
cat >> .config << 'EOF'
# ===== 插件本体（各自 DEPENDS 已含的依赖不手加，make defconfig 自动补齐）=====
# LuCI 基础（luci 集合含 luci-app-firewall → 端口转发管理页，自动带上）
CONFIG_PACKAGE_luci=y
# OpenClash · 代理分流（自动带 dnsmasq-full / kmod-tun / bash / curl / ruby 等）
CONFIG_PACKAGE_luci-app-openclash=y
# AdGuard Home · DNS 去广告（自动带 adguardhome 本体）
CONFIG_PACKAGE_luci-app-adguardhome=y
# 动态DNS（ddns-go，自动带 ddns-go 本体）
CONFIG_PACKAGE_luci-app-ddns-go=y
# Watchcat · 断线检测重启（自动带 watchcat）
CONFIG_PACKAGE_luci-app-watchcat=y
# 网络唤醒 WOL（自动带 etherwake）
CONFIG_PACKAGE_luci-app-wol=y
# KMS 服务器（自定义包，见 custom/，自动带 vlmcsd）
CONFIG_PACKAGE_luci-app-vlmcsd=y

# ===== 必须手动干预的开关（不属于任何 DEPENDS，显式声明）=====
# 默认基础版 dnsmasq 与 dnsmasq-full 互斥：OpenClash 需要 full 版（nftset/ipset），故关掉默认版
CONFIG_PACKAGE_dnsmasq=n

# ===== 按需功能项（非插件依赖，为你的使用场景主动加）=====
# 网卡驱动：6× Intel I211
CONFIG_PACKAGE_kmod-igb=y
# NAT 流表卸载（Firewall 开 Flow Offloading 时提速转发）
CONFIG_PACKAGE_kmod-nft-flowtable=y
# 多网卡中断均衡
CONFIG_PACKAGE_irqbalance=y
# TCP BBR（若内核已内置则自动跳过）
CONFIG_PACKAGE_kmod-tcp-bbr=y
# 官方磁盘挂载（block-mount/blockd 开机自动挂载；挂载点页面由 luci-mod-system 自带）
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_blockd=y
# 文件系统支持（按 2TB HDD 常用格式备齐）
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
# QoS（SQM/cake）：消除缓冲膨胀、满载时稳定延迟，官方源，默认关闭按需启用
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_sqm-scripts=y
# 按设备流量监控（自动带 nlbwmon）——看 NAS/PT 谁在占带宽
CONFIG_PACKAGE_luci-app-nlbwmon=y
# OpenClash TPROXY 模式支持（性能优于 TUN，配合流表卸载）
CONFIG_PACKAGE_kmod-nft-tproxy=y
# 系统/网络监控图表（自动带 collectd+rrdtool）
CONFIG_PACKAGE_luci-app-statistics=y

# ===== 无 WiFi 网卡，关闭无线组件 =====
CONFIG_PACKAGE_wpad-basic-mbedtls=n
CONFIG_PACKAGE_wpad-basic=n
CONFIG_PACKAGE_wpad=n
CONFIG_PACKAGE_hostapd-common=n
CONFIG_PACKAGE_kmod-mac80211=n
CONFIG_PACKAGE_kmod-cfg80211=n
CONFIG_PACKAGE_kmod-ath9k=n
CONFIG_PACKAGE_kmod-ath10k=n
CONFIG_PACKAGE_kmod-mt76=n
CONFIG_PACKAGE_iw=n
CONFIG_PACKAGE_iw-full=n
EOF
