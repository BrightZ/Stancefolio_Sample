# Tempered Edge: banking Qi for a later strike

[Implementation](../rules/tempered_edge.gd) · [Playtest regression](../tests/run.gd#L51) · [Multi-target regression](../tests/run.gd#L101)

Qi is the resource a player spends to play cards. The greatsword gives unspent Qi a second use: at the end of the player's turn, each remaining point adds one stack of *Tempered Edge*. Each player turn also starts by adding one stack, up to a total of three. The first qualifying damage segment of an actively played technique consumes the reserve for +50% damage per stack.

## The playtest that became a test

If the player finishes a turn with two Qi, how many stacks should the next turn show? Follow the case where the player has already spent the opening stack:

| Event | Stacks after the event | Effect |
| --- | ---: | --- |
| The player's first turn begins | 1 | The opening stack is available immediately. |
| A technique deals 6 base damage | 0 | The hit becomes 9 before other modifiers. |
| The player ends the turn with 2 Qi | 2 | Both unspent points are banked. |
| The enemy takes its turn | 2 | Enemy turn hooks leave the player's reserve alone. |
| The player's next turn begins | 3 | The new stack adds to the banked two. |
| Another technique deals 6 base damage | 0 | The hit becomes 15. |

The regression checks the intermediate values as well as the final hit. It also covers keeping the opening stack: saving two Qi still gives three stacks next turn, never four. A separate [zero-Qi case](../tests/run.gd#L71) checks that spending everything still leaves the player with the next turn's baseline stack.

## One sweep, two targets

Suppose one damage segment hits two enemies. Both need the same multiplier, but only one hit should report spending the stacks. If the card then deals a *second* damage segment, that segment should receive no bonus.

[`damage_multiplier`](../rules/tempered_edge.gd#L33) remembers the action ID, effect key and segment index that spent the reserve. Target ID is deliberately absent. The [test](../tests/run.gd#L101) checks the multiplier and the consumption flag separately. [Eligibility tests](../tests/run.gd#L83) verify that damage over time, reflected damage and repeated card effects cannot spend the reserve before a direct or piercing technique hit.

**Scope:** This is the greatsword branch isolated from the game's character-trait runtime, with its normal parameters fixed as constants. It returns a damage modifier; target selection, armor and HP settlement belong to the full combat engine.
