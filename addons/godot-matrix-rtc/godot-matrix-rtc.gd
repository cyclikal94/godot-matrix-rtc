@icon("res://addons/godot-matrix-rtc/assets/matrix.svg")
class_name GodotMatrixRTC
extends Node
## Godot Matrix RTC
##
## A Godot Plugin which can be used to interact with MatrixRTC.
## Sample project includes working `export_presets.cfg` and UI for Joining / Leaving.
## Project / `main.tscn` configured to resize / display nicely in Vertical or Horizontal.
##
## @tutorial(GitHub): https://github.com/cyclikal94/godot-matrix-rtc
## @tutorial(Readme): https://github.com/cyclikal94/godot-matrix-rtc/blob/main/README.md

## Signal to recieve updates to user data.
signal data_change(member_id: String, data: Dictionary)
## Signal to recieve updates when members join and leave.
signal member_change(members: Array)
## Signal to recieve updates to the local member.
signal local_member_change(member: Dictionary)
## Signal to recieve updates local members' connection status.
signal connected_changed(connected: bool)

## Callback reference for `matrixRTCSdk.data$`
var _data_callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(_data_callback)
## Callback reference for `matrixRTCSdk.members$;`
var _members_callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(_members_callback)
## Callback reference for `matrixRTCSdk.localMember$`
var _local_member_callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(_local_member_callback)
## Callback reference for `matrixRTCSdk.connected$`
var _connected_callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(_connected_callback)
## `console` interface from JavaScriptBridge to log to the browser console
var console: JavaScriptObject
## `window.matrixRTCSdk` interface from JavaScriptBridge to interact with the SDK
var sdk: JavaScriptObject

## Button node in scene with unique name of `Join`.
@onready var join: Button = %Join
## Button node in scene with unique name of `Leave`.
@onready var leave: Button = %Leave
## Label node in scene with unique name of `Status`.
@onready var status: Label = %Status


## Ready function to setup `var console` and `var sdk`
## Connects `Join` and `Leave` Button nodes `pressed` signal to respective functions.
func _ready() -> void:
	console = JavaScriptBridge.get_interface("console")
	console.log("GODOT ready")

	sdk = JavaScriptBridge.get_interface("window").matrixRTCSdk
	join.connect("pressed", _on_join_pressed)
	leave.connect("pressed", _on_leave_pressed)


## Callback function to handle updates to member data
func _data_callback(args: Array) -> void:
	var data_rtc_obj: Dictionary = args[0]
	var data: Dictionary = data_rtc_obj.data
	var id: String = data_rtc_obj.rtcBackendIdentity
	console.log("GODOT _data_callback", data_rtc_obj)
	console.log("GODOT on data:", JSON.stringify(data_rtc_obj))
	data_change.emit(id, data)


## Callback funtion to handle updates to members (joins / leaves)
func _members_callback(args: Array) -> void:
	var members_rtc: Dictionary = args[0]
	var members: Array = []
	for i in range(members_rtc.length):
		var member_rtc: Dictionary = members_rtc[i]
		console.log("GODOT _members_callback index: ",i,"member: ", member_rtc, "userId: ",member_rtc.membership.userId, "memberId: ", member_rtc.membership.memberId)
		var m : Dictionary[String, String] = {"id":member_rtc.membership.memberId,"name": member_rtc.membership.userId}
		members.push_back(m)
	console.log("GODOT _members_callback final list: ", members)
	member_change.emit(members)


## Callback function to handle updates to the local member
func _local_member_callback(args: Array) -> void:
	var local_member_rtc = args[0]
	if TYPE_NIL == typeof(local_member_rtc):
		# This can be Nil -> we do not want gd script to crash on local_member_rtc.membership
		return
	console.log("GODOT _local_member_callback emit: ", "id",local_member_rtc.membership.memberId, "name", local_member_rtc.membership.userId)
	local_member_change.emit({"id":local_member_rtc.membership.memberId, "name": local_member_rtc.membership.userId})


## Callback function to handle updates to local member connection status
func _connected_callback(args: Array) -> void:
	print("GODOT Update connectedObs", args[0])
	var connected_status: bool = args[0]
	var status_text : String
	if connected_status:
		status_text = "Connected"
	else:
		status_text = "Not Connected"
	status.text = "Status: " + status_text
	if connected_status:
		leave.visible = true
		join.visible = false
	else:
		leave.visible = false
		join.visible = true
	connected_changed.emit(connected_status)


## `Leave` Button node `pressed` signal function to handle leaving logic
## Updates `Status` Label node and `Join` / `Leave` Button node visibility
func _on_leave_pressed() -> void:
	status.text = "Status: Leaving..."
	leave.visible = false
	join.visible = true
	sdk.leave()


## `Join` Button node `pressed` signal function to handle leaving logic
## Updates `Status` Label node and `Join` / `Leave` Button node visibility
func _on_join_pressed() -> void:
	status.text = "Status: Joining..."
	leave.visible = true
	join.visible = false
	sdk.join()


## Subscribes callback refs to all MatrixRTC emitters.
func start_emitters() -> void:
	sdk.dataObs.subscribe(_data_callback_ref)
	sdk.membersObs.subscribe(_members_callback_ref)
	sdk.localMemberObs.subscribe(_local_member_callback_ref)
	sdk.connectedObs.subscribe(_connected_callback_ref)


## Function to handle sending updates to the local members' data
func update_own_data(data: Dictionary) -> void:
	sdk.sendData(data)


## Function to send text messages into the widgets' Matrix room
func send_text_message(message: String) -> void:
	sdk.sendRoomMessage(message)
