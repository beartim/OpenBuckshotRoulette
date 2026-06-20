extends Node

signal leaderboard_find_result(handle: int, found: int)
signal leaderboard_score_uploaded(success: int, this_handle: int, this_score: Dictionary)
signal leaderboard_scores_downloaded(message: String, this_leaderboard_handle: int, result: Array)

signal lobby_match_list(list: Array)
signal join_requested(this_lobby_id: int, friend_id: int)
signal lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int)
signal lobby_created(connect: int, this_lobby_id: int)
signal lobby_joined(this_lobby_id: int, permissions: int, locked: bool, response: int)
signal persona_state_change(this_steam_id: int, flag: int)

signal avatar_loaded(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray)

signal p2p_session_request(remote_id: int)
signal p2p_session_connect_fail(steam_id: int, session_error: int)

const LEADERBOARD_DATA_REQUEST_GLOBAL: int = 0
const LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER: int = 1
const LEADERBOARD_DATA_REQUEST_FRIENDS: int = 2

const LOBBY_DISTANCE_FILTER_CLOSE: int = 0
const LOBBY_DISTANCE_FILTER_FAR: int = 1
const LOBBY_DISTANCE_FILTER_WORLDWIDE: int = 2

const LOBBY_TYPE_PRIVATE: int = 0
const LOBBY_TYPE_FRIENDS_ONLY: int = 1
const LOBBY_TYPE_PUBLIC: int = 2
const LOBBY_TYPE_INVISIBLE: int = 3

const CHAT_ROOM_ENTER_RESPONSE_SUCCESS: int = 1
const CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: int = 2
const CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: int = 3
const CHAT_ROOM_ENTER_RESPONSE_FULL: int = 4
const CHAT_ROOM_ENTER_RESPONSE_ERROR: int = 5
const CHAT_ROOM_ENTER_RESPONSE_BANNED: int = 6
const CHAT_ROOM_ENTER_RESPONSE_LIMITED: int = 7
const CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: int = 8
const CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: int = 9
const CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: int = 10
const CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: int = 11

const CHAT_MEMBER_STATE_CHANGE_ENTERED: int = 1
const CHAT_MEMBER_STATE_CHANGE_LEFT: int = 2
const CHAT_MEMBER_STATE_CHANGE_KICKED: int = 3
const CHAT_MEMBER_STATE_CHANGE_BANNED: int = 4

const P2P_SEND_RELIABLE: int = 0

var _steam: Object = null
var _lobby_data: Dictionary = {}
var _lobby_distance_filter: int = LOBBY_DISTANCE_FILTER_CLOSE
var _lobby_result_count_limit: int = 50
var server_address = 'ws://buckds.1503dev.top:14122'

func _ready() -> void:
	if Engine.has_singleton("Steam"):
		_steam = Engine.get_singleton("Steam")
		_bridge_signals()

func _bridge_signals() -> void:
	_bridge_signal("leaderboard_find_result", Callable(self, "_on_real_leaderboard_find_result"))
	_bridge_signal("leaderboard_score_uploaded", Callable(self, "_on_real_leaderboard_score_uploaded"))
	_bridge_signal("leaderboard_scores_downloaded", Callable(self, "_on_real_leaderboard_scores_downloaded"))
	_bridge_signal("lobby_match_list", Callable(self, "_on_real_lobby_match_list"))
	_bridge_signal("join_requested", Callable(self, "_on_real_join_requested"))
	_bridge_signal("lobby_chat_update", Callable(self, "_on_real_lobby_chat_update"))
	_bridge_signal("lobby_created", Callable(self, "_on_real_lobby_created"))
	_bridge_signal("lobby_joined", Callable(self, "_on_real_lobby_joined"))
	_bridge_signal("persona_state_change", Callable(self, "_on_real_persona_state_change"))
	_bridge_signal("avatar_loaded", Callable(self, "_on_real_avatar_loaded"))
	_bridge_signal("p2p_session_request", Callable(self, "_on_real_p2p_session_request"))
	_bridge_signal("p2p_session_connect_fail", Callable(self, "_on_real_p2p_session_connect_fail"))

