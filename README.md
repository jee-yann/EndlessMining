# Mine EVERYTHING!

![Citrine Cove in Roblox Studio](map/CitrineCove-preview.jpg)

Citrine Cove is a multiplayer Roblox mining simulator. Aim at a cave wall or floor to highlight a single block, hold through the pickaxe swing, and bring the ore to the harbor. Each block face measures 5 × 5 studs. Every pick takes one block per cut. Speed shortens the cut and Power unlocks harder ore. A starter pack holds 36 blocks. Ore grants XP. Each level after the first awards one skill point.

## Play locally

1. Open `build/Mine-Everything.rbxlx` in Roblox Studio, or use the existing **Endless Mining** Studio place connected to this project's Rojo server. To create the build from a fresh checkout, use the commands below.
2. Press **F5**. The island is already visible in edit mode. Play generates studded plastic bricks behind the cave mouth. Cross the bridge, walk under the golden crystal marked **MINE** and onto the dirt floor. Aim down at a studded block and hold the left mouse button. On a touch device, aim with the center dot and hold **HOLD MINE**.
3. After eight blocks, open **Jobs** and claim **First strike** for 25 gold. Walk to the cyan **Upgrades** stall, use its prompt and buy **Capacity** for 24 gold to carry 80 blocks. Use the amber **Sell** counter to empty your pack. The side panel lists carried materials, rarest first, along with quantities and sale value. Select it to inspect the full pack.
4. Dig through the walls and floor to reach deeper regions. The top compass shows X and Z in blocks from the entrance and Y in blocks from the first dirt layer. Y drops by one for each full block you descend. At Y −27 you enter Iron Shelf. **Index** lists the per-block ore chances at each depth. **↑ Surface** brings you to the path outside the mine. The screen fades to black during the trip, with a longer return from deeper levels. Open **Settings** from the dock to adjust music, sound effects or menu animations.

The place uses each player’s equipped Roblox avatar. If Studio Output reports an authentication error for a missing head or clothing texture, refresh the Studio sign-in and start another play session.

![Music, sound effects and menu motion in Settings](map/Settings-preview.jpg)

To rebuild the local place after editing, run the following command in the project directory.

```powershell
New-Item -ItemType Directory -Force build | Out-Null
rojo build default.project.json -o build/Mine-Everything.rbxlx
```

For live editing, run `rojo serve default.project.json` here if this project's server is stopped. In Studio, use **Plugins → Rojo → Connect** and select **EndlessMining** at `localhost:34872`. A built place can be played directly without connecting the plugin.

## Saving your work

