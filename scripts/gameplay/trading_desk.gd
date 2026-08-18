class_name TradingDesk
extends Control


@onready var card_binder: CardBinder = $DragSurface/CardBinder


func get_card_binder() -> CardBinder:
	return card_binder
