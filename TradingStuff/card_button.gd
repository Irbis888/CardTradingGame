extends TextureButton

@onready var name_label = $NameLabel
@onready var price_label = $PriceLabel
@onready var cb = $CheckButton


var cardObject: Card
var chosen: bool = false

func init(card: Card) -> void:
	self.cardObject = card
	name_label.text = cardObject.name
	price_label.text = "$" + str(cardObject.get_price())
	
func _on_check_button_toggled(toggled_on: bool) -> void:
	self.chosen = toggled_on
