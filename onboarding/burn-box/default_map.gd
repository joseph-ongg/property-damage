# onboarding/burn-box/default_map.gd
class_name DefaultMap


static func fill(grid: MaterialGrid) -> void:
	for x in grid.width:
		for y in grid.height:
			grid.set_cell_material(x, y, MaterialGrid.Materials.AIR)

# TODO: wood buildings, stone walls, oil patches, water, using whatever API you design.
