extends Control


@onready var portrait: TextureRect = $Portrait1280x853
@onready var frame: TextureRect = $Frame
@onready var series_label: Label = $Frame/SeriesFrame/SeriesLabel
@onready var attack_label: Label = $Frame/StatPanel/Stats/STR
@onready var defense_label: Label = $Frame/StatPanel/Stats/DEF
@onready var magic_label: Label = $Frame/StatPanel/Stats/MAG
@onready var rarity_label: Label = $Frame/StatPanel/RarityLabel
@onready var name_label: Label = $Frame/Panel/NameLabel


func init(card: Card) -> void:
	portrait.texture = card.picture
	series_label.text = card.series
	attack_label.text = str(Globals.card_ui_text.get("attack_prefix", "")) + str(card.str)
	defense_label.text = str(Globals.card_ui_text.get("defense_prefix", "")) + str(card.def)
	magic_label.text = str(Globals.card_ui_text.get("magic_prefix", "")) + str(card.mag)
	rarity_label.text = card.get_literal_name()
	name_label.text = card.name
	frame.texture = load(GamePaths.card_frame(card.get_literal_name())) as Texture2D
