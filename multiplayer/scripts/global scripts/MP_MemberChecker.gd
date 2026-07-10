class_name MemberChecker extends Node

@export var packets : PacketManager
@export var ui : Label
@export var anim_fade : AnimationPlayer
@export var instance_handler : MP_UserInstanceHandler

var checking = false
var amountOfPlayers_here = 1
var membersHere_list = []
var total_members_expected = 0
var check_timer = 0.0
var check_timeout = 30.0
var fs = false
var game_started = false

func _ready():
	if (!GlobalVariables.mp_debugging):
		InitialCheck()
		print("starting member check")

func InitialCheck():
	ui.visible = true
	amountOfPlayers_here = 1
	membersHere_list.clear()
	check_timer = 0.0
	game_started = false
	fs = false
	checking = false
	
	if (GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID):
		membersHere_list.append(GlobalSteam.HOST_ID)
		for member in GlobalSteam.LOBBY_MEMBERS:
			var sid: int = member["steam_id"]
			if sid < 0 and not sid in membersHere_list:
				membersHere_list.append(sid)
				amountOfPlayers_here = membersHere_list.size()
		total_members_expected = GlobalSteam.LOBBY_MEMBERS.size()
		UpdateMemberList()
		CheckMembers()
		var packet = {
			"packet category": "lobby",
			"packet alias": "host arrived in main scene",
			"sent_from": "host",
			"packet_id": 3,
		}
		packets.send_p2p_packet(0, packet)
	else:
		total_members_expected = GlobalSteam.LOBBY_MEMBERS.size()
		UpdateMemberList()
		var packet = {
			"packet category": "lobby",
			"packet alias": "member joined list",
			"sent_from": "client",
			"packet_id": 4,
			"steam_id": GlobalSteam.STEAM_ID,
		}
		packets.send_p2p_packet(GlobalSteam.HOST_ID, packet)

func CheckMembers():
	checking = true
	if total_members_expected > 0 and amountOfPlayers_here >= total_members_expected:
		TriggerGameStart()
		return

func _process(delta: float) -> void:
	if game_started:
		return
		
	if checking and !fs:
		var current_total = GlobalSteam.LOBBY_MEMBERS.size()
		if current_total > 0 and current_total != total_members_expected:
			total_members_expected = current_total
			UpdateMemberList()
		
		if amountOfPlayers_here >= total_members_expected and total_members_expected > 0:
			TriggerGameStart()
			return
		
		check_timer += delta
		if check_timer >= check_timeout:
			UpdateMemberList()
			TriggerGameStart()

func MemberJoinedList(steam_id : int):
	if game_started:
		return
		
	if not steam_id in membersHere_list:
		membersHere_list.append(steam_id)
		amountOfPlayers_here = membersHere_list.size()
		UpdateMemberList()
		var packet = {
			"packet category": "lobby",
			"packet alias": "update member list",
			"sent_from": "host",
			"packet_id": 5,
			"number of players here": amountOfPlayers_here,
		}
		for id in membersHere_list:
			if (id != GlobalSteam.HOST_ID):
				packets.send_p2p_packet(id, packet)
	else:
		UpdateMemberList()

func UpdateMemberList():
	if game_started:
		return
		
	print("incrementing list: ", amountOfPlayers_here, "/", total_members_expected)
	ui.text = tr("MP_UI WAITING FOR PLAYERS") + " (" + str(amountOfPlayers_here) + "/" + str(total_members_expected) + ")"

func UpdateExpectedTotal(new_total: int):
	if new_total > 0 and new_total != total_members_expected:
		total_members_expected = new_total
		UpdateMemberList()
		if amountOfPlayers_here >= total_members_expected:
			TriggerGameStart()

func TriggerGameStart():
	game_started = true
	checking = false
	fs = true
	ui.visible = false
	MembersArrived()
	
	if GlobalSteam.STEAM_ID == GlobalSteam.HOST_ID:
		var packet = {
			"packet category": "lobby",
			"packet alias": "all members arrived",
			"sent_from": "host",
			"packet_id": 5,
		}
		packets.send_p2p_packet(0, packet)

func MembersArrived():
	anim_fade.play("fade")
	await GlobalVariables.tree.create_timer(2.7, false).timeout
	instance_handler.StartMainGame()

func ForceUpdateUI():
	if not game_started:
		UpdateMemberList()