func _bridge_signal(signal_name: StringName, callable: Callable) -> void:
	if _steam == null:
		return
	if !_steam.has_signal(signal_name):
		return
	if _steam.is_connected(signal_name, callable):
		return
	_steam.connect(signal_name, callable)

func _on_real_leaderboard_find_result(handle: int, found: int) -> void:
	leaderboard_find_result.emit(handle, found)

func _on_real_leaderboard_score_uploaded(success: int, this_handle: int, this_score: Dictionary) -> void:
	leaderboard_score_uploaded.emit(success, this_handle, this_score)

func _on_real_leaderboard_scores_downloaded(message: String, this_leaderboard_handle: int, result: Array) -> void:
	leaderboard_scores_downloaded.emit(message, this_leaderboard_handle, result)

func _on_real_lobby_match_list(list: Array) -> void:
	lobby_match_list.emit(list)

func _on_real_join_requested(this_lobby_id: int, friend_id: int) -> void:
	join_requested.emit(this_lobby_id, friend_id)

func _on_real_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	lobby_chat_update.emit(this_lobby_id, change_id, making_change_id, chat_state)

func _on_real_lobby_created(m_connect: int, this_lobby_id: int) -> void:
	lobby_created.emit(m_connect, this_lobby_id)

func _on_real_lobby_joined(this_lobby_id: int, permissions: int, locked: bool, response: int) -> void:
	lobby_joined.emit(this_lobby_id, permissions, locked, response)

func _on_real_persona_state_change(this_steam_id: int, flag: int) -> void:
	persona_state_change.emit(this_steam_id, flag)

