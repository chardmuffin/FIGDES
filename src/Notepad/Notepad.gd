extends Control

## Typewriter effect ##
var wait_time : float = 0.04 # Time interval (in seconds) for the typewriter effect.
var pause_time : float = 2.0 # Duration of each pause when the typewriter effect is active.
var pause_char : String = '|' # The character used in the JSON file to define where pauses should be. If you change this you'll need to edit all your dialogue files.
var newline_char : String = '@' # The character used in the JSON file to break lines. If you change this you'll need to edit all your dialogue files.
var drag_position = null #used for moving the window around
signal move_notepad_to_top

# The label where the text will be displayed.
onready var label : Node = $VBoxContainer/ScrollContainer/VBoxContainer/Text
onready var timer : Node = $Timer # Timer node.

var notes = {} #contains entire Notes.json

func _ready():
# warning-ignore:return_value_discarded
	timer.connect("timeout", self, "_on_Timer_timeout")
	pass

func _read_notes():
	var data_file = File.new()
	if data_file.open("res://data/Notes.json", File.READ) != OK:
		return "Error while reading from Notes.json file"
		
	var data_text = data_file.get_as_text()
	data_file.close()
	
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return "Error while parsing Notes.json file"

	notes = data_parse.result

func _on_drag(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_position = get_global_mouse_position() - rect_global_position
			emit_signal("move_notepad_to_top", self)
		else:
			drag_position = null
	if event is InputEventScreenDrag and drag_position:
		rect_global_position = get_global_mouse_position() - drag_position

#bring to front
func _on_ScrollContainer_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			emit_signal("move_notepad_to_top", self)

#bring to front
func _on_TextEdit_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			emit_signal("move_notepad_to_top", self)

#bring to front
func _on_VBoxContainer_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			emit_signal("move_notepad_to_top", self)

#close
func _on_ExitButton_pressed():
	call_deferred("free")

#scroll to bottom
func _on_ScrollContainer_sort_children():
	var bar = $VBoxContainer/ScrollContainer.get_v_scrollbar()
	if bar.value + bar.page >= bar.max_value:
		call_deferred("_scroll_later")

#scroll helper
func _scroll_later():
	var bar = $VBoxContainer/ScrollContainer.get_v_scrollbar()
	bar.value = bar.max_value

#write notes!
func plan(key):
	#key is in Global.curr_plans, the format is:
	#curr_plans = [["key",0],["key",2],["key",3]]
	#where key is keyName, and the int is the number of the plan to be written to notepad
	label.bbcode_text = ""
	_type_old_notes()
	call_deferred("scroll_later")
	
	#if null key is passed in, we want to open saved notes without writing new plans
	if key == null:
		return
	
	_read_notes()
	
	var plan_number
	#get the plan number from the Global.curr_plans array
	for plan in Global.curr_plans:
		if plan[0] == key:
			plan_number = str(plan[1])
		else:
			plan_number = "1"
	
	label.append_bbcode("\n\n")
	
	_type_new_notes(notes.get(key).get(plan_number))
	Global.notes += "@@" + notes.get(key).get(plan_number)

# types old notes without typewriter effect
func _type_old_notes():
	for c in Global.notes:
		if c == newline_char:
			label.append_bbcode("\n")
		elif c == pause_char:
			pass
		else:
			label.append_bbcode(c)

# uses typewriter effect to type out text
func _type_new_notes(text):
	for c in text:
		if c == newline_char:
			timer.wait_time = wait_time
			timer.start()
			label.append_bbcode("\n")
		elif c == pause_char:
			timer.wait_time = pause_time * wait_time * 10
			timer.start()
		else:
			timer.wait_time = wait_time
			timer.start()
			label.append_bbcode(c)
		yield(timer, "timeout")

func _on_Timer_timeout():
	pass
