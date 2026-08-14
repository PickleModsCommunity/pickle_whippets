# TEBBY.md - pickle_whippets

## Overview

`pickle_whippets` is a FiveM resource by Pickle Mods that adds a nitrous-oxide (N2O) whippet system to GTA V roleplay servers. Players can purchase flavoured N2O canisters (strawberry, mango, grape, raspberry, watermelon) from in-world dealers, inhale them for drug effects (drunk gait, camera shake, speed boost, ragdoll on overdose), or fill a vehicle's nitrous tank for a temporary speed boost. A multi-step "gas processing" mini-game lets players craft filled canisters from empty tanks and ammonium nitrate using a placeable compressor prop. Two built-in shops sell the required items. The resource supports ESX and QBCore out of the box, with a custom-bridge stub for other frameworks, and integrates with ox_target, qb-target, or qtarget for world interactions.

## Code design

### Architecture

The resource follows the standard FiveM client/server split with a thin shared layer:

- **`config.lua`** (shared) — all tunable settings, loaded first by every context.
- **`locales/`** — translation loader (`locale.lua`) and per-language tables (`translations/*.lua`). Strings are retrieved with `_L(key, ...)`.
- **`core/shared.lua`** — three tiny utility functions (`lerp`, `v3`, `GetRandomInt`) available everywhere.
- **`core/client.lua`** — large shared client library: entity helpers (`CreateProp`, `CreateNPC`), the animation helper `PlayAnim`, interaction system (`CreateInteraction`, `DeleteInteraction`, the proximity/target polling thread), and `ShowInteractText` via `ox_lib`'s `lib.showTextUI`.
- **`bridge/`** — framework and inventory bridges selected at runtime by checking `GetResourceState`. Pattern: each file guards itself with an early `return` if its framework is not running.
- **`modules/`** — feature modules, each owning a `client.lua` and/or `server.lua`.

### Module breakdown

| Module | Responsibility |
|---|---|
| `modules/gas/` | Whippet equip/dequip, vapor smoke effects, nitrous vehicle fill, `PlayerWhippets` server state, usage-tier effect dispatch, vehicle nitrous tracking. |
| `modules/gas_process/` | Client-side hand-target cooking mini-game UI (ammonium loading, temperature regulation, tank filling). |
| `modules/handtarget/` | The "hand-target" system: a first-person-style prop interaction camera (`StartHandTarget`/`StopHandTarget`) with draggable props and distance-based overlap detection (`IsCoordsInsideHTProp`). |
| `modules/handtarget_network/` | Server-side scenario registry (`HTScenarios`), client-side scenario rendering (`SpectatorHTScenarios`), and all gas-process server events (`startGasProcess`, `stopGasProcess`, `scenarioAction`, `explode`). |
| `modules/shops/` | In-world ped-dealer shops (buy/sell) using `ox_lib` context menus. |

### Main flows

**Whippet use:**
1. Player uses an inventory item → `RegisterUsableItem` (server) → `EquipWhippet` → `TriggerClientEvent("pickle_whippets:useWhippet")`.
2. Client loop (`modules/gas/client.lua`) controls anim, puff timer, durability drain, and calls `TriggerServerEvent("pickle_whippets:whippetSmoke", time)`.
3. Server processes durability, fires `whippetSmoke` broadcast to all clients (smoke cloud), and calls `ProcessEffects` → selects usage tier → `ExecuteStatus` + `TriggerClientEvent("pickle_whippets:whippetEffect")`.
4. On dequip: server removes item or adds empty variant, deletes the prop.

**Gas processing:**
1. Player uses `nitrous_compressor` item → server removes item, sends `TriggerClientEvent("pickle_whippets:placeGasProcessor")`.
2. Client placement thread (raycast cursor, rotate, confirm) → `TriggerServerEvent("pickle_whippets:placeGasProcessor", coords, rotation)`.
3. Server inserts into `gas_processors` DB table, calls `CreateGasProcessor` → `CreateHTScenario` → broadcasts scenario to all clients.
4. Nearby clients render the prop set; player initiates process via interaction menu → server validates ammonium + empty tanks → starts scenario.
5. Client cooking thread (temperature control, button toggle) → server `scenarioAction` events fill canisters or trigger explosion.

**Vehicle nitrous:**
1. While whippet is equipped, player aims at nearby vehicle and holds R → durability drains into `VehicleNitrous[netId]` on server → broadcast to all clients.
2. Driver presses SHIFT to activate → server event `setVehicleNitrousActive` → client applies `fInitialDriveForce` multiplier and timecycle effects.

### Conventions

- All network event names are prefixed `pickle_whippets:`.
- `ox_lib` is used for menus (`lib.registerContext`/`lib.showContext`), text UI (`lib.showTextUI`), and input dialogs (`lib.inputDialog`).
- The NUI (`nui/index.html` + bundled JS/CSS) handles the HUD: controls display, objective text, and process status. It communicates via `SendNUIMessage` typed messages (`showControls`, `hideControls`, `setObjective`, `setProcessStatus`, etc.).
- Lua 5.4 is enabled (`lua54 'yes'`); the codebase uses `?.` safe-navigation (Lua 5.4 ox_lib extension) in a few places.

