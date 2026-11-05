extends RefCounted
## The greatsword's reserve. The combat engine owns turns, targeting and HP;
## this rule answers only whether a damage segment receives a multiplier.

enum Damage { DIRECT, PIERCE, DOT, REFLECT }
enum CardType { MOVE, MOVEMENT, ULTIMATE }

const PLAYER := &"player"
const STACK_CAP := 3
const BONUS_PER_STACK := 0.5

var stacks: int = 0
var _boosted_segment := ""
var _boosted_multiplier := 1.0


func begin_turn(owner: StringName) -> void:
	if owner != PLAYER:
		return
	_boosted_segment = ""
	_boosted_multiplier = 1.0
	# Every player turn, including the first. Banked stacks survive the turn change.
	stacks = mini(STACK_CAP, stacks + 1)


func end_turn(owner: StringName, unspent_qi: int) -> void:
	if owner == PLAYER and unspent_qi > 0:
		stacks += mini(unspent_qi, STACK_CAP - stacks)


## An empty return means the caller leaves damage unchanged. A nonempty result
## distinguishes applying a modifier from consuming the resource that paid for it.
func damage_multiplier(source: StringName, kind: Damage, context: Dictionary, amount: float) -> Dictionary:
	if source != PLAYER or amount <= 0.0 or kind not in [Damage.DIRECT, Damage.PIERCE]:
		return {}
	if context.get("card_type", -1) != CardType.MOVE:
		return {}
	if context.get("execution_kind") != &"CARD_PLAY" or not context.get("active_card_play", false):
		return {}
	var action_id := int(context.get("action_id", 0))
	if action_id <= 0:
		return {}

	# Key the *segment*, not the target. One sweep can hit two targets; a
	# second strike on the same card is a different segment.
	var key := "%d:%s:%d" % [action_id, context.get("effect_key", &""), context.get("segment_index", 0)]
	if key == _boosted_segment:
		return {"multiplier": _boosted_multiplier, "stacks": 0, "consumed": false}
	if not _boosted_segment.is_empty() or stacks == 0:
		return {}

	var spent := stacks
	stacks = 0
	_boosted_segment = key
	_boosted_multiplier = 1.0 + spent * BONUS_PER_STACK
	return {"multiplier": _boosted_multiplier, "stacks": spent, "consumed": true}
