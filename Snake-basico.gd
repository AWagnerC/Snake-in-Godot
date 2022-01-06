# Tutorial do Clear Code - Creating Snake in Godot - https://www.youtube.com/watch?v=-I_AdBkryoU&t=1875s
extends Node2D


# O valor da constante é baseado nos ids dos objetos no tilemap. Serão usados três tiles no TileMap, conforme IDs.
const FOOD = 0
const SNAKE = 1
const TAIL = 2
# enum {FOOD, SNAKE, TAIL}

# Posição do alimento na tela
var food_pos :Vector2
# Corpo da cobra. Os espaços ocupados pela cobra no grid serão armazenados em forma de matriz nesta variável
# Cada vetor desse representa uma posição do grid, a ser controlado pelo set_cellv()
# Na função específica, usaremos o for para preencher os vetores armazenados nesta matriz pelo tile da cobra.

# Necessariamente a cabeça da cobra precisa ser o array de index 0 e a ponta da cauda o último index
export var snake_body = [Vector2(3, 1), Vector2(2, 1), Vector2(1, 1)]
# Direção adotada pela cobra, a ser mudada com os direcionais. Movimento inicial é pela direita
var snake_direction = Vector2.RIGHT
# Variável que representa o tamanho da tela
onready var window_size = get_viewport_rect().size
# Representa a fronteira do grid, em que aparecerão os objetos e também onde eles interagirão
var grid_size :Vector2
# Variável que indica se a cobra pegou o alimento. Se verdadeiro, sabemos que a cobra crescerá.
var snake_fed = false
# o id do tilemap dos obsátuclos é 2. Esta variável armazena a posição de todos os tiles 2.
onready var obstacle = $Grid.get_used_cells_by_id(2)

func _ready():
	def_grid_size()
	place_food_in_random_position()
	draw_snake()

# Definir as fronteiras do grid com base no tamanho da tela.
func def_grid_size():
	grid_size.x = window_size.x / 32
	grid_size.y = window_size.y / 32

# Movimento da cobra
func _input(_event):
	# evitar o movimento inverso da cobra, ou seja, se está indo pra direita, não pode apertar para a esquerda
	if Input.is_action_just_pressed("ui_right") and snake_direction != Vector2.LEFT: 
		snake_direction = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left") and snake_direction != Vector2.RIGHT: 
		snake_direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_up") and snake_direction != Vector2.DOWN: 
		snake_direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down") and snake_direction != Vector2.UP: 
		snake_direction = Vector2.DOWN

# Definir a posição aleatória do alimento no grid
func place_food_in_random_position():
	# A fim de evitar que a posição do alimento ocupe a mesma cell do snake, usaremos while.
	# No while, faremos com que o algorítimo busque uma posição aleatória, só parando de buscar
	# quando encontrar uma posição que não está dentro da matriz de snake_body.
	randomize()
	var random_pos :Vector2
	var random_pos_selected = false
	while !random_pos_selected:
		random_pos = Vector2(randi() % int(grid_size.x),randi() % int(grid_size.y))
		if (!random_pos in snake_body) and (!random_pos in obstacle):
			food_pos = random_pos
			random_pos_selected = true
	draw_food(food_pos)
	
# Desenhar o alimento na tela e colocá-lo na posição definida na função place_food_in_random_position()
func draw_food(pos):
	$Grid.set_cellv(pos, FOOD)

# Checar se a cobra conseguiu alcançar o alimento. Ocorrendo isso, o alimento precisa aparecer
# aleatoriamente em outro local do mapa. A checagem é feita a cada timeout do timer, considerando que
# o movimento da cobra também é feito a cada time_out.
func check_food_eaten():
	# Se a posição do alimento é a mesma da cabeça da cobra
	if food_pos == snake_body[0]:
		place_food_in_random_position()
		# Além disso, a cobra aumentará seu tamanho. Esta variável permitirá isso em move_snake()
		snake_fed = true