## Important files

| Path | Why it matters |
|---|---|
| `fxmanifest.lua` | Resource manifest; defines load order, escrow ignore list, and NUI page. |
| `config.lua` | Single source of truth for all tunable values: shops, whippet definitions, gas process parameters, nitrous boost, status tiers, admin groups. |
| `locales/locale.lua` | `_L()` helper; returns `ERR_TRANSLATE_<key>_404` on missing keys — useful diagnostic. |
| `locales/translations/en.lua` | All English player-facing strings. Copy to add a new language. |
| `core/client.lua` | Shared client library: entity helpers, the `Interactions` system, proximity loop. Referenced by every other client module. |
| `core/shared.lua` | `lerp`, `v3`, `GetRandomInt` utilities; must load before all other scripts. |
| `modules/gas/client.lua` | Whippet equip loop, vehicle nitrous control loop, smoke effects, all whippet client events. |
| `modules/gas/server.lua` | `PlayerWhippets` state, `EquipWhippet`/`DequipWhippet`, `ExecuteStatus`, `VehicleNitrous` map, all whippet server events. |
| `modules/gas_process/client.lua` | Hand-target cooking mini-game, prop placement flow, `ExitGasProcessScenario`. |
| `modules/gas_process/server.lua` | DB persistence for placed compressors (`gas_processors` table), `CreateGasProcessor`, placement/removal events. |
| `modules/handtarget/client.lua` | First-person hand-target camera system; `StartHandTarget`, `StopHandTarget`, `AddHandTargetProp`, `DeleteHandTargetProp`. |
| `modules/handtarget_network/server.lua` | `HTScenarios` registry, all gas-process server logic, `initializePlayer` sync event. |
| `modules/handtarget_network/client.lua` | `SpectatorHTScenarios` rendering, `GasProcessMenu`, distance-based show/hide loop, NUI config callback. |
| `modules/shops/client.lua` | Shop UI (buy/sell menus via ox_lib). |
| `modules/shops/server.lua` | Shop transaction validation, payment and inventory calls. |
| `bridge/esx/server.lua` | ESX server bridge: `GetIdentifier`, `ExecuteStatus`, inventory fallback, payment methods. |
| `bridge/qb/server.lua` | QBCore server bridge: same contract as ESX bridge. |
| `bridge/inventory/ox_inventory/server.lua` | ox_inventory server bridge; exposes `Inventory.*` API; sets `InitializeInventory` to override fallback. |
| `bridge/target/ox_target/client.lua` | ox_target bridge: `AddTargetModel`, `AddTargetZone`, `RemoveTargetZone`. |
| `__INSTALL/Items/` | Inventory item definition files (ox_inventory, QBCore, ESX, qs-inventory) to import during setup. |
| `stream/` | Custom YDR models for the five canister flavours and a YTYP prop type file. |
| `nui/` | Committed build output (index.html + hashed JS/CSS). Do not edit directly — source is in `web/`. |
| `web/` | React/TypeScript NUI source. Build with `npm run build` (do not build in this sandbox). |

## Intended behaviors

- **Framework guard returns**: Every bridge file checks `GetResourceState('es_extended')` or `GetResourceState('qb-core')` and does an early `return` if the target framework is not running. This is intentional — it is not dead code.
- **`custom` bridge prints a warning**: `bridge/custom/client.lua` and `bridge/custom/server.lua` deliberately `print("You are not using a supported framework...")` when neither ESX nor QBCore is detected. This is expected output, not an error.
- **`Config.DefaultDurability = 100`**: The comment "If you put away a whippet and it's way over 100% - set this to 1" is intentional. The value scales raw durability stored in item metadata; changing it to `1` makes the scale 0–1 instead of 0–100.
- **`speedBoosting` is a global**: The `stateChanges.active` and `stateChanges.off` functions in `config.lua` reference `speedBoosting` as an implicit global. This is intentional configuration-level Lua; the variable lives in the client environment.
- **Escrow**: Most of `modules/`, `core/`, and `bridge/` are listed in `escrow_ignore`, meaning they ship as readable Lua. The NUI assets and stream files are not in the ignore list and may be escrowed.
- **`Config.DefaultDurability`/`Inventory.NoMetadata`**: When the ESX inventory fallback is active, `Inventory.NoMetadata = true` causes `DequipWhippet` to skip saving durability metadata. This is intentional for ESX servers that do not support item metadata.
- **`prop_tennis_ball` used as invisible anchors**: Several invisible `prop_tennis_ball` and `prop_golf_ball` entities are spawned with zero alpha as world-space attachment anchors and IK targets inside the hand-target system. This is deliberate, not a leftover debug prop.
- **`prop_police_id_board` as floor collision**: Two invisible `prop_police_id_board` props are spawned in `GasProcessLoading` as flat collision surfaces. These are intentional proxy colliders, not errors.
- **Hardcoded `mysql-async`**: The manifest lists `@mysql-async/lib/MySQL.lua`. This is the required database dependency; it is not interchangeable with `oxmysql` in this resource.
- **`scoopEntity` referenced outside its scope**: In `modules/gas_process/client.lua`, `scoopEntity` is referenced in `ExitGasProcessScenario` but declared inside `GasProcessLoading`. This works because both functions run in the same client Lua environment after `GasProcessLoading` is called, making `scoopEntity` an upvalue visible to the enclosing scope's cleanup function.

