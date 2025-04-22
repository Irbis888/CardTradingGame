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

enum CardRanks {
		SIX, SEVEN, EIGHT, NINE, TEN, JACK, KING, ACE
}

var CardNames = ["Six", "Seven", "Eight", "Nine", "Ten", "Jack", "King", "Ace"]
var CardSuits = ["of Spades", "of Hearts", "of Clubs", "of Diamonds"]

var my_collection = []
var playerAccount : Player
var nextTrader: Trader


func _ready() -> void:
	create_cards()
	generate_collection(3)
	playerAccount = Player.new("Jackie Boy", 4200, my_collection, preload("res://TradingStuff/Style/Portraits/jackieBoy.jpg"), Globals.CardRanks.JACK, "of Spades")
	
func generate_collection(size:int):
		for i in size:
			my_collection.append(cardList.pick_random())
	
	
func create_cards () -> void:
	var cards_data = load_json_file("res://Resources/card_origin.json")
	if cards_data:
		for i in cards_data:
			var c = Card.new(i["name"], load("res://TradingStuff/Style/CardPics/" + i["picture"]),
			i["attack"], i["defense"], i["magic"], i["series"], i["rarity"] )
			cardList.append(c)
	
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
	
