extends Control

var parser : DialogParser
var dialog_thing : DialogParser.DialogThing

func _ready():
	pass

func _on_topics_item_activated(index):
	$Audio.stream = null
	var choice = %Choices.get_item_metadata(index) as DialogParser.DialogThing
	if choice:
		populate_choices(choice)
		parser.activate(choice)
	pass

func _on_timer_timeout():
	if %Choices.item_count == 0:
		hide()

func _on_audio_finished():
	$Timer.timeout.emit()

func begin_dialog(_parser: DialogParser, page = "page1"):
	show()
	parser = _parser
	#
	#
	parser.activate(parser.get_node(page))
	parser.page = page
	populate_choices(parser.get_node(page))

func populate_choices(dt: DialogParser.DialogThing):
	dialog_thing = dt
	choices_clear()
	if dt:
		for c in dt.get_children():
			parser.evaluate(c)
			if c is DialogParser.DialogChoice && !parser.evaluate(c).has(false):
				choice_add(c)
		if dt.get_child_count() == 0:
			if dt.code.size() == 0:
				if $Audio.stream:
					await $Audio.finished
				else:
					await $Timer.timeout
				hide()

func message_say(text: String):
	#if !$Timer.is_stopped():
	#	await $Timer.timeout
	%Message.text = text
	$Timer.start(text.length() / 10)

func sound_play(sound, _volume = ):
	#if !$Timer.is_stopped():
	#	await $Timer.timeout
	$Audio.stream = load(sound)
	$Audio.volume_db = _volume
	$Audio.play()


func choice_add(dc: DialogParser.DialogChoice):
	var item = %Choices.add_item(parser.string_format( dc.text) )
	%Choices.set_item_metadata(item, dc)

func choices_clear():
	%Choices.clear()

func close():
	hide()
	choices_clear()
	parser = null
	dialog_thing = null
