@tool
extends EditorPlugin

var window: Window
var excluded_folders: Array = []
var checked_scenes: Array = []
var include_inspector_changes: bool = false
var config: ConfigFile
var config_path: String

var folder_vbox: VBoxContainer
var scenes_vbox: VBoxContainer
var select_all_checkbox: CheckBox
var inspector_changes_checkbox: CheckBox

func _enter_tree():
	config_path = OS.get_user_data_dir() + "/scene_tree_as_text.cfg"
	config = ConfigFile.new()
	config.load(config_path)
	excluded_folders = config.get_value("exclusions", "folders", [])
	checked_scenes = config.get_value("selections", "checked_scenes", [])
	
	window = Window.new()
	window.title = "Scene Tree As Text"
	window.size = Vector2(450, 666)
	window.visible = false
	window.connect("close_requested", Callable(self, "save_and_hide_window"))
	
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1)
	background.size = window.size
	window.add_child(background)
	window.move_child(background, 0)
	
	var main_vbox = VBoxContainer.new()
	window.add_child(main_vbox)
	
	# --- Excluded Folders Section ---
	var excluded_label := RichTextLabel.new()
	excluded_label.bbcode_enabled = true
	excluded_label.bbcode_text = "[b][color=#d5eaf2]Excluded Folders[/color][/b] (relative to res://):"
	excluded_label.fit_content = true
	excluded_label.scroll_active = false
	main_vbox.add_child(excluded_label)
	
	var folder_scroll = ScrollContainer.new()
	folder_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	folder_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	folder_scroll.custom_minimum_size = Vector2(window.size.x, 100)
	main_vbox.add_child(folder_scroll)
	
	folder_vbox = VBoxContainer.new()
	folder_scroll.add_child(folder_vbox)
	
	var add_folder_container = CenterContainer.new()
	var add_folder_button = Button.new()
	add_folder_button.text = "Add Folder"
	add_folder_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	add_folder_button.get_theme_stylebox("normal").bg_color = Color("#2e6b69")
	add_folder_container.add_child(add_folder_button)
	main_vbox.add_child(add_folder_container)
	add_folder_button.pressed.connect(Callable(self, "add_folder_line"))
	
	# --- Scenes Checkboxes Section ---
	var scenes_label = RichTextLabel.new()
	scenes_label.bbcode_enabled = true
	scenes_label.bbcode_text = "[b][color=#d5eaf2]Select Scenes to Include:[/color][/b]"
	scenes_label.fit_content = true
	scenes_label.scroll_active = false
	main_vbox.add_child(scenes_label)
	
	select_all_checkbox = CheckBox.new()
	select_all_checkbox.text = "Select All"
	select_all_checkbox.add_theme_color_override("font_color", Color("#7ca6e2"))
	select_all_checkbox.pressed.connect(Callable(self, "toggle_select_all"))
	main_vbox.add_child(select_all_checkbox)
	
	var scenes_scroll = ScrollContainer.new()
	scenes_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scenes_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scenes_scroll.custom_minimum_size = Vector2(window.size.x, 355)
	main_vbox.add_child(scenes_scroll)
	
	scenes_vbox = VBoxContainer.new()
	scenes_scroll.add_child(scenes_vbox)
	
	# --- Include Inspector Changes Checkbox ---
	var inspector_changes_container = CenterContainer.new()
	inspector_changes_checkbox = CheckBox.new()
	inspector_changes_checkbox.text = "Include info about Inspector changes"
	inspector_changes_container.add_child(inspector_changes_checkbox)
	main_vbox.add_child(inspector_changes_container)
	inspector_changes_checkbox.toggled.connect(Callable(self, "on_inspector_changes_toggled"))
	
	# --- Generate Button ---
	var generate_container = CenterContainer.new()
	var generate_button = Button.new()
	generate_button.text = "Generate output.txt"
	generate_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	generate_button.get_theme_stylebox("normal").bg_color = Color("#2e6b2e")
	generate_container.add_child(generate_button)
	main_vbox.add_child(generate_container)
	generate_button.pressed.connect(Callable(self, "generate_selected_scenes"))
	
	get_editor_interface().get_base_control().add_child(window)
	
	add_tool_menu_item("Generate Scene Trees...", Callable(self, "open_window"))

func _exit_tree():
	remove_tool_menu_item("Generate Scene Trees...")
	if window and is_instance_valid(window):
		window.queue_free()

# --- Window Management ---
func open_window():
	populate_folder_lines()
	refresh_scenes_checkboxes()
	window.popup()
	window.move_to_center()

func save_and_hide_window():
	save_excluded_folders()
	save_checked_scenes()
	window.hide()

# --- Excluded Folders Functions ---
func save_excluded_folders():
	var new_folders = []
	for child in folder_vbox.get_children():
		if child is HBoxContainer:
			var line_edit = child.get_child(0) as LineEdit
			if line_edit and line_edit.text.strip_edges() != "":
				new_folders.append(line_edit.text.strip_edges())
	excluded_folders = new_folders
	config.set_value("exclusions", "folders", excluded_folders)
	config.save(config_path)
	refresh_scenes_checkboxes()

func save_checked_scenes():
	var current_checked = []
	for child in scenes_vbox.get_children():
		if child is CheckBox and child.button_pressed:
			current_checked.append(child.get_meta("full_path"))
	checked_scenes = current_checked
	config.set_value("selections", "checked_scenes", checked_scenes)
	config.save(config_path)

func populate_folder_lines():
	for child in folder_vbox.get_children():
		child.queue_free()
	for folder in excluded_folders:
		add_folder_line(folder)

