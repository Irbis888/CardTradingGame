class_name DraggableCard
extends Control


@onready var card_visual: Control = $CardVisual


func _ready() -> void:
	_disable_mouse_input(self)


func display_card(card: Card) -> void:
	card_visual.init(card)


func _disable_mouse_input(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse_input(child)
