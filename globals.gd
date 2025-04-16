extends Node

var my_collection = [Card.new("Spider", 10), Card.new("Tarakan", 15)]
var playerAccount : Player = Player.new("Joe", 42, my_collection, preload("res://TradingStuff/Style/Portraits/M3.png"))

var traderList : Array[Trader]
