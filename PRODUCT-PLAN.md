# CDDA Agent Play - Product Plan

## 产品愿景

让普通玩家能一键启动 AI 直播玩 CDDA，像使用普通游戏一样简单。

---

## 核心问题与解决方案

### 问题 1: 如何让产品变成一个真正的软件

**目标**: 像普通游戏一样，下载 → 双击 → 玩

**方案: Electron/Tauri 打包**

```
┌─────────────────────────────────────┐
│  CDDA Agent Play (GUI 客户端)         │
│  ├── 启动按钮                        │
│  ├── 版本显示                        │
│  ├── 更新提示                        │
│  └── 帮助按钮                        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Shell Script (内部)                  │
│  ├── 下载 CDDA (首次)                │
│  ├── 启动 tmux + 游戏                │
│  └── 管理游戏会话                    │
└─────────────────────────────────────┘
```

**技术选型:**
- GUI: Tauri (轻量, ~10MB) 或 Electron (成熟, ~150MB)
- 分发: electron-builder / Tauri bundler
- 目标: Windows/macOS/Linux 一键安装包

---

### 问题 2: 客户端更新时，如何让 agent 知道更新

**目标**: 更新后 agent 能自动适配新版本的绑定/命令

**方案: 版本化的 skill + 配置文件**

```
客户端 v1.0:
├── cdda-agent-play-demo.skills/
│   ├── manifest.json          # 当前版本 + 依赖版本
│   ├── skill-v1.0.md
│   └── config-v1.0.json
└── cdda-bin/...

客户端 v1.1 (更新):
├── manifest.json              # 更新了
├── skill-v1.1.md             # 新版 skill
├── config-v1.1.json
└── cdda-bin/...
```

**manifest.json 格式:**
```json
{
  "version": "1.1.0",
  "min_agent_version": "1.0.0",
  "game_version": "0.F-3",
  "skill": "skill-v1.1.md",
  "bindings": {
    "move": ["h", "j", "k", "l"],
    "pickup": ",",
    "open": "o"
  }
}
```

**Agent 启动时:**
1. 读取 `manifest.json`
2. 验证 skill 版本匹配
3. 加载对应的 skill 和 bindings
4. 如果版本不兼容，显示升级提示

---

### 问题 3: 游玩中需要帮助时，如何联系开发者

**方案: 内置帮助系统 (Discord Webhook)**

```
玩家按帮助键 (Alt+H)
    │
    ▼
┌─────────────────────────────────┐
│  捕获当前游戏状态                │
│  - 位置、血量、背包             │
│  - 最近 20 行屏幕               │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  发送到 Discord/Telegram         │
│  - 开发者收到通知               │
│  - 包含游戏状态截图             │
└─────────────────────────────────┘
```

**实现:**

```bash
# cdda-help.sh
#!/bin/bash
tmux capture-pane -t cdda-text -p > /tmp/help-screen.txt
curl -X POST "$DISCORD_WEBHOOK" \
  -d "Player needs help!"
  -d file: @/tmp/help-screen.txt
```

---

### 问题 4: 从单机版升级到联机版（存档保留）

**核心原则: 存档与客户端分离**

```
存档位置: ~/.cdda/saves/

客户端结构:
CDDA-Agent-Play/
├── CDDA-Agent-Play.exe      # 客户端 (可删除)
├── cdda-bin/                 # CDDA 二进制 (可替换)
└── config/                  # 配置

玩家数据 (不随客户端删除):
~/.cdda/
├── saves/                    # 角色存档 (保留!)
│   └── Colton McCain/
│       └── world.bin
├── config/                  # 用户设置
└── mods/                    # MOD (可选)
```

**换客户端流程:**

```
1. 卸载旧客户端 (只删 client/)
2. 安装新客户端
3. 存档自动保留在 ~/.cdda/saves/
4. 启动 → 继续玩
```

**联机版架构:**

```
┌─────────────────────────────────────────┐
│  存档服务器 (云端)                        │
│  ├── 保存最新存档                        │
│  ├── 版本历史                            │
│  └── 多设备同步                          │
└─────────────────────────────────────────┘
         ▲                    │
         │                    ▼
┌─────────────┐      ┌─────────────────┐
│  玩家设备 A  │◄───►│  玩家设备 B     │
│  下载存档    │      │  下载存档        │
│  上传存档    │      │  上传存档        │
└─────────────┘      └─────────────────┘
```

**存档同步协议:**

```json
{
  "player_id": "colton_mccain",
  "save_version": "1.0",
  "last_sync": "2026-03-27T10:30:00Z",
  "save_checksum": "abc123...",
  "download_url": "https://server/saves/colton_mccain.tar.gz"
}
```

---

## 产品路线图

### Phase 1: MVP (当前)
- [x] CDDA 文本模式运行
- [x] tmux 集成
- [x] 基本 skill
- [ ] 单 Agent 直播循环

### Phase 2: 打包分发
- [ ] Electron/Tauri 打包
- [ ] 一键安装程序
- [ ] 自动更新机制
- [ ] 版本化 skill manifest

### Phase 3: 帮助系统
- [ ] Alt+H 帮助快捷键
- [ ] 游戏状态捕获
- [ ] Discord/Telegram 通知
- [ ] 开发者接收界面

### Phase 4: 存档云同步 (联机准备)
- [ ] 存档导出/导入
- [ ] 云端存档存储
- [ ] 多设备同步
- [ ] 联机模式客户端

---

## 目录结构 (打包后)

```
CDDA-Agent-Play/
├── CDDA-Agent-Play.exe        # 启动器
├── resources/
│   ├── cdda-bin/              # CDDA 二进制
│   └── skills/                # 版本化 skill
│       └── manifest.json
├── config/
│   └── settings.json
└── updater.exe                # 自动更新程序

玩家数据 (独立目录):
~/.cdda-agent-play/
├── saves/                     # 存档 (跨版本保留)
├── logs/                      # 日志
└── webhook.txt                # 帮助通知配置
```

---

## 关键设计决策

### 1. 存档分离
- 客户端可以删，存档不能删
- `~/.cdda/saves/` 是玩家数据的根目录
- 客户端只读配置，不修改存档

### 2. Skill 版本化
- 每个客户端版本对应特定 skill 版本
- manifest.json 声明兼容性
- Agent 读取 manifest 决定加载哪个 skill

### 3. 帮助非侵入
- 帮助请求不中断游戏
- 异步发送，不阻塞玩家
- 开发者通过外部渠道回复

### 4. 联机预留
- 存档格式支持导出
- 服务器只需存储 `saves/` 目录
- 客户端升级不影响存档格式
