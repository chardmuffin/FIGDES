extends Control

#vars
var drag_position = null #used for moving the terminal window around
var terminal_prompt_size #used for placing the caret
var character_width = 0 #used for placing the caret
var current_input_length = 0 #used for placing the caret
var updatesDict = {} #entire JSON of all updates will be loaded here
var commandsDict = {} #entire JSON of all commands will be loaded here
var available_updates = [] # list of updates available for coding
var output = "" # used for temporarily storing the terminal output
var available_commands = [] # array of all currently available commands
signal reboot_terminal
signal coding_complete
signal move_terminal_to_top
signal open_plan
signal play

#initialize cursor caret and things
func _ready():
	
	#read updates file into updatesDict and commands file into commandsDict
	_read_updates()
	_read_commands()
	_set_visible_updates()
	_set_visible_commands()
	
	#init promptline text
	_set_terminal_prompt_text()
	
	#init signal connection
	# warning-ignore:return_value_discarded
	connect("coding_complete",self,"_on_coding_complete")
	
	#init Output message
	$VBoxContainer/ScrollContainer/VBoxContainer/Output.text = "\nFully Immersive Game Developer Experience Simulator 2022 " + Global.get_versionString() + "\n(c) 2022 Corporate Corporation, Inc. All Rights Reserved.\n\n"
		
	#auto type "help on first time playing"
	var init_input = ""
	if Global.prev_updates.size() == 1:
		init_input = "help"
	elif Global.prev_updates.has("shortcuts"):
		init_input = "r"
	else:
		init_input = "readme"
	
	yield(get_tree().create_timer(1.0 * Global.time_mult), "timeout")
	for c in init_input:
		yield(get_tree().create_timer(.25 * Global.time_mult), "timeout")
		$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalLineInput.text += c
		current_input_length += 1
		_moveCaret()
	yield(get_tree().create_timer(1.5 * Global.time_mult), "timeout")
	_on_TerminalLineInput_text_entered(init_input)

	#focus on LineEdit
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalLineInput.grab_focus()

#initialize the caret position
func _on_TerminalPrompt_resized():
	terminal_prompt_size = $VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalPrompt.get_rect().size
	character_width = terminal_prompt_size[0] / $VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalPrompt.text.length()
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/Caret.offset.x = terminal_prompt_size[0]
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/Caret.offset.y = terminal_prompt_size[1]

#allow dragndrop window by the header and bring terminal to top
func _on_HeaderBar_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_position = get_global_mouse_position() - rect_global_position
			emit_signal("move_terminal_to_top", self)
		else:
			drag_position = null
	if event is InputEventScreenDrag and drag_position:
		rect_global_position = get_global_mouse_position() - drag_position

#bring terminal to top
func _on_VBoxContainer_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			emit_signal("move_terminal_to_top", self)

#bring terminal to top
func _on_ScrollContainer_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			emit_signal("move_terminal_to_top", self)

#bring terminal to top
func _on_TerminalLineInput_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			emit_signal("move_terminal_to_top", self)

#displays the user input and calls the process function on said input
func _on_TerminalLineInput_text_entered(new_text):
	current_input_length = 0
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalLineInput.text = ''
	call_deferred("_scroll_later")
	$VBoxContainer/ScrollContainer/VBoxContainer/Output.text += "\n" + $VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalPrompt.text + new_text
	#print(new_text)
	_process_input(new_text)
	_moveCaret()

#move caret as you type
func _on_TerminalLineInput_text_changed(new_text):
	current_input_length = new_text.length()
	_moveCaret()

#always autoscroll to bottom
func _on_ScrollContainer_sort_children():
	var bar = $VBoxContainer/ScrollContainer.get_v_scrollbar()
	if bar.value + bar.page >= bar.max_value:
		call_deferred("_scroll_later")

#helper function for scrolling
func _scroll_later():
	var bar = $VBoxContainer/ScrollContainer.get_v_scrollbar()
	bar.value = bar.max_value

#keep caret at end of input
#if caret becomes hidden at bottom of terminal, increat Y margin of HBoxContainer
func _moveCaret():
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/Caret.offset.x = terminal_prompt_size[0] + current_input_length * character_width

#hide the caret when not about to type
func _on_TerminalLineInput_focus_exited():
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/Caret.hide()

#show the caret when typing
func _on_TerminalLineInput_focus_entered():
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/Caret.show()

#exits the game when the X button pressed
func _on_ExitButton_pressed():
	get_tree().quit()

