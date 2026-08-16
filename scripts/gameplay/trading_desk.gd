class_name TradingDesk
extends Control


const DEMO_CARD_IDS := [8, 16, 24]

@onready var cards: Array[DraggableCard] = [
	$DragSurface/CardOne as DraggableCard,
	$DragSurface/CardTwo as DraggableCard,
	$DragSurface/CardThree as DraggableCard,
]


func _ready() -> void:
	for index in range(cards.size()):
		var card := Globals.get_card_by_id(DEMO_CARD_IDS[index])
		if card != null:
			cards[index].display_card(card)
