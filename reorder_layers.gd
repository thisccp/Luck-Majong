@tool
extends SceneTree

func _init() -> void:
	print("Starting layer hierarchy reorder...")
	var scene_path = "res://scenes/Main.tscn"
	var packed = ResourceLoader.load(scene_path)
	if not packed:
		print("Failed to load scene")
		quit()
		return
	
	var main = packed.instantiate()
	
	# Verify current state to avoid duplicate execution
	if main.get_node_or_null("UILayer"):
		print("UILayer already exists. Skipping.")
		quit()
		return
		
	var uilayer = CanvasLayer.new()
	uilayer.name = "UILayer"
	main.add_child(uilayer)
	uilayer.owner = main
	
	var vbox = main.get_node("VBox")
	var board_container = vbox.get_node("BoardContainer")
	
	# Create spacer to maintain VBox layout (pushes StatusLabel down)
	var spacer = Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)
	vbox.move_child(spacer, board_container.get_index())
	
	# Detach BoardContainer from VBox and move to Main (index after Background, if any, else index 1)
	vbox.remove_child(board_container)
	main.add_child(board_container)
	main.move_child(board_container, vbox.get_index()) # Put where VBox was
	
	# Make BoardContainer span the full rect
	board_container.layout_mode = 1 # 1 = Anchors
	board_container.set_anchors_preset(Control.PRESET_FULL_RECT) # 15
	board_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Retain existing owner for board_container (should already be main)
	
	# Detach VBox from main and move to UILayer
	main.remove_child(vbox)
	uilayer.add_child(vbox)
	
	# Detach WinPopup from main and move to UILayer
	var win = main.get_node_or_null("WinPopup")
	if win:
		main.remove_child(win)
		uilayer.add_child(win)
		
	# Detach NoMovesPopup from main and move to UILayer
	var nomoves = main.get_node_or_null("NoMovesPopup")
	if nomoves:
		main.remove_child(nomoves)
		uilayer.add_child(nomoves)
		
	# Restore owners
	for node in [spacer, uilayer]:
		node.owner = main

	_set_owner_recursive(main, main)
	
	var new_packed = PackedScene.new()
	new_packed.pack(main)
	var err = ResourceSaver.save(new_packed, scene_path)
	if err == OK:
		print("Scene layout saved successfully!")
	else:
		print("Failed to save layout: ", err)
	quit()

func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	if node != new_owner:
		node.owner = new_owner
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)
