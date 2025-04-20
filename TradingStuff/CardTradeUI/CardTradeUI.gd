extends CanvasLayer

@onready var trader_money_label = $UIRoot/MainHBox/LeftPanel/MoneyLabel
@onready var sell_button = $UIRoot/MainHBox/MiddlePanel/SellButton
@onready var player_money_label = $UIRoot/MainHBox/RightPanel/PlayerMoney
@onready var trader_name_label = $UIRoot/MainHBox/LeftPanel/TraderNameLabel
@onready var player_name_label = $UIRoot/MainHBox/RightPanel/PlayerName
@onready var opponent_cards = $UIRoot/MainHBox/LeftPanel/ScrollContainer/OpponentCards
@onready var player_cards = $UIRoot/MainHBox/RightPanel/ScrollContainer/PlayerCards
@onready var summary_label = $UIRoot/MainHBox/MiddlePanel/TradeSummary

@onready var player_portrait = $UIRoot/MainHBox/RightPanel/PlayerAvatar
@onready var trader_portrait = $UIRoot/MainHBox/LeftPanel/Avatar
@onready var myCard = $UIRoot/MainHBox/MiddlePanel/TradedCards


var CardScene = load("res://TradingStuff/cardButton.tscn")



var player_money = 69
var player: Player
var counter: Trader

func _ready():
	sell_button.pressed.connect(on_sell_pressed)
	#update_money()
	
func init(player: Player, counter: Trader) -> void:
	self.player = player
	self.counter = counter
	redraw_ui()
	

func on_sell_pressed():
	var give : Array[int] = []
	var c : int = 0
	for i in player_cards.get_children():
		if i.chosen:
			give.append(c)
		c += 1
	var take : Array[int] = []
	c = 0
	for i in opponent_cards.get_children():
		if i.chosen:
			take.append(c)
		c += 1
			
	player.trade(counter, give, take)
	redraw_ui()

func gen_summary():
	var give : Array[int] = []
	var c : int = 0
	for i in player_cards.get_children():
		if i.chosen:
			give.append(c)
		c += 1
	var take : Array[int] = []
	c = 0
	for i in opponent_cards.get_children():
		if i.chosen:
			take.append(c)
		c += 1
	var cost = player.priceCount(counter, give, take)
	var out = """Summary:
		"""
	if cost < 0:
		out += "You lose $" + str(-cost)
	elif cost > 0:
		out += "You get $" + str(cost)
	out += "\nYou give:\n"
	for i in give:
		out += player.collection[i].name + "\n"
	out += "\nYou take:\n"
	for i in take:
		out += counter.collection[i].name + "\n"
	return out
		
	

func redraw_ui():
	#summary_label.text = gen_summary()
	for child in opponent_cards.get_children():
		child.queue_free()
	for child in player_cards.get_children():
		child.queue_free()
	player_name_label.text = player.name
	trader_name_label.text = counter.name
	
	player_money_label.text = "$" + str(player.LI)
	trader_money_label.text = "$" + str(counter.LI)
	
	player_portrait.texture = player.portrait
	trader_portrait.texture = counter.portrait
	
	var card
	for i in counter.collection:
		card = CardScene.instantiate()		
		opponent_cards.add_child(card)
		card.init(i, self)
	for i in player.collection:
		card = CardScene.instantiate()		
		player_cards.add_child(card)
		card.init(i,self)


func _on_up_button_pressed() -> void:
	get_tree().change_scene_to_file("res://TradingStuff/main_trade_screen.tscn")
