# Endless Mining

![Citrine Cove in Roblox Studio](map/CitrineCove-preview.jpg)

Citrine Cove is a multiplayer Roblox mining simulator. Aim at a cave wall or floor to highlight the exact blocks you can take, hold through the pickaxe swing, and bring the ore to the harbor. Each block face measures 4 × 4 studs. The starter tool takes one block per hit. The first Mining area upgrade costs 24 gold and takes two side by side. A starter pack holds 36 ore.

## Play locally

1. Open `EndlessMining.rbxlx` from this folder in Roblox Studio, or use the existing **Endless Mining** Studio place connected to this project's Rojo server.
2. Press **F5**. The island is already visible in edit mode. Play generates studded plastic bricks behind the cave mouth. Cross the bridge and walk beneath the golden crystal marked **MINE**. Aim at the dark starter seam and hold the left mouse button. On a touch device, aim with the center dot and hold **HOLD MINE**.
3. After eight blocks, open **Jobs** and claim **First strike** for 25 gold. Walk to the cyan **Upgrades** stall, use its prompt and buy **Mining area** for 24 gold to cut two blocks per hit. Use the amber **Sell** counter to empty your pack. Open **Pack** anywhere to see quantities and sale values for each ore.
4. Dig through the walls and floor to reach deeper regions. The location card shows your X, Y and Z in blocks from the mine entrance. Y drops by one for each full block you descend. At Y −27 you enter Iron Shelf. **Index** lists the vein chances at each depth. **↑ Harbor** brings you back to the surface to sell. Open **Settings** from the dock to adjust music, sound effects or menu animations.

The place uses each player’s equipped Roblox avatar. If Studio Output reports an authentication error for a missing head or clothing texture, refresh the Studio sign-in and start another play session.

![Music, sound effects and menu motion in Settings](map/Settings-preview.jpg)

To rebuild the local place after editing, run the following command in the project directory.

```powershell
rojo build default.project.json -o EndlessMining.rbxlx
```

For live editing, run `rojo serve default.project.json` here if this project's server is stopped. In Studio, use **Plugins → Rojo → Connect** and select **EndlessMining** at `localhost:34872`. A built place can be played directly without connecting the plugin.

## Saving your work

