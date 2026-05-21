# AGENTS.md — Archaic Quest Codex Instructions

## Mission

Build the Archaic Quest vertical slice as a small, playable Godot 4.x local prototype. Do not expand into full MMO systems, networking, account systems, broad open-world content, full races, relics, world shifts, or live-service features yet.

## Prime Build Law

Combat comes first. If combat weight, readability, punishment, or fairness degrades, stop feature expansion and fix combat.

## Required Slice Proof

The prototype must prove:

1. Weighty level-1 combat.
2. Input routed through intent, not raw input directly driving gameplay actions.
3. Startup / active / recovery attack windows.
4. Hit-stop and micro-stagger.
5. Stamina pressure and dodge discipline.
6. Three structurally distinct classes: Barbarian, Archer, Mage.
7. Two weapons per class.
8. Three enemy roles: Bruiser, Skirmisher, Support.
9. Threat-not-aggro AI behavior.
10. One elite modifier: Ash-Parasite Infested.
11. One mini-boss: The Forgemouth Parasite.
12. One visible world-state loop from combat into crafting, ecology, settlement, or territory.

## Technical Direction

- Engine target: Godot 4.x.
- Language: GDScript unless there is a strong reason otherwise.
- Prototype camera: top-down or isometric.
- Build locally first; no networking in V1.
- Prefer data-driven Resources for weapons, enemies, materials, mods, and events.
- Keep systems modular and testable.

## Architecture Rules

- No gameplay script should read raw input except the input/intent layer.
- Combat actions must pass through state validation.
- Attack timing must use explicit startup, active, and recovery windows.
- Bosses and elites must obey the same status/control rules as normal enemies.
- No hidden immunities.
- No stat-stick rewards. Items should alter behavior or tradeoffs.
- World variables must have visible or playable outputs.

## Scope Locks

Do not implement in V1:

- full MMO networking
- accounts/login
- guilds
- full PvP
- full race trees
- more than Barbarian, Archer, Mage
- relics or mythics
- major world shifts
- continent travel
- broad open world
- full quest chains

## Milestone Order

1. Repo and Godot project skeleton.
2. Empty playable arena and debug overlay.
3. Player movement, mouse-facing, input intent layer.
4. Combat actor foundation.
5. Barbarian heavy axe and maul.
6. Hit-stop, stagger, stamina, dodge.
7. Bruiser enemy.
8. Skirmisher and Support enemy.
9. Archer and Mage class implementation.
10. Inventory, durability, crafting bench.
11. World-state variables and visible outputs.
12. Blackglass Watchpost node.
13. Hollow Vent Approach and Forgemouth Parasite.
14. Acceptance test pass.

## Quality Bar

A feature is not done until it has:

- a debug readout or test scene support,
- clear player-facing feedback,
- no hardcoded one-off logic where a data-driven path is practical,
- an acceptance test listed or updated in `docs/acceptance-tests.md`.

