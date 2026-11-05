# Stancefolio: Gameplay Design and Testing

[![Gameplay checks](https://github.com/BrightZ/Stancefolio_Sample/actions/workflows/gameplay-checks.yml/badge.svg?branch=main)](https://github.com/BrightZ/Stancefolio_Sample/actions/workflows/gameplay-checks.yml)

Stancefolio is a martial arts deckbuilder made with Godot. These GDScript samples show how I tested two design decisions about combat and card rewards.

| Sample | What it does | Where to start |
| --- | --- | --- |
| [Tempered Edge](docs/tempered-edge.md) | The greatsword banks unspent Qi (the energy used to play cards). Every target hit by the next qualifying strike gets the damage bonus. | Read the [two-turn playtest in `tests/run.gd`](tests/run.gd#L51), then follow the [greatsword rule](rules/tempered_edge.gd). |
| [Card rewards](docs/card-rewards.md) | Within a rarity tier, cards that match the character's preferred style get double weight. A three-card offer can still include other styles. | Start with the [weighted draw in `card_rewards.gd`](rules/card_rewards.gd#L43), then open the [odds experiment](examples/reward_odds.gd). |

## My role

I used AI to help write the GDScript and automated tests. I made the gameplay decisions, reproduced problems during playtesting, and checked the fixes against the behavior I expected.

- For the **greatsword**, I changed the free stack from a one-time bonus at the start of combat to one gained every player turn. My check was to spend the opening stack and end the turn with two Qi. The two banked stacks should survive the enemy turn and become three when the player acts again.
- For **card rewards**, I chose to favor the character's style while keeping mixed builds viable. In a pool with one matching card and three others, doubling its weight should raise its chance on the first draw from 25% to 40%. The experiment checks that prediction over 10,000 draws per setting using a fixed seed.

## Run the checks

Both samples run independently of the full game. The only prerequisite is the [standard edition of Godot 4.6.3](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable). The combat tests supply the turns and hits, and the reward experiment supplies its own four-card pool.

Run these commands from the directory containing `project.godot`.

```sh
godot --headless --path . --script res://tests/run.gd
godot --headless --path . --script res://examples/reward_odds.gd
```

On Windows, use the Godot console executable if `godot` is not on your PATH. The [test suite](tests/run.gd) prints one line per case and exits with a nonzero status on failure. A passing run ends with `9 cases | 0 failed checks`. The [second script](examples/reward_odds.gd) prints the observed and expected reward probabilities.