func add_folder_line(folder = ""):
	var hbox = HBoxContainer.new()
	var line_edit = LineEdit.new()
	line_edit.custom_minimum_size = Vector2(window.size.x - 60, 35)
	line_edit.text = folder
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.connect("text_submitted", Callable(self, "on_folder_confirmed"))
	var remove_button = Button.new()
	remove_button.text = "➖"
	remove_button.custom_minimum_size = Vector2(40, 0)
	remove_button.pressed.connect(Callable(self, "remove_folder_line").bind(hbox))
	hbox.add_child(line_edit)
	hbox.add_child(remove_button)
	folder_vbox.add_child(hbox)

func remove_folder_line(hbox: HBoxContainer) -> void:
	hbox.queue_free()
	await get_tree().process_frame
	call_deferred("save_excluded_folders")

func on_folder_confirmed(_text: String):
	save_excluded_folders()

func on_checkbox_toggled(_button_pressed: bool):
	save_checked_scenes()

func on_inspector_changes_toggled(button_pressed: bool):
	include_inspector_changes = button_pressed

# --- Scenes Checkboxes Functions ---
func refresh_scenes_checkboxes():
	for child in scenes_vbox.get_children():
		child.queue_free()
	var tscn_files = get_tscn_files_excluding_folders()
	for tscn_file in tscn_files:
		var checkbox = CheckBox.new()
		checkbox.text = tscn_file.get_file()
		checkbox.set_meta("full_path", tscn_file)
		if tscn_file in checked_scenes:
			checkbox.button_pressed = true
		checkbox.toggled.connect(Callable(self, "on_checkbox_toggled"))
		scenes_vbox.add_child(checkbox)

func get_tscn_files_excluding_folders() -> Array:
	var tscn_files = []
	list_tscn_files("res://", tscn_files)
	var filtered_files = []
	for file in tscn_files:
		var exclude = false
		for folder in excluded_folders:
			if file.begins_with("res://" + folder + "/") or file == "res://" + folder:
				exclude = true
				break
		if not exclude:
			filtered_files.append(file)
	return filtered_files

func list_tscn_files(dir_path: String, files: Array):
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = dir_path + ("/" if dir_path != "res://" else "") + file_name
			if dir.current_is_dir():
				list_tscn_files(full_path, files)
			elif file_name.ends_with(".tscn"):
				files.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()

func toggle_select_all():
	var checked = select_all_checkbox.button_pressed
	for child in scenes_vbox.get_children():
		if child is CheckBox:
			child.button_pressed = checked
	save_checked_scenes()

# --- Generate Output ---
func generate_selected_scenes():
	var selected_files = []
	for child in scenes_vbox.get_children():
		if child is CheckBox and child.button_pressed:
			selected_files.append(child.get_meta("full_path"))
	
	var output = ""
	for tscn_file in selected_files:
		var packed_scene = ResourceLoader.load(tscn_file)
		if packed_scene and packed_scene is PackedScene:
			var scene_state = packed_scene.get_state()
			var path_to_index = {}
			for i in range(scene_state.get_node_count()):
				var path_str = str(scene_state.get_node_path(i))
				if path_str.begins_with("./"):
					path_str = path_str.substr(2)
				path_to_index[path_str] = i
			var instance = packed_scene.instantiate()
			var tree_str = build_tree_string_from_node(instance, "", instance, scene_state, path_to_index)
			instance.queue_free()
			output += tscn_file.get_file() + ":\n" + tree_str + "\n\n"
		else:
			output += tscn_file.get_file() + ":\nFailed to load scene\n\n"
	
	var file = FileAccess.open("res://output.txt", FileAccess.WRITE)
	if file:
		file.store_string(output)
		file.close()
		print("Generated res://output.txt")
	else:
		print("Failed to open output.txt")

func build_tree_string_from_node(node, prefix = "", scene_root = null, scene_state = null, path_to_index = null):
	var node_type = node.get_class()
	var node_name = node.name
	var name_str = 'name: "%s"' % node_name if str(node_name) != node_type else ""
	var scene_str = 'scene: "%s"' % node.get_scene_file_path() if node.get_scene_file_path() else ""
	var script = node.get_script()
	var script_str = 'script: "%s"' % script.resource_path if script else ""
	var attributes = []
	if name_str: attributes.append(name_str)
	if scene_str: attributes.append(scene_str)
	if script_str: attributes.append(script_str)
	
	if include_inspector_changes and scene_root and scene_state and path_to_index:
		var relative_path_str = str(scene_root.get_path_to(node)).strip_edges()
		if relative_path_str in path_to_index:
			var index = path_to_index[relative_path_str]
			var changes = {}
			for prop in range(scene_state.get_node_property_count(index)):
				var prop_name = scene_state.get_node_property_name(index, prop)
				var prop_value = scene_state.get_node_property_value(index, prop)
				changes[prop_name] = str(prop_value)
			if changes:
				attributes.append("changes: " + str(changes))
	
	var attr_str = " (" + ", ".join(attributes) + ")" if attributes else ""
	var node_str = "%s%s" % [node_type, attr_str]
	
	var line = node_str if not node.get_parent() else prefix + ("└── " if node == node.get_parent().get_children()[-1] else "├── ") + node_str
	
	var children = node.get_children()
	for i in range(children.size()):
		var child = children[i]
		var is_last = i == children.size() - 1
		var child_prefix = ""
		if node.get_parent():
			child_prefix = prefix + ("    " if node == node.get_parent().get_children()[-1] else "│   ")
		line += "\n" + build_tree_string_from_node(child, child_prefix, scene_root, scene_state, path_to_index)
	
	return line
