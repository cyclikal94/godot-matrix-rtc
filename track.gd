extends Node2D
#Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
var text = "Lorem ipsum dolor sit amet, ut labore et dolore magna aliqua. Ut enim ad minim veniam."
# Called when the node enters the scene tree for the first time.
@onready var carPath = %CarPath
@onready var letterPath = %Path2D
const CHAR_VIEW_RANGE = 3

var all_members = []
var ownCar: PathFollow2D = null

func on_position_update(opponent_id, car_postition):
	var opponent_cars = carPath.get_children().filter(func(o): return not o.is_own)
	var index = opponent_cars.find_custom(func(o): return o.id == opponent_id)
	if(index == -1):
		%MatrixRTCBridge.console.log("cannot find opponent: ", opponent_id, " opponents: ", opponent_cars.map(func(o): return o.id))
	else:
		opponent_cars[index].car_position = car_postition

func on_rtc_member_update(members):
	# we need to also store the members here. we need them in on_local_rtc_member_update to
	# call this method again
	all_members = members
	if(ownCar == null): 
		%MatrixRTCBridge.console.log("Not adding opponents until we have our own car")
		return 
	var opponent_members = all_members.filter(func(m): return m.id != ownCar.id)
	var opponent_cars = carPath.get_children().filter(func(o): return not o.is_own)
	var is_unknown_car = func(m):
		return opponent_cars.find_custom(func(c): return c.id ==m.id) == -1
	var missing_opponents = opponent_members.filter(is_unknown_car)
	
	var is_leftover_car = func(car):
		return opponent_members.find_custom(func(m): return m.id == car.id) == -1
	var leftover_cars = opponent_cars.filter(is_leftover_car)

	for i in range(leftover_cars.size()):
		carPath.remove_child(leftover_cars[i])

	for i in range(missing_opponents.size()):
		var opponent = missing_opponents[i]
		var car : PathFollow2D = %Car.duplicate()
		car.name_label = opponent.name
		car.id = opponent.id
		car.text = text
		car.rotation_degrees = 70
		car.visible=true
		carPath.add_child(car)
		%MatrixRTCBridge.console.log("GODOT add car for:",JSON.stringify(opponent)," with id: ", opponent.id," with name: ", car.name_label)
func on_local_rtc_member_update(member):
	if(ownCar != null):
		%MatrixRTCBridge.console.log("try adding own car again! wo do not do this yet")
		return
	%MatrixRTCBridge.send_text_message("I am entering the RACE 🚗")
	%MatrixRTCBridge.console.log("GODOT adding our own car:", member.id, member.name)
	ownCar=%Car.duplicate()
	ownCar.is_own = true
	ownCar.name = "OwnCar"
	ownCar.id = member.id
	ownCar.text = text
	ownCar.name_label = member.name
	ownCar.visible = true
	ownCar.connect("car_position_update", on_own_position_update)
	ownCar.connect("turn_completed", on_own_turn_complete)
	carPath.add_child(ownCar)
	carPath.visible=true
	on_rtc_member_update(all_members)

func on_own_position_update(car_postition, car_pos_text):
	%TypeHelper.text = text.right(-car_pos_text).left(CHAR_VIEW_RANGE)
	%MatrixRTCBridge.update_own_data({"car_postition": car_postition})

func on_own_turn_complete(turn, duration):
	var best = ownCar.get_best_turn()
	print("GODOT best turn: ",best )
	var best_string = ""
	if best != null and best.size()>1:
		var numbers = ["one", "two",  "three"]
		var turn_number = best[0]
		if turn_number < numbers.size():
			turn_number= numbers[turn_number]
		best_string="(Best: turn "+str(best[0])+" in "+str(float(best[1]) / float(1000),2) + "seconds) "
	var message = best_string + "🚗 Completed my "+str(turn)+" in " + str(float(duration) / float(1000),2) + "seconds"
	print("GODOT message to sent", message)
	%MatrixRTCBridge.send_text_message(message)

func on_connected_changed(connected:bool) -> void:
	if not connected:
		if ownCar:
			carPath.remove_child(ownCar)
			ownCar = null
			%MatrixRTCBridge.send_text_message("I am leaving the RACE 🚗")

func _ready() -> void:
	#connect to RtcBridgeSignals
	%MatrixRTCBridge.connect("data_change",on_position_update)
	%MatrixRTCBridge.connect("member_change", on_rtc_member_update)
	%MatrixRTCBridge.connect("local_member_change", on_local_rtc_member_update)
	%MatrixRTCBridge.connect("connected_changed", on_connected_changed)
	%MatrixRTCBridge.start_emitters()
	
	set_process_input(true)
	
	self.add_child(carPath)
	%TypeHelper.text = text.left(CHAR_VIEW_RANGE)

	for i in range(text.length()):
		var c = text[i]
		var newLetter = %letter.duplicate()
		if(c == ""):
			newLetter.name = "space";
		(newLetter.get_child(0) as Label).text = c;
		%Path2D.add_child(newLetter)
		newLetter.name = c;
		newLetter.progress_ratio = float(i)/float(text.length())
		newLetter.visible = true
