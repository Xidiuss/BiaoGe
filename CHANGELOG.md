# Changelog

All notable changes to the BiaoGe WotLK 3.3.5 backport are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Fixed - Character Overview row separators

- **`Core/Compat.lua`** - corrected all 34 horizontal `CreateLine` consumers. ClassicAPI 1.19+ retains ownership of endpoint/thickness state, while BiaoGe replaces only its texture transform with native `LEFT`/`RIGHT` anchors. Runtime measurements at effective scales `0.5333` and `0.9` proved that ClassicAPI divided already-logical `GetRect()` dimensions by scale again, placing separators and row highlights outside their frames. Native anchors now follow movement, resizing, and UI scale automatically; obsolete global Texture line methods and the temporary Character Overview reflow were removed.

### Fixed - Tables edit focus and owed marker interaction

- **`Core/FBUI/FBUIfunction.lua`** - Gear, Buyer, and Amount cells no longer toggle their EditBox enabled state during mouse gestures. ClassicAPI's EditBox `Enable()` clears focus, so the old unconditional `SetEnabled(true)` on every mouse-up immediately removed the caret and hid the Amount keypad; right-click `SetEnabled(false)` also disabled mouse input before the field could reliably receive mouse-up. Normal clicks now keep editing active, right-click clearing leaves the field reusable, and modifier shortcuts exit focus explicitly without disabling the cell.
- **`Core/function2.lua`** - the visible `owed` marker now enables mouse input, allowing its Amount Owed tooltip and right-click clear action to run in Tables, History, and Receive.

### Fixed - Custom Gear Filtering statistic labels

- **`Core/DB/DB_FilterClassItem.lua` + `Locales/enUS.lua`** - all 19 WotLK statistic filters now use stable project-localized display labels instead of exposing server GlobalStrings that may be `?`, `5?`, format strings, or Chinese compatibility fallbacks on enUS clients. Persistent filter keys and localized item-tooltip matching patterns remain unchanged.

### Fixed - !!!ClassicAPI 1.23 startup compatibility

- **`Core/Compat.lua` C_Item isolation** - BiaoGe no longer replaces the shared `C_Item.GetItemInfo` and `C_Item.GetItemInfoInstant` methods. It consumes the richer !!!ClassicAPI 1.23 providers first and keeps 1.19 return-value augmentation inside the private `ns.*` wrappers.
- **`Core/Compat.lua` + item API callers** - restored BiaoGe compatibility with !!!ClassicAPI 1.23, which no longer exports the legacy globals `GetItemInfoInstant`, `GetItemSubClassInfo`, and `GetItemInventorySlotInfo`. BiaoGe now sources item instant/subclass APIs from `C_Item.*` when the old globals are absent, keeps the secure native `GetItemInfo` global untouched, and aliases `GetItemInfoInstant` locally in all BiaoGe files that call it directly.
- **`Core/Compat.lua` atlas registration** - custom BiaoGe atlases are registered into both the old `ATLAS_INFO_STORAGE` store and the new `C_Texture.AtlasData` store used by !!!ClassicAPI 1.23 `SetAtlas` / `NineSliceUtil`.

### Fixed — WotLK inline-texture `:0:0` artifacts + custom icon assets

- **`Core/function1.lua`, `Core/DB/DB.lua` — inline textures with `:0:0` (zero height/width) caused icons to "float" in random screen positions.** On retail, `|Tpath:0:0:...|t` auto-sizes the texture to the font line height; **WoW 3.3.5 does not support that** and instead renders the texture at its `textureWidth:textureHeight` size at the offset position, so star/raid-target, currency, VIP, PvP-honor and specialization icons leaked out of tooltips into the world (visible on hover, tab switches, spec-icon hover). A previous pass only fixed the mouse icons from the screenshots; this completes the class: `AddTexture` and `BG.GetTalentIcon` now clamp a `0` dimension to `14`, and the remaining hard-coded `:0:0` markup (raid-target, VIP, honor) uses explicit dimensions. Confirmed against `!!!ClassicAPI`, which always emits explicit `:16:16`.
- **`Core/function1.lua` — mouse-click instructions now show mouse icons instead of tutorial arrows.** `AddTexture("LEFT"/"RIGHT")` returned `UI-TUTORIAL-FRAME-*ARROW`; in 30+ "click does X" tooltips across the addon these now use the `leftc.tga`/`rightc.tga` mouse-button icons (3.3.5 has no built-in mouse-click texture).
- **Custom icon assets replacing missing/ugly Blizzard textures** — added `Media/icon/{help-i,libi,scale,scale-}.tga` (64×64). `help-i.tga` replaces the Blizzard `InformationIcon` on every info "i" button (AuctionMSG, AuctionLog, Boss handbook, MeetingHorn, YY, Trade, WhoHistory); `libi.tga` is the Gear Lib loot-source icon (previously a map / a non-rendering refresh atlas); `scale.tga` / `scale-.tga` are the auction-chat frame enlarge/shrink buttons (previously `common-icon-zoom*` atlases that did not render). Removed a redundant decorative "Locate Gear" magnifier button (no click action) that duplicated the adjacent info button.

