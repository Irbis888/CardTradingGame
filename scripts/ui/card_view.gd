extends Control

@onready var portrait = $Portrait1280x853
@onready var frame = $Frame
@onready var seriesLabel = $Frame/SeriesFrame/SeriesLabel
@onready var strLabel = $Frame/StatPanel/Stats/STR
@onready var defLabel = $Frame/StatPanel/Stats/DEF
@onready var magLabel = $Frame/StatPanel/Stats/MAG
@onready var rarityLabel = $Frame/StatPanel/RarityLabel
@onready var nameLabel = $Frame/Panel/NameLabel

func init(card: Card):
	portrait.texture = card.picture
	seriesLabel.text = card.series
	strLabel.text = Globals.content.ui.attack_prefix + str(card.str)
	defLabel.text = Globals.content.ui.defense_prefix + str(card.def)
	magLabel.text = Globals.content.ui.magic_prefix + str(card.mag)
	rarityLabel.text = card.get_literal_name()
	nameLabel.text = card.name
	frame.texture = load(GamePaths.card_frame(card.get_literal_name()))	
	
	
