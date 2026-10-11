extends Area2D

@export var speed: float = 600.0
@export var direction: Vector2 = Vector2.UP

var active: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not active: 
		return
	
	translate(direction * speed * delta)
	
	var screen: Rect2 = get_viewport_rect()
	if position.y < screen.position.y - 20 or position.y > screen.end.y + 20:
		deactivate()


func fire(start_position: Vector2) -> void: 
	position = start_position
	active = true
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
func deactivate() -> void:
	active = false
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	

func _on_area_entered(area: Area2D) -> void:
	deactivate()
