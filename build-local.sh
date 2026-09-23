#!/bin/bash
#
# OpenWrt v24.10.8 本地编译脚本
# 运行环境: Parallels Desktop 内的 Ubuntu 22.04.5 (给 VM 分配 >=4 核 / >=8G 内存 / >=40G 磁盘)
# 用法: bash build-local.sh
#
# 说明:
#   - 复用仓库里的 .config / diy-part1.sh / diy-part2.sh / custom/ (与 GitHub Actions 完全一致)
#   - 走官方源码 tag v24.10.8
#   - 支持断点续跑: 已克隆/已下载的部分不会重复

set -e

REPO_URL="https://github.com/openwrt/openwrt"
REPO_BRANCH="v24.10.8"
CONFIG_REPO="https://github.com/uamrws/Actions-OpenWrt.git"   # 你的配置仓库 (含 .config/diy/custom)
WORKDIR="$HOME/openwrt-build"
NPROC=$(nproc)

echo "======================================================"
echo " OpenWrt $REPO_BRANCH 本地编译"
echo " 工作目录: $WORKDIR    编译线程: $NPROC"
echo "======================================================"

# ---------- 1. 安装编译依赖 (Ubuntu 22.04, 已验证) ----------
echo "[1/7] 安装编译依赖 ..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git file \
  libncurses-dev libssl-dev python3-distutils python3-setuptools rsync swig unzip zlib1g-dev \
  ack antlr3 asciidoc autoconf automake autopoint binutils bzip2 ccache cmake cpio curl \
  device-tree-compiler fastjar gperf haveged help2man intltool libc6-dev-i386 libelf-dev \
  libfuse-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libpython3-dev \
  libreadline-dev libtool lrzsz mkisofs msmtp ninja-build p7zip p7zip-full patch pkg-config \
  python3 python3-pyelftools qemu-utils scons squashfs-tools subversion texinfo uglifyjs \
  upx-ucl vim wget xmlto xxd

# ---------- 2. 克隆官方 OpenWrt 源码 (tag v24.10.8) ----------
echo "[2/7] 克隆 OpenWrt $REPO_BRANCH ..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"
if [ ! -d openwrt/.git ]; then
  git clone "$REPO_URL" -b "$REPO_BRANCH" openwrt
else
  echo "  已存在 openwrt, 跳过克隆"
fi

# ---------- 3. 拉取你的配置仓库 (diy / custom / .config) ----------
echo "[3/7] 拉取配置仓库 ..."
if [ ! -d config-repo/.git ]; then
  git clone "$CONFIG_REPO" config-repo
else
  git -C config-repo pull || echo "  配置仓库无更新"
fi
export GITHUB_WORKSPACE="$WORKDIR/config-repo"     # diy 脚本用到的 custom/ 路径
chmod +x "$GITHUB_WORKSPACE/diy-part1.sh" "$GITHUB_WORKSPACE/diy-part2.sh"

# ---------- 4. 应用自定义 feeds (diy-part1: 追加 OpenClash / ddns_go) ----------
echo "[4/7] 应用自定义 feeds ..."
cd "$WORKDIR/openwrt"
"$GITHUB_WORKSPACE/diy-part1.sh"

# ---------- 5. Update + Install feeds ----------
echo "[5/7] update + install feeds (首次较久) ..."
./scripts/feeds update -a
./scripts/feeds install -a

# ---------- 6. 应用配置 + 下载源码 + 编译 ----------
echo "[6/7] 应用配置并开始编译 ..."
cp -f "$GITHUB_WORKSPACE/.config" .config
[ -d "$GITHUB_WORKSPACE/files" ] && cp -r "$GITHUB_WORKSPACE/files" ./files
"$GITHUB_WORKSPACE/diy-part2.sh"

make defconfig
make download -j8
echo "  开始编译 ($NPROC 线程, 预计 1~3 小时) ..."
make -j"$NPROC" || make -j1 || make -j1 V=s

# ---------- 7. 完成 ----------
echo "[7/7] 编译完成! 固件位置:"
ls -lh bin/targets/*/*
echo
echo "刷机建议:"
echo "  UEFI 主板 → 选 *-squashfs-combined-efi.img.gz"
echo "  Legacy   → 选 *-squashfs-combined.img.gz"
echo "  解压后写入 /dev/sda (仅系统盘; 你的 2TB HDD 是 /dev/sdb, 不受影响)"