#reads the updates JSON and stores in the updatesDict
func _read_updates():
	var data_file = File.new()
	if data_file.open("res://data/Updates.json", File.READ) != OK:
		return "Error while reading from Updates.json file"
		
	var data_text = data_file.get_as_text()
	data_file.close()
	
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return "Error while parsing Updates.json file"

	updatesDict = data_parse.result

#reads the commands JSON and stores in the commandsDict
func _read_commands():
	
	var data_file = File.new()
	if data_file.open("res://data/Commands.json", File.READ) != OK:
		return "Error while reading from Commands.json file"
		
	var data_text = data_file.get_as_text()
	data_file.close()
	
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return "Error while parsing Commands.json file"

	commandsDict = data_parse.result

#function to calculate which updates are available
func _set_visible_updates():
	
	var isAvailable
	
	#for each update where key is updatename as String
	for key in updatesDict.keys():
		
		#reset available checker
		isAvailable = true
		
		#this if statement is to see if the update is already coded
		if Global.prev_updates.has(key):
			pass
		else:
			#ok, so the update isn't coded yet. are the prereqs met?
			for prereq in updatesDict.get(key).pre_reqs:
				
				#if the prereq was found in the updateList, do nothing
				if Global.prev_updates.has(prereq):
					pass
				else:
					isAvailable = false #missing a prereq! then update aint available
			if isAvailable:
				#add the key to the availableUpdates array
				available_updates.append(key)

#calculates which commands should be available, based on updates already coded
func _set_visible_commands():
	for update in Global.prev_updates:
		for commandString in updatesDict.get(update).commands:
			available_commands.append(commandString)
	available_commands.sort()

#returns the amount of planning remaining, returns -1 if not started
func _curr_planning(update) -> int:

	if Global.curr_plans.size() == 0:
		return 0
	
	for updates in Global.curr_plans:
		if updates[0] == update:
			return updates[1]
	return 0
	
#add text to the output label
func _output(text):
	$VBoxContainer/ScrollContainer/VBoxContainer/Output.text += text

#function assumes all coding pre_reqs and conditions are met, begins coding the update
#arg updatename is the key in updatesDict
func _begin_coding(updatename):
	Global.curr_update = updatename
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalPrompt.hide()
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalLineInput.hide()
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/Caret.hide()
	
	#store the output
	output = $VBoxContainer/ScrollContainer/VBoxContainer/Output.text + "\nTime until completion: "
	
	Global.curr_state = "coding"
	
#called from _process(delta) when Global.update_elapsed_time == update.time_req
func _on_coding_complete(updatename):
	Global.curr_state = "idle"
	Global.curr_update = ""
	Global.update_elapsed_time = 0.0
	Global.prev_updates.append(updatename)
	Global.prev_update = updatename
	
	if updatesDict.get(updatename).type == "basic":
		Global.version[1] += 1
	elif updatesDict.get(updatename).type == "complex":
		Global.version[0] += 1
	elif updatesDict.get(updatename).type == "bug":
		Global.version[2] += 1
	
	_output("\n\nSuccess!")
	yield(get_tree().create_timer(1 * Global.time_mult), "timeout")
	_output("\nRebooting")
	_output(".")
	yield(get_tree().create_timer(1 * Global.time_mult), "timeout")
	_output(".")
	yield(get_tree().create_timer(1 * Global.time_mult), "timeout")
	_output(".")
	yield(get_tree().create_timer(1 * Global.time_mult), "timeout")
	
	#reboot!
	emit_signal("reboot_terminal")

#input is formatted as an array containing each keyword
#the command's respective function is called
func _process_input(input):
	
	#for debugging
	print("terminal input was: " + input)
	
	#cleans up input, put command and args into array called inputs
	#inputs[0] is the command, inputs[1,2,3...] are the args
	var inputs = Array(input.split(" "))
	while inputs.has(""):
		inputs.erase("")
	
	if inputs.size() == 0:
		return
	
	if available_commands.has(inputs[0].to_upper()):
		call("_" + inputs[0].to_lower(), inputs)
	
	elif input.strip_edges() == "":
		pass
	else:
		_output("\n\'" + input + "\' is not a recognized command. For a list of executable commands, type HELP\n")

#if command requires args and user didn't enter, let them know usage
#returns false if not enough args
func _validate_args(inputs) -> bool:
	
	#not enough args, let user know how to use the command
	if inputs.size() == 1:
		_output("\nThe syntax of the command is incorrect.")
		_output("\n\nUsage:              " + commandsDict.get(inputs[0].to_upper()).usage + "\n")
		return false
	return true

