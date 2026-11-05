# Card rewards: favor a style without guaranteeing a card

[Implementation](../rules/card_rewards.gd) · [Runnable experiment](../examples/reward_odds.gd) · [Probability test](../tests/run.gd#L160)

Card rewards help a character build around a preferred combat style. A forced slot would guarantee a matching card even in a pool dominated by other styles. Stancefolio instead changes the weight of each matching card *after* eligibility and rarity have been determined.

## What does double weight buy?

Take a pool of four eligible cards of the same rarity. Only one matches the character's preferred style. With equal weights, its chance on the first draw is 1/4. Giving it a weight of 2 makes that chance 2/(2+1+1+1), or **40%**.

| Weight of the preferred card | Expected first-slot chance | Observed in 10,000 offers |
| --- | ---: | ---: |
| 1 (control) | 25% | 2,478 / 10,000 = 24.78% |
| 2 (game rule) | 40% | 3,975 / 10,000 = 39.75% |

To reproduce the table on Godot 4.6.3, run this from the repository root:

```sh
godot --headless --path . --script res://examples/reward_odds.gd
```

Each run starts with seed `7341`. The four-card pool resets for each offer; the random stream advances. The [probability test](../tests/run.gd#L160) allows 1.5 percentage points of sampling variation around each theoretical value. The table describes the first slot only: once a card has been drawn, later slots use a smaller pool.

## What can break besides the odds?

- **Duplicates:** [The offer test](../tests/run.gd#L114) draws three cards at a time. Each offer must contain three distinct, eligible IDs, and the caller's catalogue must remain intact.
- **Replay:** [The checkpoint test](../tests/run.gd#L131) restores the random state, reverses the input catalogue, then compares eight more offers and the final random state. Sorting candidates by ID before the draw makes replay independent of catalogue order.
- **Invalid input:** [The rejection test](../tests/run.gd#L148) passes an undersized pool and a duplicate ID. Neither request may advance the random stream and change the player's next valid reward.

**Scope:** [`_weighted_card`](../rules/card_rewards.gd#L43) is the original picker from the game's reward service. The four card records are fictional. The small [offer wrapper](../rules/card_rewards.gd#L19) demonstrates selection without replacement in one rarity tier; it does not reproduce the game's full catalogue, unlocks or rarity selection.
