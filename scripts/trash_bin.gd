extends Node2D

signal corpse_deposited

@onready var deposit_area: Area2D = $DepositArea


func _ready() -> void:
	deposit_area.body_entered.connect(_on_deposit_area_body_entered)
	deactivate()


func activate() -> void:
	deposit_area.monitoring = true
	deposit_area.monitorable = true


func deactivate() -> void:
	deposit_area.monitoring = false
	deposit_area.monitorable = false


func _on_deposit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.carrying_corpse != null:
		_accept_deposit(body)


func _accept_deposit(player: Node2D) -> void:
	var corpse: Node2D = player.get("carrying_corpse")
	player.call("drop_corpse")
	if is_instance_valid(corpse):
		corpse.queue_free()
	emit_signal("corpse_deposited")
