extends CharacterBody2D

@export_group ("Movement")
@export var move_speed: float = 260.0
@export var acceleration: float = 1400.0
@export var deceleration: float = 1800.0
@export var gravity: float = 1400.0
@export var jump_velocity = -480.0
@export var maximum_fall_speed: float = 900.0

#_____________________________________________________

@export_group("Running Animation")

@export var stride_length: float = 52.0
@export var foot_lift: float = 6.0
@export var hand_swing: float = 24.0
@export var hand_lift: float = 6.0
@export var head_bounce: float = 2.5
@export var head_lean: float = 9.0

@export var pose_response: float = 18.0

@export_group("Air Animation")
@export var air_foot_spread: float = 14.0
@export var air_foot_lift: float = 12.0
@export var air_hand_lift: float = 18.0

#____________________________________________________

@onready var foot_r: Node2D = $"IK Targets/FootR Target"
@onready var foot_l: Node2D = $"IK Targets/FootL Target"

@onready var arm_r: Node2D = $"IK Targets/ArmR Target"
@onready var arm_l: Node2D = $"IK Targets/ArmL Target"

@onready var head_target: Node2D = $"IK Targets/Head Target"

var targets: Array[Node2D] = []
var rest_positions: Dictionary = {}

var phase: float = 0.0
var facing: float = 1.0

func _ready() -> void:
	targets = [
		foot_r,
		foot_l,
		arm_r,
		arm_l,
		head_target
	]
	
	for target in targets:
		rest_positions[target] = target.position
	
	floor_snap_length = 6.0
	
func _physics_process(delta: float) -> void:
	var direction: float = get_move_input()
	
	if direction != 0.0:
		facing - signf(direction)
		
	var target_velocity: float = direction * move_speed
	var rate: float = acceleration
	
	if direction == 0.0:
		rate = deceleration
		
	velocity.x = move_toward(
		velocity.x,
		target_velocity,
		rate * delta
	)
	
	if is_on_floor():
		if velocity.y > 0.0:
			velocity.y = 0.0
			
		if jump_pressed():
			velocity.y = jump_velocity
	else:
		velocity.y = minf(
			velocity.y + gravity * delta,
			maximum_fall_speed
		)
		
	var previous_position: Vector2 = global_position

	move_and_slide()

	var distance_moved: float = absf(
		global_position.x - previous_position.x
	)

	var actual_speed: float = (
		distance_moved / maxf(delta, 0.0001)
	)

	var speed_ratio: float = clampf(
		actual_speed / maxf(move_speed, 1.0),
		0.0,
		1.0
	)

	if is_on_floor() and stride_length > 0.01:
		phase = fposmod(
			phase + distance_moved / (stride_length * 2.0),
			1.0
		)

	update_target_animation(delta, speed_ratio)
#___________________________________________________________________

func get_move_input() -> float:
	return Input.get_axis("ui_left", "ui_right")
	
func jump_pressed() -> bool:
	return Input.is_action_just_pressed("ui_accept")
	
#_________________________________________________________________


func update_target_animation(
	delta: float,
	speed_ratio: float
) -> void:
	var offsets: Dictionary = {}

	# Standing pose is the default.
	for target in targets:
		offsets[target] = Vector2.ZERO

	if not is_on_floor():
		apply_air_offsets(offsets)
	elif speed_ratio > 0.02:
		apply_run_offsets(offsets, speed_ratio)

	var weight: float = 1.0 - exp(-pose_response * delta)

	for target in targets:
		var rest_position: Vector2 = rest_positions[target]
		var offset: Vector2 = offsets[target]

		target.position = target.position.lerp(
			rest_position + offset,
			weight
		)


func apply_run_offsets(
	offsets: Dictionary,
	speed_ratio: float
) -> void:
	var right_phase: float = phase
	var left_phase: float = fposmod(phase + 0.5, 1.0)

	offsets[foot_r] = get_foot_offset(right_phase)
	offsets[foot_l] = get_foot_offset(left_phase)

	var angle: float = phase * TAU
	var arm_amount: float = lerpf(0.35, 1.0, speed_ratio)

	# Hands counter-swing against their corresponding feet.
	offsets[arm_r] = Vector2(
		-cos(angle) * hand_swing * facing,
		-absf(sin(angle)) * hand_lift
	) * arm_amount

	offsets[arm_l] = Vector2(
		cos(angle) * hand_swing * facing,
		-absf(sin(angle + PI)) * hand_lift
	) * arm_amount

	# Two head bounces per complete stride.
	var bounce: float = (
		0.5 - 0.5 * cos(angle * 2.0)
	) * head_bounce * speed_ratio

	offsets[head_target] = Vector2(
		head_lean * facing * speed_ratio,
		-bounce
	)


func get_foot_offset(cycle: float) -> Vector2:
	var half_stride: float = stride_length * 0.5
	var x: float = 0.0
	var y: float = 0.0

	if cycle < 0.5:
		# Stance: move backward relative to the character.
		var t: float = cycle / 0.5
		x = lerpf(half_stride, -half_stride, t)
	else:
		# Swing: lift the foot and return it to the front.
		var t: float = (cycle - 0.5) / 0.5
		var eased: float = t * t * (3.0 - 2.0 * t)

		x = lerpf(-half_stride, half_stride, eased)
		y = -sin(t * PI) * foot_lift

	return Vector2(x * facing, y)


func apply_air_offsets(offsets: Dictionary) -> void:
	var rising: bool = velocity.y < 0.0
	var tuck: float = 1.0 if rising else 0.45

	offsets[foot_r] = Vector2(
		air_foot_spread * facing,
		-air_foot_lift * tuck
	)

	offsets[foot_l] = Vector2(
		-air_foot_spread * facing,
		-air_foot_lift * tuck * 0.5
	)

	offsets[arm_r] = Vector2(
		-hand_swing * facing * 0.3,
		-air_hand_lift
	)

	offsets[arm_l] = Vector2(
		hand_swing * facing * 0.3,
		-air_hand_lift * 0.8
	)

	offsets[head_target] = Vector2(
		head_lean * facing * 0.4,
		-2.0
	)
