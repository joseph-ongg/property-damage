# Gameplay 模块开发说明

**先读仓库根目录的 [`README.md`](../README.md)**：那里有完整功能、双人按键、运行方法和当前完成范围。此文件专门说明 Gameplay 代码的拆分、接入方法和测试。

## 1. 默认玩法与实验场景

| 场景 | 路径 | 用途 |
| --- | --- | --- |
| 默认（F5） | `gameplay/msd/gameplay_msd.tscn` | Property Damage 双人客厅原型：玩家控制、平台、Spark 与可选互动 |
| 可选（F6） | `gameplay/demo/gameplay_test.tscn` | 自制 Moonlit Ruins 奇幻玩法实验（Dash、魔晶/火盆、实验通关条件） |

**注意：Moonlit Ruins 的名称、收集任务、Combo 和通关判定不是 Zander/设计组确认的正式玩法。** 不要把这部分默认加入团队 Gameplay PR。

## 2. Gameplay 核心模块

| 模块 | 路径 | 简要作用 |
| --- | --- | --- |
| 玩家入口 | `player.gd`、`player.tscn` | `CharacterBody2D`、按键、朝向、关联组件 |
| 独立按键 | `input_actions.gd` | 注册 `p1_*`/`p2_*`，无需改 `project.godot` |
| 移动/跳跃 | `components/player_motor.gd` | 二段跳、固定高度、空中惯性、Jump Buffer、Coyote Time |
| 单向平台下穿 | `components/platform_drop.gd` | 只临时忽略脚下 one-way 平台，不穿实体地板 |
| Spark | `components/spark_emitter.gd` | 面向方向施法，单独冷却 |
| 火焰对接 | `components/fire_bridge.gd` | 与 Ethan 的 `MaterialGrid` 对接，验证是否真正燃烧 |
| 额外实验组件 | `components/player_dash.gd`、`fire_hazard.gd` | Dash（默认 MSD 禁用）、可选火焰接触感应 |

`Player` 在碰撞层 2、只检测世界层 1，因此不会互相碰撞。场景必须创建真实世界静态碰撞体；只画背景贴图不能代替物理场景。

## 3. 客厅演示模块（可拆卸）

- `msd/msd_controller.gd`：连接两名玩家、互动对象、Spark、家电效果；包含 `experimental_books_enabled` 和 `experimental_appliances_enabled` 两个开关。
- `msd/burnable_prop.gd`：书本拾取、携带、投掷、变焦黑（轻量原型，不是物理材料破坏）。
- `msd/appliance.gd`：冰箱开关、风扇推力、空调减速（`effect_radius=130`，`cold_speed_scale=0.45`）、电脑损坏视觉。
- `msd/magic_bolt.gd`：G / `.` 实验魔法弹，仅做物件反馈，不代表完整伤害系统。
- `msd/interaction_hints.gd`：靠近才显示互动操作；和控制器的 `get_interaction_offer()` 共用目标选择。
- `msd/player_conditions.gd`：显示受冷气影响的 `SLOW` 或受风扇影响的 `WIND`，不重复计算移动物理。
- `msd/room_visuals.gd` + `msd/art/generate_room.py`：背景像素画，不处理碰撞。
- `integration/material_setup.gd`：只为测试关卡涂布材料；不维护第二套燃烧状态。
- `demo/fire_visuals.gd`：监听 `MaterialGrid.cell_changed`，画轻量像素火星，不负责存储燃烧信息。

## 4. 对接正式团队场景

1. 在最终场景中放两份 `gameplay/player.tscn`，分别设 `player_index=1` 和 `2`，并配置 P1/P2 外观。
2. 将 `FireBridge.grid_path` 指向实际 `MaterialGrid`；两个玩家的 `fire_bridge_path` 都指向该桥接节点。
3. 世界用碰撞层 1，玩家在层 2（mask 1）。桌面等单向平台使用 `CollisionShape2D.one_way_collision`。
4. 替换临时客厅、演示材料填充和测试 HUD；**不要改动 `onboarding/burn-box/burn_box.tscn`**。
5. 与 Simulation、Art 组确认最终材质、角色素材、火焰传播 API、胜负规则后再决定需要哪些可选实验。

本地曾从远端借鉴 Austin 的跳跃计数与平台下穿，并直接同步 Ethan 的 `MaterialGrid` 原始文件；完整来源 SHA 与合并说明见 [`UPSTREAM_INTEGRATION.md`](UPSTREAM_INTEGRATION.md)。是否进入正式 `main` 由团队 PR 决定。

## 5. 回归测试

使用 Godot 4.7.2 Standard，在仓库根目录运行单项测试：

```bash
"../Godot.app/Contents/MacOS/Godot" --headless --path . \
  --script res://gameplay/tests/gameplay_msd_test.gd
```

主要测试及关注点：

| 测试 | 验证内容 |
| --- | --- |
| `gameplay_smoke_test.gd` | 双人核心行为及点火 |
| `gameplay_edge_test.gd` | 跳跃缓冲、边界和容错 |
| `gameplay_controls_test.gd` | 输入、动作效果 |
| `gameplay_msd_test.gd` | 默认 MSD 场景与 Ethan 真实存储 |
| `gameplay_upstream_drop_test.gd` | 两名玩家下穿单向平台、实体地板保护 |
| `gameplay_upstream_grid_test.gd` | 木头/油点燃、石头/水拒绝、重绘事件 |
| `gameplay_advanced_test.gd` | 二段跳、空中惯性、书本和家电 |
| `gameplay_magic_test.gd` | 方向性魔法弹与目标反馈 |
| `gameplay_props_test.gd` | 书本焦黑、重复命中保护 |
| `gameplay_layout_feedback_test.gd` | 互动提示、空调减速、离开范围恢复 |
| `gameplay_quest_test.gd` | 可选奇幻关卡的任务逻辑 |
| `gameplay_ui_test.gd`、`gameplay_guidance_test.gd` | 可选关卡 HUD、帮助及暂停 |

一键执行全部 Gameplay 测试：

```bash
GODOT="../Godot.app/Contents/MacOS/Godot"
for script in gameplay/tests/*.gd; do
  "$GODOT" --headless --path . --script "res://$script" || exit 1
done
```

## 6. 注释语言

- 本地脚本当前仍是**中英文混合注释**，并非全部中文。
- 中文注释重点解释：不直观的动作逻辑、输入交互、与 Simulation 的边界、远端参考实现来源。
- 原作者代码的文件和历史来源应保留。Godot API 与 GDScript 标识符保持英文，避免翻译造成兼容问题。

像素美术与源码关系见 [`ART_SOURCES.md`](ART_SOURCES.md)；团队范围及待确认机制见 [`msd/DESIGN_NOTES.md`](msd/DESIGN_NOTES.md)。

## 7. 绘制层级 / Rendering layers

默认客厅在 `gameplay/msd/gameplay_msd.tscn` 中显式配置了 `z_index`，防止冰箱打开后的内部以及壁挂空调遮挡角色：背景 -5、家具 2、玩家 10、书本 12、魔法 14、互动提示 30 / 状态提示 31。这个层级只改变**绘制顺序**，不改变物理碰撞。验证脚本是 `gameplay/tests/gameplay_render_layers_test.gd`。

**EN:** The living-room scene explicitly sets render layers so the open fridge interior and wall-mounted AC remain behind players. Room background is -5, appliances 2, players 10, books 12, projectiles 14, and prompts/status overlays 30/31. This changes drawing order only, not collision. Run `gameplay_render_layers_test.gd` for regression coverage.
