# Archaic Quest — Vertical Slice Brief

## Purpose

This build is the first playable proof of Archaic Quest. It is not the full MMORPG. It exists to answer one question:

> Can Archaic Quest feel alive, dangerous, readable, and systemic at small scale before expansion?

## Build Strategy

Build a single-player local Godot 4.x prototype first. No networking, no accounts, no broad open world.

## Slice Identity

### Region

**Ashen Scar — Outer Caldera**

A compact volcanic frontier where Embersteel extraction, fire-beast ecology, ash parasites, resurrection strain, and faction pressure collide.

### Core Theme

**Power leaves ash behind.**

Every advantage should have a cost:

- stronger weapons require dangerous materials,
- mining Embersteel strains the region,
- overhunting fire beasts shifts enemy composition,
- repeated deaths strain resurrection,
- controlling Blackglass Watchpost changes settlement economics,
- faction help creates tradeoffs.

## Required Spaces

| Space | Purpose |
|---|---|
| Cinderford Watch | settlement hub, vendor, blacksmith, shrine, rumors |
| Outer Road | basic travel and patrol behavior |
| Fire-Beast Grounds | ecology loop and combat farming test |
| Ash Scavenger Field | enemy shift after overhunting |
| Embersteel Vein | resource depletion and faction pressure |
| Blackglass Watchpost | territory/control-node test |
| Hollow Vent Approach | proto-field dungeon route |
| Mini-Boss Arena | combat capstone and world-state output |
| Recovery Shrine | death/resurrection strain test |
| Crafting Bench | material-to-behavior loop |

## Map Flow

```text
Cinderford Watch
→ Outer Road
→ Fire-Beast Grounds
→ Embersteel Vein
→ Blackglass Watchpost
→ Hollow Vent Approach
→ Mini-Boss Arena
→ Return to Cinderford Watch
```

The return to town matters. The player must see Cinderford Watch respond.

## Playable Classes

| Class | Slice Purpose | Weapons |
|---|---|---|
| Barbarian | impact, hit-stop, stagger, recovery punishment | Heavy Axe, Maul |
| Archer | projectile clarity, spacing, weak-point targeting | Longbow, Shortbow |
| Mage | AoE, burn stacking, cast commitment, mana pressure | Fire Staff, Ember Focus |

## Enemy Package

| Role | Enemy | Purpose |
|---|---|---|
| Bruiser | Magma Brute | teaches spacing, stagger, commitment |
| Skirmisher | Ash Scavenger | punishes tunnel vision and ranged comfort |
| Support | Ember Tender | protects enemies, extends fights, forces priority |

## Elite Modifier

### Ash-Parasite Infested

Behavior changes:

- parasite burst on stagger break,
- hazard on death,
- nearby scavengers become more aggressive,
- drops Parasite Chitin,
- raises ecology pressure if ignored.

This is behavior change, not a health increase.

## Mini-Boss

### The Forgemouth Parasite

Composite boss:

- Bruiser body,
- controller-lite hazard output,
- parasite nest support relationship,
- obeys global combat/status rules.

## Six Slice Materials

| Material | Source | Use |
|---|---|---|
| Embersteel | vein / mini-boss cache | weapon impact mods |
| Ash Resin | fire-beast grounds | burn coating |
| Magma Bone | Magma Brute / beast remains | stagger mods |
| Blackglass Shard | mine / watchpost | precision edge mods |
| Parasite Chitin | ash parasite enemies | risky durability tradeoff |
| Scorched Hide | fire beasts | armor / guarding mod |

## Four Slice Mods

| Mod | Effect | Tradeoff |
|---|---|---|
| Ember Temper | adds burn buildup | weapon durability drains faster |
| Bone-Weighted Head | increases stagger | slower recovery |
| Blackglass Edge | increases weak-point damage | lower block durability |
| Chitin Binding | lowers stamina cost slightly | parasite flaw risk under high ecology pressure |

## World-State Variables

```yaml
outer_caldera_state:
  ecology_pressure: 50
  threat_density: 50
  trade_health: 50
  resurrection_strain: 25
  embersteel_supply: 50
  fire_beast_population: 50
  ash_scavenger_pressure: 20
  black_market_pressure: 0
  faction_pressure:
    concord: 20
    circle: 35
    meridian: 25
    uncontrolled: 40
  control_node_owner: UNCONTROLLED
  settlement_state: BASELINE
  dungeon_state: DORMANT
```

Every variable must eventually surface through gameplay, UI, NPC behavior, vendor stock, prices, enemy mix, or debug tools.

## Explicitly Out of Scope

- full MMO networking,
- full PvP,
- full faction progression,
- races and racial trees,
- more than three playable classes,
- relics, mythics, major world shifts,
- continent travel,
- housing, guilds, raids, live ops,
- broad open world.

## Slice Acceptance

The slice passes only when:

- combat feels heavy and fair,
- all three classes feel structurally different,
- enemy roles are readable on sight,
- at least one combat → crafting/ecology/territory loop is visible,
- death creates tension without rage-quit punishment,
- the build can be reset, debugged, and repeatedly tested.

