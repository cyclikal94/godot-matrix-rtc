@tool
extends EditorPlugin

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const EXAMPLE_EXPORT_PRESETS_PATH := "res://addons/godot-matrix-rtc/example_export_presets.cfg"
const EXPORT_DIST_PLUGIN_SCRIPT := preload("res://addons/godot-matrix-rtc/export_dist_plugin.gd")
const EXAMPLE_PROJECT_URL := "https://github.com/cyclikal94/godot-matrix-rtc"
const NOTICE_DEFAULT_SIZE := Vector2i(720, 360)
const NOTICE_MIN_HEIGHT := 340
const NOTICE_MAX_VIEWPORT_RATIO := 0.9
const NOTICE_CONTENT_VERTICAL_PADDING := 140

const INSTALL_RESULT_ADDED := 1
const INSTALL_RESULT_ALREADY_PRESENT := 0
const INSTALL_RESULT_FAILED := -1

var _install_attempted := false
var _export_dist_plugin: EditorExportPlugin

func _enter_tree() -> void:
	_register_export_dist_plugin()
	call_deferred("_run_preset_install_once")


func _enable_plugin() -> void:
	call_deferred("_run_preset_install_once")


func _exit_tree() -> void:
	_unregister_export_dist_plugin()


func _run_preset_install_once() -> void:
	if _install_attempted:
		return
	_install_attempted = true

	var install_result := _ensure_export_preset()
	var result := int(install_result.get("result", INSTALL_RESULT_FAILED))
	var preset_name := str(install_result.get("preset_name", "(unknown)"))
	if result == INSTALL_RESULT_ADDED:
		print("[Godot Matrix RTC] Installed export preset: %s" % preset_name)
		_show_reload_notice(preset_name)
	elif result == INSTALL_RESULT_ALREADY_PRESENT:
		print("[Godot Matrix RTC] Export preset already present: %s" % preset_name)
	else:
		push_error("[Godot Matrix RTC] Failed to install export preset from template: %s" % EXAMPLE_EXPORT_PRESETS_PATH)


func _ensure_export_preset() -> Dictionary:
	var template := _load_template_preset()
	if template.is_empty():
		return {"result": INSTALL_RESULT_FAILED, "preset_name": "(unknown)"}

	var preset_name := str(template.get("name", "(unknown)"))
	var template_config := template.get("config", null) as ConfigFile
	if template_config == null:
		push_error("[Godot Matrix RTC] Template config payload was invalid.")
		return {"result": INSTALL_RESULT_FAILED, "preset_name": preset_name}
	var source_index := int(template.get("source_index", -1))
	if source_index < 0:
		push_error("[Godot Matrix RTC] Template preset index was invalid.")
		return {"result": INSTALL_RESULT_FAILED, "preset_name": preset_name}

	var content := ""
	if FileAccess.file_exists(EXPORT_PRESETS_PATH):
		var input := FileAccess.open(EXPORT_PRESETS_PATH, FileAccess.READ)
		if input == null:
			push_error("[Godot Matrix RTC] Could not read export_presets.cfg")
			return {"result": INSTALL_RESULT_FAILED, "preset_name": preset_name}
		content = input.get_as_text()

	if _has_preset_name(content, preset_name):
		return {"result": INSTALL_RESULT_ALREADY_PRESENT, "preset_name": preset_name}

	var preset_index := _next_preset_index_from_text(content)
	var block := _serialize_preset(template_config, source_index, preset_index)
	if block == "":
		return {"result": INSTALL_RESULT_FAILED, "preset_name": preset_name}

	var output_text := content
	if output_text != "" and not output_text.ends_with("\n"):
		output_text += "\n"
	output_text += block

	var output := FileAccess.open(EXPORT_PRESETS_PATH, FileAccess.WRITE)
	if output == null:
		push_error("[Godot Matrix RTC] Could not write export_presets.cfg")
		return {"result": INSTALL_RESULT_FAILED, "preset_name": preset_name}
	output.store_string(output_text)
	return {"result": INSTALL_RESULT_ADDED, "preset_name": preset_name}


func _has_preset_name(content: String, preset_name: String) -> bool:
	return content.find("name=\"%s\"" % preset_name) != -1


func _next_preset_index_from_text(content: String) -> int:
	var regex := RegEx.new()
	var compile_err := regex.compile("\\[preset\\.(\\d+)\\]")
	if compile_err != OK:
		return 0

	var max_index := -1
	for match in regex.search_all(content):
		var index_text := match.get_string(1)
		if index_text.is_valid_int():
			max_index = maxi(max_index, int(index_text))
	return max_index + 1


func _load_template_preset() -> Dictionary:
	var config := ConfigFile.new()
	var load_err := config.load(EXAMPLE_EXPORT_PRESETS_PATH)
	if load_err != OK:
		push_error("[Godot Matrix RTC] Could not read template presets file: %s" % EXAMPLE_EXPORT_PRESETS_PATH)
		return {}

	var source_index := _first_preset_index(config)
	if source_index == -1:
		push_error("[Godot Matrix RTC] No [preset.N] sections found in template file.")
		return {}

	var section := "preset.%d" % source_index
	var preset_name := str(config.get_value(section, "name", ""))
	if preset_name == "":
		push_error("[Godot Matrix RTC] Template preset is missing its name field.")
		return {}

	return {
		"config": config,
		"source_index": source_index,
		"name": preset_name,
	}


