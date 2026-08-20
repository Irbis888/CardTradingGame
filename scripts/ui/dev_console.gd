class_name DevConsole
extends Control


const DRAGGABLE_CARD_SCENE := preload("res://scenes/ui/draggable_card.tscn")
const MAX_OUTPUT_LINES := 60

@export var card_spawn_surface_path: NodePath
@export var suspended_surface_paths: Array[NodePath] = []

@onready var title_label: Label = $ConsolePanel/Margin/VBox/TitleLabel
@onready var output: RichTextLabel = $ConsolePanel/Margin/VBox/Output
@onready var command_input: LineEdit = $ConsolePanel/Margin/VBox/CommandRow/CommandInput

var _commands: Array[Dictionary] = []
var _output_lines := PackedStringArray()
var _surface_input_states: Dictionary = {}


func _ready() -> void:
	visible = false
	command_input.text_submitted.connect(_on_command_submitted)
	_load_commands()
	_write_welcome()


func _exit_tree() -> void:
	_restore_surface_input()


func _input(event: InputEvent) -> void:
	if not _is_console_toggle(event):
		return
	set_console_open(not visible)
	get_viewport().set_input_as_handled()


func set_console_open(open: bool) -> void:
	if visible == open:
		return
	visible = open
	if open:
		_suspend_surface_input()
		command_input.call_deferred("grab_focus")
	else:
		command_input.clear()
		command_input.release_focus()
		_restore_surface_input()


func execute_command(command_text: String) -> bool:
	var tokens := command_text.strip_edges().split(" ", false)
	if tokens.is_empty():
		return false

	var command_definition := _find_command(tokens)
	if command_definition.is_empty():
		_write_line("Unknown command: %s" % command_text.strip_edges())
		return false

	var command_token_count := _get_command_token_count(command_definition)
	var raw_arguments := PackedStringArray()
	for token_index in range(command_token_count, tokens.size()):
		raw_arguments.append(tokens[token_index])

	var parsed_arguments: Array = []
	if not _parse_arguments(command_definition, raw_arguments, parsed_arguments):
		return false

	match str(command_definition.get("handler", "")):
		"quit":
			_write_line("Closing game...")
			get_tree().quit()
			return true
		"give_card":
			return _give_card(int(parsed_arguments[0]))
		_:
			_write_line("Command handler is not supported.")
			return false


func _load_commands() -> void:
	_commands.clear()
	var data = ContentLoader.load_json(GamePaths.DATA_DEV_COMMANDS)
	if not (data is Dictionary):
		push_error("Dev console commands could not be loaded from %s." % GamePaths.DATA_DEV_COMMANDS)
		return

	title_label.text = str(data.get("title", "DEV CONSOLE"))
	var command_entries = data.get("commands", [])
	if not (command_entries is Array):
		push_error("Dev console command list must be an array.")
		return
	for entry in command_entries:
		if entry is Dictionary:
			_commands.append(entry)


func _write_welcome() -> void:
	var data = ContentLoader.load_json(GamePaths.DATA_DEV_COMMANDS)
	if data is Dictionary:
		_write_line(str(data.get("ready_message", "Console ready.")))
	_write_line("Available commands:")
	for command_definition in _commands:
		_write_line(
			"  %s — %s" % [
				str(command_definition.get("usage", "")),
				str(command_definition.get("description", "")),
			]
		)


func _on_command_submitted(command_text: String) -> void:
	var cleaned_command := command_text.strip_edges()
	command_input.clear()
	if cleaned_command.is_empty():
		return
	_write_line("> %s" % cleaned_command)
	execute_command(cleaned_command)
	command_input.call_deferred("grab_focus")


func _find_command(tokens: PackedStringArray) -> Dictionary:
	var selected_command: Dictionary = {}
	var selected_token_count := 0
	for command_definition in _commands:
		var command_tokens = command_definition.get("tokens", [])
		if not (command_tokens is Array) or command_tokens.size() > tokens.size():
			continue

		var matches := true
		for token_index in range(command_tokens.size()):
			if str(command_tokens[token_index]).to_lower() != tokens[token_index].to_lower():
				matches = false
				break
		if matches and command_tokens.size() > selected_token_count:
			selected_command = command_definition
			selected_token_count = command_tokens.size()
	return selected_command


