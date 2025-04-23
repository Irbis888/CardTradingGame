# trader.gd
class_name Trader
extends Object

const Card = preload("res://TradingStuff/LogicScripts/cardLogic.gd")  # если понадобится типизация

var name: String
var LI: int  # ЛИ — валюта
var collection: Array  # Коллекция карт
var portrait = preload("res://TradingStuff/Style/Portraits/M2.png")
var rank: int  # карточный ранг (enum)
var suit: String # карточная масть отдельно
var event_price_modifier: float = 1.0 # пиздец я хуею

func _init(name: String, li: int, starting_cards: Array, portrait: Resource, rank : int, suit: String, event_price_modifier: float):
	self.name = name
	self.LI = li
	self.collection = starting_cards.duplicate()
	self.portrait = portrait
	self.rank = rank
	self.suit = suit
	self.event_price_modifier = event_price_modifier
	
func get_price_multiplier_against(other_rank: int) -> float:
	var diff = self.rank - other_rank 
	var base_mult: float
	if diff < 0:
		base_mult = 1.0 + diff * 0.05 
	elif diff > 0:
		base_mult = 1.1 + diff * 0.1 
	else: base_mult = 1.0
	return base_mult * event_price_modifier
		

func get_mult() -> float:
	# Заглушка множителя
	return 1.0
	
