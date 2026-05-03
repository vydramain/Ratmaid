extends Node2D

@export var label_text: String = "PLACEHOLDER"
@export var box_size: Vector2 = Vector2(64.0, 64.0)
@export var box_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var solid: bool = false

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _ready() -> void:
	color_rect.color = box_color
	color_rect.size = box_size
	color_rect.position = -box_size * 0.5
	label.text = label_text
	label.size = box_size
	label.position = -box_size * 0.5
	if collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = box_size
	collision_shape.set_deferred("disabled", not solid)
