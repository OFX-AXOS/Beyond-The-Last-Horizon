extends CharacterBody2D

# Using @export makes it easy to tweak values in the Inspector without touching code
@export var WALK_SPEED := 130.0
@export var CROUCH_SPEED := 65.0
@export var JUMP_VELOCITY := -350.0

@onready var stand_collision: CollisionShape2D = $stand
@onready var crouch_collision: CollisionShape2D = $crouch
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead := false

func _physics_process(delta: float) -> void:
	if is_dead: return # Stop processing if dead

	apply_gravity(delta)
	handle_jump()
	
	# Get input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	# Handle Crouching state
	var is_crouching := Input.is_action_pressed("do_crouch") and is_on_floor()
	
	# Movement logic
	var target_speed = CROUCH_SPEED if is_crouching else WALK_SPEED
	
	if direction != 0:
		velocity.x = direction * target_speed
		sprite.flip_h = direction < 0
	else:
		# move_toward here makes stopping feel less "snappy" and more natural
		velocity.x = move_toward(velocity.x, 0, target_speed)

	move_and_slide()
	
	# Update visuals
	update_collision(is_crouching)
	update_animations(direction, is_crouching)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump() -> void:
	if Input.is_action_just_pressed("move_up") and is_on_floor():
		# Optional: prevent jumping while crouching if desired
		velocity.y = JUMP_VELOCITY

func update_collision(is_crouching: bool) -> void:
	stand_collision.disabled = is_crouching
	crouch_collision.disabled = not is_crouching

func update_animations(direction: float, is_crouching: bool) -> void:
	# 1. AIRBORNE STATES
	if not is_on_floor():
		if velocity.y < 0:
			play_if_new("jump")
		else:
			play_if_new("fall")
		return # Exit early so ground animations don't override air ones

	# 2. GROUND STATES
	if is_crouching:
		play_if_new("crouch")
	elif direction != 0:
		play_if_new("run")
	else:
		play_if_new("idle")

# Helper function to prevent animation stuttering
func play_if_new(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func die() -> void:
	if is_dead: return
	is_dead = true
	# Play a death animation here if you have one!
	sprite.play("die") # Ensure you have a 'die' animation or remove this line
	get_tree().create_timer(0.5).timeout.connect(func(): get_tree().reload_current_scene())
