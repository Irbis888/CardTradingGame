extends CanvasLayer

@onready var money_label = $UIRoot/MainHBox/LeftPanel/MoneyLabel
@onready var sell_button = $UIRoot/MainHBox/LeftPanel/SellButton
@onready var player_money_label = $UIRoot/MainHBox/RightPanel/PlayerMoney

var player_money = 69

func _ready():
	sell_button.pressed.connect(on_sell_pressed)
	update_money()

func on_sell_pressed():
	player_money += 5
	update_money()

func update_money():
	money_label.text = "$%d" % player_money
	player_money_label.text = "$%d" % (player_money - 27) # просто пример разницы
