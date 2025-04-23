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

func _init(name: String, li: int, starting_cards: Array, portrait: Resource, rank : int, suit: String):
	self.name = name
	self.LI = li
	self.collection = starting_cards.duplicate()
	self.portrait = portrait
	self.rank = rank
	self.suit = suit
	
func get_price_multiplier_against(other_rank: int) -> float:
	var diff = self.rank - other_rank 
	if diff < 0:
		return 1.0 + diff * 0.05 
	elif diff > 0:
		return 1.1 + diff * 0.1 
	else: return 1.0
		

func get_mult() -> float:
	# Заглушка множителя
	return 1.0
	
