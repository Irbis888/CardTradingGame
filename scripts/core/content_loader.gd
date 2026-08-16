class_name ContentLoader
extends RefCounted


static func load_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error == OK:
		return json.get_data()

	print(
		"Ошибка парсинга JSON: ",
		json.get_error_message(),
		" в строке ",
		json.get_error_line()
	)
	return null

