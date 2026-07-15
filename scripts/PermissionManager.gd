class_name PermissionManager extends Node

@export var roundManager : RoundManager
@export var itemManager : ItemManager
@export var indicatorArray : Array[PickupIndicator]
@export var interactionBranchArray : Array[InteractionBranch]
@export var description : DescriptionManager
@export var userItemsParent : Node3D
@export var stackDisabledItemArray : Array[String]
@export var stackDisabledItemArray_bools : Array[bool]

func _ready():
	#SetItemInteraction(true)
	pass

func SetIndicators(state : bool):
	for indicator in indicatorArray:
		if !is_instance_valid(indicator):
			continue
		indicator.interactionAllowed = state
		if !state:
			indicator.moving = false

func DisableShotgun():
	for branch in interactionBranchArray:
		if is_instance_valid(branch) and branch.interactionAlias == "shotgun":
			branch.interactionAllowed = false
			break
	for indicator in indicatorArray:
		if is_instance_valid(indicator) and indicator.itemName == "SHOTGUN":
			indicator.interactionAllowed = false
			break

func SetInteractionPermissions(state : bool):
	for branch in interactionBranchArray:
		if is_instance_valid(branch):
			branch.interactionAllowed = state

	if !roundManager.roundArray[roundManager.currentRound].usingItems:
		return
	var pair_count := mini(itemManager.items_dynamicInteractionArray.size(), itemManager.items_dynamicIndicatorArray.size())
	for i in range(pair_count):
		var branch := itemManager.items_dynamicInteractionArray[i]
		var indicator := itemManager.items_dynamicIndicatorArray[i]
		if !is_instance_valid(branch) or !is_instance_valid(indicator):
			continue
		branch.interactionAllowed = state
		indicator.interactionAllowed = state

func SetItemInteraction(state : bool):
	for child in userItemsParent.get_children():
		if !is_instance_valid(child) or child.get_child_count() < 2:
			continue
		var indicator := child.get_child(0) as PickupIndicator
		var branch := child.get_child(1) as InteractionBranch
		if indicator != null:
			indicator.interactionAllowed = state
		if branch != null:
			branch.interactionAllowed = state

@export var inter : ItemInteraction
func SetStackInvalidIndicators():
	if stackDisabledItemArray_bools.size() > 5:
		stackDisabledItemArray_bools[5] = inter.stealing
	if stackDisabledItemArray_bools.size() > 4:
		stackDisabledItemArray_bools[4] = roundManager.dealerCuffed
	if stackDisabledItemArray_bools.size() > 0:
		stackDisabledItemArray_bools[0] = roundManager.barrelSawedOff

	if !roundManager.roundArray[roundManager.currentRound].usingItems:
		return
	var pair_count := mini(itemManager.items_dynamicInteractionArray.size(), itemManager.items_dynamicIndicatorArray.size())
	for i in range(stackDisabledItemArray.size()):
		if i >= stackDisabledItemArray_bools.size():
			break
		for c in range(pair_count):
			var branch := itemManager.items_dynamicInteractionArray[c]
			var indicator := itemManager.items_dynamicIndicatorArray[c]
			if !is_instance_valid(branch) or !is_instance_valid(indicator):
				continue
			if branch.itemName == stackDisabledItemArray[i]:
				branch.interactionInvalid = stackDisabledItemArray_bools[i]
				indicator.interactionInvalid = stackDisabledItemArray_bools[i]

func RevertDescriptionUI():
	description.EndLerp()
