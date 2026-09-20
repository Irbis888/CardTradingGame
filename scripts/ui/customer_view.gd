class_name CustomerView
extends Control


signal replica_spoken(text: String)

const PORTRAIT_PATH_TEMPLATE := "res://assets/portraits_new/Customer_00%d.png"

@export var customer_manager_path: NodePath
@export var portrait_path: NodePath
@export var speech_view_path := NodePath("SpeechBubble")
@export_range(0.05, 5.0, 0.05, "or_greater") var fade_duration := 0.35

var _customer_manager: CustomerManager
var _portrait: TextureRect
var _speech_view: CustomerSpeechView
var _transition_tween: Tween


func _ready() -> void:
	_resolve_dependencies()
	_connect_customer_manager()
	_prepare_empty_view()


func _exit_tree() -> void:
	_kill_transition_tween()


func _resolve_dependencies() -> void:
	_customer_manager = get_node_or_null(customer_manager_path) as CustomerManager
	_portrait = get_node_or_null(portrait_path) as TextureRect
	_speech_view = get_node_or_null(speech_view_path) as CustomerSpeechView
	if _customer_manager == null:
		push_error("CustomerView requires customer_manager_path.")
	if _portrait == null:
		push_error("CustomerView requires portrait_path.")
	if _speech_view == null:
		push_error("CustomerView requires speech_view_path.")


func _connect_customer_manager() -> void:
	if _customer_manager == null:
		return
	_customer_manager.customer_arrival_started.connect(_on_customer_arrival_started)
	_customer_manager.customer_departure_started.connect(_on_customer_departure_started)
	if _speech_view != null:
		_customer_manager.dialogue_requested.connect(_speech_view.show_trade_line)
		_customer_manager.raw_replica_requested.connect(_speech_view.show_replica)
		_speech_view.replica_spoken.connect(replica_spoken.emit)


func _prepare_empty_view() -> void:
	visible = false
	modulate.a = 1.0
	if _portrait != null:
		_portrait.visible = false
		_portrait.modulate.a = 1.0
	if _speech_view != null:
		_speech_view.hide_replica()


func _on_customer_arrival_started(customer: CustomerVisit) -> void:
	if _portrait == null:
		_customer_manager.complete_customer_arrival(customer)
		return
	_kill_transition_tween()
	_apply_portrait_texture(customer.portrait_number)
	visible = true
	_portrait.visible = true
	modulate.a = 0.0
	_portrait.modulate.a = 0.0
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_portrait, "modulate:a", 1.0, fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(
		self, "modulate:a", 1.0, fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.finished.connect(_finish_customer_arrival.bind(customer))


func _finish_customer_arrival(customer: CustomerVisit) -> void:
	_transition_tween = null
	if _customer_manager != null:
		_customer_manager.complete_customer_arrival(customer)


func _on_customer_departure_started(customer: CustomerVisit) -> void:
	if _speech_view != null:
		_speech_view.hide_replica()
	if _portrait == null:
		_finish_customer_departure(customer)
		return
	_kill_transition_tween()
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_portrait, "modulate:a", 0.0, fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.tween_property(
		self, "modulate:a", 0.0, fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.finished.connect(_finish_customer_departure.bind(customer))


func _finish_customer_departure(customer: CustomerVisit) -> void:
	_transition_tween = null
	if _portrait != null:
		_portrait.visible = false
	visible = false
	if _customer_manager != null:
		_customer_manager.complete_customer_departure(customer)


func _kill_transition_tween() -> void:
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()
	_transition_tween = null


func _apply_portrait_texture(portrait_number: int) -> bool:
	if _portrait == null:
		return false
	var portrait_resource_path := PORTRAIT_PATH_TEMPLATE % portrait_number
	if not ResourceLoader.exists(portrait_resource_path):
		push_warning("Customer portrait does not exist: %s" % portrait_resource_path)
		return false
	var portrait_texture := load(portrait_resource_path) as Texture2D
	if portrait_texture == null:
		return false
	_portrait.texture = portrait_texture
	return true
