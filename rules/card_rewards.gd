extends RefCounted
## One stage of a reward: the caller has already filtered eligibility and rarity.
## Affinity changes the weight of each individual card in that pool.

const PREFERRED_WEIGHT := 2.0

# Small stand-in for the game's card resource. No game catalogue is required.
class BattleCardData:
	var card_id: StringName
	var routine_id: StringName

	func _init(id: StringName, routine: StringName) -> void:
		card_id = id
		routine_id = routine


## Sample wrapper: a single-rarity offer with no duplicate IDs. An invalid pool
## produces no offer and spends no random draws.
static func draw_offer(
	eligible: Array[BattleCardData], slots: int, rng: RandomNumberGenerator,
	preferred: StringName, affinity: float = PREFERRED_WEIGHT
) -> Array[StringName]:
	var offer: Array[StringName] = []
	if rng == null or slots < 1 or slots > eligible.size() or not is_finite(affinity) or affinity <= 0.0:
		return offer
	var seen := {}
	for card in eligible:
		if card == null or card.card_id == &"" or seen.has(card.card_id):
			return offer
		seen[card.card_id] = true

	var available := eligible.duplicate()
	available.sort_custom(func(a: BattleCardData, b: BattleCardData): return str(a.card_id) < str(b.card_id))
	var weights := {str(preferred): affinity}
	for slot in range(slots):
		var pick := _weighted_card(available, rng, weights)
		offer.append(pick.card_id)
		available.erase(pick)
	return offer


# This picker is taken verbatim from the game's card reward service.
static func _weighted_card(cards: Array[BattleCardData], rng: RandomNumberGenerator, weights: Dictionary) -> BattleCardData:
	var total := 0.0
	for card: BattleCardData in cards:
		total += maxf(0.001, float(weights.get(str(card.routine_id), 1.0)))
	var roll := rng.randf() * total
	for card: BattleCardData in cards:
		roll -= maxf(0.001, float(weights.get(str(card.routine_id), 1.0)))
		if roll < 0.0:
			return card
	return cards.back()
