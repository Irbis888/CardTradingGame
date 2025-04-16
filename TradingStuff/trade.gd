extends Node2D
#Это файл экрана торговли с ОДНИМ КОНКРЕТНЫМ торговцем

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	var ui = get_tree().current_scene.get_node("CardTradeUI")
	var my_collection = [Card.new("Spider", 10), Card.new("Tarakan", 15)]
	var his_collection = [Card.new("Tommygun", 10), Card.new("Mob Boss", 15)]
	ui.init(Globals.playerAccount,
	 Trader.new("Jack", 69, his_collection, preload("res://TradingStuff/Style/Portraits/M5.png")))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
