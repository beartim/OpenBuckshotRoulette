class_name HandManager extends Node

@export var dealerAI : DealerIntelligence
@export var itemManager : ItemManager
@export var animator_hands : AnimationPlayer
@export var animator_dealerHeadLook : AnimationPlayer
@export var handArray_L : Array[Node3D]
@export var handArray_R : Array[Node3D]
@export var gridOffsetArray : Array[Vector3] #ITEM'S ACTIVE GRID INDEX STORED IN PICKUP INDICATOR: dealerGridIndex
@export var inter : ItemInteraction
@export var cam : CameraManager

@export var handParent_L : Node3D
@export var handParent_R : Node3D
@export var hand_defaultL : Node3D
@export var hand_defaultR : Node3D
@export var hand_cigarettepack : Node3D 	#L
@export var hand_beer : Node3D 				#L
@export var hand_medicine : Node3D			#L
@export var hand_inverter : Node3D			#L
@export var hand_adrenaline : Node3D		#L
@export var hand_handcuffs : Node3D 		#R
@export var hand_handsaw : Node3D 			#R
@export var hand_magnifier : Node3D 		#R
@export var hand_burnerphone : Node3D		#R

@export var lerpDuration : float
@export var handRot_left : Vector3 #hand rotation when grabing from left grids
@export var handRot_right : Vector3 #same shit
@export var parentOriginal_posL : Vector3
@export var parentOriginal_rotL : Vector3
@export var parentOriginal_posR : Vector3
@export var parentOriginal_rotR : Vector3
@export var amounts : Amounts
var moving = false
var lerping_L = false
var lerping_R = false
var pos_current
var pos_next
var rot_current
var rot_next
var elapsed = 0
var orig_pos
var orig_rot
var activeHandParent
var activeItemToGrab

func _process(_delta: float) -> void:
	LerpHandMovement()

var stealing = false
func PickupItemFromTable(itemName : String):
	dealerAI.Speaker_HandCrack()
	var activeIndex := -1
	var activeInstance: Node3D = null
	var whichHandToGrabWith := ""
	var whichGridSide := ""
	var matchIndex := -1
	activeItemToGrab = itemName

	for i in range(itemManager.itemArray_instances_dealer.size()):
		var candidate := itemManager.itemArray_instances_dealer[i]
		if !is_instance_valid(candidate) or candidate.get_child_count() < 2:
			continue
		var branch := candidate.get_child(1) as InteractionBranch
		if branch != null and itemName == branch.itemName:
			activeInstance = candidate
			matchIndex = i
			break

	if activeInstance == null or matchIndex < 0:
		stealing = false
		HandFailsafe()
		return

	var indicator := activeInstance.get_child(0) as PickupIndicator
	if indicator == null:
		stealing = false
		HandFailsafe()
		return

	activeIndex = indicator.dealerGridIndex
	if activeIndex < 0 or activeIndex >= gridOffsetArray.size():
		stealing = false
		HandFailsafe()
		return

	ToggleHandVisible("BOTH", false)
	hand_defaultL.visible = true
	hand_defaultR.visible = true
	if itemName in ["beer", "cigarettes", "expired medicine", "inverter", "adrenaline"]:
		whichHandToGrabWith = "left"
	else:
		whichHandToGrabWith = "right"
	whichGridSide = indicator.whichSide
	animator_hands.play("RESET")
	BeginHandLerp(whichHandToGrabWith, activeIndex, whichGridSide)
	if whichGridSide == "right":
		animator_dealerHeadLook.play("dealer look right")
	else:
		animator_dealerHeadLook.play("dealer look left")

	if stealing:
		if whichGridSide == "right":
			cam.BeginLerp("player item grid left")
		else:
			cam.BeginLerp("player item grid right")
		for res in amounts.array_amounts:
			if res.itemName == itemName:
				res.amount_player = maxi(0, res.amount_player - 1)
				break

	await GlobalVariables.tree.create_timer(maxf(lerpDuration - .4, 0.0), false).timeout
	if whichHandToGrabWith == "right":
		hand_defaultR.visible = false
	else:
		hand_defaultL.visible = false
	dealerAI.Speaker_HandCrack()

	match itemName:
		"handsaw": hand_handsaw.visible = true
		"magnifying glass": hand_magnifier.visible = true
		"handcuffs": hand_handcuffs.visible = true
		"cigarettes":
			hand_cigarettepack.visible = true
			itemManager.numberOfCigs_dealer = maxi(0, itemManager.numberOfCigs_dealer - 1)
		"beer": hand_beer.visible = true
		"expired medicine": hand_medicine.visible = true
		"inverter": hand_inverter.visible = true
		"burner phone": hand_burnerphone.visible = true
		"adrenaline": hand_adrenaline.visible = true

	itemManager.itemArray_instances_dealer.remove_at(matchIndex)
	var gridname = indicator.dealerGridName
	if !stealing and gridname != null and !itemManager.gridParentArray_enemy_available.has(gridname):
		itemManager.gridParentArray_enemy_available.append(gridname)
	if stealing:
		inter.RemovePlayerItemFromGrid(activeInstance)
	activeInstance.queue_free()
	await GlobalVariables.tree.create_timer(.2, false).timeout
	ReturnHand()
	if stealing:
		cam.BeginLerp("enemy")
	if whichGridSide == "right":
		animator_dealerHeadLook.play("dealer look forward from right")
	else:
		animator_dealerHeadLook.play("dealer look forward from left")
	await GlobalVariables.tree.create_timer(lerpDuration + .01, false).timeout
	HandFailsafe()

	var animationName := "dealer use " + itemName
	PlaySound(itemName)
	animator_hands.play("RESET")
	if animator_hands.has_animation(animationName):
		animator_hands.play(animationName)
		var length := animator_hands.get_animation(animationName).get_length()
		moving = false
		await GlobalVariables.tree.create_timer(length, false).timeout
	else:
		moving = false
	stealing = false