- **On your PC** press **Ctrl+S** in VS Code to save a script. If you edit the island directly in Studio, stop Play before editing and save the `Workspace.CitrineCove` model to `map/CitrineCove.rbxmx`. The build command above bundles those files into a place you can reopen.
- **On GitHub** commit your saved source files, then push your feature branch. In VS Code these actions are under **Source Control**. A pull request lets you merge the work into `main`.
- **On Roblox** open the built place in Studio and choose **File → Publish**. A new experience starts private. Open the published experience in the Roblox app to keep your miner’s gold, inventory, upgrades and best depth. The game autosaves every 45 seconds and on exit. A local playtest labeled **Practice session** resets when you stop it. [Roblox publishing guide](https://create.roblox.com/docs/production/publishing/publish-games-and-places)

## World and balance

The harbor spans roughly 268 × 229 studs inside a continuous rock rim. The spawn compass opens onto a 95-stud-wide court. Follow the central bridge to the mine, the amber bullion sign to Sell, or the cyan pickaxe to Upgrades. Side paths pass ore wagons, gardens and the stepped waterfall. Both hillside paths climb to the rear cableway trail, where four grounded towers carry three moving ore cars.

Music and effects have separate sliders in **Settings**. Volume and menu-motion preferences are saved with player progress. The track plays quietly beneath the mining cues. The music slider sets the volume of Anthony Mawer’s *Prima Bossa Nova*. The buttons use short bubble pops. Each ore has its own break sound, and gold, diamond and emerald add progressively longer rising notes. [Prima Bossa Nova](https://create.roblox.com/store/asset/1837070127) · [UI Cute Pop](https://create.roblox.com/store/asset/15675055424) · [UI Cute Goodbye](https://create.roblox.com/store/asset/15675081158)

![The haul panel and gold balance at the mine entrance](map/Harbor-HUD.jpg)

The harbor has a dispatch board, a covered Ore Index with eight labeled samples, a pass stall and a leaderboard court behind spawn. One board ranks the top five connected miners by level. The other ranks your Roblox friends by depth. The top-right server leaderboard shows every connected miner’s level, equipped title and current gold. It sorts by level. Click its header or press Tab to fold or expand it. Each board has three podiums with waving miners. In published play it includes friends with saved scores even when they are offline. Local practice sessions use connected miners.

![Friends and Server Miners boards behind spawn](map/Miners-Court.jpg)

Digging opens a shared route through five regions. Each eligible block independently rolls against its region’s percentages.

| Region | Depth below the dig floor | Stone | Coal | Copper | Iron | Gold | Diamond | Emerald | Mystery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Sunstone Hollow | 0–26 | 82% | 13% | 5% | – | – | – | – | – |
| Iron Shelf | 27–89 | 78% | 6% | 7% | 8% | 1% | – | – | – |
| Prism Grotto | 90–184 | 75% | 3% | 5% | 9% | 6% | 2% | – | – |
| Emerald Deep | 185–259 | 72.88% | 2% | 3% | 7% | 8% | 5% | 2% | 0.12% |
| Midnight Fault | 260+ | 74.755% | 2% | 3% | 5% | 6% | 6% | 3% | 0.22% and 0.025% |

The percentages apply to solid rock beneath the two dirt layers. Cave air yields no material.

The backpack shows occupied slots, each ore count and the gold the Sell counter will pay for it.

![Backpack showing one coal worth five gold](map/Backpack-preview.jpg)

Each of the seven shift jobs pays once. Players can collect completed jobs in any order. The index keeps discoveries after a sale. Coal and rarer ores grant increasing XP. The wallet shows level progress between XP thresholds. Dirt and stone count toward achievements. **Inventory → Titles** shows the unlock levels and equips the player’s choice. The **Skills** tab maps linked paths for reach, movement, lighting and cutting speed. **Pets** equips or names one cosmetic rock. Custom names use Roblox’s broadcast text filter. The **Achievements** dock button lists every goal and tracks lifetime totals and consecutive-cut challenges. Sequence progress carries over between visits. Achievement and title unlocks queue their own center-screen celebration. Existing saves keep earned XP and start material counts with their current haul. Capacity grows the worn field pack, Power changes the pick head and its arc, and Speed shortens every cut.

Walk through the arch at island height. The hut has a 10 × 10 floor of five-stud dirt blocks, flush with the entrance sill. Dig through two dirt layers to reach stone and ore, then tunnel under the island in any direction. The surrounding foundation holds up the paths and bluffs. The top HUD shows region, coordinates, depth and the surface return. Horizontal headings continue beneath the island and out past the shoreline. All materials gain rock hardness at depths 27, 60, 90, 140 and 185. Each step adds 45% of the base cutting time and requires the corresponding Power level. Hard ores also retain their own Power requirement.

The server privately seeds each field. An 8 × 8 × 8 chunk keeps records only for excavated cells and their exposed neighbours. Breaking into a cave opens a long, bending passage with a solid floor and ceiling. Nearby clients stream this rock as players advance. After 2,400 cuts the server gives a 20-second warning, brings miners outside, and replaces the field. Players keep their haul, level and upgrades.

Each completed cut removes the highlighted block. A mint border follows its exposed faces. A pick cursor marks a valid target, a red symbol marks ore above the current Power level, and five stepped fracture patterns branch across each exposed face. The ink disappears with the block. At the same Speed level, diamond takes 2.5 times as long to cut as stone and emerald takes three times as long. Releasing early or switching targets cancels the swing. The server checks elapsed cutting time, reach, sight, power, and space before awarding a block. Returning players receive a one-time gold refund for retired mining-area purchases.

![Block borders in three Studio views, exposed, flush with the wall, and covered by another rock](map/Mining-area-preview.jpg)

| Change | File |
| --- | --- |
| Seed, site, layers, reach, save interval and work budget | `src/shared/GameConfig.luau` |
| Material appearance, sale value and required power | `src/shared/Ores.luau` |
| Upgrade values, level caps and cost curves | `src/shared/Upgrades.luau` |
| Skill tree, pets and achievements | `src/shared/FieldGuide.luau` |
| Jobs and ranks | `src/shared/Expeditions.luau` |
| Game pass IDs and perks | `src/shared/PassCatalog.luau`, `src/server/Passes.luau` |
| Seeded ore rolls and underground caves | `src/server/Geology.luau` |
| Editable island, signed stations, spawn and bridge | `map/CitrineCove.rbxmx` |
| Studded brick geometry and visible targets | `src/server/MineBlocks.luau`, `src/shared/BlockPattern.luau` |
| Region depths and ore percentages | `src/shared/GameConfig.luau` |
| Station binding | `src/server/MineSite.luau` |
| Starting editor camera and lighting | `default.project.json` |
| Music and button sounds | `src/client/HarborAudio.luau` |

## Project and data ownership

Rojo owns the scripts under `ReplicatedStorage.Shared`, `ServerScriptService.Server` and `StarterPlayer.StarterPlayerScripts.Client`, plus the authored `Workspace.CitrineCove` model and the lighting listed in `default.project.json`. To keep island edits in the source project, export the selected CitrineCove model from Studio as `map/CitrineCove.rbxmx` before rebuilding. Keep additional Studio-only models as siblings in Workspace. The server starts the mine at the island’s SiteOrigin and checks for unrelated parts and existing terrain before choosing a dig site. If the site is occupied, it relocates the island and mine together for that session. Existing terrain palettes are preserved.

During Play the edit-mode cave face gives way to the shared block grid. Remotes, HUD and headlamps are created at runtime. Player profiles contain gold, ore still in the pack, upgrade levels, lifetime ore mined, mining XP, best depth, completed jobs and discovered ore types. The server uses DataStore `EndlessMining_v1` with separate Studio and live scopes, conditional session ownership, periodic saves, and leave/shutdown saves. A failed load or unsupported record opens an explicitly labeled temporary session with writes disabled. An unpublished local build or a simulated test user gets a practice session.

## Visual references

Three local Roblox captures in `%LOCALAPPDATA%\Roblox\tmp-capture-storage` informed the island. The beach scene ending in `1795063278721` supplied the sea, sand-path and studded-lawn palette. The grass ledges in `1795062944957` informed the layered bluffs. The striped tool stand in `1795063226069` informed the small coral and teal market stalls. The citrine outcrop and island geometry use native Studio parts.

The two newer lobby captures ending in `1795070093346` and `1795070096049` informed the oversized signs, colored icon dock and visible job tracker. The harbor, pickaxe and HUD icons are built from native Roblox objects.

## Outfitters and Robux

**Double Gold** doubles ore-sale proceeds. **Prism Trail** equips a cosmetic rainbow trail that returns after respawn. The **Outfitters** counter’s **Try in Studio** button previews either perk in an unpublished practice session. A trial ends when the player leaves.

To turn on real sales after publishing, create two passes for this experience under **Creator Dashboard → Monetization → Passes**, put them on sale, and enter their pass asset IDs in `src/shared/PassCatalog.luau`. Publish the updated build. The shop requests the player's current price from Roblox, and checkout opens after the player selects the price. The server checks ownership on join and grants successful purchases. [Roblox pass setup](https://create.roblox.com/docs/production/monetization/passes) · [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing)

## Reproduce the checks

The tests live outside the game’s Rojo tree. Use a fresh local build for the map check. With Studio open, these PowerShell commands select its installed executable.

```powershell
$studioExe = (Get-Process RobloxStudioBeta | Select-Object -First 1).Path
$miningPlace = (Resolve-Path '.\build\Mine-Everything.rbxlx').Path
$terrainTest = (Resolve-Path '.\tests\Mine.spec.luau').Path

& $studioExe --task RunScript --localPlaceFile $miningPlace --runScriptFile $terrainTest --outputFile "$env:TEMP\EndlessMining-terrain.log" --quitAfterExecution
```

Look for a standalone `MINING_TESTS_PASSED` output line. The map checks cover the walk from spawn, both market counters, their lights, the outer paths, 360 directions around the rock rim and the surface threshold and the diggable hut floor. The mining checks cover save ownership, profile validation, economy, three seeds, shared depletion, server reach and obstructions, two pure dirt layers, regional stone percentages, sealed caves, depth gates and long headings across chunk boundaries. Run the input and two-client checks with Python 3 and a signed-in Studio session. The runner builds two temporary places with the test players and music mute already configured.

```powershell
python tests/run_play.py "$studioExe"
```

The play check first uses a virtual mouse in a solo session to verify depth-tested face borders, the pickaxe grip through repeated swings, the visible cut meter, cancellation and collection. It then uses two clients with real client-to-server requests. Each miner must check the server leaderboard, open the inventory, pet, skill, achievement and station menus, fill a pack, check its ore counts, visit the Sell counter, upgrade pack capacity, collect two completed jobs in reverse order, try both Studio passes, and return to the surface. The test checks that remote sales and out-of-range upgrades are declined, ore finds appear at the mined block, effects load and respond to their slider, the soundtrack stays muted during automated playtests, and an ore carrier moves. Look for `MINING_PLAYTEST_RESULT PASS` followed by both clients' results.

For hands-on checks, choose **Server & Clients** in Studio's Test selector and start two players. Mine the same face, compare balances and verify both players see the same missing bricks. Use the device emulator to check the shop, hold/release control, thumbstick and jump in phone landscape and portrait. A persistence round trip requires a separate published test place with Studio API access enabled. Sell ore, buy an upgrade, stop the session and rejoin to verify the balance and level.
