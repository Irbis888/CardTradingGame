class_name GamePaths
extends RefCounted


const DATA_CARDS := "res://data/cards.json"
const DATA_ENDINGS := "res://data/endings.json"
const DATA_EVENTS := "res://data/events.json"
const DATA_QUESTS := "res://data/quests.json"
const DATA_STORY_TRADERS := "res://data/story_traders.json"
const DATA_TEXT := "res://data/text.json"

const SCENE_MAIN_MENU := "res://scenes/screens/main_menu.tscn"
const SCENE_DIALOGUE := "res://scenes/screens/dialogue.tscn"
const SCENE_TUTORIAL := "res://scenes/screens/tutorial.tscn"
const SCENE_ENDING := "res://scenes/screens/ending.tscn"
const SCENE_TRADER_LIST := "res://scenes/screens/trader_list.tscn"
const SCENE_TRADE := "res://scenes/screens/trade.tscn"

const SCENE_CARD_BUTTON := "res://scenes/ui/card_button.tscn"
const SCENE_CARD_VIEW := "res://scenes/ui/card_view.tscn"
const SCENE_TRADER_BUTTON := "res://scenes/ui/trader_button.tscn"

const CARDS_DIR := "res://assets/cards/"
const CARD_FRAMES_DIR := "res://assets/ui/card_frames/"
const PORTRAITS_DIR := "res://assets/portraits/"
const STORY_IMAGES_DIR := "res://assets/story/"

const DEFAULT_STORY_IMAGE := STORY_IMAGES_DIR + "sink.jpg"
const DAY_COMPLETE_IMAGE := STORY_IMAGES_DIR + "zloi.jpg"
const EVENT_IMAGE := STORY_IMAGES_DIR + "playing.jpg"
const PLAYER_PORTRAIT := PORTRAITS_DIR + "jackieBoy.jpg"
const CHARACTER_FRAME := PORTRAITS_DIR + "CharacterFrame.png"
const ACE_FRAME := CARD_FRAMES_DIR + "fSSP.png"


static func card_image(file_name: String) -> String:
	return CARDS_DIR + file_name


static func card_frame(rarity_name: String) -> String:
	return CARD_FRAMES_DIR + "f" + rarity_name + ".png"


static func portrait(file_name: String) -> String:
	return PORTRAITS_DIR + file_name

