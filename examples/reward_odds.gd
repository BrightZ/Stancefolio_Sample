extends SceneTree
## A balance probe, not a combat simulation. Reset the four-card pool for each
## first draw. Both experiments consume the same sequence of random numbers.

const Rewards = preload("res://rules/card_rewards.gd")
const TRIALS := 10_000
const SEED_VALUE := 7341
const PREFERRED := &"blade"
const PREFERRED_CARD := &"reed_cut"


static func pool() -> Array[Rewards.BattleCardData]:
	return [
		Rewards.BattleCardData.new(PREFERRED_CARD, PREFERRED),
		Rewards.BattleCardData.new(&"river_step", &"footwork"),
		Rewards.BattleCardData.new(&"palm_guard", &"palm"),
		Rewards.BattleCardData.new(&"stone_palm", &"palm"),
	]


static func preferred_first_draws(weight: float) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_VALUE
	var eligible := pool()
	var hits := 0
	for trial in range(TRIALS):
		var offer := Rewards.draw_offer(eligible, 1, rng, PREFERRED, weight)
		if offer.size() != 1:
			return -1
		if offer[0] == PREFERRED_CARD:
			hits += 1
	return hits


func _initialize() -> void:
	print("First draw only | 1 preferred card, 3 others | seed %d" % SEED_VALUE)
	for weight: float in [1.0, Rewards.PREFERRED_WEIGHT]:
		var hits := preferred_first_draws(weight)
		if hits < 0:
			printerr("The reward rule returned an incomplete offer.")
			quit(1)
			return
		print("%.1fx: %d/%d preferred = %.2f%% (expected %.2f%%)" % [
			weight, hits, TRIALS, 100.0 * hits / TRIALS, 100.0 * weight / (weight + 3.0)])
	quit(0)
