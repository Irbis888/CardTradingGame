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
	strLabel.text = "ATK: " + str(card.str)
	defLabel.text = "DEF: " + str(card.def)
	magLabel.text = "MAG: " + str(card.mag)
	rarityLabel.text = card.get_literal_name()
	nameLabel.text = card.name
	frame.texture = load("res://TradingStuff/Style/CardFrames/f" + card.get_literal_name() +".png")	
	
	
