# AutoMacro

A World of Warcraft Classic addon that automatically creates per-character **mouseover macros** for your class's heals, dispels, buffs, resurrections and crowd control.

When you log in or learn a new spell, AutoMacro checks which supported spells you know and creates a macro for each one that doesn't already have a mouseover macro. Macros cast by spell name without a rank, so they always use the highest rank you know.

## Features

- Creates macros like `@Flash Heal` with `#showtooltip` and sensible targeting:
  - **Heals, dispels, buffs:** mouseover friendly → current friendly target → yourself
  - **Resurrections:** mouseover dead friendly → dead friendly target
  - **Crowd control:** mouseover enemy → current enemy target
- Skips spells that already have a mouseover macro (account or character), so it won't duplicate your own macros.
- Runs automatically on login and when your spellbook changes; waits until combat ends if needed.
- Hides the `@` prefix in action bar labels, so buttons show `Flash Heal` instead of `@Flash Heal`.
- Spell lookup by spell ID, so it works with any client language.

## Supported classes

| Class   | Spells |
|---------|--------|
| Priest  | Lesser Heal, Heal, Greater Heal, Flash Heal, Renew, Power Word: Shield, Dispel Magic, Cure Disease, Abolish Disease, Power Word: Fortitude, Divine Spirit, Shadow Protection, Fear Ward, Resurrection |
| Druid   | Healing Touch, Regrowth, Rejuvenation, Swiftmend, Remove Curse, Cure Poison, Abolish Poison, Mark of the Wild, Thorns, Innervate, Revive, Rebirth, Entangling Roots |
| Paladin | Holy Light, Flash of Light, Holy Shock, Lay on Hands, Purify, Cleanse, Blessings (Might, Wisdom, Kings, Salvation, Light, Sanctuary, Protection, Freedom, Sacrifice), Redemption |
| Shaman  | Healing Wave, Lesser Healing Wave, Chain Heal, Cure Poison, Cure Disease, Water Walking, Water Breathing, Ancestral Spirit |
| Mage    | Remove Lesser Curse, Arcane Intellect, Amplify Magic, Dampen Magic |
| Warlock | Unending Breath, Detect Invisibility |

## Installation

1. Download `AutoMacro-<version>.zip` from the [latest release](../../releases/latest).
2. Extract it into your `World of Warcraft/_forever_/Interface/AddOns/` folder, so you end up with `Interface/AddOns/AutoMacro/AutoMacro.toc`.
3. Restart the game or `/reload`.

## Usage

| Command | Description |
|---------|-------------|
| `/am` or `/am run` | Generate missing macros now |
| `/am list` | List your class's supported spells, whether you know them and whether they're skipped |
| `/am skip <short name>` | Toggle skipping a spell, e.g. `/am skip Thorns` (use the name shown by `/am list` without the `@`) |
| `/am off` | Disable automatic generation (manual `/am run` still works) |
| `/am on` | Re-enable automatic generation |

`/automacro` works as an alias for `/am`.

## Notes

- Macros are created as **character** macros. If your character macro slots are full, AutoMacro tells you which macros couldn't be created.
- Settings (disabled state and skip list) are saved per character.
- AutoMacro never edits or deletes existing macros. To regenerate one, delete it and run `/am`.
