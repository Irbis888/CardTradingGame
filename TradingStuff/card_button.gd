extends TextureButton

@onready var name_label = $NameLabel
@onready var price_label = $PriceLabel
@onready var cb = $CheckButton
@onready var tex = $TextureRect


var cardObject: Card
var chosen: bool = false
var parent

func init(card: Card, parent) -> void:
	var coeffs = Vector3i(5, 3, 7)
	self.parent = parent
	
	self.cardObject = card
	name_label.text = cardObject.name
	price_label.text = "$" + str(cardObject.base_price)
	tex.texture = card.picture
		
func _on_check_button_toggled(toggled_on: bool) -> void:
	self.chosen = toggled_on
	self.parent.summary_label.text = self.parent.gen_summary()
	
