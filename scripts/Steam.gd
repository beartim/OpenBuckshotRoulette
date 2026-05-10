extends Node

signal packet_received(packet_data: Dictionary)
signal lobby_created(connect: int, this_lobby_id: int)
signal lobby_joined(this_lobby_id: int, permissions: int, locked: bool, response: int)
signal lobby_members_changed()

var appid : int = 2835570

const PACKET_READ_LIMIT: int = 32

var DATA
var LOBBY_ID = 0
var LOBBY_MEMBERS = []
var USER_ID_LIST_TO_IGNORE : Array[int]
var LOBBY_INVITE_ARG = false
var STEAM_ID = 0
var STEAM_NAME = ""
var ONLINE = false
var HOST_ID = 0

var is_lobby_friends_only = true
var lobby_player_limit = 4

var ws_peer = WebSocketPeer.new()
var connected = false
var is_active_connection = false
var client_id = 0

var connection_attempts = 0
var reconnection_attempts = 0
var had_successful_connection = false
var retry_timer = 0.0
var heartbeat_timer = 0.0

func _ready():
	process_priority = 1000
	set_process_internal(true)
	InitializeSteam()
	
	if GlobalVariables.using_steam:
		ONLINE = Steam.loggedOn()
		STEAM_ID = Steam.getSteamID()
		STEAM_NAME = Steam.getPersonaName()
	else:
		STEAM_ID = randi() % 1000000 + 1000
		STEAM_NAME = generate_random_name()
	
	if GlobalVariables.mp_debugging: STEAM_ID = 1234
	print("online ... ", ONLINE, " ... steam id ... ", STEAM_ID, " ... steam name ... ", STEAM_NAME)

	call_deferred("_ensure_steam_lobby_mirror_connected")

func connect_to_server():
	if is_active_connection and ws_peer.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws_peer.close()
	
	connected = false
	var err = ws_peer.connect_to_url(Steam.server_address)
	if err != OK:
		print("Failed to initiate connection to ", Steam.server_address)
		is_active_connection = false
		_handle_connection_failure()
	else:
		print("Connecting to server at ", Steam.server_address, "...")
		is_active_connection = true

func _handle_connection_failure():
	if not had_successful_connection:
		if connection_attempts < 3:
			connection_attempts += 1
			retry_timer = 3.0
			print("Initial connection failed, retrying in 3s... Attempt: ", connection_attempts)
	else:
		if reconnection_attempts < 10:
			reconnection_attempts += 1
			retry_timer = 3.0
			print("Reconnection failed, retrying in 3s... Attempt: ", reconnection_attempts)

func generate_random_name() -> String:
	var length = randi() % 5 + 6
	var m_name = ""
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	for i in range(length):
		m_name += chars[randi() % chars.length()]
	return m_name

func _process(delta: float) -> void:
	if GlobalVariables.using_steam:
		Steam.run_callbacks()
	
	if retry_timer > 0:
		retry_timer -= delta
		if retry_timer <= 0:
			connect_to_server()
		return

	if not is_active_connection:
		return

	ws_peer.poll()
	var state = ws_peer.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		ONLINE = true
		if not connected:
			connected = true
			had_successful_connection = true
			connection_attempts = 0
			reconnection_attempts = 0
			heartbeat_timer = 0.0
			print("Connected to server")
		
		heartbeat_timer += delta
		if heartbeat_timer >= 15.0:
			heartbeat_timer = 0.0
			ws_peer.send_text(JSON.stringify({"type": "heartbeat"}))

		while ws_peer.get_available_packet_count() > 0:
			var packet = ws_peer.get_packet()
			if ws_peer.was_string_packet():
				var data = JSON.parse_string(packet.get_string_from_utf8())
				handle_server_message(data)
			else:
				handle_binary_packet(packet)
	elif state == WebSocketPeer.STATE_CLOSED or state == WebSocketPeer.STATE_CLOSING:
		ONLINE = false
		if connected:
			connected = false
			print("Disconnected from server, attempting immediate reconnect")
			connect_to_server()
		elif not retry_timer > 0:
			_handle_connection_failure()
	else: 
		ONLINE = false

func handle_binary_packet(packet: PackedByteArray):
	if packet.is_empty():
		return
	var decoded: Variant = bytes_to_var(packet)
	if decoded is Dictionary:
		emit_signal("packet_received", decoded as Dictionary)
		return
	var decompressed: PackedByteArray = packet.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if not decompressed.is_empty():
		decoded = bytes_to_var(decompressed)
		if decoded is Dictionary:
			emit_signal("packet_received", decoded as Dictionary)
			return
	push_warning("Steam.gd: could not decode binary websocket packet (size=%d)" % packet.size())

func InitializeSteam():
	if GlobalVariables.using_steam:
			OS.set_environment("SteamAppId", str(appid))
			OS.set_environment("SteamGameId", str(appid))
			
			var INIT: Dictionary = Steam.steamInit(false)
			print("steam init: ", str(INIT))
	else: print("steam not initialized - not running steam version")

