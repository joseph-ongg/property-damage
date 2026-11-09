class_name Projectile
extends Area2D

var direction := Vector2.RIGHT
var speed := 400.0
var damage := 20

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Remove it if it flies off and never hits anything.
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	var h := body.get_node_or_null("Health") as Health
	if h:
		h.take_damage(damage)
	queue_free()
