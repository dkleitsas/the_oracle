extends Node2D

@onready var cat: Sprite2D = $Cat
@onready var cat_player: AnimationPlayer = $CatPlayer

var rotating = false

func _ready() -> void:
	cat_player.play("Speaking")
