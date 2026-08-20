class_name GamePaths
extends RefCounted


const DATA_CARDS := "res://data/cards.json"
const DATA_TEXT := "res://data/text.json"
const DATA_DEV_COMMANDS := "res://data/dev_commands.json"

const CARDS_DIR := "res://assets/cards/"
const CARD_FRAMES_DIR := "res://assets/ui/card_frames/"


static func card_image(file_name: String) -> String:
	return CARDS_DIR + file_name


static func card_frame(rarity_name: String) -> String:
	return CARD_FRAMES_DIR + "f" + rarity_name + ".png"
