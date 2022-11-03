extends Control

var t #holds terminal scene
var terminal
var m #holds music file
var backgroundMusic
var n #holds notepad scene
var notepad
var r #holds room scene
var room
var g #holds GUI scene
var gui

func _enter_tree():
	
	#init all Global variables
	Global.load_game()

func _exit_tree():
	
	if Global.hasAutoSave:
		Global.save_game()

func _ready():
	#init terminal
	t = load("res://Terminal/Terminal.tscn")
	terminal = t.instance()
	add_child(terminal)
	
	terminal.connect("reboot_terminal",self,"on_reboot_terminal")
	terminal.connect("move_terminal_to_top", self, "move_window_to_top")
	terminal.connect("open_plan", self, "on_open_notes")
	terminal.connect("play",self,"on_play")
	
	g = load("res://GUI.tscn")
	gui = g.instance()
	add_child(gui)
	gui.hide()
	
	if Global.prev_updates.has("GUI"):
		init_GUI()
	if Global.prev_updates.has("music"):
		init_music()

func on_reboot_terminal():

	#free the terminal
	if is_instance_valid(terminal):
		terminal.call_deferred("free")
	
	#if init music for the very first time
	if Global.prev_update == "music":
		init_music()
	
	#if init GUI for the very first time
	if Global.prev_update == "GUI":
		gui.show()
	
	#re-init terminal
	terminal = t.instance()
	add_child(terminal)
	terminal.connect("reboot_terminal",self,"on_reboot_terminal")
	terminal.connect("play",self,"on_play")
	terminal.connect("move_terminal_to_top", self, "move_window_to_top")
	terminal.connect("open_plan", self, "on_open_notes")
	
	#if init notes for the very first time
	if Global.prev_update == "writeReq":
		on_open_notes("first")

#if opening notes without planning, pass in key = null
func on_open_notes(key):
	#if notes not already opened
	if not is_instance_valid(notepad):
		n = load("res://Notepad/Notepad.tscn")
		notepad = n.instance()
		add_child(notepad)
		notepad.connect("move_notepad_to_top", self, "move_window_to_top")
	else:
		move_child(notepad, get_child_count() - 1)
	notepad.plan(key)

func init_GUI():
	if Global.showGUI:
		gui.show()
	else:
		gui.hide()

func init_music():
	if Global.isMusicPlaying:
		#load the current background music
		m = load(Global.musicDict.get(Global.current_music_file).file)
		m.set_loop(true)
		$Music.stream = m
		$Music.play()
	else:
		$Music.stop()

func move_window_to_top(node):
	move_child(node, get_child_count() - 1)

func on_play():
	#terminal.call_deferred("free")
	#if is_instance_valid(notepad):
	#	notepad.call_deferred("free")
	terminal._output("\n\nYour head starts to hurt. Maybe it's time to go do something else.\n\n(This feature is not yet supported.)")
	#r = load("res://Room/Room.tscn")
	#room = r.instance()
	#add_child(room)
	#room.connect("open_terminal", self, "on_reboot_terminal")
