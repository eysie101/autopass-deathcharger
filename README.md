# AutoPassDeathcharger

![AutoPassDeathcharger](https://raw.githubusercontent.com/eysie101/autopass-deathcharger/assets/icon.png) ![Manual: Heavy Frostweave Bandage](https://raw.githubusercontent.com/eysie101/autopass-deathcharger/assets/icon-manual.png)
<img width="378" height="21" alt="image" src="https://github.com/user-attachments/assets/cc2dea35-1aa1-4284-96da-e6ed000324d0" />

WoW 3.3.5a addon. It passes every loot roll on the items of its list and hides that roll's window. The list starts
with Reins of the Naxxramas Deathcharger (item 23193) and Manual: Heavy Frostweave Bandage (item 39152).

Option to add/remove own items to the AutoPass list.

```
/autopass add <itemID|link>      add an item to the list
/autopass remove <itemID|link>   remove an item from the list
/autopass list                   print the list
/autopass last                   window: last 6 rolled items, tooltip on mouseover, Add
```

The same in ESC > Interface > AddOns > AutoPassDeathcharger.

## Changes

- 1.2.0: own item list, `/autopass`, options page, window with the last 6 rolled items.
- 1.1.1: no chat line when a roll is passed (a commented-out line in the Lua file brings it back).
- 1.1.0: Manual: Heavy Frostweave Bandage (39152) is passed too.

## Install

Copy the folder `AutoPassDeathcharger` into `<WoW folder>\Interface\AddOns`.
