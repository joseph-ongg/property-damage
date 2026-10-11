# 远端分支择优整合记录（本地实验）

本文件用于后续和组员对接；这里**不是**宣称整个远端分支已合并，也不代表 PR 已获批准。
所有移植逻辑在 `gameplay/`，没有改 `onboarding/burn-box/` 或远端 `main`。

| 原作者 / 分支 | 原始来源 | 引入的功能 | 本地文件 |
| --- | --- | --- | --- |
| Austin (`chouhuaidan`) / `sim/jackson/burn-box-render` | `a529274`, `player.gd` | 借鉴 `↓ + Jump` 下穿平台；重写为双玩家独立输入和临时平台碰撞例外，不允许穿实体地板 | `components/platform_drop.gd`, `player.gd`, `input_actions.gd` |
| Ethan (`Miao-Zinan`) / `ethan/burn-box-grid` | `46c3df2`, `onboarding/burn-box/material_grid.gd` | 按 `ignite()`、`is_burning()`、`world_to_cell()`、`in_bounds()` 契约改进点火结果判断；空气、石头和水不再误报成功 | `components/fire_bridge.gd`, `tests/fixtures/upstream_grid_contract.gd` |
| Jackson / `sim/jackson/burn-box-render` | `c897a2e`, `onboarding/burn-box/grid_renderer.gd` | 借鉴 `cell_changed` 触发重绘和材料与燃烧状态分色；封装为**可选调试预览**，不会默认遮盖现有像素场景 | `integration/material_grid_preview.gd` |

## 为什么没有直接 cherry-pick 整个分支

1. Austin 的 `main.tscn` 含冲突标记，而他的 `player.gd` 使用单人的 `ui_*` 输入，不兼容当前双人控制。
2. Ethan 的材料存储还在 Simulation 分支：它应该由负责人合并，而不是私下复制成另一份正式 `MaterialGrid`。测试用 fixture 是独立的 API 合约模型，**不是**真正的火焰存储。
3. Jackson 的原始渲染器将整屏格子画成色块；本地已采用像素客厅画面，因此只保留可复用的信号驱动调试预览思路。
4. `angela/CollisionShape2D` 当前与远端 main 相同，不能据此找到可直接引入的新代码。

## 输入和验收

- 默认 Gameplay MSD：P1 `S + W`，P2 `↓ + ↑` 从**单向平台**落下，普通地板不能穿透。此功能为对 Austin 方案的安全化适配。
- `gameplay/tests/gameplay_upstream_drop_test.gd`：检查双人单向下穿及实体地板保护。
- `gameplay/tests/gameplay_upstream_grid_test.gd`：按 Ethan 的公开 API 用例测试材料、点火和事件；另验证 Jackson 式预览仅在格子变化时更新。
- 之后如果 Ethan 的 PR 合并，应**再用真实 MaterialGrid 实测**。本地测试不能代替合并验证。

Git 来源（以原 SHA 为准，避免本地改写提交标题造成歧义）：
- https://github.com/joseph-ongg/property-damage/commit/a5292743351c673dcd095efabcba34f6f996219b
- https://github.com/joseph-ongg/property-damage/commit/46c3df2d01275ce1ebbaee87bb3f7ba19e4dabb4
- https://github.com/joseph-ongg/property-damage/commit/c897a2e735c4c65f4173cb4b4a542e94f512323b
