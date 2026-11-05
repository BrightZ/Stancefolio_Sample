extends SceneTree
## No test addon or editor import step. A failed expectation or unfinished
## case returns a nonzero process status, both locally and in CI.

const Edge = preload("res://rules/tempered_edge.gd")
const Rewards = preload("res://rules/card_rewards.gd")
const Probe = preload("res://examples/reward_odds.gd")
const P := &"player"
const E := &"enemy"

var failures := 0


func _initialize() -> void:
	var cases: Array[Callable] = [
		opening_strike, banked_qi_playtest, recharge_without_saving_qi,
		ineligible_damage, one_segment_many_targets, unique_offers,
		replay_from_checkpoint, invalid_offers_spend_no_rng, affinity_odds,
	]
	for test in cases:
		var before := failures
		if test.call() != true:
			failures += 1
			printerr("Case did not finish: ", test.get_method())
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("%d cases | %d failed checks" % [cases.size(), failures])
	quit(0 if failures == 0 else 1)


func equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures += 1
		printerr("  %s: expected %s, got %s" % [message, str(expected), str(actual)])


func move(action: int, effect: StringName = &"cut", segment: int = 0) -> Dictionary:
	return {"card_type": Edge.CardType.MOVE, "execution_kind": &"CARD_PLAY",
		"active_card_play": true, "action_id": action, "effect_key": effect, "segment_index": segment}


func opening_strike() -> bool:
	var edge := Edge.new()
	edge.begin_turn(P)
	var first := edge.damage_multiplier(P, Edge.Damage.DIRECT, move(1), 6.0)
	equal(6.0 * first.get("multiplier", 1.0), 9.0, "opening six-damage strike")
	equal(edge.stacks, 0, "opening reserve was spent")
	equal(edge.damage_multiplier(P, Edge.Damage.DIRECT, move(2), 6.0), {}, "next card has no bonus")
	return true


func banked_qi_playtest() -> bool:
	# Playtest reproduction: end with two Qi, then inspect the next player's turn.
	# Try both spending the opening stack and keeping it. Neither may exceed 3.
	for spend_opening in [false, true]:
		var edge := Edge.new()
		edge.begin_turn(P)
		if spend_opening:
			edge.damage_multiplier(P, Edge.Damage.DIRECT, move(1), 6.0)
		edge.end_turn(P, 2)
		equal(edge.stacks, 2 if spend_opening else 3, "banked before the enemy acts")
		edge.begin_turn(E)
		edge.end_turn(E, 3)
		equal(edge.stacks, 2 if spend_opening else 3, "enemy cannot charge the reserve")
		edge.begin_turn(P)
		equal(edge.stacks, 3, "incoming turn, capped at three")
		var next := edge.damage_multiplier(P, Edge.Damage.DIRECT, move(2), 6.0)
		equal(6.0 * next.get("multiplier", 1.0), 15.0, "banking changes the next strike")
	return true


func recharge_without_saving_qi() -> bool:
	var edge := Edge.new()
	edge.begin_turn(P)
	edge.damage_multiplier(P, Edge.Damage.DIRECT, move(1), 6.0)
	edge.end_turn(P, 0)
	edge.begin_turn(E)
	equal(edge.stacks, 0, "no free stack on the enemy turn")
	edge.begin_turn(P)
	equal(edge.stacks, 1, "baseline replenishes even on later turns")
	return true


func ineligible_damage() -> bool:
	var edge := Edge.new()
	edge.begin_turn(P)
	var active := move(1)
	# These events happen in combat too, but must not steal the player's bonus.
	for kind in [Edge.Damage.DOT, Edge.Damage.REFLECT]:
		equal(edge.damage_multiplier(P, kind, active, 6.0), {}, "indirect damage")
	for changes in [{"card_type": Edge.CardType.MOVEMENT}, {"execution_kind": &"CARD_REPEAT"},
			{"active_card_play": false}, {"action_id": 0}]:
		equal(edge.damage_multiplier(P, Edge.Damage.DIRECT, active.merged(changes, true), 6.0), {}, str(changes))
	equal(edge.damage_multiplier(E, Edge.Damage.DIRECT, active, 6.0), {}, "enemy hit")
	equal(edge.damage_multiplier(P, Edge.Damage.DIRECT, active, 0.0), {}, "zero amount")
	equal(edge.stacks, 1, "reserve survives every ineligible event")
	var pierce := edge.damage_multiplier(P, Edge.Damage.PIERCE, active, 6.0)
	equal(pierce, {"multiplier": 1.5, "stacks": 1, "consumed": true}, "piercing technique qualifies")
	return true


