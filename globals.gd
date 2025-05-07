extends Node


var traderList : Array[Trader] 
var cardList: Array[Card]
var nameList = [
	"Vinny 'The Wrench' Moretti",
	"Salvatore 'Silk Suit' Romano",
	"Tommy 'Knuckles' Mancini",
	"Frankie 'No Nose' Bellini",
	"Angelo 'The Hat' Vitale",
	"Johnny 'Dice' Calabrese",
	"Rocco 'Two-Times' Russo",
	"Luca 'The Shadow' Marino",
	"Tony 'The Fox' Caruso",
	"Nicky 'The Chin' Gravano",
	"Vito 'Dead Eyes' Giordano",
	"Sammy 'Slick' Barone",
	"Marco 'The Knife' Esposito",
	"Joey 'Boots' Terranova",
	"Benny 'Numbers' Capelli",
	"Donnie 'Quickhands' Rizzo",
	"Carlo 'Whispers' Abate",
	"Enzo 'The Ghost' Bellomo",
	"Pauly 'Bricks' DiAngelo",
	"Leo 'Switchblade' Romano",
	"Ralphie 'The Roach' Vassallo",
	"Dominic 'Fats' Giaccone",
	"Freddie 'Bang Bang' Lupo",
	"Albie 'The Suit' Costello",
	"Mickey 'Snaps' Fiorentino",
	"Vincent 'Lucky V' D'Amico",
	"Silvio 'Scar' Bonasera",
	"Lenny 'The Rat' Accardi",
	"Tony 'Whiskers' Gallo",
	"Gianni 'The Smile' Ferro"
]

var dialoguesNeutral = [
	"Show me what you've got!",
	"What happened to your face?",
	"I've got the best cards in all of Cardia Nostra!"	,
	"Another day, another risky deal. You in?",
	"Win, lose... as long as you walk away breathing, it’s a good day."
]

var dialogueRude = [
	"I'm doing charity work today, it seems.",
	"You smell of desperation... and saltwater.",
	"I shouldn't even be seen dealing with you. Count yourself lucky.",
	"Pfft... I should be dealing with those who still have a face.",
	"Make your offer quickly, before I change my mind."
]

var dialoguesFlatter = [
	"It's an honor to be dealing with the street legend. My collection is at your service!",
	"Please, take a look at my best offers!",
	"Anything for you, sir!",
	"Legendary Jackie Boy! Every trader in Cardia Nostra envies me right now!"
]

var day: int = 0

enum CardRanks {
		SIX, SEVEN, EIGHT, NINE, TEN, JACK, QUEEN, KING, ACE
}

var CardNames = ["Six", "Seven", "Eight", "Nine", "Ten", "Jack", "Queen", "King", "Ace"]
var CardSuits = ["of Spades", "of Hearts", "of Clubs", "of Diamonds"]

var NextPic: Resource = load("res://TradingStuff/Style/StoryPics/sink.jpg")
var NextText: String = "You used to be the Mafia Boss, the true Ace of Spades
But no king rule forever
You brother in arms betrayed you and sent to feed fish
The only thing that saved your life and your position in the Mafia was 

A DEAL WITH SEA DEVIL

He make you outta the concrete boot but took your face
Your collection was put on sale and started going around whole city
Get you collection back!"
var is_next_to_trade = true

var story_traders: Array = []

func load_story_dumbasses():
	var data = load_json_file("res://Resources/story_traders.json")
	if data != null:
		story_traders = data
	else:
		print("no story traders for ya")

func get_story_bitches():
	for trader_data in Globals.story_traders:
		for appearance in trader_data.appearances:
			if appearance.day == Globals.day:
				var cards = []
				for card_id in appearance.cards:
					var card = Globals.get_card_by_id(card_id)
					if card != null:
						cards.append(card)
			
				var portrait_path = "res://TradingStuff/Style/Portraits/" + trader_data.portrait
				var portrait = load(portrait_path)

				var story_trader = Trader.new(
					trader_data.name,
					trader_data.money,
					cards,
					portrait,
					trader_data.rank,
					trader_data.suit,
					1.0,
					trader_data.mult,
					appearance.dialogue
				)
				Globals.traderList.insert(0, story_trader)  # всегда первым
		