func handle_server_message(data):
	match data.type:
		"connected":
			client_id = data.clientId
			print("Assigned client ID: ", client_id)
		"roomCreated":
			LOBBY_ID = int(data.roomId)
			HOST_ID = data.hostId
			LOBBY_MEMBERS.clear()
			if data.has("members"):
				for member_data in data.members:
					LOBBY_MEMBERS.append({"steam_id": member_data.playerId, "steam_name": member_data.playerName})
			else:
				var member = {"steam_id": client_id, "steam_name": STEAM_NAME}
				LOBBY_MEMBERS.append(member)
			print("Room created: ", LOBBY_ID)
			emit_signal("lobby_created", 1, LOBBY_ID)
		"joinedRoom":
			LOBBY_ID = int(data.roomId)
			HOST_ID = data.hostId
			LOBBY_MEMBERS.clear()
			
			if data.has("members"):
				for member_data in data.members:
					var dup = false
					for existing in LOBBY_MEMBERS:
						if existing["steam_id"] == member_data.playerId:
							dup = true
							break
					if not dup:
						LOBBY_MEMBERS.append({"steam_id": member_data.playerId, "steam_name": member_data.playerName})
			
			var self_exists = false
			for member in LOBBY_MEMBERS:
				if member["steam_id"] == STEAM_ID:
					self_exists = true
					break
			if not self_exists:
				LOBBY_MEMBERS.append({"steam_id": STEAM_ID, "steam_name": STEAM_NAME})
			
			print("Joined room: ", LOBBY_ID, " - Members: ", LOBBY_MEMBERS.size())
			emit_signal("lobby_joined", LOBBY_ID, 0, false, 1)
		"playerJoined":
			var exists = false
			for existing_member in LOBBY_MEMBERS:
				if existing_member["steam_id"] == data.playerId:
					exists = true
					break
			
			if not exists:
				var member = {"steam_id": data.playerId, "steam_name": data.get("playerName", "Player" + str(data.playerId))}
				LOBBY_MEMBERS.append(member)
				print("Player joined: ", data.playerId, " name: ", member["steam_name"])
				emit_signal("lobby_members_changed")
		"playerLeft":
			for i in range(LOBBY_MEMBERS.size()):
				if LOBBY_MEMBERS[i]["steam_id"] == data.playerId:
					LOBBY_MEMBERS.remove_at(i)
					break
			print("Player left: ", data.playerId)
			emit_signal("lobby_members_changed")
		"roomList":
			var lobby_list = []
			for room in data.rooms:
				lobby_list.append({
					"lobby_id": int(room.roomId),
					"owner": room.hostId,
					"members": room.memberCount,
					"max_members": lobby_player_limit
				})
			Steam.lobby_match_list.emit(lobby_list)
		_:
			pass

func create_room():
	if connected:
		var room_id = randi_range(100000, 999999)
		LOBBY_ID = room_id
		var msg = {"type": "createRoom", "playerId": STEAM_ID, "playerName": STEAM_NAME}
		ws_peer.send_text(JSON.stringify(msg))

func join_room(room_id: int):
	if connected:
		var msg = {"type": "joinRoom", "roomId": str(room_id), "playerId": STEAM_ID, "playerName": STEAM_NAME}
		ws_peer.send_text(JSON.stringify(msg))

func leave_room() -> void:
	if not connected or LOBBY_ID == 0:
		return
	ws_peer.send_text(JSON.stringify({"type": "leaveRoom"}))

func getNumLobbyMembers(lobby_id: int) -> int:
	if lobby_id == LOBBY_ID:
		return LOBBY_MEMBERS.size()
	return 0

func getLobbyMemberByIndex(lobby_id: int, index: int) -> int:
	if lobby_id == LOBBY_ID and index < LOBBY_MEMBERS.size():
		return LOBBY_MEMBERS[index]["steam_id"]
	return 0

func getFriendPersonaName(steam_id: int) -> String:
	for member in LOBBY_MEMBERS:
		if member["steam_id"] == steam_id:
			return member["steam_name"]
	if steam_id == STEAM_ID:
		return STEAM_NAME
	return "Unknown"

func getLobbyOwner(lobby_id: int) -> int:
	if lobby_id == LOBBY_ID:
		return HOST_ID
	return 0

func send_packet(data: PackedByteArray) -> void:
	if connected:
		ws_peer.send(data)

func _ensure_steam_lobby_mirror_connected() -> void:
	if not GlobalVariables.using_steam:
		return
	if Steam.lobby_chat_update.is_connected(_on_steam_lobby_mirror_refresh):
		return
	if Steam.has_signal("lobby_chat_update"):
		Steam.lobby_chat_update.connect(_on_steam_lobby_mirror_refresh)

func _on_steam_lobby_mirror_refresh(this_lobby_id: int, _change_id: int, _making_change_id: int, _chat_state: int) -> void:
	if not GlobalVariables.using_steam or this_lobby_id == 0:
		return
	if this_lobby_id != LOBBY_ID or LOBBY_ID == 0:
		return
	sync_lobby_members_from_steam_sdk()

func sync_lobby_members_from_steam_sdk() -> void:
	if not GlobalVariables.using_steam:
		return
	var lid : Variant = LOBBY_ID
	if lid == 0:
		return
	var num_of_members := Steam.getNumLobbyMembers(lid)
	LOBBY_MEMBERS.clear()
	for member_index in range(num_of_members):
		var mid: int = Steam.getLobbyMemberByIndex(lid, member_index)
		var mnm: String = Steam.getFriendPersonaName(mid)
		LOBBY_MEMBERS.append({"steam_id": mid, "steam_name": mnm})
	HOST_ID = Steam.getLobbyOwner(lid)
	emit_signal("lobby_members_changed")
