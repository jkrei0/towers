extends Node2D

@onready var BlockContainer : CanvasGroup = $Blocks

var currently_placing : bool = false
var current_block : RigidBody2D
var last_block : int = -1

func _process(delta):
	if not currently_placing:
		currently_placing = true
		
		const NUM_BLOCKS = 6
		var num : int = randi()
		# Don't give two of the same blocks in a row
		while last_block == num % NUM_BLOCKS:
			num = randi()
		last_block = num % NUM_BLOCKS
		if num % NUM_BLOCKS == 0:
			current_block = $Templates/Lleft.duplicate()
		elif num % NUM_BLOCKS == 1:
			current_block = $Templates/Lright.duplicate()
		elif num % NUM_BLOCKS == 2:
			current_block = $Templates/Straight.duplicate()
		elif num % NUM_BLOCKS == 3:
			current_block = $Templates/Tshape.duplicate()
		elif num % NUM_BLOCKS == 4:
			current_block = $Templates/Zright.duplicate()
		else:
			current_block = $Templates/Square.duplicate()
		
		BlockContainer.add_child(current_block)
		current_block.init($PositionIndicator)
		current_block.ready_to_place.connect(_on_ready_to_place)


func _on_ready_to_place(body):
	current_block.ready_to_place.disconnect(_on_ready_to_place)
	current_block.place()
	currently_placing = false
