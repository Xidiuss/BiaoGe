# BiaoGe — 金团表格

> **Raid loot, auction tracking and character overview addon** for World of Warcraft.
> **WotLK 3.3.5a backport** of the retail addon by 苍穹之霜 (Cangqiongzhihuang).

[![Interface](https://img.shields.io/badge/Interface-30300-blue)](#)
[![Version](https://img.shields.io/badge/Version-1.27.3-green)](#)
[![Lua](https://img.shields.io/badge/Lua-5.1-purple)](#)
[![Dependency](https://img.shields.io/badge/Requires-!!!ClassicAPI-orange)](#)

---

## 🎯 What is BiaoGe?

BiaoGe (金团表格 — "Gold Team Spreadsheet") is a comprehensive raid management addon originally built for Chinese gold-runs / "金团" raid teams. It tracks loot distribution, auction bids, member accounts, character gear, and raid history. This project is a **community backport to WoW WotLK 3.3.5a** (Interface 30300, Lua 5.1).

Slash commands: `/BiaoGe` · `/GBG` · `/BGR` (Character Overview) · `/bgmap` · `/aimap`

---

## ✨ Features

### Loot & Auction
- **Auto-auction system** — ALT+click any item in your bags / chat / table to open the auction panel (as raid leader or item distributor)
- **Auction countdown** — automatic timer when items go up for bid
- **Outbid voice alert** — "Watch for sniping!" warning when bid is outbid with <10s remaining
- **Auction log** — full history of auctioned items, prices, winners, returns
- **Auction WeakAuras integration** — visualize auction state in your HUD
- **Auction message templates** — customizable announcement formats

### Raid Management
- **Character Overview (`/BGR`)** — grid view of all raid members: class, spec, role, gear, cooldowns
- **Raid cooldown tracking (FBCD)** — Bloodlust, Innervate, etc., per-character timers
- **Position maps** — raid leader sends positioning map, other members display it
- **MeetingHorn integration** — raid discovery support
- **WhoHistory** — track who you've inspected

### Financial / Accounting
- **Receive log** — track items received in trade
- **Trade log** — every trade you make, logged with timestamps
- **DuiZhang (accounts)** — guild member balance sheets
- **TongBao (guild treasury)** — withdrawals (ZhangDan), transfers (LiuPai), consumption (XiaoFei), debts (QianKuan)
- **WCL integration** — WarcraftLogs DPS/HPS pull
- **Quick accounting** — chat-based fast entry for purchases

### Gear & Items
- **GearLib / ItemLib** — equipment library with DressUp model preview (CTRL+hover)
- **Equipment filter** — per-class, per-slot, per-quality whitelist/blacklist
- **Expired gear reminder** — ItemOutTime panel warns when gear becomes stale
- **AtlasLoot integration** — direct loot table access
- **BagSync integration** — cross-character bag visibility
- **Item swap** — CTRL+ALT+click grid swaps entire row contents

### Other
- **World boss CD tracker** — kill timer per realm
- **Achievement helpers**
- **Loot tracking** — full LOOT_OPENED hooks
- **CommerceAuthority Vanilla** — vanilla-era trade tools
- **Minimap button** with LibDBIcon

---

## 📦 Installation

### Requirements

- **WoW client:** WotLK 3.3.5a (Interface 30300)
- **!!!ClassicAPI** — bridge addon emulating retail API on 3.3.5. Available from common 3.3.5 addon repositories. **Hard dependency** — BiaoGe will not load without it.

### Steps

1. Download or clone this repository
2. Copy the `BiaoGe` folder into your `World of Warcraft\Interface\AddOns\` directory
3. Ensure `!!!ClassicAPI` is also present in `Interface\AddOns\`
4. Restart WoW or `/reload`
5. Type `/BiaoGe` to open the main panel

Final layout:
```
World of Warcraft/
└── Interface/
    └── AddOns/
        ├── !!!ClassicAPI/       ← required dependency
        └── BiaoGe/              ← this addon
```

---

## 🛠 Backport Notes (WotLK 3.3.5 specifics)

BiaoGe was authored for the retail WoW client. This fork includes a substantial **compatibility layer** to make it work on the WotLK 3.3.5a engine and Lua 5.1 runtime.

Key adaptations:
- **`Core/Compat.lua`** — polyfills for `SetStartPoint`/`SetEndPoint` 4-arg form, `MODELFRAME_DEFAULT_ROTATION`, atlas direct registration, DressUpModel transmog stubs, WotLK stat globals (`STAT_HASTE`, `STAT_CRITICAL_STRIKE`, etc.)
- **`Core/DropDownAdapter.lua`** — replaces `LibUIDropDownMenu-4.0` (requires retail-only `TooltipBackdropTemplateMixin`) with a thin wrapper around `!!!ClassicAPI`'s `C_UIDropDownMenu`. Maintains `L_*` legacy globals for backward compatibility.
- **`BG_BACKDROP_*` constants** in `Core/function1.lua` — canonical backdrop templates avoiding `ChatFrameBackground` UV-overflow issues
- **Frame level renormalization handling** — interactive children in `FULLSCREEN_DIALOG` strata receive explicit `SetFrameLevel(parent + 10)` to work around WotLK 3.3.5's strata-relative level cap

---

## 🐛 Known Limitations on 3.3.5

Some retail features are stubbed or unavailable:

- **DressUp transmog** — `SetUseTransmogSkin`, `SetUseTransmogChoices`, `SetObeyHideInTransmogFlag` are no-ops (cosmetic only on retail)
- **Specialization queries** — `GetSpecialization()` not available; spec is derived from talent tree distribution
- **Async item/spell loading** — `Item:ContinueOnItemLoad()` fires synchronously; rare race conditions possible on fresh login
- **`PlayerModel:SetPortraitZoom()`** — no-op
- **`CreateMaskTexture()`** — no-op
- **TTS voice** — `C_VoiceChat.GetTtsVoices()` returns empty (no engine support)

For most users these are invisible — addon functionality is preserved.

---

## 🎨 Tips & Shortcuts

| Action | Shortcut |
|--------|----------|
| Open main table | `/BiaoGe` or `/GBG` |
| Open Character Overview | `/BGR` |
| Show position map | `/bgmap` or `/aimap` |
| Clear input box | Right-click |
| Jump cursor between fields | `Tab` or arrow keys |
| Jump to next BOSS | `Alt`/`Ctrl`/`Shift` + arrow keys |
| Auto-auction item | `ALT` + click item (raid leader / distributor) |
| Follow auction (as member) | `ALT` + click item |
| Open auction countdown | Right-click chat box equipment |
| Quick accounting | Right-click chat box (as member) |
| View alternative gear (same slot) | `CTRL` + click equipment |
| Model preview | `CTRL` + hover over equipment |
| Swap row contents | `CTRL`+`ALT`+click grid 1, then click grid 2 |
| Copy text | `Ctrl` + `X` in dialog |

---

## 📜 Credits

- **Original author:** 苍穹之霜 (Cangqiongzhihuang) — retail addon design and development
- **Retail addon supports:** MOP, CTM, WLK, Titan, and Vanilla Classic clients
- **Backport target:** WoW WotLK 3.3.5a — this repository
- **Compatibility layer:** community-driven, see `Core/Compat.lua` and `Core/DropDownAdapter.lua`

---

## 📄 License

This project preserves the original BiaoGe addon under its source license terms.
Compatibility layer code is provided as-is for the WotLK 3.3.5 community.

---

## 🔗 Related

- **!!!ClassicAPI** — required bridge addon
- **BiaoGeAI** — companion AddOn for raid leaders sending position maps
- **BiaoGeAccounts** — multi-account integration for Battle.net characters

---

## 🤝 Contributing

Issues and pull requests welcome. When reporting bugs:
- Include WoW client version (`/console scriptErrors 1` for Lua errors)
- Note your `!!!ClassicAPI` version
- Provide reproduction steps