# Desenhar o corpo da cobra no grid, com base nas posições armazenadas em snake_body. Veja observações.
func draw_snake():
	# Adicionar o corpo da cobra no grid. Faz a mesma coisa do seguinte comando:
	#	for body in range(snake_body.size()):
	#		$Grid.set_cellv(snake_body[body], SNAKE)
	for body in snake_body:
		$Grid.set_cellv(body, SNAKE)

# Veja as observações para entender o sentido do movimento da cobra no tilemap
func move_snake():
	# se snake_fed for true, a cobra precisa aumentar seu tamanho, logo, o body_copy
	# precisa pegar toda a matriz de snake_body, e não pegar só um parte usando slice()
	if snake_fed == true:
		delete_cell(SNAKE)
		var body_copy = snake_body.duplicate()
		var new_head = body_copy[0] + snake_direction
		body_copy.insert(0, new_head)
		snake_body = body_copy
		# A fim fazer a cobra crescer eternamente sem ter pego o alimento.
		snake_fed = false
	else:
		# Esta função é importante para deletar as células velhas, ou seja, evitar que
		# onde a cobra passe, fique permanentemente uma parte sua lá.
		delete_cell(SNAKE)
		# Vamos usar uma variável auxiliar para copiar do primeiro índice ao penúltimo da matriz de snake_body.
		# Lembre-se, a ponta da cauda vai passar a ocupar a célula que era da penúltima parte do corpo.
		# Dessa forma, devemos remover da matriz o último vetor, mas faremos inicialmente através de uma
		# variável auxiliar.
	
		# slice serve para cortar um array - slice(índice inicial, índice final)
		# Aqui cortamos do primeiro índice ao penúltimo
		var body_copy = snake_body.slice(0, snake_body.size() - 2)
		# A cabeça vai passar a ocupar a célula a qual o direction está apontando
		var new_head = body_copy[0] + snake_direction
		# Vamos colocar a nova posição da cabeça no index 0 da matriz
		body_copy.insert(0, new_head)
		# snake_body = body_copy, a fim de aplicar as mudanças na matriz de origem
		snake_body = body_copy

func delete_cell(id: int):
	# Deletando as células para permitir o efeito de movimento da cobra
	var cells = $Grid.get_used_cells_by_id(id)
	for cell in cells:
		$Grid.set_cellv(cell, -1)


func _on_Timer_timeout():
	# O movimento da cobra é feito com o time_out
	move_snake()
	# como as células da cobra foram deletadas, temos que redesenhá-las instantaneamente
	draw_snake()
	# Checar se a cobra alcançou o alimento. Esta checagem também poderia ser colocada em process
	check_food_eaten()
	
func check_game_over():
	var head = snake_body[0]
	# Caso a cobra se choque com o obstáculo
	if head in obstacle:
		reset_game()
	# Caso a cobra se choque com sua cauda. Devemos recortar do pescoço pra última cauda
	var tail = snake_body.slice(1, snake_body.size() - 1)
	if head in tail:
		reset_game()

# Reinicia o jogo ao dar game_over
func reset_game():
	var _reset = get_tree().reload_current_scene()
	
func _process(_delta):
	# A checagem do game_over precisa ser constante
	check_game_over()

# == OBSERVAÇÕES ==
 
# draw_snake(): podemos também adicionar um outro comando para que a cobra tenha uma animação melhor.
# Primeiramente, no TileMap, coloque os sprites da cobra em uma única imagem e utilize o comando NEW_ATLAS,
# ao invés de SINGLE_TILE. Uma outra cena será criada para mostrar a mecânica.

# === Movimento da cobra ===
# No movimento da cobra, o que ocorre: a cabeça avança para uma célula, enquanto cada parte do corpo passa
# a ocupar a célula que era ocupada pela parte posterior do corpo. Dessa forma, o que deve ser aplicado
# na prática. A cabeça vai ocupar uma nova célula, e a ponta da cauda é deletada.



