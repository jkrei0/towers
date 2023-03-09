extends RigidBody2D

signal ready_to_place

const START_POS : Vector2i = Vector2i(248, 32) # starting offset
const PLACING_BOX_TOLERANCE : float = 2 # shrink hitbox while placing
const TOLERANCE : int = 16 # fall at least this far before placing
const BLOCK_SIZE : int = 16 # how large each square is
const MOVE_STEP : int = BLOCK_SIZE / 2 # how far to move
const FALL_SPEED : int = 60 # how fast to fall / drop
const DROP_SPEED : int = 300

@onready var Bounds = $Bounds

var y_step : int = FALL_SPEED
var last_step : float = 0

enum DIR {RIGHT, LEFT, NONE}
var moving_direction : DIR = DIR.NONE
var initiated : bool = false
var placed : bool = false

var PositionIndicator : ColorRect
var Area : Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if placed:
		self.freeze = false
	
	if initiated and not placed:
		self.position.y += y_step * delta
		last_step = y_step * delta
		
		if moving_direction == DIR.RIGHT:
			self.position.x += MOVE_STEP
		elif moving_direction == DIR.LEFT:
			self.position.x -= MOVE_STEP
		moving_direction = DIR.NONE
		
		var deg : int = int(abs(self.rotation_degrees/10)) % 36
		if deg == 0 or deg == 18:
			PositionIndicator.position.x = self.position.x + Bounds.position.x
			PositionIndicator.size.x = Bounds.size.x
		else:
			PositionIndicator.position.x = self.position.x + Bounds.position.y
			PositionIndicator.size.x = Bounds.size.y
		
		self.linear_velocity.x = 0
		self.linear_velocity.y = 0
		self.angular_velocity = 0
	
	if not placed and Input.is_action_just_pressed("SpinCW"):
		self.rotation_degrees += 90
	elif not placed and Input.is_action_just_pressed("SpinCCW"):
		self.rotation_degrees -= 90
		
	if self.position.y > 700:
		self.get_parent().remove_child(self)


func _input(event):
	if event.is_action_pressed("Right"):
		moving_direction = DIR.RIGHT
	elif event.is_action_pressed("Left"):
		moving_direction = DIR.LEFT
	
	if event.is_action_pressed("Drop"):
		y_step = DROP_SPEED
	elif event.is_action_released("Drop"):
		y_step = FALL_SPEED


# Initalize the block (set position and variables).
# This should be called after duplicating the block
func init(idc):
	if not self.get_node("CenterOfMass"):
		print("No 'CenterOfMass' child of block_template")
		print("Please add a Node2D 'CenterOfMass' defining the center of mass ",
			"of the block!")
	else:
		self.center_of_mass = self.get_node("CenterOfMass").position
		
	if not self.get_node("Area2D"):
		print("No Area2D/CollisionShape2D child of block_template")
		print("Please add an Area2D with one or more CollisionShape2D(s).")
	else:
		Area = self.get_node("Area2D")
		Area.body_entered.connect(_on_Area_body_entered)
		
		for c_shape in self.get_node("Area2D").get_children():
			# duplicate c_shape.shape, otherwise changes will affect
			# future c_shape copies as well
			c_shape.shape = c_shape.shape.duplicate()
			c_shape.shape.size.x -= PLACING_BOX_TOLERANCE
			c_shape.shape.size.y -= PLACING_BOX_TOLERANCE
	
	PositionIndicator = idc
	initiated = true
	self.rotation_degrees = 0
	self.position.x += START_POS.x
	self.position.y += START_POS.y
	self.visible = true


func place():
	placed = true
	self.position.y -= last_step * 2
	self.gravity_scale = 1
	
	# Once placed, collide with things
	for c_shape in self.get_node("Area2D").get_children():
		var new_child = c_shape.duplicate()
		self.add_child(new_child)
		c_shape.shape.size.x += PLACING_BOX_TOLERANCE
		c_shape.shape.size.y += PLACING_BOX_TOLERANCE


func can_be_placed(block) -> bool:
	if self.position.y > START_POS.y + TOLERANCE and block.is_placed():
		return true
	return false


func is_placed():
	return placed


func _on_Area_body_entered(body):
	if self.can_be_placed(body):
		ready_to_place.emit(body)