## Common issues & fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| Locale strings not loading / buttons show raw keys | Resource folder name does not match `pickle_whippets` exactly (e.g. `pickle_whippet` or `pickle_whippets_v2`). | Rename the folder to `pickle_whippets` exactly (see `INSTALL.md` step 1). |
| `ERR_TRANSLATE_<key>_404` in chat | `Config.Language` does not match a key in `locales/translations/`. Default is `"en"` → `Language["en"]`. | Ensure the value matches the table key in the translation file. |
| Items not found / shop crashes | Item names in `config.lua` (`Config.Shops`, `Config.Whippets`) are not registered in the inventory. | Import the correct file from `__INSTALL/Items/` for your inventory resource. |
| `gas_processors` table missing on first boot | SQL auto-creates the table via `MySQL.ready` on first run; if mysql-async is not running at startup the table will not be created. | Ensure `mysql-async` starts before `pickle_whippets` in `server.cfg`. |
| Gas processor props not visible to other players | `pickle_whippets:initializePlayer` broadcasts `HTScenarios` on join; if the player joins before the resource finishes initializing, they miss it. | Trigger `pickle_whippets:initializePlayer` server-event after reconnect, or restart the resource. |
| Vehicle nitrous not syncing | `VehicleNitrous` is declared in `modules/gas/server.lua` but read in `modules/handtarget_network/server.lua` — both load in the same server environment so this works. If ordering changes the global may be nil. | Do not reorder server script load order in the manifest. |
| Whippet durability resets to 100 on re-equip | ESX fallback (`Inventory.NoMetadata = true`) skips metadata persistence. | Use ox_inventory (via `bridge/inventory/ox_inventory/`) to gain metadata support. |
| Target interactions not appearing | `Config.UseTarget = true` but no supported target resource is running; or the target bridge's guard check (`GetResourceState('ox_target') ~= 'started'`) returns false. | Set `Config.UseTarget = false` for keypress interactions, or ensure `ox_target`/`qb-target`/`qtarget` starts before this resource. |
| `shop_not_enough_item` locale key missing | `modules/shops/server.lua` calls `_L("shop_not_enough_item", ...)` but the key in `en.lua` is `shop_not_enough_items` (with an "s"). | This is a latent bug: the sell-check notification uses the wrong key. Fix by correcting the key name in the server or locale file. |
| NUI controls HUD not showing | NUI message type mismatch or the NUI page did not load. Check browser console via `nui/index.html` in dev mode. Never rebuild the NUI in this sandbox — delegate to the GitHub Actions workflow or a local build. |

## Conventions

- **Naming**: All network events use the prefix `pickle_whippets:`. NUI message `type` strings use camelCase (e.g. `showControls`, `setObjective`). Config keys use `PascalCase` for top-level tables (`Config.Whippets`, `Config.GasProcess`) and `camelCase` for sub-keys.
- **Locale keys**: snake_case, prefixed by feature (`gp_` for gas process, `w_` for whippet, `shop_` for shops). The `_L()` helper is used everywhere; never concatenate raw strings for player-facing text.
- **Bridge pattern**: Each bridge file begins with a framework guard (`if GetResourceState(...) ~= 'started' then return end`). New bridges must follow the same pattern and implement the same function signatures as the ESX and QBCore bridges.
- **Inventory API**: All inventory access goes through the `Inventory.*` table (set up by the active bridge). Never call framework inventory functions directly in module code.
- **Thread style**: `CreateThread`/`Citizen.CreateThread` are used interchangeably (both are valid in FiveM Lua). New code should use `CreateThread` for consistency with the majority of the codebase.
- **`Wait(0)` game loops**: Busy loops that must run every frame use `Wait(0)` at the end. Loops that poll less frequently use a `wait` variable that is bumped to 1500 when nothing is nearby and set to 0 when in range.
- **Server events**: Always capture `local source = source` at the top of a `RegisterNetEvent` handler before any async call, as `source` is a global that changes between ticks.
- **`SetTimeout`**: Used instead of `CreateThread` + `Wait` for one-shot deferred calls; consistent throughout the codebase.
- **PR style**: Lua files use 4-space indentation. No semicolons. Comments follow the `--` style; block comments are rare. Keep changes inside the intended module file; do not add logic to bridge files unless it is bridge-specific.
