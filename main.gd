extends Node2D

@export var spawn_position: Vector2 = Vector2(400.0, 300.0)
@export var floor_position: Vector2 = Vector2(400.0, 550.0)
@export var floor_width: float = 4000.0
@export var floor_height: float = 80.0
@export var reset_below_y: float = 1200.0

@onready var player: CharacterBody2D = $Player
@onready var ground: StaticBody2D = $Ground
@onready var ground_collision: CollisionShape2D = (
	$Ground/CollisionShape2D
)
@onready var ground_visual: Polygon2D = $Ground/Polygon2D


func _ready() -> void:
	RenderingServer.set_default_clear_color(
		Color(0.10, 0.12, 0.17)
	)

	setup_ground()
	reset_player()


func _physics_process(_delta: float) -> void:
	# Return the player if they fall below the level.
	if player.global_position.y > reset_below_y:
		reset_player()


func setup_ground() -> void:
	ground.position = floor_position

	ground.collision_layer = 1
	ground.collision_mask = 1

	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(floor_width, floor_height)

	ground_collision.shape = rectangle

	var half_width: float = floor_width * 0.5
	var half_height: float = floor_height * 0.5

	ground_visual.polygon = PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height)
	])

	ground_visual.color = Color(0.25, 0.65, 0.48)


func reset_player() -> void:
	player.global_position = spawn_position
	player.velocity = Vector2.ZERO
