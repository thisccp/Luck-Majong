extends ColorRect

signal refill_requested
signal popup_closed

@onready var refill_btn: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/RefillBtn
@onready var close_btn: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/CloseBtn

func _ready() -> void:
	refill_btn.pressed.connect(func(): refill_requested.emit())
	close_btn.pressed.connect(func(): popup_closed.emit())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		popup_closed.emit()
