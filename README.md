# nockchain 一键部署脚本

## 项目简介

本项目为 [nockchain](https://github.com/zorp-corp/nockchain) 区块链协议的自动化一键部署脚本，支持 macOS、Linux（含 WSL），帮助开发者和节点运营者快速完成环境搭建、钱包生成与节点启动。

## 环境依赖

- macOS 或 Linux（推荐 Ubuntu 20.04+/WSL）
- bash shell
- git
- Rust（自动安装）
- Homebrew（macOS，自动检测）或 apt（Linux）
- 其他依赖自动安装

## 一键安装与初始化

1. 克隆本仓库：
   ```bash
   git clone git@github.com:airdrop-group/nock.git
   cd nock
   ```
2. 赋予安装脚本执行权限：
   ```bash
   chmod +x nock-install.sh
   ```
3. 运行安装脚本：
   ```bash
   ./nock-install.sh
   ```
   - 脚本会自动安装依赖、Rust、编译 nockchain、生成钱包、写入挖矿公钥。
   - 助记词、主私钥、公钥会自动提取并显示。
   - 支持 screen/tmux 后台运行节点。

## 节点启动方法

进入 nockchain 目录后，选择以下任一方式启动节点：

### 方式一：推荐后台运行
```bash
screen -S leader
make run-nockchain-leader
# 另开终端
screen -S follower
make run-nockchain-follower
```
- 查看日志：
  - `screen -r leader`  查看 leader 日志
  - `screen -r follower` 查看 follower 日志
  - `Ctrl+A` 再按 `D` 可退出 screen 会话

### 方式二：直接运行
```bash
make run-nockchain-leader
make run-nockchain-follower
```

## 常见问题

- **助记词/主私钥/主公钥未正确提取？**
  - 请确保钱包命令输出正常，脚本已自动检测并中断异常。
- **依赖安装失败？**
  - 请检查网络环境，或根据脚本提示手动安装依赖。

## 参考与支持

- nockchain 官方仓库：[https://github.com/zorp-corp/nockchain](https://github.com/zorp-corp/nockchain)
- 如有问题欢迎提 issue 或联系维护者。 