#sets the promptline text
func _set_terminal_prompt_text():
	$VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/TerminalPrompt.text = "C:\\" + Global.my_name + "\\Files\\FIGDES2022>"

#returns key if update is available or if subupdates are already coded
func _plan_code_subupdate_helper(inputs):
	
	var key = ""
	
	#not enough args, let user know how to use the command
	if _validate_args(inputs) == false:
		return
	
	#get available updates in lowercase format
	#both arrays are in the same order so I can get the caseSensitive key
	var aUpdatesLowercase = []
	for update in available_updates:
		aUpdatesLowercase.append(update.to_lower())
	
	#if the update is available
	if aUpdatesLowercase.has(inputs[1].to_lower()):
		#set key to the case sensitive updatename string by matching index w/ lowercase array
		key = available_updates[aUpdatesLowercase.find(inputs[1].to_lower())]
	else:
		#unrecognized update-name
		_output("\n\nError: [" + inputs[1] + "] is not recognized as a currently available update.\n")
		return
	
	#if has sub-updates...
	if updatesDict.get(key).type == "complex":
		var i = false
		var remainingChildList = []
		for child in updatesDict.get(key).children:
			if not Global.prev_updates.has(child):
				i = true
				remainingChildList.append(child)
		#...you must code all sub updates first!
		if i:
			_output("\n\nThe following sub-updates must be coded prior to coding or planning this update:\n")
			for update in remainingChildList:
				_output("\n" + update)
			_output("\n")
			return
	return key

#this is the while(true)
func _process(delta):
	if Global.curr_state == "coding":
		Global.update_elapsed_time += delta * Global.time_mult
		
		# display some major mAtRiX hAcKiNg on the screen by applying the ratio of update_elapsed_time/time_req
		# to the "code" length to get the number of chars of the full string of "code" to display at any given time
		var fragmentLength = int(Global.update_elapsed_time / updatesDict.get(Global.curr_update).time_req * updatesDict.get(Global.curr_update).code.length())
		$VBoxContainer/ScrollContainer/VBoxContainer/Output.text = output + str(stepify(updatesDict.get(Global.curr_update).time_req - Global.update_elapsed_time, 0.01)) + "\n\n" + updatesDict.get(Global.curr_update).code.substr(0, fragmentLength)
		if Global.update_elapsed_time >= updatesDict.get(Global.curr_update).time_req:
			$VBoxContainer/ScrollContainer/VBoxContainer/Output.text = output + "0.00\n" + updatesDict.get(Global.curr_update).code
			emit_signal("coding_complete", Global.curr_update)



################################################################################
#############################COMMAND FUNCTIONS##################################
################################################################################

func _help(inputs):
	
	#if calling the general help
	if inputs.size() == 1:
		#disclaimer
		_output("\nFor more information on a specific command, type HELP [command-name]\n")
	
		#for each command where key is commandName as String
		for key in available_commands:
		
			var numSpaces = 20 - key.length()
			var spaces = ""
			for _i in range(numSpaces):
				spaces += " "
			_output("\n" + key + spaces + commandsDict.get(key).desc)
		_output("\n")
		
	else:
		
		#set numSpaces
		var numSpaces = 20 - inputs[1].length()
		var spaces = ""
		for _i in range(numSpaces):
				spaces += " "
		
		#display help for inputs[1] if command
		if available_commands.has(inputs[1].to_upper()):
			_output("\n" + inputs[1].to_upper() + spaces + commandsDict.get(inputs[1].to_upper()).desc)
			_output("\n\nUsage:              " + commandsDict.get(inputs[1].to_upper()).usage + "\n")
			return
		
		var aUpdatesLowercase = []
		for update in available_updates:
			aUpdatesLowercase.append(update.to_lower())
	
		#display help for inputs[1] if update
		if aUpdatesLowercase.has(inputs[1].to_lower()):
			var key = ""
			#set key to the caseSensitive updatename string by matching index w/ lowercase array
			key = available_updates[aUpdatesLowercase.find(inputs[1].to_lower())]
			
			_output("\n" + key + spaces + updatesDict.get(key).desc)
			_output("\n\nType:               " + updatesDict.get(key).type.capitalize())
			
			#display energy required if stats update is coded
			if Global.prev_updates.has("addStats"):
				_output("\nEnergy Required:    " + str(updatesDict.get(key).res_req))
			_output("\nTime Required:      " + str(updatesDict.get(key).time_req))
			
			#display planning required if writereq update is coded
			if Global.prev_updates.has("writeReq"):
				_output("\nPlanning Required:  " + str(updatesDict.get(key).plan_req))
			
			#display subupdates required if type is Complex
			if updatesDict.get(key).type == "complex":
				_output("\nSub-updates Required: " + str(updatesDict.get(key).children).rstrip("]").lstrip("["))
			_output("\n")
			return
				
		"""else"""
		#you typed a non-existant command or update, silly
		_output("\n\n[" + inputs[1] + "] is not recognized as a valid command or update name.\n")