func _first_preset_index(config: ConfigFile) -> int:
	var first_index := -1
	for section in config.get_sections():
		if section.ends_with(".options"):
			continue
		if not section.begins_with("preset."):
			continue

		var suffix := section.trim_prefix("preset.")
		if not suffix.is_valid_int():
			continue

		var index := int(suffix)
		if first_index == -1 or index < first_index:
			first_index = index

	return first_index


func _serialize_preset(config: ConfigFile, source_index: int, target_index: int) -> String:
	var source_section := "preset.%d" % source_index
	var source_options_section := "%s.options" % source_section
	var target_section := "preset.%d" % target_index
	var target_options_section := "%s.options" % target_section
	var lines := PackedStringArray()

	lines.append("[%s]" % target_section)
	for key in config.get_section_keys(source_section):
		var value: Variant = config.get_value(source_section, key)
		lines.append("%s=%s" % [key, var_to_str(value)])
	lines.append("")

	if config.has_section(source_options_section):
		lines.append("[%s]" % target_options_section)
		for key in config.get_section_keys(source_options_section):
			var value: Variant = config.get_value(source_options_section, key)
			lines.append("%s=%s" % [key, var_to_str(value)])
		lines.append("")

	return "\n".join(lines)


func _show_reload_notice(preset_name: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Godot Matrix RTC"
	dialog.dialog_text = ""
	dialog.exclusive = false
	dialog.get_ok_button().hide()
	dialog.get_ok_button().disabled = true

	var not_now_button := dialog.add_button("Not Now", false)
	var reload_button := dialog.add_button("Reload", true)

	var message := RichTextLabel.new()
	message.bbcode_enabled = true
	message.scroll_active = true
	message.fit_content = false
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.set_anchors_preset(Control.PRESET_FULL_RECT)
	message.offset_left = 16
	message.offset_top = 16
	message.offset_right = -16
	message.offset_bottom = -84
	message.text = "[center]✅ Godot Matrix RTC plugin setup complete.\nExport preset \"%s\" installed, you'll need to reload the project to refresh the Export UI.\n\nIt's highly recommended to take a look at the sample project as it is pre-configured and nicely resizes regardless of widget layout:\n\n[url=%s]%s[/url][/center]" % [preset_name, EXAMPLE_PROJECT_URL, EXAMPLE_PROJECT_URL]
	message.meta_clicked.connect(_on_notice_link_clicked)

	var base_control := get_editor_interface().get_base_control()
	base_control.add_child(dialog)
	dialog.add_child(message)
	dialog.close_requested.connect(dialog.queue_free)
	not_now_button.pressed.connect(dialog.queue_free)
	reload_button.pressed.connect(_on_reload_button_pressed.bind(dialog))
	dialog.popup_centered(NOTICE_DEFAULT_SIZE)
	call_deferred("_fit_notice_dialog", dialog, message)


func _on_reload_button_pressed(dialog: AcceptDialog) -> void:
	dialog.queue_free()
	var editor := get_editor_interface()
	if editor.has_method("restart_editor"):
		editor.restart_editor(true)
	else:
		push_error("[Godot Matrix RTC] Could not reload automatically. Please reload the project manually.")


func _on_notice_link_clicked(meta: Variant) -> void:
	var err := OS.shell_open(str(meta))
	if err != OK:
		push_error("[Godot Matrix RTC] Could not open example project URL: %s" % str(meta))


func _fit_notice_dialog(dialog: AcceptDialog, message: RichTextLabel) -> void:
	if not is_instance_valid(dialog) or not is_instance_valid(message):
		return

	var viewport_size: Vector2 = get_editor_interface().get_base_control().get_viewport_rect().size
	var max_height := int(viewport_size.y * NOTICE_MAX_VIEWPORT_RATIO)
	var content_height := message.get_content_height()
	var target_height := clampi(content_height + NOTICE_CONTENT_VERTICAL_PADDING, NOTICE_MIN_HEIGHT, max_height)
	dialog.size = Vector2i(dialog.size.x, target_height)
	var centered_position: Vector2 = (viewport_size - Vector2(dialog.size)) / 2.0
	dialog.position = Vector2i(centered_position)
	message.scroll_active = target_height < content_height + NOTICE_CONTENT_VERTICAL_PADDING


func _register_export_dist_plugin() -> void:
	if _export_dist_plugin != null:
		return
	_export_dist_plugin = EXPORT_DIST_PLUGIN_SCRIPT.new()
	add_export_plugin(_export_dist_plugin)


func _unregister_export_dist_plugin() -> void:
	if _export_dist_plugin == null:
		return
	remove_export_plugin(_export_dist_plugin)
	_export_dist_plugin = null
