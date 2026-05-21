# Archaic Quest — Vertical Slice Build Backlog

## Milestone 0 — Repo + Prototype Foundation

Goal: create a clean project that supports rapid testing.

Status: COMPLETE. See Gate M0 in `docs/acceptance-tests.md`.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M0-001 | Create Godot project repo | P0 | Repo has `project.godot` and opens in Godot 4.x |
| M0-002 | Add folder structure | P0 | `/scenes`, `/scripts`, `/data`, `/docs` exist |
| M0-003 | Add placeholder arena scene | P0 | Empty arena can run |
| M0-004 | Add debug overlay shell | P0 | Debug UI can display text values |
| M0-005 | Add reset/reload test key | P0 | Test scene reloads without editor restart |
| M0-006 | Add data folder resources | P0 | Weapons/enemies/materials/mods/events have starter data |
| M0-007 | Create EventBus singleton | P0 | Other systems can emit/subscribe to events |
| M0-008 | Create GameState singleton | P0 | Global test state persists during scene reload |

## Milestone 1 — Player Movement + Input Intent

Goal: implement the control spine.

Status: P0 COMPLETE. See Gate M1 in `docs/acceptance-tests.md`; P1 sprint/controller mapping remains deferred.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M1-001 | Implement WASD movement | P0 | Player moves predictably in arena |
| M1-002 | Implement mouse-facing | P0 | Character faces cursor direction |
| M1-003 | Implement Input → Intent layer | P0 | Gameplay reads intent actions, not raw inputs |
| M1-004 | Add dodge input | P0 | Dodge has cost and recovery |
| M1-005 | Add sprint input if needed | P1 | Sprint can be enabled/disabled by class |
| M1-006 | Add input buffering shell | P0 | Buffered inputs trigger only in valid windows |
| M1-007 | Add controller placeholder mapping | P1 | Basic controller actions map to same intents |
| M1-008 | Add movement debug readout | P1 | Debug panel shows velocity/facing/state |

## Milestone 2 — Combat Actor Foundation

Goal: make combat real before adding content.

Status: COMPLETE. See Gate M2 in docs/acceptance-tests.md.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M2-001 | Create CombatActor base class | P0 | Player/enemies share health/status hooks |
| M2-002 | Create HealthComponent | P0 | Damage and death events work |
| M2-003 | Create StaminaComponent | P0 | Spend/recover stamina works |
| M2-004 | Create ManaComponent | P1 | Mage resource foundation exists |
| M2-005 | Create HitboxComponent | P0 | Active hit windows can damage hurtboxes |
| M2-006 | Create HurtboxComponent | P0 | Actors receive validated hits |
| M2-007 | Create AttackStateMachine | P0 | Startup/active/recovery states exist |
| M2-008 | Implement startup / active / recovery | P0 | Attacks are readable and punishable |
| M2-009 | Add no-offensive-cancel recovery rule | P0 | Recovery cannot be bypassed by attack spam |
| M2-010 | Add hit-stop system | P0 | Successful heavy hits briefly pause impact |
| M2-011 | Add damage event logging | P1 | Debug log shows source, target, damage, status |

## Milestone 3 — Barbarian Combat Proof

Goal: prove weight and stagger with one class first.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M3-001 | Add Barbarian class data | P0 | Class loads from data file |
| M3-002 | Add Heavy Axe data | P0 | Wide cleave, high stagger, long recovery |
| M3-003 | Add Maul data | P0 | Narrow impact, very high stagger, slower startup |
| M3-004 | Implement stagger component | P0 | Stagger thresholds and micro-stagger work |
| M3-005 | Implement stamina attack costs | P0 | Misses and repeated attacks apply pressure |
| M3-006 | Implement weapon equip switching | P1 | Player can swap test weapons |
| M3-007 | Tune hit-stop and recovery | P0 | Heavy hits feel weighty; misses feel costly |

## Milestone 4 — Enemy Role AI V1

