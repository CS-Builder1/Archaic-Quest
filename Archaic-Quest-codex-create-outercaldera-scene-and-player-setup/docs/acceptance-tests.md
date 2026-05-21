# Archaic Quest — Vertical Slice Acceptance Tests

## Gate M0 — Project Skeleton

Status: COMPLETE. Manual run verified 2026-05-19: project opens, arena runs, player marker is visible, movement/dodge input responds, and the debug overlay reports state/velocity/facing/intent.

- [x] Godot project opens with `OuterCaldera` as the main scene.
- [x] `OuterCaldera` placeholder arena scene exists and runs locally.
- [x] Player scene exists and is wired to `PlayerController` and `PlayerInputIntent`.
- [x] Player scene has a visible facing marker and collision shape for local tuning.
- [x] Debug overlay shell is visible and reports movement/intent state.


## Gate M1 — Input Intent Lock + State Gating

Status: COMPLETE. Manual run verified 2026-05-19: PlayerInputIntent remains the only physical input collector, player state transitions are explicit, attack/dodge inputs buffer, and dodge cannot bypass attack recovery.

- [x] `PlayerInputIntent` is the sole physical input collection layer for player gameplay actions.
- [x] Player state constants/enum exist for movement, attack windows, dodge, and recovery gates.
- [x] `can_move()`, `can_dodge()`, `can_start_attack()`, and `can_buffer_attack()` are implemented and actively used.
- [x] Primary attack and dodge input buffering exists with a short timeout.
- [x] Dodge cannot bypass attack recovery via direct or buffered inputs.
- [x] Debug overlay shows current state, facing direction, move vector, and buffered action.

## Gate A — Combat Greenlight

The build cannot move beyond single-class combat until these pass.

- [ ] Player attacks have startup, active, and recovery phases.
- [ ] Recovery cannot be offensively cancelled.
- [ ] Heavy hits produce visible hit-stop.
- [ ] Micro-stagger is readable and does not feel random.
- [ ] Misses create punishable recovery.
- [ ] Stamina prevents attack spam.
- [ ] Dodge has cost, direction, and recovery.
- [ ] One major mistake costs meaningful health.
- [ ] Debug panel shows player state, stamina, health, current weapon, and attack phase.

## Gate B — Rule Integrity

- [ ] Status effects are routed through a shared status component.
- [ ] Burn uses intensity/decay logic.
- [ ] Stagger uses threshold logic.
- [ ] Buff/debuff hooks exist even if only minimally used.
- [ ] No enemy, elite, or boss has hidden immunity logic.

## Gate C — Three-Class System Collision

- [ ] Barbarian feels weighty and punishable.
- [ ] Archer depends on spacing, line-of-sight, and aim timing.
- [ ] Mage depends on cast windows, mana pressure, and AoE placement.
- [ ] Each class has two weapons.
- [ ] Each weapon changes timing, recovery, resource pressure, or threat behavior.

## Gate D — AI Readability

- [ ] Magma Brute reads as slow, heavy, high-commitment pressure.
- [ ] Ash Scavenger reads as lateral, disruptive, and evasive.
- [ ] Ember Tender reads as support and retreat-priority behavior.
- [ ] Enemy tells are visible before damage.
- [ ] Support protection behavior works.
- [ ] Skirmishers punish tunnel vision.
- [ ] AI behavior is not just nearest-target aggro.

## Gate E — Item / Crafting Proof

- [ ] Six materials exist and are collectible/testable.
- [ ] Four mods exist and can be applied.
- [ ] Every mod has a tradeoff.
- [ ] Crafting changes combat behavior, not just damage number.
- [ ] Durability changes through use or death.
- [ ] Debug output shows mod effects and durability.

## Gate F — World-State Proof

- [ ] Outer Caldera world variables exist.
- [ ] Fire-beast overhunting changes spawn mix.
- [ ] Cinderford Watch can shift from Baseline to Alerted or Strained.
- [ ] Resurrection strain increases on death.
- [ ] Blackglass Watchpost ownership affects route/vendor/faction variables.
- [ ] World-state changes are visible through UI, debug, NPC text, stock, prices, or enemy composition.

## Gate G — Mini-Boss Proof

- [ ] Forgemouth Parasite uses readable phases.
- [ ] Parasite nests create priority pressure.
- [ ] Boss obeys global combat/status rules.
- [ ] Boss does not use hidden immunity.
- [ ] Boss output changes world-state variables.
- [ ] Boss can be reset for repeated tuning.

## Slice Pass / Fail

The slice passes only if all are true:

1. Hits feel heavy.
2. Misses feel punishing but fair.
3. Enemy roles are readable on sight and behavior.
4. Three classes feel structurally different.
5. Crafting creates behavior-changing choices.
6. Death creates tension without rage-quit punishment.
7. At least one world reaction is visible without reading documentation.
8. No out-of-scope MMO features were added before the slice proved weight, clarity, and consequence.

