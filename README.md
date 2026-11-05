# Stancefolio: Gameplay Design and Testing

[![Gameplay checks](https://github.com/BrightZ/Stancefolio_Sample/actions/workflows/gameplay-checks.yml/badge.svg?branch=main)](https://github.com/BrightZ/Stancefolio_Sample/actions/workflows/gameplay-checks.yml)

Stancefolio is a martial arts deckbuilder made with Godot. These two GDScript samples show how a player-facing rule becomes a piece of code, and how to tell when a change has broken it.

| Sample | Design question | Implementation |
| --- | --- | --- |
| [Tempered Edge: banking Qi](docs/tempered-edge.md) | What makes ending a turn with energy left over a useful choice? | [Greatsword trait](rules/tempered_edge.gd) |
| [Card rewards: weighting a combat style](docs/card-rewards.md) | How can rewards favor a character's style while leaving room for other builds? | [Weighted picker and offer](rules/card_rewards.gd) |

The first sample includes a regression from playtesting. The second includes a fixed-seed experiment that compares the intended reward odds with 10,000 draws per setting. The sample runs without the game, its assets, Steam, or any plugins.

## Run the checks

Use the standard edition of [Godot 4.6.3](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable). From the directory containing `project.godot`, run:

```sh
godot --headless --path . --script res://tests/run.gd
godot --headless --path . --script res://examples/reward_odds.gd
```

On Windows, use the Godot console executable if `godot` is not on your PATH. The [test suite](tests/run.gd) prints one line per case and exits with a nonzero status on failure. A passing run ends with `9 cases | 0 failed checks`. The [second script](examples/reward_odds.gd) prints the observed and expected reward probabilities.
