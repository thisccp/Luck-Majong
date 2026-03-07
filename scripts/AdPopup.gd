extends ColorRect

signal refill_requested
signal popup_closed

@onready var refill_btn: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/RefillBtn
@onready var close_btn: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/CloseBtn

func _ready() -> void:
	refill_btn.pressed.connect(func(): refill_requested.emit())
	close_btn.pressed.connect(func(): popup_closed.emit())
