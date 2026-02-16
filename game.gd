extends Node2D
## Godot Matrix RTC - Example Game Script
##
## Script to demonstrate using the Godot Matrix RTC signals
##
## @tutorial(GitHub): https://github.com/cyclikal94/godot-matrix-rtc
## @tutorial(Readme): https://github.com/cyclikal94/godot-matrix-rtc/blob/main/README.md

## Global variable for all members in the MatrixRTC session
var all_members: Array = []
## Variable to track if player has ever joined in this instance of the game running
## Used to differentiate first join / leaving logic
var previously_joined: bool = false

## GodotMatrixRTC node in scene with unique name of `GodotMatrixRTC`
@onready var godot_matrix_rtc: GodotMatrixRTC = %GodotMatrixRTC


## Connect to `GodotMatrixRTC` Node signals to handle RTC updates
func _ready() -> void:
	godot_matrix_rtc.connect("data_change", on_data_update)
	godot_matrix_rtc.connect("member_change", on_rtc_member_update)
	godot_matrix_rtc.connect("local_member_change", on_local_rtc_member_update)
	godot_matrix_rtc.connect("connected_changed", on_connected_changed)
	
	await godot_matrix_rtc.ready
	godot_matrix_rtc.start_emitters()
	
	set_process_input(true)


## Do something with other members' data
## i.e. Use this to update other members' character position
func on_data_update(member_id: String, data: Dictionary) -> void:
	godot_matrix_rtc.console.log("GODOT ", "Member ID: ", str(member_id), "Data: ", str(data))


## Update `all_members` when new members join
## i.e. Ensure all members are given characters in-game
func on_rtc_member_update(members: Array) -> void:
	all_members = members
	godot_matrix_rtc.console.log("GODOT ", str(all_members))


## Update local member after join
## i.e. Use this to set player icons' name / id
func on_local_rtc_member_update(member: Dictionary) -> void:
	godot_matrix_rtc.console.log("GODOT ", member.id, member.name)
	on_rtc_member_update(all_members)


## Update local members' data
## i.e. Use this to update local members' character position
func on_own_data_update(data: Dictionary) -> void:
	godot_matrix_rtc.update_own_data(data)


## Send message into Matrix chat
## i.e. Following a level complete, send members' score / completion time
func send_text_message(message: String) -> void:
	godot_matrix_rtc.send_text_message(message)


## Do something when the local members' connection status changes
## i.e. Send a message into the room indicating ready to play a game
func on_connected_changed(connected: bool) -> void:
	if not connected and previously_joined:
		# Do something when local member is not connected
		# i.e. Show game over screen / play stats
		send_text_message("I am leaving the game.")
	elif not connected:
		# Do something when local member opens the widget
		# i.e. Indicate member is intending to play
		send_text_message("I have opened the game, but not joined.")
	else:
		# Do something when local member is connected
		# i.e. Hide start screen and show lobby / game map
		previously_joined = true
		send_text_message("I am joining the game.")