func one_segment_many_targets() -> bool:
	var edge := Edge.new()
	edge.begin_turn(P)
	var sweep := move(12, &"sweep", 0)
	var first := edge.damage_multiplier(P, Edge.Damage.DIRECT, sweep.merged({"target": &"front"}), 6.0)
	var second := edge.damage_multiplier(P, Edge.Damage.DIRECT, sweep.merged({"target": &"back"}), 6.0)
	equal(first, {"multiplier": 1.5, "stacks": 1, "consumed": true}, "first target spends reserve")
	equal(second, {"multiplier": 1.5, "stacks": 0, "consumed": false}, "same sweep, second target")
	for segment in [move(12, &"sweep", 1), move(12, &"thrust", 0), move(13, &"sweep", 0)]:
		equal(edge.damage_multiplier(P, Edge.Damage.DIRECT, segment, 6.0), {}, "different segment/effect/action")
	return true


func unique_offers() -> bool:
	var pool := Probe.pool()
	var original := pool.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	for offer_number in range(40):
		var ids := Rewards.draw_offer(pool, 3, rng, Probe.PREFERRED)
		var unique := {}
		for id in ids:
			unique[id] = true
			equal(id in [&"reed_cut", &"river_step", &"palm_guard", &"stone_palm"], true, "legal candidate")
		equal(ids.size(), 3, "offer size")
		equal(unique.size(), 3, "no duplicate card within an offer")
	equal(pool, original, "drawing does not reorder or deplete the catalogue")
	return true


func replay_from_checkpoint() -> bool:
	var pool := Probe.pool()
	var reversed := pool.duplicate()
	reversed.reverse()
	var live := RandomNumberGenerator.new()
	live.seed = 81
	Rewards.draw_offer(pool, 3, live, Probe.PREFERRED)
	var resumed := RandomNumberGenerator.new()
	resumed.seed = 81
	resumed.state = live.state
	for i in range(8):
		equal(Rewards.draw_offer(reversed, 3, resumed, Probe.PREFERRED),
			Rewards.draw_offer(pool, 3, live, Probe.PREFERRED), "offer after reload, reordered catalogue")
	equal(resumed.state, live.state, "both sessions end at the same RNG checkpoint")
	return true


func invalid_offers_spend_no_rng() -> bool:
	var pool := Probe.pool()
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	var checkpoint := rng.state
	equal(Rewards.draw_offer(pool, 5, rng, Probe.PREFERRED).is_empty(), true, "too few candidates")
	pool.append(Rewards.BattleCardData.new(Probe.PREFERRED_CARD, &"another_routine"))
	equal(Rewards.draw_offer(pool, 3, rng, Probe.PREFERRED).is_empty(), true, "duplicate ID, distinct objects")
	equal(rng.state, checkpoint, "invalid requests leave RNG untouched")
	return true


func affinity_odds() -> bool:
	# Compare only the first slot, with replacement BETWEEN offers. Later slots
	# have different odds because the previously offered card is unavailable.
	var neutral := float(Probe.preferred_first_draws(1.0)) / Probe.TRIALS
	var biased := float(Probe.preferred_first_draws(Rewards.PREFERRED_WEIGHT)) / Probe.TRIALS
	equal(absf(neutral - 0.25) < 0.015, true, "neutral: expected 25%%, observed %.2f%%" % (100.0 * neutral))
	equal(absf(biased - 0.40) < 0.015, true, "affinity: expected 40%%, observed %.2f%%" % (100.0 * biased))
	return true
