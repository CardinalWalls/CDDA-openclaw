# CDDA Live Demo - AI 直播版

Cataclysm: Dark Days Ahead (CDDA) text mode + MoonBit 工具 + AI 直播 skill。

## 快速开始

### 1. 检查依赖

```bash
./setup.sh
```

需要：`tmux`

### 2. 下载 CDDA (如果还没有)

```bash
# Linux x86_64
./scripts/download-cdda.sh

# 或者手动下载:
# https://github.com/CleverRaven/Cataclysm-DDA/releases
# 选择 "Cataclysm文本模式" Linux 版本
```

### 3. 启动游戏

```bash
./start.sh
```

这会:
- 在 tmux session `cdda-text` 中启动 CDDA
- 等待游戏加载完成
- 自动创建新游戏角色

### 4. 开始直播 (在 OpenClaw 中)

```
/游戏开始
```

## 目录结构

```
cdda-live-demo/
├── README.md           # 本文件
├── Makefile            # 常用命令
├── setup.sh            # 依赖检查
├── start.sh            # 启动游戏
├── package.sh          # 打包脚本
├── bin/                # CDDA 二进制 (需下载，约 100MB)
├── scripts/
│   ├── download-cdda.sh      # 下载 CDDA
│   ├── cdda-tools.sh         # Agent 工具集 (REPL 模式)
│   └── cdda-quick-start.sh   # 快速启动逻辑
├── skills/
│   └── cdda-agent-play-demo/ # 直播 skill (中文)
├── openclaw-skill/
│   └── SKILL.md             # OpenClaw 集成 skill (英文)
└── runs/                # 回合记录
```

## 工具命令

在 cdda-tools.sh REPL 中可用:

```bash
# 观察
look_around           # 环顾四周
check_inventory       # 检查背包
check_character        # 检查角色状态

# 移动
move_north/south/east/west

# 等待
wait_turn

# 交互
pick_up               # 捡东西
open_door/close_door  # 开门/关门
```

## 直播 Skill

`/游戏开始` 会:
1. 读取当前游戏状态
2. 以生动的方式描述场景
3. Agent 思考下一步行动
4. 执行动作并验证结果
5. 循环直到遇到重要事件

## 故障排除

### tmux not found
```bash
# Ubuntu/Debian
sudo apt install tmux

# macOS
brew install tmux
```

### 游戏卡在主菜单
```bash
tmux attach -t cdda-text
# 手动按 'n' -> Enter -> Tab x 6 -> Y
```

### 查看游戏输出
```bash
tmux attach -t cdda-text
# 按 Ctrl+B 然后 D 来分离
```
