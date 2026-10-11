class_name DraggableCard
extends "res://scripts/ui/drag_drop/dual_space_draggable.gd"


@onready var card_visual: Control = $DeskView/CardVisual
@onready var counter_name_label: Label = $CounterView/NameLabel
@onready var counter_meta_label: Label = $CounterView/MetaLabel

var card_data: Card


func _ready() -> void:
	super()
	card_visual.set_interactive(true)


func display_card(card: Card) -> void:
	card_data = card
	set_item_payload(card)
	card_visual.init(card)
	counter_name_label.text = card.name
	counter_meta_label.text = "%s  %s" % [card.series, card.get_literal_name()]


func can_start_drag_at(global_point: Vector2) -> bool:
	if current_space == &"counter":
		return true
	return not card_visual.is_flipping() and not card_visual.can_flip_at(global_point) and not card_visual.can_scroll_at(global_point)


func set_back_visible(value: bool) -> void:
	card_visual.set_back_visible(value)


func get_card_data() -> Card:
	return card_data
