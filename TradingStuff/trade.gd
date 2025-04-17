extends Node2D
#Это файл экрана торговли с ОДНИМ КОНКРЕТНЫМ торговцем

	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	var ui = get_tree().current_scene.get_node("CardTradeUI")
	var his_collection = []
	var size = 10
	for i in size:
		his_collection.append(Globals.cardList.pick_random())
	ui.init(Globals.playerAccount, Globals.nextTrader)
	 #Trader.new("Siddy", 69, his_collection, preload("res://TradingStuff/Style/Portraits/M5.png")))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
