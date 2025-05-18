extends Button

var trader: Trader



func init(tr: Trader) -> void:
	pass
	self.trader = tr
	self.icon = trader.portrait
	self.text = "%s\n%s %s" % [trader.name, Globals.CardNames[trader.rank], trader.suit]

	
func _on_pressed() -> void:
	Globals.nextTrader = trader
	get_tree().change_scene_to_file("res://TradingStuff/store_screen.tscn")
	
