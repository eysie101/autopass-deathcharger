# AutoPassDeathcharger

![AutoPassDeathcharger](icon.png) ![Manual: Heavy Frostweave Bandage](icon-manual.png)
<img width="378" height="21" alt="image" src="https://github.com/user-attachments/assets/cc2dea35-1aa1-4284-96da-e6ed000324d0" />

WoW 3.3.5a addon. It passes every loot roll on Reins of the Naxxramas Deathcharger (item 23193) and on Manual: Heavy
Frostweave Bandage (item 39152, the bind-on-pickup First Aid book that teaches Heavy Frostweave Bandage) and hides
that roll's window. It does nothing else and has no settings.

## Changes

- 1.1.1: no chat line when a roll is passed (a commented-out line in the Lua file brings it back).
- 1.1.0: Manual: Heavy Frostweave Bandage (39152) is passed too.

## Install

1. Copy the folder `AutoPassDeathcharger` into `<WoW folder>\Interface\AddOns`.
2. Start WoW. A new addon is read at client start, not at `/reload`.

## Remove

Delete the folder `AutoPassDeathcharger`.
