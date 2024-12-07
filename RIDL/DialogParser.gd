class_name DialogParser
extends Node

var pages: Dictionary#[String, DialogPage] ## DialogThing
var page = "page1"
var message : String
var code = []

signal MessageSaid(message: String)
signal DialogBegan(parser: DialogParser, page: String)
signal Closed()
signal SoundPlayed(path: String)
signal ChoiceActivated(dialogChoice: DialogChoice)
signal ChoicePopulated(dialogChoice: DialogChoice)
signal ChoicesPopulated(dt: DialogThing)


func _init(_name = "DialogParser"):
	name = _name
	Game.add_child(self)

func parse(code: String):
	var lines = code.split("\n")
	var choices : Array[DialogChoice]
	var dialog_thing = self
	var dialog_page : DialogPage
	var depth = 0 # WARNING Unused???
	var index = 0
	for i in lines.size():
		var line = lines[i].strip_edges()
		var command = line.get_slice("#", 0).get_slice(" ", 0)
		var argument = line.get_slice("#", 0).get_slice("]", 1).strip_edges()
		argument = argument.strip_edges()
		var comment = line.get_slice("#", 1)
		#
		var is_command_valid = command.begins_with("[")
		var command_args = string_quoted(line, "[", "]").split(",") ## WARNING This causes errors in the Editor
		for n in command_args.size():
			command_args[n] = string_format(command_args[n])
		match command_args[0]:
			"page":
				depth = line.count("\t")
				var newPage = DialogPage.new()
				dialog_thing.add_child(newPage)
				dialog_thing = newPage
				newPage.name = command_args[1].strip_edges()
			"option", "choice", "select":
				depth = line.count("\t")
				var newChoice = DialogChoice.new()
				newChoice.text = string_format(argument)
				dialog_thing.add_child(newChoice)
				dialog_thing = newChoice
				if command_args.size() > 1:
					newChoice.name = command_args[0].strip_edges()
				else:
					newChoice.name = "choice_"+str(randi() % 1000).pad_zeros(4)
				
			"end":
				dialog_thing = dialog_thing.get_parent()
			##
			
			"condition", "if", "expression", "cond", "test":
				if dialog_thing is DialogChoice:
					dialog_thing.condition_expression = argument
			_:
				if dialog_thing is DialogThing:
					if command_args[0].begins_with("?"):
						dialog_thing.conditions.append(line.strip_edges())
					else:
						dialog_thing.code.append(line.strip_edges())
static func string_quoted(s, qA, qB):
	var start = false
	var result = ""
	for c in s:
		if c == qA:
			start = true
		elif c == qB:
			return result
		else:
			if start:
				result += c
	return s

static func string_quoted_array(s: String, qA, qB):
	var results = []
	var count = s.count(qA)
	for i in count:
		var quoted_text = string_quoted(s, qA, qB)
		s = s.replace(quoted_text, "")
		results.append(quoted_text)
		i += 1
	return results

func string_format(s: String):
	var result = s
	for var_name in Game.variables.keys():
		result = result.replace("$(" + var_name + ")", str(Game.variables[var_name]))
	return result

class DialogThing extends Node:
	var message : String = "" ## The text that will display
	var audio_stream: AudioStream ## The sound that will play
	var code = []
	var conditions = []

func evaluate(thing):
	var conditions = []
	for line in thing.conditions:
		var command = line.get_slice("#", 0).get_slice(" ", 0)
		var command_args = string_quoted(line, "[", "]").split(",") ## WARNING This causes errors in the Editor
		var argument = line.get_slice("#", 0).get_slice("]", 1).strip_edges()
		argument = argument.strip_edges()
		var comment = line.get_slice("#", 1)
		for n in command_args.size():
			command_args[n] = string_format(command_args[n])
		match command_args[0]:
			"?=":
				conditions.append(str_to_var(string_format(argument)) == str_to_var(string_format(command_args[1])))
			"?!":
				conditions.append(str_to_var(string_format(argument)) != str_to_var(string_format(command_args[1])))
			"?<":
				conditions.append(str_to_var(string_format(argument)) > str_to_var(string_format(command_args[1])))
			"?>":
				conditions.append(str_to_var(string_format(argument)) < str_to_var(string_format(command_args[1])))
	return conditions
func activate(thing: Node):
	#
	var last_variable_name = ""
	if thing is DialogThing:
		if thing.message != "":
			#DialogScreen.message_say(thing.message)
			MessageSaid.emit(thing.message)
		#
		for line in thing.code:
			var command = line.get_slice("#", 0).get_slice(" ", 0)
			var command_args = string_quoted(line, "[", "]").split(",") ## WARNING This causes errors in the Editor
			var argument = line.get_slice("#", 0).get_slice("]", 1).strip_edges()
			argument = argument.strip_edges()
			var comment = line.get_slice("#", 1)
			for n in command_args.size():
				command_args[n] = string_format(command_args[n])
			match command_args[0]:
				"message":
					DialogScreen.message_say(string_format(argument))
				"sound", "audio", "play":
					#SoundPlayed.emit(argument)
					DialogScreen.sound_play(argument, 0)
				"goto":
					#DialogBegan.emit(DialogScreen.parser, argument)
					DialogScreen.begin_dialog(DialogScreen.parser, (argument))
				"close":
					#DialogScreen.close()
					Closed.emit()
				"item_give": pass
				"item_take": pass
				"signal", "emit":
					Game.CustomSignal.emit(command_args)
				"boo": 
					if !argument in Game.variables:
						Game.variables[argument] = false
					last_variable_name = argument
				"num": 
					if !argument in Game.variables:
						Game.variables[argument] = 0
					last_variable_name = argument
				"str":
					if !argument in Game.variables:
						Game.variables[argument] = ""
					last_variable_name = argument
				"value", "assign", "$=":
					if last_variable_name in Game.variables:
						if Game.variables[last_variable_name] in [null, 0, "", false]:
							Game.variables[last_variable_name] = str_to_var(argument)
				"=", "":
					if Game.variables[last_variable_name] is String:
						Game.variables[last_variable_name] = string_format(argument)
					else:
						Game.variables[last_variable_name] = str_to_var(string_format(argument))
				"+": Game.variables[argument] += str_to_var(string_format(command_args[1]))
				"*": Game.variables[argument] *= str_to_var(string_format(command_args[1]))
				"/": Game.variables[argument] /= str_to_var(string_format(command_args[1]))
				"-": Game.variables[argument] -= str_to_var(string_format(command_args[1]))
				"^": Game.variables[argument] ^= str_to_var(string_format(command_args[1]))
				"**": Game.variables[argument] **= str_to_var(string_format(command_args[1]))
				"++": Game.variables[argument] += 1
				"--": Game.variables[argument] -= 1


class DialogPage extends DialogThing:
	pass

class DialogChoice extends DialogThing:
	var text : String = "Choice" ## The button's text for this option
	var condition_expression : String ## The condition under which this item will show up
	
