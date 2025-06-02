extends TextureButton

@onready var name_label = $NameLabel
@onready var price_label = $PriceLabel
@onready var cb = $CheckButton
@onready var tex = $TextureRect
@onready var frame = $Frame


var cardObject: Card
var chosen: bool = false
var parent

@onready var card_view_scene = preload("res://TradingStuff/cardView.tscn")
var card_view_instance: Node = null


func init(card: Card, parent) -> void:
	var coeffs = Vector3i(5, 5, 5)
	self.parent = parent
	
	self.cardObject = card
	name_label.text = cardObject.name
	price_label.text = "$" + str(cardObject.base_price)
	tex.texture = card.picture
	frame.texture = load("res://TradingStuff/Style/CardFrames/f" + card.get_literal_name() +".png")
		
func _on_check_button_toggled(toggled_on: bool) -> void:
	self.chosen = toggled_on
	self.parent.summary_label.text = self.parent.gen_summary()
	
func _on_mouse_entered() -> void:
	if card_view_instance == null:
		card_view_instance = card_view_scene.instantiate()
		parent.myCard.add_child(card_view_instance)
		#card_view_instance.global_position = get_global_mouse_position() + Vector2(10, -200) # немного сместим от курсора
		#card_view_instance.z_index = 100
		#card_view_instance.top_level = true
		card_view_instance.init(cardObject)

func _on_mouse_exited() -> void:
	await get_tree().create_timer(0.01).timeout  # Подождать один кадр
	if get_viewport().gui_get_hovered_control() == null:
		return
	if not get_viewport().gui_get_hovered_control().is_inside_tree() or not self.is_hovered():
		if card_view_instance:
			card_view_instance.queue_free()
			card_view_instance = null
