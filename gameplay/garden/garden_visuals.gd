## Garden artwork and its matching flammable footprint share one layout.
## The MaterialGrid remains the only owner of ignition and burning state.
extends Node2D

const SKY := Color("edf8f1")
const GRASS := Color("9bcf3b")
const DARK_GRASS := Color("4a9a47")
const WOOD := Color("66574b")
const BARK := Color("4c4038")
const LEAVES := Color("8abe22")
const LEAF_LIGHT := Color("add447")
const FENCE := Color("a4a995")
const ROSE := Color("d84b43")


static func paint_grid(grid: MaterialGrid) -> void:
	for x in grid.width:
		for y in grid.height:
			var point := Vector2(float(x) + 0.5, float(y) + 0.5) * float(grid.cell_size)
			if _is_wood(point):
				grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)


static func _is_wood(p: Vector2) -> bool:
	# Fence rails and posts, including the rose-covered trellis on the left.
	for rect in [
		Rect2(0, 251, 680, 24), Rect2(0, 381, 680, 25),
		Rect2(84, 214, 43, 284), Rect2(278, 252, 43, 246),
		Rect2(484, 210, 43, 288),
		Rect2(42, 124, 286, 26), Rect2(43, 137, 23, 361),
		Rect2(305, 137, 24, 361),
	]:
		if rect.has_point(p):
			return true
	# Tree trunk, branches and leafy crown all accept sparks.
	if Rect2(738, 82, 125, 416).has_point(p):
		return true
	if _near_segment(p, Vector2(766, 173), Vector2(536, 276), 22.0):
		return true
	if _near_segment(p, Vector2(788, 149), Vector2(673, 64), 18.0):
		return true
	for crown in [
		Vector3(623, 30, 88), Vector3(752, 18, 104),
		Vector3(863, 23, 103), Vector3(941, 42, 91),
	]:
		if _inside_ellipse(p, Vector2(crown.x, crown.y), Vector2(crown.z, 54)):
			return true
	return false


static func _near_segment(p: Vector2, a: Vector2, b: Vector2, radius: float) -> bool:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) <= radius