### Fixed - WotLK icon rendering fallbacks

- **`Core/Compat.lua` + RoleOverview** - added a WotLK-safe `C_CurrencyInfo.GetCurrencyInfo` wrapper backed by the 3.3.5 currency list APIs and WoW currency fallbacks, so Character Overview currency icons no longer collapse to `iconFileID = 0`.
- **UI icon paths** - replaced unsupported retail atlas/texture references in Manual help, Auction Chat Log helper buttons, Gear Lib source filter, trade gold text, and the amount numpad backspace label with WotLK-compatible texture paths.

### Fixed — enUS locale terminology audit

- **`Locales/enUS.lua` — corrected machine-translation artifacts and WoW terminology** — replaced mistranslated spell/item-name substitutions in UI copy (for example search, healing, modifier-key, raid, lockout, and Waylaid Supplies text), corrected WotLK raid labels, and fixed three `%s` placeholder mismatches in enUS locale strings.

### Fixed — Mover notification hyperlink regression

- **`Core/BiaoGe.lua` — mover mode no longer blocks item links in notification frames** — the spec 003 mover fix enabled mouse capture directly on `BG.FrameLootMsg` / `BG.FrameTradeMsg` (`ScrollingMessageFrame`). That stopped mouse pass-through to world objects, but it also intercepted the native hyperlink hit-testing for item links in those message frames. Mover mode now leaves the scrolling message frames mouse-disabled for hyperlink interaction and uses a separate transparent `BiaoGeMoveHitFrame` behind each mover to handle empty-area drag/reset.

### Fixed — Action bar macros blocked by taint (spec 004)

- **`Core/Compat.lua` block 16 + 14 caller files** — with BiaoGe enabled, **action-bar macros stopped working** (no keybind, no click), and disabling WIM/ElvUI revealed *"BiaoGe has been blocked from an action only available to the Blizzard UI."* Root cause (confirmed via `taint.log`): `Compat.lua` **overwrote the global `GetItemInfo`** with an insecure wrapper (it augments returns 12/13 with `classID`/`subClassID`, absent on WotLK 3.3.5). Blizzard's secure macro parser `CreateCanonicalActions` (ChatFrame.lua) **reads `GetItemInfo`** while resolving `/cast`, `/use`, `/castsequence` → the read taints the execution path → `CastSpellByName`/`RunMacro` blocked. Plain abilities went through `UseAction` (no macro parser) so they kept working — hence "spells work, macros don't". Fix: the global `GetItemInfo`/`GetItemInfoInstant` stay native (secure); the augmented wrapper is exposed as `ns.GetItemInfo`/`ns.GetItemInfoInstant` and the 14 modules that read `classID`/`subClassID` alias it locally. Verified in-game: `issecurevariable("GetItemInfo")` → `true`; macros work.

### Fixed — Equipment filter panel & Gear Lib tooltip (spec 005)

- **`Core/Module/FilterClassItem.lua` — "Custom Gear Filtering" panel auto-opened on load** — the panel frame is created visible (`CreateFrame` default) and built in an init function with no closing `Hide()`, so it appeared on every login/`/reload`. Added `Hide()` at the end of the builder (after height/`GetTop` layout, so layout math still runs on a shown frame).

- **`Core/Module/FilterClassItem.lua` — nested ESC for the filter panels** — WotLK `CloseSpecialWindows` hides *all* `UISpecialFrames` at once, so ESC closed the panel together with the main window, and the "New filter program" subframe could not be closed at all. Replaced static registration with a dynamic stack that keeps only the top-most *visible* of `{AddFrame, filter panel, main window}` in `UISpecialFrames`, recomputed on each frame's `OnShow`/`OnHide` (the `OnHide` recompute is deferred one frame via `C_Timer.After(0)` so the re-added next frame isn't caught by the same close-all ESC pass). ESC now closes New filter program → filter panel → main window, one step per press.

