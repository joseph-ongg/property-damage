# Property Damage — 双人 Gameplay 原型

> **项目定位**：这是 Gameplay 小组的本地可玩原型，**不是**已经合并或获得设计组批准的正式游戏版本。
> 正式项目名为 **Property Damage**；额外的书本、家电、远程魔法等属于可拆卸的玩法实验。尚未确认完整的胜利规则。

[English overview](#english-overview) · [按键](#双人操作) · [功能](#已有功能) · [运行](#如何运行) · [代码结构](#主要代码在哪里) · [测试](#自动测试) · [团队来源](#团队代码与素材来源)

## 如何运行

- 使用 **Godot 4.7.2 Standard（GDScript，不需要 .NET）**。
- 在 Godot 中导入仓库根目录的 `project.godot`，按 **F5** 启动默认的像素风客厅原型。
- 入口：`main.tscn` → `gameplay/msd/gameplay_msd.tscn`。
- 另有单独的实验关卡 `gameplay/demo/gameplay_test.tscn`，需要在 Godot 中打开后按 **F6** 运行；其 Moonlit Ruins、魔晶收集和火盆通关条件并不是团队正式要求。

## 双人操作

| 动作 | Player 1（青绿色） | Player 2（橙色） |
| --- | --- | --- |
| 左右移动 / 空中转向 | `A` / `D` | `←` / `→` |
| 固定高度跳跃、二段跳 | `W`（可按两次） | `↑`（可按两次） |
| 从单向平台落下 | `S` + `W` | `↓` + `↑` |
| Spark：点燃面前格子 | `F` | `Enter` |
| 远程魔法弹（实验性） | `G` | `.` |
| 拾取/扔书本、开关家具 | `E` | `Shift` |
| 暂停 / 恢复 | `P` 或 `Esc` | 同左 |
| 重开默认场景 | `R`（非暂停时） | 同左 |

默认原型**不启用 Dash**；`Q`、`/` 是独立实验关卡中的 Dash 按键。接近物件时，画面会显示当前玩家可用的操作提示。

## 已有功能

### 双人操作和物理（Gameplay 核心）

- 两名玩家分别使用独立输入；左右朝向、移动、跳跃、二段跳；落地恢复跳跃次数。
- 固定跳跃高度、空中松开方向键后保留水平惯性、空中转向、Coyote Time、Jump Buffer。
- 碰撞：地板、墙壁不穿透；书架、桌子和冰箱顶部是可从下方穿过的单向平台，也支持主动向下穿过。
- P1 和 P2 分别在玩家碰撞层 2，仅与世界层 1 碰撞，因此两个玩家可以互相穿过。
- Spark 在玩家当前面向方向调用 `GameplayFireBridge`；使用 **Ethan 的 `MaterialGrid` 数据存储**。火焰材质和燃烧状态来自 Simulation，而非另一份自建字典。

### 场景反馈与实验交互（**尚未获正式玩法确认**）

- 原创像素客厅背景、冷暖色区分的玩家、简洁 HUD、落地/火星反馈、接近式互动提示。
- 书本：靠近拾取、携带、投掷；Spark 或魔法命中后出现短暂火星与焦黑视觉。
- 家电：冰箱开关门、风扇的区域水平推力、空调的区域减速、电脑开关及魔法损坏状态。
- 空调开启后：**130 像素作用范围**内的目标移动速度系数为 **0.45**；空中继承的速度也会逐步降到相应上限。进入范围显示 `SLOW` 与蓝色像素反馈；离开后恢复正常。
- 远程魔法弹：独立于 Spark，可使书本或电脑产生实验性的视觉变化；不消耗法力，也没有真实生命值伤害。
- 可在 `gameplay/msd/msd_controller.gd` 中关闭 `experimental_books_enabled` / `experimental_appliances_enabled`，以便单独检验基础 Gameplay。

### 尚未完成 / 不应误称已完成

- Simulation 的真实火焰传播、燃烧耗尽、完整材质破坏与家具物理系统。
- 法力、玩家血量、破坏值影响伤害、正式得分、胜负与回合规则。
- 最终 Art/Simulation 场景合并，以及完整玩法审批。

## 主要代码在哪里

| 路径 | 用途 |
| --- | --- |
| `gameplay/player.gd` + `gameplay/player.tscn` | 玩家角色、输入和模块连接 |
| `gameplay/input_actions.gd` | P1/P2 独立按键映射 |
| `gameplay/components/player_motor.gd` | 加速度、空中惯性、固定二段跳 |
| `gameplay/components/platform_drop.gd` | 通过单向平台向下掉落 |
| `gameplay/components/spark_emitter.gd` / `fire_bridge.gd` | Spark 方向、冷却、Simulation 接口 |
| `onboarding/burn-box/material_grid.gd` | 从 Ethan 远端分支同步的材料/燃烧存储实现 |
| `gameplay/msd/msd_controller.gd` | 客厅原型主控制器，连接交互与区域效果 |
| `gameplay/msd/burnable_prop.gd` | 书本拾取、投掷和焦黑效果 |
| `gameplay/msd/appliance.gd` | 冰箱、风扇、空调和电脑 |
| `gameplay/msd/magic_bolt.gd` | 方向性实验魔法弹 |
| `gameplay/msd/interaction_hints.gd` / `player_conditions.gd` | 互动提示、`SLOW`/`WIND` 状态 |
| `gameplay/msd/art/generate_room.py` | 使用 Pillow 在本地生成像素客厅贴图 |
| `gameplay/demo/gameplay_test.tscn` | 与默认场景分开的奇幻实验关卡 |

## 自动测试

测试位于 `gameplay/tests/`，包含移动、双跳、平台、点火、双人输入、家具和 UI 的回归测试。在仓库根目录执行（根据自己的 Godot 路径调整）：

```bash
"../Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_msd_test.gd
"../Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_layout_feedback_test.gd
```

两条示例测试并不等于全部回归；详细测试清单见 [`gameplay/README.md`](gameplay/README.md)。

## 团队代码与素材来源

- Austin：部分跳跃次数与单向平台下穿设计；不是直接复制原来的单人控制器。
- Ethan：`MaterialGrid` 原始实现，已在本地对接；**不表示其 PR 已合并至团队 main**。
- Jackson：`cell_changed` 驱动的材质显示思路；默认场景仅绘制轻量火焰视觉。
- 本地像素贴图来自 `gameplay/art/generate_art.py` 与 `gameplay/msd/art/generate_room.py` 等自绘脚本，不是下载的商业游戏资源。

详细来源和原始 Git SHA 见 [`gameplay/UPSTREAM_INTEGRATION.md`](gameplay/UPSTREAM_INTEGRATION.md)；素材清单见 [`gameplay/ART_SOURCES.md`](gameplay/ART_SOURCES.md)，设计范围见 [`gameplay/msd/DESIGN_NOTES.md`](gameplay/msd/DESIGN_NOTES.md)。

本机 `.godot/`、Godot MCP 插件和 `project.godot` 的本机配置不属于可玩的运行依赖；不要将个人 MCP 设置当作团队正式项目设置提交。

## English overview

This branch is an **independent, playable Godot 4.7.2 Gameplay prototype** for Property Damage, **not a team-approved finished game**. Press F5 to play a local two-player living-room test arena. It demonstrates movement, fixed-height double jump, air momentum, one-way platforms, directional Spark integration with Ethan's MaterialGrid, and experimental book/appliance interactions, including local AC slowdown and contextual prompts. The extra quest scene and magic/device mechanics are optional prototypes, not confirmed MVP requirements. There is no final scoring, damage scaling, mana, fire propagation, or victory system yet. See the tables above for controls, files and attribution.
