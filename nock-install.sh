#!/bin/bash

set -e

# 检测操作系统
OS="$(uname)"
echo -e "\n📦 检测操作系统: $OS"

# 检查 shell 类型
SHELL_RC="$HOME/.bashrc"
if [[ $SHELL == *zsh ]]; then
  SHELL_RC="$HOME/.zshrc"
fi
# 如果 rc 文件不存在则自动创建
if [ ! -f "$SHELL_RC" ]; then
  touch "$SHELL_RC"
fi

# 安装依赖
if [[ "$OS" == "Darwin" ]]; then
  echo -e "\n🍎 检测到 macOS，准备安装依赖..."

  # 检查 Xcode Command Line Tools
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "❗ 未检测到 Xcode Command Line Tools，正在安装..."
    xcode-select --install
    echo "请安装完成后重新运行本脚本。"
    exit 1
  fi

  # 检查 Homebrew
  if ! command -v brew >/dev/null 2>&1; then
    echo "❌ 未检测到 Homebrew，请先手动安装 Homebrew: https://brew.sh/"
    exit 1
  fi

  brew update
  brew install curl gcc

  echo "🦀 安装 Rust..."
  if ! command -v rustc &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
  else
    echo "🦀 Rust 已安装，跳过安装。"
  fi
else
  echo -e "\n🐧 检测到 Linux，使用 apt 安装依赖..."
  sudo apt-get update && sudo apt install sudo -y
  sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
fi

# 检查 Rust 是否已安装
if ! command -v cargo >/dev/null 2>&1; then
  echo -e "\n🦀 安装 Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo -e "\n🦀 Rust 已安装，跳过安装。"
  source "$HOME/.cargo/env"
fi
rustup default stable

# 检查 nockchain 仓库
if [ -d "nockchain" ]; then
  echo "⚠️ 已存在 nockchain 目录，是否删除重新克隆？(y/n)"
  read -r confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    rm -rf nockchain
    git clone https://github.com/zorp-corp/nockchain
  else
    echo "➡️ 使用已有目录 nockchain"
  fi
else
  git clone https://github.com/zorp-corp/nockchain
fi

cd nockchain

# 编译核心组件
for step in install-hoonc build install-nockchain-wallet install-nockchain; do
  echo -e "\n🔧 make $step ..."
  if ! make $step; then
    echo "❌ make $step 失败，请检查依赖和源码。"
    exit 1
  fi
  echo "✅ $step 完成"
done

# 配置环境变量
NCK_PATH="$(pwd)/target/release"
echo -e "\n✅ 编译完成，配置环境变量..."
if ! grep -q "$NCK_PATH" $SHELL_RC; then
  echo "export PATH=\"\$PATH:$NCK_PATH\"" >> $SHELL_RC
fi
echo 'export RUST_LOG=info' >> $SHELL_RC
echo 'export MINIMAL_LOG_FORMAT=true' >> $SHELL_RC
source $SHELL_RC

# 生成钱包
echo -e "\n🔐 自动生成钱包助记词与主私钥..."
WALLET_CMD="./target/release/nockchain-wallet"
if [ ! -f "$WALLET_CMD" ]; then
  echo "❌ 未找到钱包命令 $WALLET_CMD"
  exit 1
fi

SEED_OUTPUT=$($WALLET_CMD keygen)
echo "$SEED_OUTPUT"

# 获取助记词
SEED_PHRASE=$($WALLET_CMD show-seedphrase | sed -n "/'/,/'/p" | tr -d "'\n")
echo "🧠 助记词：$SEED_PHRASE"
if [ -z "$SEED_PHRASE" ]; then
  echo "❌ 助记词提取失败，请检查钱包输出。"
  exit 1
fi

# 获取主私钥
MASTER_PRIVKEY=$($WALLET_CMD show-master-privkey | sed -n '7,8p' | tr -d '\n')
echo "主私钥：$MASTER_PRIVKEY"
if [ -z "$MASTER_PRIVKEY" ]; then
  echo "❌ 主私钥提取失败，请检查钱包输出。"
  exit 1
fi

# 获取主公钥
MASTER_PUBKEY=$($WALLET_CMD show-master-pubkey  | awk '/master public key/{getline; while(getline && NF){printf "%s", $0}} END{print ""}')
echo "主公钥：$MASTER_PUBKEY"
if [ -z "$MASTER_PUBKEY" ]; then
  echo "❌ 主公钥提取失败，请检查钱包输出。"
  exit 1
fi

echo -e "\n📄 写入 Makefile 挖矿公钥..."
sed -i.bak "s|^export MINING_PUBKEY :=.*$|export MINING_PUBKEY := $MASTER_PUBKEY|" Makefile

# 启动指引
cd ..
echo -e "\n🚀 配置完成，启动命令如下："
echo -e "\n➡️ 进入 nockchain 目录："
echo -e "cd nockchain"
echo -e "\n➡️ 启动 leader 节点："
echo -e "screen -S leader\nmake run-nockchain-leader"
echo -e "\n➡️ 启动 follower 节点："
echo -e "screen -S follower\nmake run-nockchain-follower"
echo -e "\n📄 查看日志方法："
echo -e "screen -r leader   # 查看 leader 日志"
echo -e "screen -r follower # 查看 follower 日志"
echo -e "Ctrl+A 再按 D 可退出 screen 会话"
echo -e "\n---"
echo -e "或直接在 nockchain 目录下运行："
echo -e "make run-nockchain-leader"
echo -e "make run-nockchain-follower"
echo -e "\n🎉 部署完成，祝你挖矿愉快！"
