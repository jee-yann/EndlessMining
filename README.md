# Endless Mining

![Citrine Cove in Roblox Studio](map/CitrineCove-preview.jpg)

Citrine Cove is a multiplayer Roblox mining simulator. Cross the inlet on the wooden bridge and follow the sand path to the crystal cave, hold to carve a sphere out of the rock, sell the contents of your pack, and spend the proceeds at the workshop. The first radius upgrade costs 24 gold. It takes the brush from 5 to 7 studs. A starter pack holds 36 ore.

## Play locally

1. Open `EndlessMining.rbxlx` from this folder in Roblox Studio, or use the existing **Endless Mining** Studio place connected to this project's Rojo server.
2. Press **F5**. The island is already visible in edit mode. Play generates the excavatable rock behind the cave mouth. Cross the bridge and walk beneath the golden crystal marked **MINE**. Aim at the dark starter seam and hold the left mouse button. On a touch device, aim with the center dot and hold **HOLD MINE**.
3. Select **SELL**, then **UPGRADES → Radius**. The backpack and price are visible before purchase. The ore exchange and workshop also have proximity prompts. Both HUD actions work underground.
4. Use **↑ SURFACE** to return from the mine. Falling outside the quarry also recalls the character. Press **Shift+F5** to end the session.

To rebuild the local place after editing, run the following command in the project directory.

```powershell
rojo build default.project.json -o EndlessMining.rbxlx
```

For live editing, run `rojo serve default.project.json` here if this project's server is stopped. In Studio, use **Plugins → Rojo → Connect** and select **EndlessMining** at `localhost:34872`. A built place can be played directly without connecting the plugin.

## World and balance

The 192 × 224 stud mine extends 352 studs below the entrance. Sunstone Hollow gives way to the Iron Shelf, Prism Grotto, and Emerald Deep. Each 32-stud geological region receives a seeded, tilted ore deposit. Minimum and preferred depths control its composition. Some deep regions contain an oversized precious-metal or gem lode around a hollow pocket. A fixed coal seam makes the opening reproducible.

The server generates native Roblox smooth Terrain in batches of at most 16 × 16 × 16 cells. Terrain provides the collision mesh, replication and material grid. Every server starts with a fresh copy of the configured seed. Excavations are shared for that server's lifetime. The material at each occupied cell identifies its yield, so a second miner can collect only what remains.

A pulse reads and writes one clipped region. Precomputed sphere offsets visit the closest cells first when a pack is nearly full. The largest brush is 28 studs, with 1,419 candidate cells inside a 15³ bounding box. A FIFO queue, one pending request per player, server cooldowns, and a shared cell budget bound per-frame work. The server checks reach, line of sight, material hardness and inventory space. Clients supply an aim point and render effects. All prices, yields and balances come from the server.

| Change | File |
| --- | --- |
| Seed, site, layers, reach, save interval and work budget | `src/shared/GameConfig.luau` |
| Ore appearance, value, hardness and depth weighting | `src/shared/Ores.luau` |
| Upgrade values, level caps and cost curves | `src/shared/Upgrades.luau` |
| Vein shapes, rich pockets and the starter seam | `src/server/Geology.luau` |
| Editable island, signed stations, spawn and bridge | `map/CitrineCove.rbxmx` |
| Station binding and terrain palette | `src/server/Quarry.luau` |
| Starting editor camera and lighting | `default.project.json` |

## Project and data ownership

Rojo owns the scripts under `ReplicatedStorage.Shared`, `ServerScriptService.Server` and `StarterPlayer.StarterPlayerScripts.Client`, plus the authored `Workspace.CitrineCove` model and the lighting listed in `default.project.json`. To keep island edits in the source project, export the selected CitrineCove model from Studio as `map/CitrineCove.rbxmx` before rebuilding. Keep additional Studio-only models as siblings in Workspace. The server starts the mine at the island’s SiteOrigin and checks for unrelated parts and existing terrain before choosing a dig site. If the site is occupied, it relocates the island and mine together for that session. Existing terrain palettes are preserved.

The edit-mode cave face gives way to mineable terrain during Play. Remotes, HUD and headlamps are created at runtime. Player profiles contain gold, ore still in the pack, upgrade levels, lifetime ore mined and best depth. The server uses DataStore `EndlessMining_v1` with separate Studio and live scopes, conditional session ownership, periodic saves, and leave/shutdown saves. A failed load or unsupported record opens an explicitly labeled temporary session with writes disabled. An unpublished local build or a simulated test user gets a practice session.

## Visual references

Three local Roblox captures in `%LOCALAPPDATA%\Roblox\tmp-capture-storage` informed the island. The beach scene ending in `1795063278721` supplied the sea, sand-path and studded-lawn palette. The grass ledges in `1795062944957` informed the layered bluffs. The striped tool stand in `1795063226069` informed the small coral and teal market stalls. The citrine outcrop and island geometry use native Studio parts.

## Reproduce the checks

The two test scripts live outside the Rojo tree. Use a fresh local build. Studio's **RunScript** command runs the checks in a disposable session. With Studio open, these PowerShell commands select its installed executable.

```powershell
$studioExe = (Get-Process RobloxStudioBeta | Select-Object -First 1).Path
$quarryPlace = (Resolve-Path '.\EndlessMining.rbxlx').Path
$terrainTest = (Resolve-Path '.\tests\Quarry.spec.luau').Path
$playTest = (Resolve-Path '.\tests\Play.spec.luau').Path

& $studioExe --task RunScript --localPlaceFile $quarryPlace --runScriptFile $terrainTest --outputFile "$env:TEMP\EndlessMining-terrain.log" --quitAfterExecution
```

Look for a standalone `QUARRY_TESTS_PASSED` output line. This checks save ownership, profile validation, economy, three seeds, shared depletion, server reach and obstructions, and repeated maximum-radius edits. Then run the two-client check in a signed-in Studio session.

```powershell
& $studioExe --task RunScript --localPlaceFile $quarryPlace --runScriptFile $playTest --outputFile "$env:TEMP\EndlessMining-play.log" --quitAfterExecution
```

The two-client check uses real client-to-server requests. Both simulated players must fill their packs, sell, upgrade, and return to the surface. Look for `QUARRY_PLAYTEST_RESULT PASS` followed by both clients' results.

For hands-on checks, choose **Server & Clients** in Studio's Test selector and start two players. Mine the same face, compare balances and verify both players see the same cavity. Use the device emulator to check the shop, hold/release control, thumbstick and jump in phone landscape and portrait. A persistence round trip requires a separate published test place with Studio API access enabled. Sell ore, buy an upgrade, stop the session and rejoin to verify the balance and level.
