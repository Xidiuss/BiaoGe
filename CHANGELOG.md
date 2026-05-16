# Changelog

All notable changes to the BiaoGe WotLK 3.3.5 backport are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-05-16

### Initial public release of the WotLK 3.3.5 backport

This is the first published version of BiaoGe ported to WoW WotLK 3.3.5a (Interface 30300, Lua 5.1).

Based on retail BiaoGe v1.27.3 by 苍穹之霜 (Cangqiongzhihuang).

### Added — Compatibility layer

- **`Core/Compat.lua`** — comprehensive WotLK 3.3.5 compatibility shim
  - `SetStartPoint` / `SetEndPoint` 4-argument form patch (CreateLine support)
  - `MODELFRAME_DEFAULT_ROTATION` fallback (`-π/6`)
  - Atlas direct registration (`ATLAS_INFO_STORAGE[name] = {...}`) — works with !!!ClassicAPI v1.15 and v1.16
  - DressUpModel transmog method stubs (`SetUseTransmogSkin`, `SetUseTransmogChoices`, `SetObeyHideInTransmogFlag`, `SetDoBlend`)
  - WotLK stat globals fallbacks (`STAT_HASTE`, `STAT_CRITICAL_STRIKE`, `HIT_LCD`, `MELEE_ATTACK`, `RANGED_ATTACK`, item mod shorts, mana regeneration, spell damage/healing)
  - NineSlice patches for retail-style `backdropInfo` / `ApplyBackdrop` pattern

- **`Core/DropDownAdapter.lua`** — full replacement for `LibUIDropDownMenu-4.0`
  - Wraps `C_UIDropDownMenu_*` API from !!!ClassicAPI
  - Maintains `L_*` legacy aliases (`L_DropDownList1`, `L_UIDROPDOWNMENU_MAXBUTTONS`, etc.)
  - Re-syncs aliases on `L_DropDownList1:OnShow`
  - Frame strata propagation for menus opened from `FULLSCREEN_DIALOG` parents
  - Fixes `$parentChild` property access on private servers (uses `_G[name.."Child"]`)

- **`Core/function1.lua`** — canonical backdrop constants
  - `BG_BACKDROP_BORDER` — thin ChatFrame edge, no fill (for frames with own textures)
  - `BG_BACKDROP_THIN` — thin edge + UI-Tooltip-Background fill (dropdowns)
  - `BG_BACKDROP_PANEL` — 16px border + fill (large dialogs)
  - `BG_BACKDROP_PANEL_10` — 10px border + fill (compact panels)
  - All use UI-Tooltip-* textures (avoids ChatFrameBackground UV-overflow blocking mouse hit)

### Fixed — WotLK 3.3.5 specific issues

- **Frame level renormalization** — WotLK 3.3.5 engine renormalizes `SetFrameLevel(N)` relative to strata base (~499 for `FULLSCREEN_DIALOG`). Interactive children (checkboxes, buttons, EditBox) in panels under FULLSCREEN_DIALOG now receive explicit `SetFrameLevel(parent:GetFrameLevel() + 10)`. Fixes panels appearing visible but ignoring clicks (clicks pass through to parent).

- **Version detection antipattern** — replaced `if not BG.verLess2` checks with explicit `if BG.IsRetail` / `if BG.IsWLK`. The former is TRUE in WotLK (not just retail), causing retail-only API calls to fire.

- **`GetTop()`/`GetBottom()` nil for hidden frames** — added nil-guards in `BG.Init` for layout calculations done before frames are shown. Previously caused `nil - nil + 40` arithmetic → panels rendered at 40px height.

- **Dropdown `L_*` alias nil errors** — added `(L_UIDROPDOWNMENU_MAXBUTTONS or 0)` fallback and `if btn then` guards in Map.lua, Options.lua, DB.lua, DuiZhang.lua. Fixes `'for' limit must be number` crashes.

- **Atlas registration v1.15 vs v1.16 ABI mismatch** — switched from `C_Texture.RegisterAtlasTable({[name]={...}})` (crashes in v1.16) to direct `ATLAS_INFO_STORAGE[name] = {...}` writes (compatible with both).

- **`EasyMenu` routing bypass** — `LibBG:EasyMenu` now routes through adapter's `ToggleDropDownMenu` instead of `C_ToggleDropDownMenu` directly, preserving hook chain and L_ alias sync.

- **Lazy-defined `BG.*` functions** — added nil-guards for `BG.UpdateFBCD`, `BG.ReceiveMainFrame:SetScale` and similar lazy-init functions called from cross-module hooks. Prevents race conditions.

- **`CreateTexture("OVERLAY")` bad signature** — corrected to `CreateTexture(nil, "OVERLAY")` (texture name vs draw layer).

- **`SetBackdrop` with `edgeFile` only + `SetBackdropColor(0,0,0,0)` = invisible** — migrated 4 frames (BG.Movetable, BG.auctionLogFrame, BG.itemGuoQiFrame, BG.FBCDFrame) to `BG_BACKDROP_PANEL` (with bgFile) + `SetBackdropColor(0,0,0,0.65)`.

### Changed — UI / Theme

- All frames migrated to `BackdropTemplate` from `BackdropTemplateMixin` (via !!!ClassicAPI)
- Texture deprecation pass: `SetColorTexture(r,g,b,a)` replaces `SetTexture("WHITE8x8") + SetVertexColor + SetAlpha` in 12+ sites
- Selection highlights migrated from `UI-ChatIcon-BlinkHilight` (UV overflow issue) to `SetColorTexture`
- Shadow rendering corrected (previous `ChatFrameBackground` shadow was blocking mouse hits)

### Removed

- `Libs_classic/LibUIDropDownMenu.lua` — disabled in TOC (requires retail-only `TooltipBackdropTemplateMixin`). Replaced by `Core/DropDownAdapter.lua`.

### Dependencies

- Hard dependency: **!!!ClassicAPI** (any version from 1.15 onwards). Without it, BiaoGe will fail to load. Add `## Dependencies: !!!ClassicAPI` to TOC.

---

## Pre-public history

Development of the WotLK 3.3.5 backport began in early May 2026 across 12+ iterative sessions. Each session targeted specific compatibility issues observed in-game. The 1.0.0 release above consolidates all session work.
