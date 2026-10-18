extends Node

#quantidade de inimigos em cada linha da formação (tipo no original)
const ROW_SIZE = [4, 8, 8, 10, 10]
#tipo de inimigo de cada linha: 0 = chefe, 1 = borboleta, 2 = abelha
const ROW_TYPE = [0, 1, 1, 2, 2]

@export var enemies_to_win: int = 80
@export var initial_lives: int = 3

@onready var formation: Node2D = $Formation
@onready var player: Area2D = $Player
@onready var enemy_pool: Node = $EnemyPool
@onready var enemy_bullet_pool: Node = $EnemyBulletPool
@onready var spawn_timer: Timer = $SpawnTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var score_label: Label = $HUD/ScoreLabel
@onready var kills_label: Label = $HUD/KillsLabel
@onready var message: Label = $HUD/MessageLabel
@onready var lives_box: HBoxContainer = $HUD/Lives

var score: int = 0
var kills: int = 0
var lives: int
var playing: bool = false
var game_finished: bool = false

var slots: Array = []          #posição de cada lugar da formação
var slot_rows: Array = []      #linha de cada lugar
var spawn_index: int = 0       #próximo lugar a ser preenchido
var entrance_paths: Array = [] #caminhos de entrada


func _ready() -> void:
	#prepara todos os inimigos da pool
	for enemy in enemy_pool.objects:
		enemy.formation = formation
		enemy.connect("killed", _on_enemy_killed)
		enemy.connect("shoot", _on_enemy_shoot)

	entrance_paths.append(get_path_points($Paths/PathLeft))
	entrance_paths.append(get_path_points($Paths/PathRight))
	create_slots()

	lives = initial_lives
	update_hud()
	player.disable()
	message.text = "GALAGA\n\nPressione ENTER"


func _process(_delta: float) -> void:
	if not playing:
		if Input.is_action_just_pressed("ui_accept"):
			if game_finished:
				get_tree().reload_current_scene()
			else:
				start_game()
		return

	if spawn_index >= slots.size():
		if count_active_enemies() == 0:
			spawn_wave()
		elif not formation.breathing and not any_enemy_entering():
			formation.breathing = true
			attack_timer.start()


#lê as posições dos Marker2D filhos de um nó
func get_path_points(path_node: Node) -> Array:
	var points = []
	for marker in path_node.get_children():
		points.append(marker.global_position)
	return points


#calcula a posição de cada lugar da formação, relativa ao centro dela
func create_slots() -> void:
	for row in range(ROW_SIZE.size()):
		for col in range(ROW_SIZE[row]):
			var x = (col - (ROW_SIZE[row] - 1) / 2.0) * formation.distanciamneto.x
			var y = row * formation.distanciamneto.y
			slots.append(Vector2(x, y))
			slot_rows.append(row)


func start_game() -> void:
	playing = true
	message.hide()
	player.respawn()
	spawn_wave()


func spawn_wave() -> void:
	spawn_index = 0
	formation.reset()
	attack_timer.stop()
	spawn_timer.start(1.0)


func _on_spawn_timer_timeout() -> void:
	var enemy = enemy_pool.get_free_object()
	if enemy == null:
		spawn_timer.start(0.5)   #com a pool vazia, tenta de novo daqui a pouco
		return

	var row = slot_rows[spawn_index]
	#linhas pares entram pela esquerda e linhas ímpares pela direita
	enemy.spawn(ROW_TYPE[row], slots[spawn_index], entrance_paths[row % 2])
	spawn_index += 1

	if spawn_index < slots.size():
		if slot_rows[spawn_index] != row:
			spawn_timer.start(1.5)
		else:
			spawn_timer.start(0.15)


func count_active_enemies() -> int:
	var count = 0
	for enemy in enemy_pool.objects:
		if enemy.active:
			count += 1
	return count


func any_enemy_entering() -> bool:
	for enemy in enemy_pool.objects:
		if enemy.is_entering():
			return true
	return false


func _on_attack_timer_timeout() -> void:
	var candidates = []
	for enemy in enemy_pool.objects:
		if enemy.is_in_formation():
			candidates.append(enemy)
	if not candidates.is_empty():
		candidates.pick_random().attack(player.position.x)


func _on_enemy_shoot(shot_position: Vector2) -> void:
	var bullet = enemy_bullet_pool.get_free_object()
	if bullet:
		bullet.fire(shot_position)


func _on_enemy_killed(points: int) -> void:
	if not playing:
		return
	score += points
	kills += 1
	update_hud()
	if kills >= enemies_to_win:
		end_game(true)


func _on_player_hit() -> void:
	if not playing:
		return
	lives -= 1
	update_hud()
	if lives <= 0:
		end_game(false)
	else:
		message.text = "READY"
		message.show()
		respawn_timer.start()


func _on_respawn_timer_timeout() -> void:
	message.hide()
	player.respawn()


func update_hud() -> void:
	score_label.text = "SCORE\n" + str(score)
	kills_label.text = "INIMIGOS\n" + str(kills) + "/" + str(enemies_to_win)
	#mostra uma nave reserva para cada vida extra
	for i in range(lives_box.get_child_count()):
		lives_box.get_child(i).visible = i < lives - 1


func end_game(victory: bool) -> void:
	playing = false
	game_finished = true
	spawn_timer.stop()
	attack_timer.stop()
	respawn_timer.stop()

	if victory:
		message.text = "VOCÊ VENCEU!"
		for enemy in enemy_pool.objects:
			enemy.deactivate()
	else:
		message.text = "GAME OVER"
	message.text += "\n\nPressione ENTER"
	message.show()