Goal: enemy behavior reads as role-based, not health-pool logic.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M4-001 | Create AIController base | P0 | Enemies can perceive, decide, act |
| M4-002 | Create ThreatModel | P0 | Threat accounts for damage, control, support pressure |
| M4-003 | Add Magma Brute | P0 | Slow heavy telegraphs, weak to flanking |
| M4-004 | Add Ash Scavenger | P0 | Lateral movement, hit-and-retreat behavior |
| M4-005 | Add Ember Tender | P0 | Supports allies and retreats behind bruisers |
| M4-006 | Add hazard avoidance placeholder | P1 | AI can avoid tagged hazard zones |
| M4-007 | Add short retreat behavior | P1 | Enemies can back off when pressured |
| M4-008 | Add formation test encounter | P0 | Brute + Scavenger + Tender pack works |

## Milestone 5 — Archer + Mage Differentiation

Goal: prove three classes stress different systems.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M5-001 | Add Archer class data | P0 | Archer loads and uses ranged weapons |
| M5-002 | Add Longbow | P0 | Long draw, high precision, strong weak-point damage |
| M5-003 | Add Shortbow | P0 | Faster draw, lower impact, better mobility |
| M5-004 | Implement projectile clarity | P0 | Arrows are readable and validated |
| M5-005 | Add Mage class data | P0 | Mage loads and uses mana |
| M5-006 | Add Fire Staff | P0 | Slower cast, controlled burn zones |
| M5-007 | Add Ember Focus | P0 | Faster casts, smaller AoE, higher mana pressure |
| M5-008 | Implement burn stacking | P0 | Burn uses intensity/decay logic |

## Milestone 6 — Inventory, Crafting, Durability

Goal: prove item behavior changes combat feel.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M6-001 | Create Inventory | P0 | Small backpack and quick belt exist |
| M6-002 | Add DurabilityComponent | P0 | Weapons lose durability through use/death |
| M6-003 | Add MaterialData resources | P0 | Six slice materials exist |
| M6-004 | Add ModData resources | P0 | Four slice mods exist |
| M6-005 | Create CraftingBench | P0 | Mods can be applied to weapons |
| M6-006 | Enforce mod tradeoffs | P0 | Every mod has a cost |
| M6-007 | Add crafting debug output | P1 | Craft results are logged and visible |

## Milestone 7 — World-State Loop

Goal: prove combat changes the world.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M7-001 | Create OuterCalderaState | P0 | Slice variables exist and update |
| M7-002 | Create EcologySystem | P0 | Overhunting fire beasts changes spawns |
| M7-003 | Create SettlementStateMachine | P0 | Cinderford can be Baseline/Alerted/Strained |
| M7-004 | Create FactionPressureSystem | P1 | Concord/Circle/Meridian/Uncontrolled values update |
| M7-005 | Create ControlNodeSystem | P0 | Blackglass Watchpost changes owner/state |
| M7-006 | Add vendor price/stock placeholder | P1 | Trade health affects visible vendor data |
| M7-007 | Add resurrection strain | P0 | Death updates strain and settlement/shrine response |

## Milestone 8 — Hollow Vent + Mini-Boss

Goal: cap the slice with a readable composite boss.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M8-001 | Build Hollow Vent Approach route | P0 | Short proto-dungeon route exists |
| M8-002 | Add parasite nest object | P0 | Nest supports boss/encounter pressure |
| M8-003 | Add Ash-Parasite Infested modifier | P0 | Modifier changes behavior and drops chitin |
| M8-004 | Add Forgemouth Parasite boss | P0 | Boss has phases and readable tells |
| M8-005 | Boss world-state outputs | P0 | Clean kill/nests/deaths/extraction update variables |
| M8-006 | Add resettable boss test | P0 | Boss can be restarted for tuning |

## Milestone 9 — Slice Acceptance

Goal: validate readiness before expansion.

| ID | Task | Priority | Done When |
|---|---|---|---|
| M9-001 | Combat feel pass | P0 | Hits heavy, misses punishing, telegraphs readable |
| M9-002 | Three-class differentiation pass | P0 | Classes feel structurally different |
| M9-003 | AI readability pass | P0 | Roles readable on sight and behavior |
| M9-004 | System interaction pass | P0 | Combat influences crafting/ecology/territory visibly |
| M9-005 | Death consequence pass | P0 | Death creates tension without rage-quit friction |
| M9-006 | Scope discipline pass | P0 | No out-of-scope features added |