func _code(inputs):
	
	"""
	the criteria to begin coding a update:
	1. must be available (all pre_req updates already coded)
	2. must have enough energy to complete (energy must be greater than or equal to res_req)
	3. must have completed planning
	4. if there are sub-updates, must code them first
	"""
	
	var key = _plan_code_subupdate_helper(inputs)
	if key == null:
		return
	
	#if made it past helpr function, then update is available and subupdates coded
	
	#if all necessary planning is complete
	if _curr_planning(key) >= updatesDict.get(key).plan_req:
		
		#...and if player has enough energy
		if updatesDict.get(key).res_req <= Global.energy:
			
			#then all code conditions are met, allowed to begin coding!
			_begin_coding(key)
			
		else:
			#not enough energy
			_output("\n\nThis task requires more energy.\nYour energy:        " + str(Global.energy))
			_output("\nRequired energy:    " + str(updatesDict.get(key).res_req) + "\n")
	else:
		#needs more planning
		_output("\n\nPlanning is insufficient!")
		_output("\nTotal planning required:    " + str(updatesDict.get(key).plan_req))
		_output("\nCurrent planning:           " + str(_curr_planning(key)) + "\n")
		
func _updates(_inputs):
	
	#disclaimers
	_output("\nUpdates are used with the CODE command in the format CODE [update-name]")
	_output("\nFor more information on a specific update, type HELP [update-name]\n")
	
	#for each available update where key is updatename as String
	var parentkey
	var numSpaces
	var spaces
	_output("\n")
	for key in available_updates:
		
		numSpaces = 20 - key.length()
		
		if updatesDict.get(key).type == "complex":
			parentkey = key
		if not parentkey == null:
			if updatesDict.get(parentkey).children.has(key):
				numSpaces = 18 - key.length()
				_output("  ")
			
		spaces = ""
		for _i in range(numSpaces):
			spaces += " "
		
		_output(key + spaces + updatesDict.get(key).desc + "\n")
	_output("\n")
	
func _readme(_inputs):
	
	_output("\nFully Immersive Game Developer Experience Simulator 2022\n")
	_output("\nRelease Notes " + Global.get_versionString())
	for line in updatesDict.get(Global.prev_update).release_notes:
		_output("\n - " + line)
	_output("\n")
	
func _plan(inputs):
	
	#key = the name of the update to be planned
	var key = _plan_code_subupdate_helper(inputs)
	if key == null:
		return
	
	# if planning is already complete
	if updatesDict.get(key).plan_req == _curr_planning(key):
		_output("\n\nPlanning for this update is already completed!\n")
		return
	
	# if player has enough energy
	if Global.energy >= 1:
		# plan away my friend!
		
		# has planning already started on this item?
		for plan in Global.curr_plans:
			# if yes then ++ the plan number for that update and subtract an energy
			if plan[0] == key:
				
				emit_signal("open_plan", key)
				
				plan[1] += 1
				Global.energy += -1
				_output("\n\nTotal planning required:    " + str(updatesDict.get(key).plan_req))
				_output("\nCurrent planning:           " + str(_curr_planning(key)) + "\n")
				return
		
		#else, initiate the plan!
		emit_signal("open_plan", key)
		Global.curr_plans.append([key, 1])
		Global.energy += -1
		
		_output("\n\nTotal planning required:    " + str(updatesDict.get(key).plan_req))
		_output("\nCurrent planning:           " + str(_curr_planning(key)) + "\n")
	else:
		#not enough energy, although this should be impossible
		_output("\n\nThis task requires more energy.\nYour energy:        " + str(Global.energy))
		_output("\nRequired energy:    1\n")

func _h(inputs):
	_help(inputs)

func _c(inputs):
	_code(inputs)

func _s(inputs):
	_save(inputs)

func _r(inputs):
	_readme(inputs)

func _p(inputs):
	_plan(inputs)

func _save(_inputs):
	Global.save_game()
	_output("\nGame Saved!")

