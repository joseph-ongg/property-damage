## Neutral living-room test arena matching the Property Damage design direction.
## Art-only: real collision geometry lives in the paired StaticBody2D nodes.
extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Quiet interior: dark wallpaper, window and floor trim. No fantasy quest art.
	draw_rect(Rect2(0, 0, 960, 500), Color("303949"))
	for y in range(19, 486, 29):
		draw_line(Vector2(0, y), Vector2(960, y), Color("3a4554", 0.45), 1.0)
	for x in range(24, 965, 64):
		draw_line(Vector2(x, 0), Vector2(x, 493), Color("263243", 0.45), 1.0)
	# A centered night window reinforces a real domestic room.
	draw_rect(Rect2(374, 80, 212, 145), Color("141f32"))
	draw_rect(Rect2(384, 90, 192, 125), Color("1b2c47"))
	draw_circle(Vector2(529, 121), 15, Color("d3d8bb"))
	for x in range(390, 571, 27):
		var h := float(18 + ((x * 13) % 39))
		draw_rect(Rect2(x, 214.0 - h, 23, h), Color("233a52"))
	for x in range(397, 559, 29):
		draw_rect(Rect2(x, 189, 3, 5), Color("c4a16e", 0.65))
	draw_rect(Rect2(374, 80, 212, 145), Color("c0a88a"), false, 6)
	draw_line(Vector2(480, 85), Vector2(480, 222), Color("bba48b"), 5)
	draw_line(Vector2(377, 156), Vector2(583, 156), Color("bba48b"), 5)
	# Crown moulding and a patterned baseboard.
	draw_rect(Rect2(0, 0, 960, 10), Color("5a5961"))
	draw_rect(Rect2(0, 488, 960, 10), Color("77716e"))
	draw_rect(Rect2(0, 498, 960, 40), Color("625952"))
	for x in range(0, 960, 40):
		draw_line(Vector2(x, 501), Vector2(x, 539), Color("4c4845"), 1)
	draw_rect(Rect2(0, 499, 960, 4), Color("baa17b"))
	# Bookshelf: three furniture ledges, ONE-WAY collision only at the top.
	draw_rect(Rect2(145, 347, 187, 151), Color("4e3940"))
	draw_rect(Rect2(153, 352, 171, 141), Color("705649"))
	for y in [380, 426, 474]:
		draw_rect(Rect2(153, y, 171, 7), Color("b18a63"))
	var shelf_rows: Array[int] = [354, 386, 433]
	for row in shelf_rows.size():
		var level: int = shelf_rows[row]
		for index in range(12):
			var x := 160 + index * 13
			var top := level + ((index * 7 + row * 3) % 9)
			var shades: Array[Color] = [Color("8a6561"), Color("8d8975"), Color("617d85"), Color("9c765e")]
			draw_rect(Rect2(x, top, 8, 24 - (top - level)), shades[(index + row) % shades.size()])
	draw_rect(Rect2(145, 343, 187, 10), Color("d1a779"))
	# Table: top matches one-way collider but legs are decorative only.
	draw_rect(Rect2(376, 411, 218, 17), Color("b78c69"))
	draw_rect(Rect2(388, 428, 16, 68), Color("785649"))
	draw_rect(Rect2(567, 428, 16, 68), Color("785649"))
	draw_rect(Rect2(379, 412, 212, 4), Color("e1c096"))
	# Fridge/freezer silhouette, with a clearly readable top platform.
	draw_rect(Rect2(716, 351, 132, 146), Color("818a91"))
	draw_rect(Rect2(721, 359, 122, 130), Color("a6aaac"))
	draw_rect(Rect2(716, 350, 132, 9), Color("c8bdad"))
	draw_rect(Rect2(720, 417, 124, 4), Color("666e7a"))
	draw_rect(Rect2(733, 379, 5, 23), Color("5e646f"))
	draw_rect(Rect2(733, 443, 5, 24), Color("5e646f"))
	# Solid world walls, both with subtle clear boundary markers.
	for x in [0, 948]:
		draw_rect(Rect2(x, 0, 12, 499), Color("595969"))
		draw_rect(Rect2(x + 3, 0, 3, 499), Color("77717a", 0.6))
