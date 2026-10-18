extends Area2D

@export var textures: Array[Texture2D] 
@export var speed: float
@export var loop_radius: float 

var active: bool = false
var state: State = State.INACTIVE
var type: int = 0
var formation: Node2D   
var slot: Vector2       #lugar desse inimigo no formacao
var path: Array = []    #pontos(o caminho) que o inimigo ainda precisa visitar
var has_shot: bool = false

signal killed(points: int)
signal shoot(shot_position: Vector2)

enum State {
	INACTIVE, 
	ENTERING,
	RETURNING,
	FORMATION,
	ATTACKING
}

# Pontos de cada tipo (0 = chefe, 1 = borboleta, 2 = abelha)
const POINTS_FORMATION = [150, 80, 50]   # abatido parado na formação
const POINTS_ATTACK = [400, 160, 100]    # abatido em voo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if state == State.INACTIVE:
		return
	
	if state == State.FORMATION:   #parado na formação (acompanha o movimento dela)
		position = formation.get_slot_position(slot)
		
	elif state == State.RETURNING:    #voltando p seu lugar na formação
		var posicao = formation.get_slot_position(slot)
		move_to(posicao, delta)
		if position.distance_to(posicao) < 1.0:
			state = State.FORMATION
			rotation = 0
			
	else:     # ENTERING ou ATTACKING ->segue a lista de pontos
		follow_path(delta)


func move_to(posicao: Vector2, delta: float) -> void:
	var direcao = posicao - position
	
	if direcao.length() > 1.0:
		rotation = direcao.angle() - PI /2  #nimigo "olha"/fica p baixo
		
	position = position.move_toward(posicao, speed*delta)


func follow_path(delta: float) -> void:
	if path.is_empty():
		if state == State.ATTACKING:  #saiu por baixo da tela -> volta p topo
			position = Vector2(formation.get_slot_position(slot).x, -40)
		state = State.RETURNING
		return

	move_to(path[0], delta)
	if position.distance_to(path[0]) < 1.0:
		path.pop_front()

	#durante o ataque atira uma vez qnd passar de 40% da altura
	if state == State.ATTACKING and not has_shot and position.y > get_viewport_rect().size.y * 0.4:
		has_shot = true
		shoot.emit(position)


#spawn e seguir um caminho de entrada
func spawn(enemy_type: int, slot_position: Vector2, entrance_path: Array) -> void:
	type = enemy_type
	$Sprite2D.texture = textures[type]
	slot = slot_position
	path = entrance_path.duplicate()   #copia pq vários inimigos usam o mesmo caminho
	position = path.pop_front()        #começa no primeiro ponto do caminho
	rotation = 0
	state = State.ENTERING
	active = true
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func deactivate() -> void:
	active = false
	state = State.INACTIVE
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func is_in_formation() -> bool:
	return state == State.FORMATION

func is_entering() -> bool:
	return state == State.ENTERING

func attack(target_x: float) -> void: #sai da formação e mergulha em direção à posição x do jogador
	var screen = get_viewport_rect().size
	var side = -1.0 if position.x < screen.x / 2 else 1.0  #inimigos da esquerda faz o loop p a esq, e vice-versa
	var center = position + Vector2(side * loop_radius, 0)
	
	path = []
	#meia-volta para cima (semicírculo de 6 pontos)
	for i in range(1, 7):
		var angle = PI * i / 6.0
		path.append(center + Vector2(-side * cos(angle), -sin(angle)) * loop_radius)
		
	#em direção ao jogador e saída por baixo da tela
	path.append(Vector2(target_x, screen.y * 0.6))
	path.append(Vector2(target_x + side * 60, screen.y + 40))

	has_shot = false
	state = State.ATTACKING

func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	var points = POINTS_FORMATION[type] if state == State.FORMATION else POINTS_ATTACK[type]
	deactivate()
	killed.emit(points)
