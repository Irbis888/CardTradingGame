# trader.gd
class_name Trader
extends Object

const Card = preload("res://TradingStuff/LogicScripts/cardLogic.gd")  # если понадобится типизация

var name: String
var LI: int  # ЛИ — валюта
var collection: Array  # Коллекция карт
var portrait = preload("res://TradingStuff/Style/Portraits/M2.png")

func _init(name: String, li: int, starting_cards: Array, portrait: Resource):
	self.name = name
	self.LI = li
	self.collection = starting_cards.duplicate()
	self.portrait = portrait

func get_mult() -> float:
	# Заглушка множителя
	return 1.0
	