static func _inside_ellipse(p: Vector2, center: Vector2, radius: Vector2) -> bool:
	var d := (p - center) / radius
	return d.length_squared() <= 1.0


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), SKY)
	draw_rect(Rect2(0, 462, 960, 78), GRASS)
	draw_rect(Rect2(0, 457, 960, 8), DARK_GRASS)
	# The garden fence sits behind the other objects.
	for rail in [Rect2(0, 251, 680, 24), Rect2(0, 381, 680, 25)]:
		draw_rect(rail, FENCE)
		draw_rect(Rect2(rail.position, Vector2(rail.size.x, 4)), Color("d0d3bd"))
	for post in [Rect2(84, 214, 43, 284), Rect2(278, 252, 43, 246), Rect2(484, 210, 43, 288)]:
		draw_rect(post, FENCE)
		draw_rect(Rect2(post.position, Vector2(5, post.size.y)), Color("d0d3bd"))
	# Rose arbor from the reference sketch.
	for beam in [Rect2(42, 124, 286, 26), Rect2(43, 137, 23, 361), Rect2(305, 137, 24, 361)]:
		draw_rect(beam, Color("8c7961"))
	for x in range(55, 327, 25):
		draw_circle(Vector2(x, 133 + 7 * sin(float(x) * 0.13)), 15, DARK_GRASS)
		draw_circle(Vector2(x + 5, 121 + 8 * sin(float(x) * 0.17)), 9, ROSE)
	for y in range(160, 452, 38):
		for x in [47, 320]:
			draw_circle(Vector2(x, y), 11, DARK_GRASS)
			draw_circle(Vector2(x + 5, y - 4), 6, ROSE)
	# The orange hose box and coiled green hose in the lower left.
	draw_rect(Rect2(0, 366, 175, 96), Color("ed8c56"))
	draw_line(Vector2(25, 454), Vector2(26, 399), Color("2d7f56"), 12)
	draw_line(Vector2(26, 399), Vector2(144, 385), Color("2d7f56"), 12)
	draw_line(Vector2(144, 385), Vector2(146, 457), Color("2d7f56"), 12)
	draw_line(Vector2(51, 452), Vector2(56, 418), Color("2d7f56"), 10)
	draw_line(Vector2(56, 418), Vector2(110, 412), Color("2d7f56"), 10)
	draw_line(Vector2(110, 412), Vector2(115, 454), Color("2d7f56"), 10)
	# Branching tree and its broad canopy.
	draw_line(Vector2(774, 166), Vector2(537, 276), WOOD, 43)
	draw_line(Vector2(794, 148), Vector2(671, 61), WOOD, 36)
	draw_colored_polygon(PackedVector2Array([
		Vector2(741, 462), Vector2(748, 361), Vector2(743, 90),
		Vector2(840, 84), Vector2(838, 375), Vector2(862, 462),
	]), WOOD)
	draw_rect(Rect2(764, 98, 17, 278), BARK)
	draw_circle(Vector2(800, 118), 21, Color("9e7957"))
	draw_circle(Vector2(805, 398), 23, Color("9e7957"))
	for crown in [
		Vector3(623, 30, 88), Vector3(752, 18, 104),
		Vector3(863, 23, 103), Vector3(941, 42, 91),
	]:
		draw_set_transform(Vector2(crown.x, crown.y), 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, crown.z, LEAVES)
		draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(628, 12), 45, LEAF_LIGHT)
	# Small hanging treehouse and nest high above the garden.
	draw_line(Vector2(588, 24), Vector2(588, 66), Color("c49b5a"), 4)
	draw_line(Vector2(645, 24), Vector2(645, 66), Color("c49b5a"), 4)
	draw_rect(Rect2(582, 64, 73, 62), Color("896b50"))
	draw_rect(Rect2(595, 71, 46, 55), Color("a47b51"))
	draw_circle(Vector2(618, 93), 17, Color("735033"))
	# Bird above the nest, echoing the sketch's high left focal point.
	draw_line(Vector2(359, 62), Vector2(467, 25), Color("d7d1cb"), 25)
	draw_line(Vector2(370, 70), Vector2(466, 70), Color("d7d1cb"), 17)
	draw_circle(Vector2(358, 62), 17, Color("d7d1cb"))
	draw_circle(Vector2(349, 59), 3, Color("897b73"))
	draw_line(Vector2(382, 94), Vector2(413, 110), Color("b8804e"), 6)
	draw_line(Vector2(413, 110), Vector2(445, 94), Color("b8804e"), 6)
	draw_circle(Vector2(409, 101), 24, Color("c15e48"))
	draw_circle(Vector2(403, 81), 9, Color("f3d39b"))
	draw_circle(Vector2(419, 82), 9, Color("f3d39b"))
	# Two gnomes and a pair of mushrooms mark the lower foreground.
	_draw_gnome(Vector2(401, 462), Color("ce3838"))
	_draw_gnome(Vector2(464, 462), Color("617dd0"))
	_draw_mushroom(Vector2(685, 462), 1.0, Color("7791db"))
	_draw_mushroom(Vector2(863, 462), 0.65, Color("c64f43"))
	# A thin ground edge remains legible through the fire overlay.
	draw_rect(Rect2(0, 494, 960, 4), Color("3b8641"))


func _draw_gnome(base: Vector2, hat: Color) -> void:
	draw_rect(Rect2(base + Vector2(-14, -31), Vector2(28, 31)), Color("896baf"))
	draw_circle(base + Vector2(0, -31), 14, Color("efd0b5"))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-26, -39), base + Vector2(0, -76),
		base + Vector2(27, -39),
	]), hat)
	draw_rect(Rect2(base + Vector2(-22, -42), Vector2(44, 10)), hat)


func _draw_mushroom(base: Vector2, scale: float, cap: Color) -> void:
	draw_rect(Rect2(base + Vector2(-9, -31) * scale, Vector2(18, 31) * scale), Color("d8b9aa"))
	draw_set_transform(base + Vector2(0, -30) * scale, 0.0, Vector2(scale, scale * 0.55))
	draw_circle(Vector2.ZERO, 39, cap)
	draw_set_transform(Vector2.ZERO)