- **`Core/Module/ItemLib.lua` + `Core/BiaoGe.lua` — Gear Lib multi-source tooltip had no background** — the "multiple sources" hover tooltip (`BiaoGeTooltip2`) called `SetText` without `Show()`, so its backdrop was never drawn. Under ElvUI/NDui the dedicated skin branch also stripped the native backdrop and drew only a 1px edge (no `bgFile`). Added the missing `Show()` and a `BACKGROUND` fill texture on the tooltip itself (renders below the text and survives ElvUI's tooltip skinning).

### Fixed — Equipment filter panel layout, frame-level clicks, movers, locale (spec 003)

- **Frame-level click-through** — a duplicate `SetFrameLevel(600)` on the FULLSCREEN_DIALOG filter panel (called after its children existed) renormalized the panel's level downward, so the "+" / new-profile (`AddFrame`) controls created afterward landed *below* the parent and ignored clicks. Removed the redundant second call; later children regain a clean parent level and become clickable.

- **Filter panel layout** — restored 5-column grid at 110px column width and widened the panel (560→720px) so full profile names fit without adding rows; opaque AddFrame dialog background; close/back buttons relabeled ("Back") with persistent gold borders.

- **Movers (`BG.Move`)** — drag handles now `EnableMouse(true)` with a green border so they capture the mouse (previously the cursor passed through to the world and drag did not start). Mouse-button hint icons (`Media/icon/leftc.tga`, `rightc.tga`) wired into the Manual instructions, mover reset hint, and AuctionWA import/copy tooltips.

- **Icon grid** — removed retail-only numeric fileID icons (Legion 7.0+, unsupported on 3.3.5, rendered as red squares) and the MoP-only Monk entries; restored ~30 verified classic 3.3.5 `Interface\Icons` paths. Icon-picker selection highlight enlarged to a 36px solid-blue border.

- **Locale (enUS)** — corrected ~16 mislabeled equipment-filter strings (1H/2H, Guns, Crossbows, Wands, Thrown, Fist Weapons, Cloth, Mail, Plate, Shields, Librams, Idols, Totems, Sigils) and replaced retail `|A:NPE_RightClick|a` atlas markup in the Manual help text (enUS/zhCN/zhTW) with WotLK-compatible markup. Manual help tooltip now fires (`EnableMouse(true)` on its frame).

### Fixed — Panel backdrop fills (spec 002) + numpad reparent crash

- **Backdrop fills across ~40 content panels (23 files)** — panels created with a `SetBackdrop({…})` table lacking a `bgFile` plus `SetBackdropColor(0,0,0,0)` rendered fully transparent on WotLK 3.3.5 (retail supplied a default fill; the WotLK engine does not). Replaced with the canonical `BG_BACKDROP_PANEL` / `BG_BACKDROP_PANEL_10` / `BG_BACKDROP_THIN` constants from `Core/function1.lua` plus `SetBackdropColor(0,0,0,0.8)`. Affected: auction start popup & ongoing-auction windows, trade-side panels (debt record, accounting preview, fast-give-money), DuiZhang chat/raid lists, gear/buyer/amount lists, History list + rename dialogs, Loot, Receive, Map, MeetingHorn, QuickAccounting, AuctionLog/MSG, Achievement, WhoHistory, WorldBossCD, YY rating panels, Handbook boss panels, Hope import, MoP loot popups, ad copy. Ornate `UI-DialogBox-Border` frames keep their border (bgFile added inline); WeakAura-style `AuctionWA` windows get a bgFile while preserving the user-configurable color. `Trade.tradeSeeFrame` state-color methods (`SetNormalColor`/`SetGreenColor`) updated so the dark fill persists across trade states.

- **`Core/Module/ItemLib.lua`** — GearLib Ctrl-hold model preview (`BG.DressUpFrame`) backdrop opacity 0.65 → 0.8 for clearer model silhouette contrast.

- **`Core/function2.lua` — numpad (`BG.FrameNumFrame`) silent client crash** — the shared on-screen numpad's `OnHide` handler called `self:SetParent(nil)`. Reparenting a frame from inside its own `OnHide` (while the 3.3.5 engine is mid-traversal hiding the frame tree) corrupts the frame hierarchy. The "amount owed" editbox's right-click-to-clear (`SetEnabled(false)` on a focused editbox) forces a focus-loss → numpad hide → reparent on **every** click, so rapid repeated right-clicks accumulated corruption into a silent client crash (no Lua error). Removed the `OnHide` handler entirely — the reparent was redundant because `CreateNumFrame` re-parents on every show from a safe focus-handler context.

### Fixed — Compat stubs (spec 001) + garrmission hyperlink crash (spec 007)

- **`Core/Compat.lua` block 8f-ext** — `SetCamDistanceScale` no-op stub (retail-only `DressUpModel` method; WotLK engine ignores zoom override safely). Fixes crash in `ItemLib.lua` DressUp preview path.

- **`Core/Compat.lua` block 8g** — `FlashClientIcon` no-op stub (retail-only OS taskbar flash global). Silences log spam on every load.

- **`Core/Compat.lua` block 8h** — `SetItemRef` wrapper: early-return for `garrmission:` link prefix (BiaoGe's custom chat link scheme, WoD+ Garrison Missions — unknown to WotLK 3.3.5 native `ItemRef.lua`). Also adds `ItemRefTooltip.SetHyperlink` defense-in-depth override for addons that bypass `SetItemRef`. Fixes 3–17× "Unknown link type" errors per BiaoGe chat link click (ElvUI / WIM / LibExtraTip / Enchantrix / TradeSkillMaster hook chain). BiaoGe `hooksecurefunc("SetItemRef", …)` post-hooks still fire correctly.

- **`Core/Module/DuiZhang.lua` lines 321/329** — `button.Highlight:Show/Hide()` → `button:LockHighlight()/UnlockHighlight()`. `C_UIDropDownMenuButtonTemplate` (!!!ClassicAPI) does not create a child `Highlight` frame; the correct API is the Button method pair.

- **`Core/Module/DuiZhang.lua` line 773** — nil-guard `if not (BiaoGe.duizhang and BiaoGe.duizhang[num]) then return end` in `DuiZhangSet`. Prevents arithmetic-on-nil crash when a stale chat link is clicked before data is loaded.

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
