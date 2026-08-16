class_name DraggableCard
extends "res://scripts/ui/drag_drop/dual_space_draggable.gd"


@onready var card_visual: Control = $DeskView/CardVisual
@onready var counter_name_label: Label = $CounterView/NameLabel
@onready var counter_meta_label: Label = $CounterView/MetaLabel
@onready var counter_stats_label: Label = $CounterView/StatsLabel

var card_data: Card


func _ready() -> void:
	super()


func display_card(card: Card) -> void:
	card_data = card
	set_item_payload(card)
	card_visual.init(card)
	counter_name_label.text = card.name
	counter_meta_label.text = "%s  %s" % [card.series, card.get_literal_name()]
	counter_stats_label.text = "S:%d  D:%d  M:%d" % [card.str, card.def, card.mag]


func get_card_data() -> Card:
	return card_data