@export var speaker_interaction : AudioStreamPlayer2D
@export var sound_adrenaline : AudioStream
@export var sound_medicine : AudioStream
@export var sound_burnerphone : AudioStream
@export var sound_inverter : AudioStream
func PlaySound(itemName : String):
	match itemName:
		"adrenaline":
			speaker_interaction.stream = sound_adrenaline
			speaker_interaction.play()
		"expired medicine":
			speaker_interaction.stream = sound_medicine
			speaker_interaction.play()
		"burner phone":
			speaker_interaction.stream = sound_burnerphone
			speaker_interaction.play()
		"inverter":
			speaker_interaction.stream = sound_inverter
			speaker_interaction.play()

func RemoveItem_Remote(activeInstance : Node3D) -> bool:
	if !is_instance_valid(activeInstance) or activeInstance.get_child_count() < 2:
		return false
	var indicator := activeInstance.get_child(0) as PickupIndicator
	var branch := activeInstance.get_child(1) as InteractionBranch
	if indicator == null or branch == null or !indicator.isDealerItem:
		return false
	if !itemManager.itemArray_instances_dealer.has(activeInstance):
		return false

	itemManager.itemArray_dealer.erase(branch.itemName.to_lower())
	itemManager.numberOfItemsGrabbed_enemy = maxi(0, itemManager.numberOfItemsGrabbed_enemy - 1)
	itemManager.itemArray_instances_dealer.erase(activeInstance)
	var gridname = indicator.dealerGridName
	if gridname != null and !itemManager.gridParentArray_enemy_available.has(gridname):
		itemManager.gridParentArray_enemy_available.append(gridname)
	return true

func ToggleHandVisible(selectedHand : String, state : bool):
	if selectedHand == "L" or selectedHand == "BOTH":
		for i in range(handArray_L.size()):
			if (state): handArray_L[i].visible = true
			else: handArray_L[i].visible = false
	if selectedHand == "R" or selectedHand == "BOTH":
		for i in range(handArray_R.size()):
			if (state): handArray_R[i].visible = true
			else: handArray_R[i].visible = false

func BeginHandLerp(whichHand : String, gridIndex : int, whichSide : String):
	if (whichHand == "right"): activeHandParent = handParent_R
	else: activeHandParent = handParent_L
	pos_current = activeHandParent.transform.origin
	rot_current = activeHandParent.rotation_degrees
	orig_pos = pos_current
	orig_rot = rot_current
	pos_next = gridOffsetArray[gridIndex]
	lerping_L = false
	lerping_R = false
	if(whichSide == "right"): rot_next = handRot_right
	else: rot_next = handRot_left
	if(whichHand == "right"): lerping_R = true
	else: lerping_L = true
	elapsed = 0
	moving = true

func ReturnHand():
	pos_current = activeHandParent.transform.origin
	rot_current = activeHandParent.rotation_degrees
	pos_next = orig_pos
	rot_next = orig_rot
	elapsed = 0
	moving = true

func HandFailsafe():
	handParent_L.transform.origin = parentOriginal_posL
	handParent_L.rotation_degrees = parentOriginal_rotL
	handParent_R.transform.origin = parentOriginal_posR
	handParent_R.rotation_degrees = parentOriginal_rotR

func LerpHandMovement():
	if (moving):
		elapsed += get_process_delta_time()
		var c = clampf(elapsed / lerpDuration, 0.0, 1.0)
		c = ease(c, 0.2)
		if (lerping_L):
			var pos = lerp(pos_current, pos_next, c)
			var rot = lerp(rot_current, rot_next, c)
			handParent_L.transform.origin = pos
			handParent_L.rotation_degrees = rot
		if (lerping_R):
			var pos = lerp(pos_current, pos_next, c)
			var rot = lerp(rot_current, rot_next, c)
			handParent_R.transform.origin = pos
			handParent_R.rotation_degrees = rot
		pass
