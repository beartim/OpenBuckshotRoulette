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
var client_id = 0

func _ready():
	process_priority = 1000
	set_process_internal(true)
	InitializeSteam()
	
	if GlobalVariables.using_steam:
		ONLINE = Steam.loggedOn()
		STEAM_ID = Steam.getSteamID()
		STEAM_NAME = Steam.getPersonaName()
	else:
		ONLINE = true
		STEAM_ID = randi() % 1000000 + 1000  # Random ID
		STEAM_NAME = generate_random_name()
	
	if GlobalVariables.mp_debugging: STEAM_ID = 1234
	print("online ... ", ONLINE, " ... steam id ... ", STEAM_ID, " ... steam name ... ", STEAM_NAME)
	
	# Connect to custom server
	var err = ws_peer.connect_to_url("ws://127.0.0.1:14122")
	if err != OK:
		print("Failed to connect to server")
	else:
		print("Connecting to server...")

func generate_random_name() -> String:
	var length = randi() % 5 + 6  # 6-10
	var name = ""
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	for i in range(length):
		name += chars[randi() % chars.length()]
	return name

func _process(_delta: float) -> void:
	if GlobalVariables.using_steam:
		Steam.run_callbacks()
	
	ws_peer.poll()
	var state = ws_peer.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not connected:
			connected = true
			print("Connected to server")
		while ws_peer.get_available_packet_count() > 0:
			var packet = ws_peer.get_packet()
			if ws_peer.was_string_packet():
				var data = JSON.parse_string(packet.get_string_from_utf8())
				handle_server_message(data)
			else:
				# Binary packet
				handle_binary_packet(packet)
	elif state == WebSocketPeer.STATE_CLOSED:
		if connected:
			connected = false
			print("Disconnected from server")

func handle_binary_packet(packet: PackedByteArray):
	# Decompress (data was already compressed by MP_PacketManager)
	var decompressed = packet.decompress(FileAccess.COMPRESSION_GZIP, -1)
	if decompressed.size() == 0:
		print("Failed to decompress packet. Packet size: ", packet.size())
		# Try treating as already decompressed for debugging
		if packet.size() > 0:
			print("Attempting to parse as uncompressed data...")
			var readable_data = bytes_to_var(packet)
			if readable_data is Dictionary:
				print("Successfully parsed as uncompressed dictionary")
				emit_signal("packet_received", readable_data)
			else:
				print("Failed to parse uncompressed data")
		return
	var readable_data = bytes_to_var(decompressed)
	emit_signal("packet_received", readable_data)

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
			# Emit signal like Steam
			emit_signal("lobby_created", 1, LOBBY_ID)
		"joinedRoom":
			LOBBY_ID = int(data.roomId)
			HOST_ID = data.hostId
			LOBBY_MEMBERS.clear()
			if data.has("members"):
				for member_data in data.members:
					LOBBY_MEMBERS.append({"steam_id": member_data.playerId, "steam_name": member_data.playerName})
			else:
				var member = {"steam_id": client_id, "steam_name": STEAM_NAME}
				LOBBY_MEMBERS.append(member)
			print("Joined room: ", LOBBY_ID)
			emit_signal("lobby_joined", LOBBY_ID, 0, false, 1)
		"playerJoined":
			# Add to members
			var member = {"steam_id": data.playerId, "steam_name": data.get("playerName", "Player" + str(data.playerId))}
			LOBBY_MEMBERS.append(member)
			print("Player joined: ", data.playerId, " name: ", member["steam_name"])
			emit_signal("lobby_members_changed")
		"playerLeft":
			# Remove from members
			for i in range(LOBBY_MEMBERS.size()):
				if LOBBY_MEMBERS[i]["steam_id"] == data.playerId:
					LOBBY_MEMBERS.remove_at(i)
					break
			print("Player left: ", data.playerId)
			emit_signal("lobby_members_changed")
		_:
			# Forward to packet manager or something
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

# Simulated Steam functions
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
		# Data is already compressed by MP_PacketManager, don't compress twice
		ws_peer.send(data)
