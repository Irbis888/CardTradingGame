# trader.gd
class_name Trader
extends Object

const Card = preload("res://TradingStuff/LogicScripts/cardLogic.gd")  # если понадобится типизация

var name: String
var LI: int  # ЛИ — валюта
var collection: Array  # Коллекция карт

func _init(name: String, li: int, starting_cards: Array):
	self.name = name
	self.LI = li
	self.collection = starting_cards.duplicate()

func get_mult() -> float:
	# Заглушка множителя
	return 1.0
	
