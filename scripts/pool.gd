extends Node

@export var scene: PackedScene #cena dos objetos na pool
@export var pool_size: int = 10

var objects: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(pool_size):
		var obj = scene.instantiate()
		add_child(obj)
		obj.deactivate()
		objects.append(obj)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#devolve um objeto não usado ou null se todos estiverem sendo usados
func get_free_object() -> Node:
	for obj in objects:
		if not obj.active:
			return obj
	return null
			
