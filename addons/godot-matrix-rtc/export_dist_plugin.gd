@tool
extends EditorExportPlugin

const SOURCE_DIST_DIR := "res://addons/godot-matrix-rtc/dist"
const TARGET_DIST_DIR := "dist"

var _export_path := ""
var _is_web_export := false


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	_export_path = path
	_is_web_export = features.has("web")
	if not _is_web_export:
		return

	var source_abs := ProjectSettings.globalize_path(SOURCE_DIST_DIR)
	if not DirAccess.dir_exists_absolute(source_abs):
		push_error("[Godot Matrix RTC] Missing dist directory: %s" % SOURCE_DIST_DIR)


func _export_end() -> void:
	if not _is_web_export:
		return

	var source_abs := ProjectSettings.globalize_path(SOURCE_DIST_DIR)
	if not DirAccess.dir_exists_absolute(source_abs):
		return

	var output_dir := _get_output_dir(_export_path)
	if output_dir == "":
		push_error("[Godot Matrix RTC] Could not resolve export output directory from path: %s" % _export_path)
		return

	var target_abs := output_dir.path_join(TARGET_DIST_DIR)
	var remove_err := _remove_dir_recursive(target_abs)
	if remove_err != OK and remove_err != ERR_DOES_NOT_EXIST:
		push_error("[Godot Matrix RTC] Failed to clear export dist directory: %s" % target_abs)
		return

	var copy_err := _copy_dir_recursive(source_abs, target_abs)
	if copy_err != OK:
		push_error("[Godot Matrix RTC] Failed to copy dist into export output. (%s -> %s)" % [source_abs, target_abs])
		return

	print("[Godot Matrix RTC] Copied dist into export output: %s" % target_abs)


func _get_output_dir(path: String) -> String:
	if path == "":
		return ""
	var resolved := path
	if resolved.begins_with("res://"):
		resolved = ProjectSettings.globalize_path(resolved)
	resolved = resolved.replace("\\", "/")
	return resolved.get_base_dir()


func _copy_dir_recursive(source_dir: String, target_dir: String) -> int:
	var mk_err := DirAccess.make_dir_recursive_absolute(target_dir)
	if mk_err != OK:
		return mk_err

	var dir := DirAccess.open(source_dir)
	if dir == null:
		return ERR_CANT_OPEN

	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry == "." or entry == "..":
			continue

		var source_path := source_dir.path_join(entry)
		var target_path := target_dir.path_join(entry)
		if dir.current_is_dir():
			var child_err := _copy_dir_recursive(source_path, target_path)
			if child_err != OK:
				dir.list_dir_end()
				return child_err
		else:
			var copy_err := DirAccess.copy_absolute(source_path, target_path)
			if copy_err != OK:
				dir.list_dir_end()
				return copy_err

	dir.list_dir_end()
	return OK


func _remove_dir_recursive(path: String) -> int:
	if not DirAccess.dir_exists_absolute(path):
		return ERR_DOES_NOT_EXIST

	var dir := DirAccess.open(path)
	if dir == null:
		return ERR_CANT_OPEN

	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry == "." or entry == "..":
			continue

		var child_path := path.path_join(entry)
		var err := OK
		if dir.current_is_dir():
			err = _remove_dir_recursive(child_path)
			if err != OK and err != ERR_DOES_NOT_EXIST:
				dir.list_dir_end()
				return err
		else:
			err = DirAccess.remove_absolute(child_path)
			if err != OK and err != ERR_DOES_NOT_EXIST:
				dir.list_dir_end()
				return err

	dir.list_dir_end()
	return DirAccess.remove_absolute(path)
