# 远端分支择优整合记录（本地实验）

本文件用于后续和组员对接；这里**不是**宣称整个远端分支已合并，也不代表 PR 已获批准。
大部分适配与测试都在 `gameplay/`。按本次「以远端实现替换重复本地实现」的要求，
**唯一直接同步的 Simulation 源文件**是 `onboarding/burn-box/material_grid.gd`：
它与 Ethan 上游 `46c3df2` 的文件内容完全一致。`burn_box.tscn` 未修改，
远端 `main` 也未修改或推送。将来 PR #3 合并时需要再次核对差异。

| 原作者 / 分支 | 原始来源 | 引入的功能 | 本地文件 |
| --- | --- | --- | --- |
| Austin (`chouhuaidan`) / `sim/jackson/burn-box-render` | `a529274`, `player.gd` | 借鉴 `↓ + Jump` 下穿平台；重写为双玩家独立输入和临时平台碰撞例外，不允许穿实体地板 | `components/platform_drop.gd`, `player.gd`, `input_actions.gd` |
| Ethan (`Miao-Zinan`) / `ethan/burn-box-grid` | `46c3df2`, `onboarding/burn-box/material_grid.gd` | 用上游原始 `MaterialGrid` 直接替换测试假存储；点火 API 同时验证状态，拒绝空气、石头和水 | `onboarding/burn-box/material_grid.gd`, `integration/material_setup.gd`, `components/fire_bridge.gd` |
| Jackson / `sim/jackson/burn-box-render` | `c897a2e`, `onboarding/burn-box/grid_renderer.gd` | 借鉴 `cell_changed` 触发重绘和材料与燃烧状态分色；封装为**可选调试预览**，不会默认遮盖现有像素场景 | `integration/material_grid_preview.gd` |

## 为什么没有直接 cherry-pick 整个分支

1. Austin 的 `main.tscn` 含冲突标记，而他的 `player.gd` 使用单人的 `ui_*` 输入，不兼容当前双人控制。保留我们的可复用电机 API，但把内部跳跃次数换成 Austin 的 `jumps_left` 模式。
2. Ethan 的存储已经按要求**从远端原样引入本地测试分支**，无需保留第二套存储实现。团队的 PR #3 仍由 Simulation 负责人决定是否合并；不要拿本地同步冒充团队 merge。
3. Jackson 的原始渲染器将整屏格子画成色块；默认界面改用纯火焰 VFX，按 `cell_changed` 重绘，避免盖住像素客厅。
4. `angela/CollisionShape2D` 当前与远端 main 相同，不能据此找到可直接引入的新代码。

## 输入和验收

- 默认 Gameplay MSD：P1 `S + W`，P2 `↓ + ↑` 从**单向平台**落下，普通地板不能穿透。此功能为对 Austin 方案的安全化适配。
- `gameplay/tests/gameplay_upstream_drop_test.gd`：检查双人单向下穿及实体地板保护。
- `gameplay/tests/gameplay_upstream_grid_test.gd`：直接实例化 Ethan 的真实 MaterialGrid 测试材料、点火和事件；另验证 Jackson 式预览仅在格子变化时更新。
- 本地已使用真实 MaterialGrid 实测；仍需要在 Ethan 的 PR 正式合并后，在团队集成分支重新跑测试，检查其他 Simulation 模块是否有变化。

Git 来源（以原 SHA 为准，避免本地改写提交标题造成歧义）：
- https://github.com/joseph-ongg/property-damage/commit/a5292743351c673dcd095efabcba34f6f996219b
- https://github.com/joseph-ongg/property-damage/commit/46c3df2d01275ce1ebbaee87bb3f7ba19e4dabb4
- https://github.com/joseph-ongg/property-damage/commit/c897a2e735c4c65f4173cb4b4a542e94f512323b