- **On your PC** press **Ctrl+S** in VS Code to save a script. If you edit the island directly in Studio, stop Play before editing and save the `Workspace.CitrineCove` model to `map/CitrineCove.rbxmx`. The build command above bundles those files into a place you can reopen.
- **On GitHub** commit your saved source files, then push your feature branch. In VS Code these actions are under **Source Control**. A pull request lets you merge the work into `main`.
- **On Roblox** open the built place in Studio and choose **File → Publish**. A new experience starts private. Open the published experience in the Roblox app to keep your miner’s gold, inventory, upgrades and best depth. The game autosaves every 45 seconds and on exit. A local playtest labeled **Practice session** resets when you stop it. [Roblox publishing guide](https://create.roblox.com/docs/production/publishing/publish-games-and-places)

## World and balance

The harbor spans roughly 268 × 229 studs inside a continuous rock rim. The spawn compass opens onto a 95-stud-wide court. Follow the central bridge to the mine, the amber bullion sign to Sell, or the cyan pickaxe to Upgrades. Side paths pass ore wagons, gardens and the stepped waterfall. Both hillside paths climb to the rear cableway trail, where four grounded towers carry three moving ore cars.

Music and effects have separate sliders in **Settings**. Volume and menu-motion preferences are saved with player progress. The music slider sets the volume of Anthony Mawer’s *Prima Bossa Nova*. The buttons use short bubble pops. Each ore has its own break sound, and gold, diamond and emerald add progressively longer rising notes. [Prima Bossa Nova](https://create.roblox.com/store/asset/1837070127) · [UI Cute Pop](https://create.roblox.com/store/asset/15675055424) · [UI Cute Goodbye](https://create.roblox.com/store/asset/15675081158)

![Workshop menu in Roblox Studio](map/Workshop-preview.jpg)

The harbor has a core sample table, dispatch board, ore museum, pass stall and a leaderboard court behind spawn. One board ranks the top five miners present by lifetime blocks. The other shows your standing alongside your Roblox friends. In published play it includes friends with saved scores even when they are offline. Local practice sessions use connected miners.

![Friends and Server Miners boards behind spawn](map/Miners-Court.jpg)

Digging opens a shared route through four regions. The percentages below describe the chance that a new vein in each region contains that ore. Host blocks fill the space between veins.

| Region | Depth in blocks | Coal | Copper | Iron | Gold | Diamond | Emerald |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Sunstone Hollow | 0–26 | 72% | 28% | – | – | – | – |
| Iron Shelf | 27–89 | 23% | 27% | 44% | 6% | – | – |
| Prism Grotto | 90–184 | 10% | 15% | 36% | 27% | 12% | – |
| Emerald Deep | 185–288 | 6% | 9% | 26% | 28% | 23% | 8% |

The backpack shows occupied slots, each ore count and the gold the Sell counter will pay for it.

![Backpack showing one coal worth five gold](map/Backpack-preview.jpg)

The seven shift jobs award gold once each. The index records discoveries even after you sell them. Ranks and job claims use lifetime mining progress.

The mine is 48 blocks wide, 56 blocks long and 288 blocks deep. Sunstone Hollow gives way to the Iron Shelf, Prism Grotto, and Emerald Deep. Each eight-block geological chunk receives a seeded, tilted ore deposit. The region’s vein weights determine its composition. Orange-brown dirt lies close to the turf and extends at most three blocks below entrance level. Grey stone fills the deeper mine. Some deep regions contain an oversized precious-metal or gem lode around a hollow pocket. A fixed coal seam makes the opening reproducible. The green roof is permanent turf.

The server keeps one byte per grid cell. Only exposed rock needs physical Parts. Within each 8 × 8 × 8 cell chunk, neighbouring exposed cells of the same shade share anchored plastic bricks. Cutting a block rebuilds the affected chunks and exposes the next layer. Excavations are shared for the lifetime of that server.

Mining area upgrades unlock **1×1, 2×1, 2×2, 3×2, 3×3, 4×3, 4×4, and 5×5** face patterns. Each hit takes one layer. Mint borders follow the visible faces of each selected block. A flush wall shows one square. Exposed corners show multiple sides as you move the camera. A pick cursor marks a valid target. A red no-entry sign marks an ore above your power tier. Cracks spread across the selected blocks as the cut progresses. Nearby miners see a fading ore name and quantity at the mined block. Dirt and stone go straight into the pack. Holding a target plays a sequence of quick pickaxe swings while one meter fills for the cut. Releasing early or switching targets cancels the stroke. The outlines and on-screen count account for missing blocks, reach, obstructions, power and space in the pack. An almost-full pack selects the nearest blocks to the aim point first. The server checks the same pattern and intersects it with the squares the player saw. If another player takes one, the hit skips that square. Existing profiles retain their upgrade levels.

![Block borders in three Studio views, exposed, flush with the wall, and covered by another rock](map/Mining-area-preview.jpg)

| Change | File |
| --- | --- |
| Seed, site, layers, reach, save interval and work budget | `src/shared/GameConfig.luau` |
| Material appearance, sale value and required power | `src/shared/Ores.luau` |
| Upgrade values, level caps and cost curves | `src/shared/Upgrades.luau` |
| Jobs and ranks | `src/shared/Expeditions.luau` |
| Game pass IDs and perks | `src/shared/PassCatalog.luau`, `src/server/Passes.luau` |
| Vein shapes, rich pockets and the starter seam | `src/server/Geology.luau` |
| Editable island, signed stations, spawn and bridge | `map/CitrineCove.rbxmx` |
| Studded brick geometry and face patterns | `src/server/MineBlocks.luau`, `src/shared/BlockPattern.luau` |
| Region depths and vein weights | `src/shared/GameConfig.luau` |
| Station binding | `src/server/Quarry.luau` |
| Starting editor camera and lighting | `default.project.json` |
| Music and button sounds | `src/client/HarborAudio.luau` |

## Project and data ownership

Rojo owns the scripts under `ReplicatedStorage.Shared`, `ServerScriptService.Server` and `StarterPlayer.StarterPlayerScripts.Client`, plus the authored `Workspace.CitrineCove` model and the lighting listed in `default.project.json`. To keep island edits in the source project, export the selected CitrineCove model from Studio as `map/CitrineCove.rbxmx` before rebuilding. Keep additional Studio-only models as siblings in Workspace. The server starts the mine at the island’s SiteOrigin and checks for unrelated parts and existing terrain before choosing a dig site. If the site is occupied, it relocates the island and mine together for that session. Existing terrain palettes are preserved.

During Play the edit-mode cave face gives way to the shared block grid. Remotes, HUD and headlamps are created at runtime. Player profiles contain gold, ore still in the pack, upgrade levels, lifetime ore mined, best depth, completed jobs and discovered ore types. The server uses DataStore `EndlessMining_v1` with separate Studio and live scopes, conditional session ownership, periodic saves, and leave/shutdown saves. A failed load or unsupported record opens an explicitly labeled temporary session with writes disabled. An unpublished local build or a simulated test user gets a practice session.

## Visual references

Three local Roblox captures in `%LOCALAPPDATA%\Roblox\tmp-capture-storage` informed the island. The beach scene ending in `1795063278721` supplied the sea, sand-path and studded-lawn palette. The grass ledges in `1795062944957` informed the layered bluffs. The striped tool stand in `1795063226069` informed the small coral and teal market stalls. The citrine outcrop and island geometry use native Studio parts.

The two newer lobby captures ending in `1795070093346` and `1795070096049` informed the oversized signs, colored icon dock and visible job tracker. The harbor, pickaxe and HUD icons are built from native Roblox objects.

## Outfitters and Robux

**Double Gold** doubles ore-sale proceeds. **Prism Trail** equips a cosmetic rainbow trail that returns after respawn. The **Outfitters** counter’s **Try in Studio** button previews either perk in an unpublished practice session. A trial ends when the player leaves.

To turn on real sales after publishing, create two passes for this experience under **Creator Dashboard → Monetization → Passes**, put them on sale, and enter their pass asset IDs in `src/shared/PassCatalog.luau`. Publish the updated build. The shop requests the player's current price from Roblox, and checkout opens after the player selects the price. The server checks ownership on join and grants successful purchases. [Roblox pass setup](https://create.roblox.com/docs/production/monetization/passes) · [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing)

## Reproduce the checks

The two test scripts live outside the Rojo tree. Use a fresh local build. Studio's **RunScript** command runs the checks in a disposable session. With Studio open, these PowerShell commands select its installed executable.

```powershell
$studioExe = (Get-Process RobloxStudioBeta | Select-Object -First 1).Path
$quarryPlace = (Resolve-Path '.\EndlessMining.rbxlx').Path
$terrainTest = (Resolve-Path '.\tests\Quarry.spec.luau').Path
$playTest = (Resolve-Path '.\tests\Play.spec.luau').Path

& $studioExe --task RunScript --localPlaceFile $quarryPlace --runScriptFile $terrainTest --outputFile "$env:TEMP\EndlessMining-terrain.log" --quitAfterExecution
```

Look for a standalone `QUARRY_TESTS_PASSED` output line. The map checks cover the walk from spawn, both market counters, their lights, the outer paths and 360 directions around the rock rim. The mining checks cover save ownership, profile validation, economy, three seeds, shared depletion, server reach and obstructions, face previews on all six sides, stale selections and repeated 5×5 cuts. Then run the two-client check in a signed-in Studio session.

```powershell
& $studioExe --task RunScript --localPlaceFile $quarryPlace --runScriptFile $playTest --outputFile "$env:TEMP\EndlessMining-play.log" --quitAfterExecution
```

The play check first uses a virtual mouse in a solo session to verify depth-tested face borders, the pickaxe grip through repeated swings, the visible cut meter, cancellation and collection. It then uses two clients with real client-to-server requests. Each miner must open all six menus, fill a pack, check its ore counts, visit the Sell counter, upgrade to a two-block cut, claim a job once, try both Studio passes, and return to the surface. The test checks that remote sales and out-of-range upgrades are declined, ore finds appear at the mined block, each sound loads, music and effects respond independently to their sliders, and an ore carrier moves. Look for `QUARRY_PLAYTEST_RESULT PASS` followed by both clients' results.

For hands-on checks, choose **Server & Clients** in Studio's Test selector and start two players. Mine the same face, compare balances and verify both players see the same missing bricks. Use the device emulator to check the shop, hold/release control, thumbstick and jump in phone landscape and portrait. A persistence round trip requires a separate published test place with Studio API access enabled. Sell ore, buy an upgrade, stop the session and rejoin to verify the balance and level.
