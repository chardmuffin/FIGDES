extends Node

#init global var, not for saving
var time_mult = 1.0
#time_mult = 0.0 #allows for debugging by skipping all time dependant tasks if 0.0

#init global vars to be saved
var curr_state = "idle"
var version = [1,0,0] #stores values for version control
var file_name = "" #name of the save file
var prev_patch = "first" #name of the most recent patch
var curr_patch = "" #name of the patch currently being coded
var random_count = 0 #number of days since last random event
var days_count = 0 #number of days since starting game
var patch_elapsed_time = 0 #track time since current patch started coding
var energy = 10 # the current energy
var max_energy = 10 #max number of energy
var hunger = 4 #the current hunger level
var max_hunger = 10 #max value of hunger
var wisdom = 0 #the current wisdom level
var max_wisdom = 10 #max value of wisdom
var insanity = 1 #the current insanity level
var max_insanity = 10 #max value of insanity
var luck = 5 #the current amount of luck
var max_luck = 10 #max value of luck
var money = 5000.0 #money
var energy_timer #tracks time until energy replenish by 1
var hunger_timer #tracks time until hunger decrease by 1
var inside_timer #tracks time since last gone outside
var exercise_timer #tracks time since last exercise
var sleep_timer #tracks time since last sleep
var my_name = "MyPhone" #the developer's name
var prev_patches = ["first"] #if coded, the caseSensitive patchname will be added to the list
var curr_plans = [["setName",0],["writeReq",0],["shortcuts",0]] # for tracking the current planning progress of patches
var hasAutoSave = false
var showGUI = false
var food_count = 0
var isMusicPlaying = true
var current_music_file = "2"
var unlocked_music = ["1", "2"]
var musicDict = {
	"1":{
		"title": "Sinfonia #11 in g minor",
		"artist": "J.S. Bach",
		"file":"res://audio/bach-sinfonia-11-g-minor-loop.ogg"
	},
	"2":{
		"title": "Goldberg Variations: Var. 12, Inverted Canon on the 4th",
		"artist": "J.S. Bach",
		"file":"res://audio/bach-goldberg-variation-12.ogg"
	}
}
var notes : String = "" #this will contain notes that have already been typed (saved notes)

func save_game():
	#construct a dictionary containing global data to be saved
	var data = {
		"curr_state" : curr_state,
		"file_name" : file_name,
		"version" : version,
		"prev_patch" : prev_patch,
		"curr_patch" : curr_patch,
		"random_count" : random_count,
		"days_count" : days_count,
		"patch_elapsed_time" : patch_elapsed_time,
		"max_energy" : max_energy,
		"max_hunger" : max_hunger,
		"max_wisdom" : max_wisdom,
		"max_insanity" : max_insanity,
		"max_luck" : max_luck,
		"money" : money,
		"energy_timer" : energy_timer,
		"hunger_timer" : hunger_timer,
		"inside_timer" : inside_timer,
		"exercise_timer" : exercise_timer,
		"sleep_timer" : sleep_timer,
		"my_name" : my_name,
		"prev_patches" : prev_patches,
		"energy" : energy,
		"hunger" : hunger,
		"wisdom" : wisdom,
		"insanity" : insanity,
		"luck" : luck,
		"curr_plans" : curr_plans,
		"hasAutoSave": hasAutoSave,
		"showGUI":showGUI,
		"food_count":food_count,
		"isMusicPlaying":isMusicPlaying,
		"current_music_file": current_music_file,
		"unlocked_music":unlocked_music,
		"notes":notes
	}
	# Open a file
	var file = File.new()
	if file.open("user://saved_game.sav", File.WRITE) != 0:
		print("Error opening file")
		return

	# Save the dictionary as JSON
	file.store_line(to_json(data))
	file.close()

func load_game():
	# Check if there is a saved file
	var file = File.new()
	if not file.file_exists("user://saved_game.sav"):
		print("No file saved!")
		return

	# Open existing file
	if file.open("user://saved_game.sav", File.READ) != 0:
		print("Error opening file")
		return

	# Get the data
	var data = parse_json(file.get_line())
	file.close()
	
	#load the data
	curr_state = data["curr_state"]
	file_name = data["file_name"]
	version = data["version"]
	prev_patch = data["prev_patch"]
	curr_patch = data["curr_patch"]
	random_count = data["random_count"]
	days_count = data["days_count"]
	patch_elapsed_time = data["patch_elapsed_time"]
	max_energy = data["max_energy"]
	max_hunger = data["max_hunger"]
	max_wisdom = data["max_wisdom"]
	max_insanity = data["max_insanity"]
	max_luck = data["max_luck"]
	money = data["money"]
	energy_timer = data["energy_timer"]
	hunger_timer = data["hunger_timer"]
	inside_timer = data["inside_timer"]
	exercise_timer = data["exercise_timer"]
	sleep_timer = data["sleep_timer"]
	my_name = data["my_name"]
	energy = data["energy"]
	hunger = data["hunger"]
	wisdom = data["wisdom"]
	insanity = data["insanity"]
	luck = data["luck"]
	curr_plans = data["curr_plans"]
	hasAutoSave = data["hasAutoSave"]
	showGUI = data["showGUI"]
	food_count = data["food_count"]
	isMusicPlaying = data["isMusicPlaying"]
	current_music_file = data["current_music_file"]
	unlocked_music = data["unlocked_music"]
	notes = data["notes"]
	prev_patches = data["prev_patches"]

func canAfford(cost):
	if cost > money:
		return false
	return true

func dollar_format(amount):
	
	# Handle negative numbers by adding the "minus" sign in advance, as we discard it
	# when looping over the number.
	var formatted_number := "-" if sign(amount) == -1 else ""
	var index := 0
	var number_string := str(abs(amount))
	
	for digit in number_string:
		formatted_number += digit
		
		var counter := number_string.length() - index

		# Don't add a comma at the end of the number, but add a comma every 3 digits
		# (taking into account the number's length).
		if counter >= 2 and counter % 3 == 1:
			formatted_number += ","
			
		index += 1
	formatted_number = "$" + formatted_number
	return formatted_number

#----------------------------------GETTERS--------------------------------------

func get_versionString() -> String:
	return "[Version " + str(version[0]) + "." + str(version[1]) + "." + str(version[2]) + "]"

func get_money() -> String:
	return dollar_format(money)
