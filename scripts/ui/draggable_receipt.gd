class_name DraggableReceipt
extends "res://scripts/ui/drag_drop/dual_space_draggable.gd"


@onready var desk_type_label: Label = $DeskView/TypeLabel
@onready var desk_watermark_label: Label = $DeskView/WatermarkLabel
@onready var desk_amount_label: Label = $DeskView/AmountLabel
@onready var counter_type_label: Label = $CounterView/TypeLabel
@onready var counter_amount_label: Label = $CounterView/AmountLabel

var receipt_type: StringName = &"ASK"
var amount := 0


func _ready() -> void:
	super()
	_refresh_receipt()


func setup_receipt(type: StringName, value: int) -> void:
	receipt_type = StringName(str(type).to_upper())
	amount = maxi(value, 0)
	set_item_payload({
		"type": receipt_type,
		"amount": amount,
	})
	if is_node_ready():
		_refresh_receipt()


func get_receipt_type() -> StringName:
	return receipt_type


func get_amount() -> int:
	return amount


func _refresh_receipt() -> void:
	var type_text := str(receipt_type)
	var amount_text := "$%d" % amount
	desk_type_label.text = type_text
	desk_watermark_label.text = type_text
	desk_amount_label.text = amount_text
	counter_type_label.text = type_text
	counter_amount_label.text = amount_text
