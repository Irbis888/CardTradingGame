class_name CustomerSpeechView
extends Panel


signal replica_spoken(text: String)

@export var speech_label_path := NodePath("ReplicaLabel")
@export var speech_timer_path := NodePath("SpeechTimer")
@export_range(0.1, 60.0, 0.1, "or_greater") var default_replica_duration := 4.0

var _speech_label: Label
var _speech_timer: Timer
var _trade_text: Dictionary = {}


func _ready() -> void:
	_speech_label = get_node_or_null(speech_label_path) as Label
	_speech_timer = get_node_or_null(speech_timer_path) as Timer
	if _speech_label == null:
		push_error("CustomerSpeechView requires speech_label_path.")
	if _speech_timer != null:
		_speech_timer.timeout.connect(hide_replica)
	_load_trade_text()
	visible = false


func show_trade_line(key: String, values: Dictionary, duration: float) -> void:
	show_replica(str(_trade_text.get(key, key)).format(values), duration)


func show_replica(text: String, duration: float = -1.0) -> void:
	var replica := text.strip_edges()
	if replica.is_empty() or _speech_label == null:
		return
	_speech_label.text = replica
	visible = true
	if _speech_timer != null:
		var visible_duration := duration if duration > 0.0 else default_replica_duration
		_speech_timer.start(visible_duration)
	replica_spoken.emit(replica)


func hide_replica() -> void:
	if _speech_timer != null:
		_speech_timer.stop()
	visible = false


func _load_trade_text() -> void:
	var loaded_text = ContentLoader.load_json(GamePaths.DATA_TRADING_TEXT)
	if loaded_text is Dictionary:
		_trade_text = loaded_text
	else:
		push_error("Trading text could not be loaded.")
		_trade_text = {}
