@icon("res://addons/godot-matrix-rtc/aseets/matrix_icon.svg")
extends Node
## A component that can be used to interact with the Matrix Client-Server API
class_name MatrixRTCBridge

var _data_callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(_data_callback)
var _members_callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(_members_callback)
var _local_member_callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(_local_member_callback)
var _connected_callback_ref: JavaScriptObject = JavaScriptBridge.create_callback(_connected_callback)
var console: JavaScriptObject
var sdk: JavaScriptObject

@onready var join: Button = %Join
@onready var leave: Button = %Leave
@onready var status: Label = %Status

signal member_change(members: Array)
signal local_member_change(member: Dictionary)
signal data_change(member_id: String, data: Dictionary)
signal connected_changed(connected: bool)

func update_own_data(data: Dictionary):
	sdk.sendData(data)

func send_text_message(message: String):
	sdk.sendRoomMessage(message)

func _ready():
	console = JavaScriptBridge.get_interface("console")
	console.log("GODOT ready")
	console.warn("danger")

	sdk = JavaScriptBridge.get_interface("window").matrixRTCSdk
	join.connect("pressed", _on_join_pressed)
	leave.connect("pressed", _on_leave_pressed)

func start_emitters():
	sdk.dataObs.subscribe(_data_callback_ref)
	sdk.membersObs.subscribe(_members_callback_ref)
	sdk.localMemberObs.subscribe(_local_member_callback_ref)
	sdk.connectedObs.subscribe(_connected_callback_ref)

func _data_callback(args: Array):
	var data_rtc_obj: Dictionary = args[0]
	var data: Dictionary = data_rtc_obj.data
	console.log("GODOT _data_callback", data_rtc_obj)
	var id = data_rtc_obj.rtcBackendIdentity
	emit_signal("data_change", id, data)
	console.log("GODOT on data:", JSON.stringify(data_rtc_obj))

func _members_callback(args: Array):
	var members_rtc: Array = args[0]
	var members : Array = []
	for i in range(members_rtc.length):
		var member_rtc = members_rtc[i]
		console.log("GODOT _members_callback index: ",i,"member: ", member_rtc, "userId: ",member_rtc.membership.userId, "memberId: ", member_rtc.membership.memberId)
		var m : Dictionary[String, String] = {"id":member_rtc.membership.memberId,"name": member_rtc.membership.userId}

		members.push_back(m)
	console.log("GODOT _members_callback final list: ", members)
	emit_signal("member_change", members)

func _local_member_callback(args):
	var local_member_rtc = args[0]
	if TYPE_NIL ==typeof(local_member_rtc):
		# This can be Nil -> we do not want gd script to crash on local_member_rtc.membership
		return

	console.log("GODOT _local_member_callback emit: ", "id",local_member_rtc.membership.memberId, "name", local_member_rtc.membership.userId)
	emit_signal("local_member_change", {"id":local_member_rtc.membership.memberId, "name": local_member_rtc.membership.userId})

func _connected_callback(args: Array):
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
	emit_signal("connected_changed", connected_status)

func _on_leave_pressed() -> void:
	status.text = "Status: Leaving..."
	leave.visible = false
	join.visible = true
	sdk.leave()

func _on_join_pressed() -> void:
	status.text = "Status: Joining..."
	leave.visible = true
	join.visible = false
	sdk.join()
