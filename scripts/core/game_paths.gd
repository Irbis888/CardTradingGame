class_name GamePaths
extends RefCounted


const DATA_CARDS := "res://data/cards.json"
const DATA_CARD_PRICES := "res://data/card_prices.json"
const SAVE_CARD_PRICES := "user://card_prices.json"
const DATA_TEXT := "res://data/text.json"
const DATA_DEV_COMMANDS := "res://data/dev_commands.json"
const DATA_TRADING_TEXT := "res://data/trading_text.json"

const CARDS_DIR := "res://assets/cards/"
const CARD_FRAMES_DIR := "res://assets/ui/card_frames/"


static func card_image(file_name: String) -> String:
	if file_name.begins_with("res://"):
		return file_name
	return CARDS_DIR + file_name


static func card_frame(rarity_name: String) -> String:
	# The existing common-rarity frame uses Cyrillic С (U+0421) in its filename.
	if rarity_name == "C":
		return CARD_FRAMES_DIR + "f\u0421.png"
	return CARD_FRAMES_DIR + "f" + rarity_name + ".png"
