extends Area2D

signal hit

@export var speed: float = 250.0
@export var bullet_pool: Node #pool dos tiros

var active: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not active:
		return
		
	var dx = Input.get_axis("move_left", "move_right")
	translate(Vector2.RIGHT * dx * speed * delta)
	
	var half_widht : float = $Sprite2D.get_rect().size.x * $Sprite2D.scale.x / 2
	var screen: Rect2 = get_viewport_rect()
	position.x = clampf(position.x, screen.position.x + half_widht, screen.end.x - half_widht)
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
		

#pega um tiro livre na pool, caso tenha
func shoot() -> void:
	var bullet = bullet_pool.get_free_object()
	if bullet:
		bullet.fire(position + Vector2(0, -20))

func disable() -> void: 
	active = false
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func respawn() -> void:
	position.x = get_viewport_rect().size.x / 2
	active = true
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


func _on_area_entered(area: Area2D) -> void:
	if active: 
		disable()
		hit.emit()
