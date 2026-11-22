## Standable one-way outlines following the sloped branch in original Garden art.
## Garden background world mapping: x=54+2*source_x, y=-16+2*source_y.
## Do not use a large invisible horizontal rectangle through empty tree sky.
class_name GameplayGardenTreeBranch
extends StaticBody2D

const POINTS: Array[Vector2] = [
    Vector2(530, 230), Vector2(560, 225), Vector2(589, 225),
    Vector2(621, 207), Vector2(648, 177), Vector2(676, 158),
    Vector2(705, 133)
]

func _ready() -> void:
    collision_layer = 1
    collision_mask = 0
    for idx in range(POINTS.size()-1):
        var segment := SegmentShape2D.new()
        segment.a = POINTS[idx]
        segment.b = POINTS[idx+1]
        var ledge := CollisionShape2D.new()
        ledge.name = "SlopedBranch%d" % (idx+1)
        ledge.shape = segment
        ledge.one_way_collision = true
        ledge.one_way_collision_margin = 3.0
        add_child(ledge)