func generate_traders():
	var weights = Globals.get_rank_weights_for(Globals.playerAccount.rank)
	
	while Globals.traderList.size() != 4:
		var pn = randi_range(2, 9)
		var portrait = load("res://TradingStuff/Style/Portraits/M" + str(pn) + ".png")
		var gangName = Globals.nameList.pick_random()
		var coll = []
		var dialogue: String


		var trader_rank = Globals.choose_weighted_rank(weights)
		var rand_suit = Globals.CardSuits[randi_range(0, 3)]
		for j in range(randi_range(4, 10)):
			coll.append(Globals.choose_card_for_rank(trader_rank))
			
		if trader_rank - Globals.playerAccount.rank >= 2:
			dialogue = Globals.dialogueRude.pick_random()
		elif trader_rank - Globals.playerAccount.rank <= -2:
			dialogue = Globals.dialoguesFlatter.pick_random()
		else:
			dialogue = Globals.dialoguesNeutral.pick_random()	
			
		#TraderList.append(Trader.new(gangName, randi_range(10, 100)+100, coll, portrait, trader_rank, rand_suit, 1.0))
		Globals.traderList.append(Trader.new(gangName, randi_range(10, 100)+100, coll, portrait, trader_rank,
		 rand_suit, 1.0, 1.0, dialogue))

# это меняет с какой частотой спавнится каждый ранг (с учетом ранга джеки боя)

func get_rank_weights_for(player_rank: int) -> Dictionary:
	var weights := {
		Globals.CardRanks.SIX: 10,
		Globals.CardRanks.SEVEN: 10,
		Globals.CardRanks.EIGHT: 10,
		Globals.CardRanks.NINE: 10,
		Globals.CardRanks.TEN: 10,
		Globals.CardRanks.JACK: 5,
		Globals.CardRanks.KING: 5,
		Globals.CardRanks.QUEEN: 5,
		Globals.CardRanks.ACE: 5,
	}

	if player_rank < Globals.CardRanks.JACK:
		weights[Globals.CardRanks.QUEEN] = 3
		weights[Globals.CardRanks.KING] = 2
		weights[Globals.CardRanks.ACE] = 0

	return weights

static func choose_weighted_rank(weights: Dictionary) -> int:
	var total_weight = 0
	for w in weights.values():
		total_weight += w
	
	var rand = randi_range(0, total_weight - 1)
	var cumulative = 0
	
	for rank in weights.keys():
		cumulative += weights[rank]
		if rand < cumulative:
			return rank
	
	return weights.keys()[0]  # fallback

var my_collection = []
var playerAccount : Player
var nextTrader: Trader

# тут будет код для генерации карт с учетом ранга челика

func get_weight_for_card(card: Card, rank: int) -> int:
	if rank == CardRanks.ACE:
		return card.rarity * 5
	elif rank >= CardRanks.QUEEN:
		return card.rarity * 3
	elif rank >= CardRanks.TEN:
		return card.rarity * 2
	else:
		return 6 - card.rarity  # чаще выпадут дешёвые
		

func choose_card_for_rank(rank: int) -> Card:
	var weighted_cards := []
	for card in cardList:
		var weight := get_weight_for_card(card, rank)
		for i in range(weight):
			weighted_cards.append(card)
	return weighted_cards.pick_random()


func _ready() -> void:
	create_cards()
	generate_collection(3)
	playerAccount = Player.new("Jackie Boy", 4200, my_collection, preload("res://TradingStuff/Style/Portraits/jackieBoy.jpg"),
	Globals.CardRanks.NINE, "of Spades", 1.0, 1.0, "")
	load_story_dumbasses()
	
func generate_collection(size:int):
		for i in size:
			my_collection.append(cardList.pick_random())
	
	
func create_cards () -> void:
	var cards_data = load_json_file("res://Resources/card_origin.json")
	if cards_data:
		for i in cards_data:
			var c = Card.new(i["name"], load("res://TradingStuff/Style/CardPics/" + i["picture"]),
			i["attack"], i["defense"], i["magic"], i["series"], i["rarity"], i["id"] )
			cardList.append(c)
			
func get_card_by_id(id: int) -> Card:
	for c in cardList:
		if c.id == id:
			return c
	return null
	
func load_json_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error == OK:
		return json.get_data()
	else:
		print("Ошибка парсинга JSON: ", json.get_error_message(), " в строке ", json.get_error_line())
		return null
	
