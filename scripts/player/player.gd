extends CharacterBody2D

@export_group("Movement")
@export var MAX_WALK_SPEED := 160.0
@export var ACCELERATION    := 1200.0  
@export var FRICTION        := 1500.0  
@export var TURNAROUND_MULT := 2.5    
@export var AIR_RESISTANCE  := 600.0   

@export_group("Jump")
@export var JUMP_IMPULSE    := -380.0

const VELOCITY_THRESHOLD := 10.0 

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision: CollisionShape2D = $HitBox

@onready var _base_height: float = _collision.shape.height
@onready var _base_y: float = _collision.position.y

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	# Duplicate shape so changes don't affect other instances using the same resource
	_collision.shape = _collision.shape.duplicate()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	
	var input_axis := Input.get_axis(&"move_left", &"move_right")
	var is_grounded := is_on_floor()
	var is_crouching := is_grounded and Input.is_action_pressed(&"do_crouch")
	
	_handle_locomotion(input_axis, is_crouching, is_grounded, delta)
	
	# Updated before move_and_slide to sync collision changes with physics frame
	_tick_collision(is_crouching)
	
	move_and_slide()
	_update_visual_state(input_axis, is_crouching, is_grounded)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

func _handle_locomotion(axis: float, crouching: bool, grounded: bool, delta: float) -> void:
	if crouching:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	else:
		var accel = ACCELERATION if grounded else AIR_RESISTANCE
		
		if axis != 0:
			var is_turning = sign(axis) != sign(velocity.x) and velocity.x != 0
			var final_accel = accel * (TURNAROUND_MULT if is_turning else 1.0)
			velocity.x = move_toward(velocity.x, axis * MAX_WALK_SPEED, final_accel * delta)
		else:
			var current_friction = FRICTION if grounded else AIR_RESISTANCE
			velocity.x = move_toward(velocity.x, 0, current_friction * delta)
		
		if grounded and Input.is_action_just_pressed(&"move_up"):
			velocity.y = JUMP_IMPULSE

func _tick_collision(crouching: bool) -> void:
	var target_h := _base_height * (0.7 if crouching else 1.0)
	
	if not is_equal_approx(_collision.shape.height, target_h):
		_collision.shape.height = target_h
		# Shift Y position to keep the bottom of the shape anchored to the floor
		_collision.position.y = _base_y + ((_base_height - target_h) * 0.5)

func _update_visual_state(axis: float, crouching: bool, grounded: bool) -> void:
	if axis != 0 and not crouching:
		_sprite.flip_h = axis < 0

	if not grounded:
		_play_if_new(&"jump" if velocity.y < 0 else &"fall")
	elif crouching:
		_play_if_new(&"crouch")
	elif abs(velocity.x) > VELOCITY_THRESHOLD:
		_play_if_new(&"run")
	else:
		_play_if_new(&"idle")

func _play_if_new(anim_name: StringName) -> void:
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)
