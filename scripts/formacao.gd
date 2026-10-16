extends Node2D

@export var distanciamneto: Vector2
@export var velocMovimentoLateral: float 
@export var distMovimentacaoFormacao: float

var start_x: float
var direction: float = 1.0
var breathing: bool = false  #vira true quando todos os inimigos já chegaram
var spread: float = 1.0      #oq "abre" e "fecha" a formação
var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_x = position.x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if breathing:
		position.x = move_toward(position.x, start_x, velocMovimentoLateral * delta)
		time += delta
		spread = 1.0 + 0.1 * (1.0 - cos(time * 2.0))
	else:
		#balança de um lado p outro enquanto os inimigos chegam
		position.x += direction * velocMovimentoLateral * delta
		if position.x > start_x + distMovimentacaoFormacao:
			direction = -1.0
		elif position.x < start_x - distMovimentacaoFormacao:
			direction = 1.0


#converte a posição de um lugar da formação p uma posição na tela
func get_slot_position(slot: Vector2) -> Vector2:
	return position + slot * spread

func reset() -> void:
	breathing = false
	spread = 1.0
	time = 0.0
