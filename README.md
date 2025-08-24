# TotemBar (Vanilla / Turtle WoW)

A lightweight addon for Shaman players on Vanilla 1.12 clients (including [Turtle WoW](https://turtle-wow.org/)) that makes it easy to manage a single "one-press" macro for dropping your chosen totems.

## Features

- Simple **4-button UI**: one square for each element (Earth, Fire, Water, Air).
- Click an element button to pick from the totems of that type you have learned.
- The button updates to show the **icon of your chosen totem** (or the element name if none is selected).
- The addon automatically builds a **single macro** (`TotemDrop`) that:
  1. Casts **Totemic Recall** (if you know it).
  2. Casts your selected **Fire**, **Earth**, **Water**, and **Air** totems, in that order.

No need to maintain custom macros by hand — the addon keeps it up-to-date whenever you change your selections or learn new spells.

---

## Installation

1. Download/clone this repository.
2. Copy the folder into your WoW client’s `Interface/AddOns/` directory.
3. Restart (or `/reload`) the game.
4. Enable **TotemBar** from the AddOns menu at the character select screen.

---

## Usage

1. Type `/totembar show` if the UI is hidden.  
   - You can drag the frame around; its position is remembered per character.
2. Click each element button (Earth, Fire, Water, Air) and choose the totem you want.
3. The addon will **auto-update** the macro named **TotemDrop** in your **character-specific macros**.
4. Open the game’s **Macro UI**, drag **TotemDrop** onto your action bar, and bind it to a hotkey.

Pressing that macro will recall existing totems and immediately drop your chosen set.

---

## Screenshots

### Empty UI (no totems chosen)
![Empty TotemBar UI](docs/screenshots/empty-ui.png)

### Selecting totems
![Dropdown showing totem list](docs/screenshots/totem-dropdown.png)

### UI with chosen totems (icons displayed)
![UI with selected totems](docs/screenshots/totems-chosen.png)

### TotemDrop macro in Macro UI
![Macro UI with TotemDrop created](docs/screenshots/macro-ui.png)

*(replace these placeholders with your own screenshots)*

---

## Commands

- `/totembar show` – show the selection UI
- `/totembar hide` – hide the selection UI
- `/totembar resetpos` – reset UI to the center of the screen
- `/totembar macro` – force rebuild the macro
- `/totembar dump` – (debug) show current selections
- `/totembar showmacro` – (debug) preview the macro body
- `/totembar log on|off` – enable/disable chat logging

---

## Notes

- The **TotemDrop** macro is created in your **character-specific macros** (not account-wide).
- The macro will always use a totem-themed icon (Recall if available).
- The order of casts is **Recall → Fire → Earth → Water → Air**.
- Works on Vanilla 1.12 clients (including Turtle WoW). Not intended for modern retail WoW.

---

## License

MIT – free to use, modify, and share.