func _parse_arguments(
	command_definition: Dictionary,
	raw_arguments: PackedStringArray,
	parsed_arguments: Array
) -> bool:
	var argument_definitions = command_definition.get("arguments", [])
	if not (argument_definitions is Array) or raw_arguments.size() != argument_definitions.size():
		_write_usage(command_definition)
		return false

	for argument_index in range(argument_definitions.size()):
		var argument_definition = argument_definitions[argument_index]
		if not (argument_definition is Dictionary):
			_write_line("Malformed command argument definition.")
			return false
		var raw_value := raw_arguments[argument_index]
		match str(argument_definition.get("type", "string")):
			"int":
				if not raw_value.is_valid_int():
					_write_line("%s must be an integer." % str(argument_definition.get("name", "argument")))
					_write_usage(command_definition)
					return false
				parsed_arguments.append(raw_value.to_int())
			_:
				parsed_arguments.append(raw_value)
	return true


func _write_usage(command_definition: Dictionary) -> void:
	_write_line("Usage: %s" % str(command_definition.get("usage", "")))


func _give_card(card_id: int) -> bool:
	var card := Globals.get_card_by_id(card_id)
	if card == null:
		_write_line("Card ID %d does not exist." % card_id)
		return false

	var spawn_surface := get_node_or_null(card_spawn_surface_path) as Control
	if spawn_surface == null or not spawn_surface.has_method("register_draggable"):
		_write_line("Card spawn surface is unavailable.")
		return false

	var spawn_index := 0
	var highest_z_index := 0
	for child in spawn_surface.get_children():
		if child is DraggableCard:
			spawn_index += 1
		if child is Control:
			highest_z_index = maxi(highest_z_index, (child as Control).z_index)

	var card_instance := DRAGGABLE_CARD_SCENE.instantiate() as DraggableCard
	card_instance.z_index = highest_z_index + 1
	spawn_surface.add_child(card_instance)
	card_instance.display_card(card)
	card_instance.position = _get_card_spawn_position(spawn_surface, card_instance, spawn_index)
	var draggable := card_instance.get_node_or_null("UIDraggable") as UIDraggable
	if draggable != null:
		draggable.synchronize_position()

	_write_line("Spawned card %d: %s" % [card.id, card.name])
	return true


func _get_card_spawn_position(
	spawn_surface: Control,
	card_instance: Control,
	spawn_index: int
) -> Vector2:
	var cascade_index := spawn_index % 6
	var cascade_offset := Vector2(cascade_index * 26.0, cascade_index * 18.0)
	var base_position := Vector2(
		spawn_surface.size.x - card_instance.size.x - 55.0,
		55.0
	)
	return base_position - Vector2(cascade_offset.x, -cascade_offset.y)


func _get_command_token_count(command_definition: Dictionary) -> int:
	var command_tokens = command_definition.get("tokens", [])
	return command_tokens.size() if command_tokens is Array else 0


func _write_line(line: String) -> void:
	_output_lines.append(line)
	while _output_lines.size() > MAX_OUTPUT_LINES:
		_output_lines.remove_at(0)
	output.text = "\n".join(_output_lines)


func _is_console_toggle(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return (
		key_event.keycode == KEY_QUOTELEFT
		or key_event.physical_keycode == KEY_QUOTELEFT
		or key_event.unicode == KEY_QUOTELEFT
	)


func _suspend_surface_input() -> void:
	_surface_input_states.clear()
	for surface_path in suspended_surface_paths:
		var surface := get_node_or_null(surface_path)
		if surface == null or _surface_input_states.has(surface):
			continue
		_surface_input_states[surface] = surface.is_processing_input()
		surface.set_process_input(false)


func _restore_surface_input() -> void:
	for surface in _surface_input_states:
		if is_instance_valid(surface):
			surface.set_process_input(bool(_surface_input_states[surface]))
	_surface_input_states.clear()