func _setname(inputs):
	
	if _validate_args(inputs) == false:
		return
	
	_output("\n\n")
	if inputs.size() > 2:
		_output("Spaces are not allowed!\n")
	
	Global.my_name = inputs[1]
	_output("Developer name set to \"" + Global.my_name + "\"\n")
	_set_terminal_prompt_text()

func _getstats(_inputs):
	_output("\n\nEnergy:             " + str(Global.energy))
	_output("\nEnergy Timer:       " + str(Global.energy_timer))
	_output("\nHunger:             " + str(Global.hunger))
	_output("\nHunger Timer:       " + str(Global.hunger_timer))
	_output("\nInsanity:           " + str(Global.insanity))
	_output("\nLuck:               " + str(Global.luck))
	_output("\nMoney:              " + Global.get_money())
	_output("\nWisdom:             " + str(Global.wisdom) + "\n")

func _togglegui(_inputs):
	Global.showGUI = not Global.showGUI
	get_tree().get_root().get_node("Main").init_GUI()

func _getenergy(_inputs):
	_output("\n\nEnergy:             " + str(Global.energy))
	_output("\nEnergy Timer:       " + str(Global.energy_timer) + "\n")

func _getluck(_inputs):
	_output("\n\nLuck:               " + str(Global.luck) + "\n")

func _gethunger(_inputs):
	_output("\n\nHunger:             " + str(Global.hunger))
	_output("\nHunger Timer:       " + str(Global.hunger_timer) + "\n")

func _getwisdom(_inputs):
	_output("\n\nWisdom:             " + str(Global.wisdom) + "\n")

func _getmoney(_inputs):
	_output("\n\nMoney:              " + str(Global.get_money()) + "\n")

func _getinsanity(_inputs):
	_output("\n\nInsanity:           " + str(Global.insanity) + "\n")

func _togglemusic(_inputs):
	if Global.isMusicPlaying:
		Global.isMusicPlaying = false
	else:
		Global.isMusicPlaying = true
	get_tree().get_root().get_node("Main").init_music()

func _getmusic(_inputs):
	_output("\nCurrent Track: " + Global.musicDict.get(Global.current_music_file).title + " by " + Global.musicDict.get(Global.current_music_file).artist)
	_output("\n\nTrack No.   Artist        Title")
	var spaces
	for key in Global.musicDict:
		spaces = ""
		if Global.unlocked_music.has(key):
			for _c in range(14 - Global.musicDict.get(key).artist.length()):
				spaces += " "
			_output("\n" + key + "           " + Global.musicDict.get(key).artist + spaces + Global.musicDict.get(key).title)
		else:
			_output("\n" + key + "           ???           ???")
	_output("\n")

func _setmusic(inputs):
	
	if _validate_args(inputs) == false:
		return
	
	if Global.unlocked_music.has(inputs[1]):
		call_deferred("free", get_tree().get_root().get_node("Main").m)
		Global.current_music_file = inputs[1]
		get_tree().get_root().get_node("Main").init_music()
	else:
		_output("\nInvalid track number!\n")
		_getmusic(inputs)
		
#TODO remove magic number 3 and replace with food filling amount
func _eat(_inputs):
	if Global.food_count <= 0:
		#you don't have any food!
		_output("\n\nYou are out of food!\n")
	else:
		_output("\n\nHunger:             " + Global.hunger)
		_output("\n\nEating...")
		Global.food_count -= 1
		Global.hunger -= 3
		Global.hunger_timer = 0
		
		yield(get_tree().create_timer(2.0 * Global.time_mult), "timeout")
		
		_output("\n\nDelicious!\nHunger:             " + Global.hunger + "\n")

#TODO allow food variety (changes local var food_cost)
func _buyfood(inputs):
	
	if _validate_args(inputs) == false:
		return
	
	var food_cost = 20
	var cost = inputs[1] * food_cost
	
	if Global.canAfford(cost):
		Global.food_count += inputs[1]
		Global.money -= cost
	else:
		#you can't afford that!
		_output("\n\nInsufficient funds!")
		_output("\nYou have:           " + Global.get_money())
		
		var costString = "Cost @ " + Global.dollar_format(food_cost) + " per food:"
		
		var numSpaces = 20 - costString.length()
		if numSpaces <= 1:
			numSpaces = 4
		var spaces = ""
		for _i in range(numSpaces):
			spaces += " "
		
		_output("\n" + costString + spaces + Global.dollar_format(cost) + "\n")

func _play(_inputs):
	emit_signal("play")