func _on_real_avatar_loaded(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	avatar_loaded.emit(user_id, avatar_size, avatar_buffer)

func _on_real_p2p_session_request(remote_id: int) -> void:
	p2p_session_request.emit(remote_id)

func _on_real_p2p_session_connect_fail(steam_id: int, session_error: int) -> void:
	p2p_session_connect_fail.emit(steam_id, session_error)

func steamInit(is_server: bool) -> Dictionary:
	if _steam != null and _steam.has_method("steamInit"):
		return _steam.steamInit(is_server)
	return {"status": 0, "message": "Steam shim (no Steamworks)"}

func run_callbacks() -> void:
	if _steam != null and _steam.has_method("run_callbacks"):
		_steam.run_callbacks()

func loggedOn() -> bool:
	if _steam != null and _steam.has_method("loggedOn"):
		return _steam.loggedOn()
	return false

func getSteamID() -> int:
	if _steam != null and _steam.has_method("getSteamID"):
		return int(_steam.getSteamID())
	return 0

func getPersonaName() -> String:
	if _steam != null and _steam.has_method("getPersonaName"):
		return str(_steam.getPersonaName())
	return "OFFLINE"

func getFriendPersonaName(steam_id: int) -> String:
	if _steam != null and _steam.has_method("getFriendPersonaName"):
		return str(_steam.getFriendPersonaName(steam_id))
	if steam_id == 0:
		return "N/A"
	return str(steam_id)

func isSteamRunningOnSteamDeck() -> bool:
	if _steam != null and _steam.has_method("isSteamRunningOnSteamDeck"):
		return bool(_steam.isSteamRunningOnSteamDeck())
	return false

func setAchievement(apiname: String) -> void:
	if _steam != null and _steam.has_method("setAchievement"):
		_steam.setAchievement(apiname)

func clearAchievement(apiname: String) -> void:
	if _steam != null and _steam.has_method("clearAchievement"):
		_steam.clearAchievement(apiname)

func storeStats() -> void:
	if _steam != null and _steam.has_method("storeStats"):
		_steam.storeStats()

func setLeaderboardDetailsMax(max_details: int) -> int:
	if _steam != null and _steam.has_method("setLeaderboardDetailsMax"):
		return int(_steam.setLeaderboardDetailsMax(max_details))
	return max_details

func findLeaderboard(_name: String) -> void:
	if _steam != null and _steam.has_method("findLeaderboard"):
		_steam.findLeaderboard(_name)
		return
	call_deferred("_emit_mock_leaderboard_find_result")

func _emit_mock_leaderboard_find_result() -> void:
	leaderboard_find_result.emit(1, 1)

func uploadLeaderboardScore(score: int, keep_best: bool, details: PackedInt32Array, leaderboard_handle: int) -> void:
	if _steam != null and _steam.has_method("uploadLeaderboardScore"):
		_steam.uploadLeaderboardScore(score, keep_best, details, leaderboard_handle)
		return
	call_deferred("_emit_mock_leaderboard_score_uploaded", leaderboard_handle, score, details)

func _emit_mock_leaderboard_score_uploaded(leaderboard_handle: int, score: int, details: PackedInt32Array) -> void:
	leaderboard_score_uploaded.emit(0, leaderboard_handle, {"score": score, "details": details})

func downloadLeaderboardEntries(range1: int, range2: int, request_type: int) -> void:
	if _steam != null and _steam.has_method("downloadLeaderboardEntries"):
		_steam.downloadLeaderboardEntries(range1, range2, request_type)
		return
	call_deferred("_emit_mock_leaderboard_scores_downloaded")

func _emit_mock_leaderboard_scores_downloaded() -> void:
	leaderboard_scores_downloaded.emit("offline", 1, [])

func getLeaderboardEntryCount(leaderboard_handle: int) -> int:
	if _steam != null and _steam.has_method("getLeaderboardEntryCount"):
		return int(_steam.getLeaderboardEntryCount(leaderboard_handle))
	return 0

func addRequestLobbyListResultCountFilter(count: int) -> void:
	_lobby_result_count_limit = count
	if _steam != null and _steam.has_method("addRequestLobbyListResultCountFilter"):
		_steam.addRequestLobbyListResultCountFilter(count)

func addRequestLobbyListDistanceFilter(filter: int) -> void:
	_lobby_distance_filter = filter
	if _steam != null and _steam.has_method("addRequestLobbyListDistanceFilter"):
		_steam.addRequestLobbyListDistanceFilter(filter)

func requestLobbyList() -> void:
	if GlobalVariables.using_steam and _steam != null and _steam.has_method("requestLobbyList"):
		_steam.requestLobbyList()
		return
	if GlobalSteam != null and GlobalSteam.ws_peer != null:
		GlobalSteam.ws_peer.send_text(JSON.stringify({"type": "listRooms"}))
		return
	call_deferred("_emit_mock_lobby_match_list")

func _emit_mock_lobby_match_list() -> void:
	lobby_match_list.emit([])

func setLobbyData(lobby_id: int, key: String, value: String) -> void:
	if _steam != null and _steam.has_method("setLobbyData"):
		_steam.setLobbyData(lobby_id, key, value)
		return
	if !_lobby_data.has(lobby_id):
		_lobby_data[lobby_id] = {}
	_lobby_data[lobby_id][key] = value

func getLobbyData(lobby_id: int, key: String) -> String:
	if _steam != null and _steam.has_method("getLobbyData"):
		return str(_steam.getLobbyData(lobby_id, key))
	if !_lobby_data.has(lobby_id):
		return ""
	return str(_lobby_data[lobby_id].get(key, ""))

func setLobbyMemberLimit(lobby_id: int, max_members: int) -> void:
	if _steam != null and _steam.has_method("setLobbyMemberLimit"):
		_steam.setLobbyMemberLimit(lobby_id, max_members)
		return
	setLobbyData(lobby_id, "max_members", str(max_members))

func setLobbyJoinable(lobby_id: int, joinable: bool) -> void:
	if _steam != null and _steam.has_method("setLobbyJoinable"):
		_steam.setLobbyJoinable(lobby_id, joinable)

func setLobbyType(lobby_id: int, lobby_type: int) -> void:
	if _steam != null and _steam.has_method("setLobbyType"):
		_steam.setLobbyType(lobby_id, lobby_type)
		return
	setLobbyData(lobby_id, "friends_only", "true" if lobby_type == LOBBY_TYPE_FRIENDS_ONLY else "false")

func activateGameOverlayInviteDialog(lobby_id: int) -> void:
	if _steam != null and _steam.has_method("activateGameOverlayInviteDialog"):
		_steam.activateGameOverlayInviteDialog(lobby_id)

func allowP2PPacketRelay(allow: bool) -> bool:
	if _steam != null and _steam.has_method("allowP2PPacketRelay"):
		return bool(_steam.allowP2PPacketRelay(allow))
	return false

func createLobby(lobby_type: int, max_members: int) -> void:
	if _steam != null and _steam.has_method("createLobby"):
		_steam.createLobby(lobby_type, max_members)
		return
	call_deferred("_emit_mock_lobby_created")

func _emit_mock_lobby_created() -> void:
	lobby_created.emit(0, 0)

func joinLobby(lobby_id: int) -> void:
	if _steam != null and _steam.has_method("joinLobby"):
		_steam.joinLobby(lobby_id)
		return
	call_deferred("_emit_mock_lobby_joined", lobby_id)

func _emit_mock_lobby_joined(lobby_id: int) -> void:
	lobby_joined.emit(lobby_id, 0, false, CHAT_ROOM_ENTER_RESPONSE_ERROR)

func leaveLobby(lobby_id: int) -> void:
	if _steam != null and _steam.has_method("leaveLobby"):
		_steam.leaveLobby(lobby_id)

func kickLobbyMember(lobby_id: int, steam_id_member: int) -> void:
	if _steam != null and _steam.has_method("kickLobbyMember"):
		_steam.kickLobbyMember(lobby_id, steam_id_member)

func getLobbyOwner(lobby_id: int) -> int:
	if _steam != null and _steam.has_method("getLobbyOwner"):
		return int(_steam.getLobbyOwner(lobby_id))
	return 0

func getNumLobbyMembers(lobby_id: int) -> int:
	if _steam != null and _steam.has_method("getNumLobbyMembers"):
		return int(_steam.getNumLobbyMembers(lobby_id))
	return 0

func getLobbyMemberByIndex(lobby_id: int, member_index: int) -> int:
	if _steam != null and _steam.has_method("getLobbyMemberByIndex"):
		return int(_steam.getLobbyMemberByIndex(lobby_id, member_index))
	return 0

func closeP2PSessionWithUser(steam_id: int) -> void:
	if _steam != null and _steam.has_method("closeP2PSessionWithUser"):
		_steam.closeP2PSessionWithUser(steam_id)

func acceptP2PSessionWithUser(steam_id: int) -> void:
	if _steam != null and _steam.has_method("acceptP2PSessionWithUser"):
		_steam.acceptP2PSessionWithUser(steam_id)

func getAvailableP2PPacketSize(channel: int) -> int:
	if _steam != null and _steam.has_method("getAvailableP2PPacketSize"):
		return int(_steam.getAvailableP2PPacketSize(channel))
	return 0

func readP2PPacket(packet_size: int, channel: int) -> Dictionary:
	if _steam != null and _steam.has_method("readP2PPacket"):
		return _steam.readP2PPacket(packet_size, channel)
	return {}

func sendP2PPacket(target: int, data: PackedByteArray, send_type: int, channel: int) -> void:
	if _steam != null and _steam.has_method("sendP2PPacket"):
		_steam.sendP2PPacket(target, data, send_type, channel)

func getPlayerAvatar(size: int, steam_id: int) -> void:
	if _steam != null and _steam.has_method("getPlayerAvatar"):
		_steam.getPlayerAvatar(size, steam_id)
