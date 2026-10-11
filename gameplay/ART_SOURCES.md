# Gameplay 占位美术来源清单

- `gameplay/art/generate_art.py` 生成 `gameplay/art/` 里的 9 张像素 PNG：人物、平台、背景、魔晶、火盆等。使用 Python Pillow 绘制原创几何图形，没有从网上下载纹理。
- `gameplay/msd/art/generate_room.py` 生成 `gameplay/msd/art/living_room_pixel.png`：像素客厅的窗户、木家具、灯、钟、冰箱等，均为本地程序绘图。
- `gameplay/msd/appliance.gd`、`burnable_prop.gd`、`magic_bolt.gd` 等中的图形由 Godot `_draw()` 绘制，不是外部下载的贴图。
- Godot 工程根目录 `icon.svg` 是原仓库已有文件，不属于本地绘图成果。
- 远端 `sim/jackson/burn-box-render` 的 `stage_tiles.png` 是其他成员提供的素材，本分支**没有导入**，不能宣称是自己绘制。
- 外部游戏仅参考像素清晰度、反馈与色彩原则；没有复制商业游戏角色或原图。若将来加入网络素材，应另行记录作者、许可证和原始链接。
