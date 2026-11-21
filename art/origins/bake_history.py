"""Bake the playable cove's scenery and animation groups into the opening.

Run this file with Python after editing the island. The atlas carries geometry and
finishes only. Client play never copies or animates instances from the live island.
"""

import json
from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "map/CitrineCove.rbxmx"
DEST = ROOT / "src/client/MineOrigins/HistoryAtlas.luau"
GATE_FLOOR = (0, 24.205, 5.25)
BASE_PARTS = {"Part", "WedgePart", "SpawnLocation"}
IDENTITY = (1, 0, 0, 0, 1, 0, 0, 0, 1)


def prop(item, key):
    return item.find(f"./Properties/*[@name='{key}']")


def name(item):
    return prop(item, "Name").text


def vector(item, key="CFrame"):
    field = prop(item, key)
    return tuple(float(field.findtext(axis)) for axis in "XYZ")


def children(node, path):
    for key in path.split("/"):
        node = next(child for child in node.findall("Item") if name(child) == key)
    return node


def solids(model):
    return [item for item in model.iter("Item") if item.get("class") in BASE_PARTS]


def named(items, *names):
    return [part for part in items if name(part) in names]


def number(value):
    return "0" if abs(value) < .000004 else f"{value:.6f}".rstrip("0").rstrip(".")


def lua_row(values):
    return "{" + ", ".join(json.dumps(v) if isinstance(v, str) else number(v) for v in values) + "}"


class Atlas:
    def __init__(self):
        self.map = ET.parse(SOURCE).getroot().find("Item")
        self.finishes = {}
        self.rotations = {}
        self.groups = {}

    def parts(self, path):
        return solids(children(self.map, path))

    def add(self, label, motion, start, duration, parts, offset=(0, 0, 0)):
        pieces = []
        for part in parts:
            props = part.find("Properties")
            transparency = float(props.findtext("float[@name='Transparency']", "0"))
            if transparency >= .95:
                continue
            color = int(prop(part, "Color3uint8").text) & 0xffffff
            shape = 3 if part.get("class") == "WedgePart" else int(props.findtext("token[@name='shape']", "1"))
            finish = (shape, f"{color:06X}", int(props.findtext("token[@name='Material']", "272")),
                      int(props.findtext("token[@name='TopSurface']", "0")),
                      int(props.findtext("token[@name='BottomSurface']", "0")), transparency)
            style_id = self.finishes.setdefault(finish, len(self.finishes) + 1)
            rotation = tuple(round(float(prop(part, "CFrame").findtext(f"R{a}{b}")), 6)
                             for a in range(3) for b in range(3))
            position = (round(v - origin + shift, 4) for v, origin, shift in zip(vector(part), GATE_FLOOR, offset))
            size = (round(v, 4) for v in vector(part, "size"))
            piece = (style_id, *position, *size)
            if rotation != IDENTITY:
                piece += (self.rotations.setdefault(rotation, len(self.rotations) + 1),)
            pieces.append(piece)
        if pieces:
            self.groups.setdefault((label, motion, start, duration), []).extend(pieces)

    def write(self):
        lines = ["-- Cinematic scenery sampled from map/CitrineCove.rbxmx, in studs relative to the portal paving.",
                 "-- Each piece stores its finish, center, dimensions and optional orientation index.", "return {",
                 "\tfinishes = {"]
        lines.extend("\t\t" + lua_row(style) + "," for style in self.finishes)
        lines.extend(["\t},", "\torientations = {"])
        lines.extend("\t\t" + lua_row(rotation) + "," for rotation in self.rotations)
        lines.extend(["\t},", "\tformations = {"])
        for (label, motion, start, duration), pieces in self.groups.items():
            lines.append(f"\t\t{{ name = {json.dumps(label)}, motion = {json.dumps(motion)}, "
                         f"start = {number(start)}, duration = {number(duration)}, pieces = {{")
            lines.extend("\t\t\t" + lua_row(piece) + "," for piece in pieces)
            lines.append("\t\t} },")
        lines.extend(["\t},", "}"])
        DEST.write_bytes(("\n".join(lines) + "\n").encode("utf8"))


def terrain(a):
    shore = a.parts("Island and lagoon")
    a.add("Strait and tide pools", "Water", 0, 0, named(shore, "Lagoon", "Shallow water", "Water glint", "Tide rock"))
    a.add("Two banks", "Soil", 0, 0, [p for p in shore if "island" in name(p) or "Distant" in name(p)])
    a.add("Outer meadow", "Soil", 0, 0, named(a.parts("Citrine Highlands/Outer meadows"), "Headland turf", "Tidal shallows"))

    ridge = a.parts("Citrine Highlands/Cableway ridge")
    a.add("Northern skyline", "Distant", 1, 4, named(ridge, "Mountain flank", "Summit facet", "Far slope"))
    a.add("Cableway mesas", "Highland", 1.5, 5, named(ridge, "Mesa face", "Meadow cap", "Basalt bedding"))
    tree = []
    for part in ridge:
        if name(part) == "Fir trunk":
            if tree:
                a.add(f"Ridge fir {len(a.groups)}", "MesaTree", 5.5 + abs(vector(tree[0])[0]) % 8 / 6, 1.55, tree)
            tree = [part]
        elif name(part) == "Fir boughs":
            tree.append(part)
    if tree:
        a.add(f"Ridge fir {len(a.groups)}", "MesaTree", 6.3, 1.4, tree)

    rim = named(a.parts("Citrine Highlands/Rock rim"), "Coastal escarpment", "Slate crown")
    a.add("Coastal cliffs", "Highland", 1, 5, [p for p in rim if vector(p)[2] < 45])
    bluffs = a.parts("Honey bluffs")
    a.add("Honey bluffs west", "Bluff", 2.9, 3.5, [p for p in bluffs if vector(p)[0] < 0])
    a.add("Honey bluffs east", "Bluff", 2.3, 3.5, [p for p in bluffs if vector(p)[0] >= 0])
    gallery = a.parts("Working gallery")
    a.add("Gallery bedrock", "Bedrock", 2.4, 4.5, named(gallery, "Bank foundation", "Bank turf", "Bluff foundation",
          "Bluff turf", "Sloping bluff foundation", "Ridge footing", "Rear bluff foundation", "Hut side wall",
          "Hut back wall", "Rear gallery ceiling", "Stone canopy", "Entrance return", "Sill foundation"))
    a.add("Authored dig floor", "Gallery", 2.4, 4.5, a.parts("EditFace"))
    a.add("Gallery strata and fittings", "Gallery", 2.4, 4.5, named(gallery, "Exposed bedding", "Mica lens", "Deep fault",
          "Center lantern hanger", "Center lantern housing", "Center lantern", "Lantern hook", "Survey lamp", "Gallery lintel"))
    a.add("Gallery threshold", "Pave", 13.35, .8, named(gallery, "Entrance sill", "Gallery lintel", "Survey lamp",
          "Center lantern", "Center lantern hanger", "Center lantern housing"))

    grove = children(a.map, "Coastal grove").findall("Item")
    for j, tree in enumerate(grove):
        tree_parts = solids(tree)
        x, y, _ = vector(tree_parts[0])
        growth = "MesaTree" if abs(x) > 100 else "BluffTree" if y > 35 else "Tree"
        a.add(f"Sea grape {j+1}", growth, 4.15 + (j*7 % 11)*.23, 1.35 + .2*(j%3), tree_parts)
    # Root early growth in the future plaza and clear the crossing when the survey arrives.
    banks = [(-14, 14), (19, 19), (-25, 26), (11, 56), (-17, 63), (31, 48), (-40, 13)]
    for j, (x, z) in enumerate(banks):
        tree = solids(grove[j])
        trunk_x, trunk_y, trunk_z = vector(tree[0])
        foot = trunk_y - vector(tree[0], "size")[1] / 2
        a.add(f"Pioneer grove {j+1}", "Pioneer", 4.3 + j*.29, 1.9, tree, (x-trunk_x, 24-foot, z-trunk_z))
    a.add("Waterfall", "Falls", 4.15, 1.9, a.parts("Spring falls"))


def crossing(a):
    bridge = a.parts("Sand path and bridge")
    a.add("Footpath", "Pave", 10.1, 1.7, named(bridge, "Landing path"))
    a.add("Survey junction", "Pave", 12.2, 1.6, named(bridge, "Mine path", "Market square", "Portal paving"))
    deck = named(bridge, "Bridge bearer", "Bridge plank", "Bridge decking", "Bridge post", "Handrail", "Post cap")
    for i, part in enumerate(sorted(deck, key=lambda item: -vector(item)[2])):
        key = name(part)
        distance = 43 - vector(part)[2]
        if key == "Bridge plank":
            motion, start, duration = "Board", 11.80 + distance*.085, .37
        elif key == "Bridge bearer":
            motion, start, duration = "Raise", 11.03, .62
        elif key == "Bridge decking":
            motion, start, duration = "Pave", 12.97, .66
        elif key in ("Bridge post", "Post cap"):
            motion, start, duration = "Raise", 11.28 + distance*.088 + (.3 if key == "Post cap" else 0), .43
        else:
            motion, start, duration = "Board", 12.05 + distance*.087, .52
        a.add(f"{key} {i+1}", motion, start, duration, [part])

    arch = a.parts("Citrine Mine")
    a.add("Arch shoulders", "Bluff", 2.95, 3.6, named(arch, "Cave jamb", "Cave shoulder", "Capstone",
          "Amber keystone bed", "Crystal facet", "Crystal point"))
    masonry = sorted(named(arch, "Cut basalt pier", "Arch voussoir"), key=lambda part: (vector(part)[1], vector(part)[0]))
    for j, part in enumerate(masonry):
        a.add(f"{name(part)} {j}", "Mason", 13.38 + j*.18, .68, [part])
    a.add("Sconces", "Lights", 16.8, .43, named(arch, "Sconce base", "Amber sconce", "Guide inlay", "Threshold stud",
          "Brass reveal", "Reflector", "Guide post", "Guide rail", "Portal footing"))
    a.add("Mine sign", "Sign", 14.90, 1.69, named(arch, "Mine sign", "Painted edge"))


def settlement(a):
    for j, stall in enumerate(("Sell", "Upgrades", "Supplies", "Book", "Store", "Jobs")):
        items = a.parts(("Shore market/" if j < 2 else "Harbor Plaza/") + stall)
        if j >= 2:
            a.add(stall+" stall", "Furniture", 15.55+j*.22, .92,
                  [p for p in items if "label" not in name(p).lower() and name(p) not in ("Name tag", "Printed rule")])
            continue
        a.add(stall+" floor", "Pave", 13.3+j*.22, .66, named(items, "Deck", "Service mat"))
        a.add(stall+" posts", "Raise", 13.85+j*.3, .77, named(items, "Canopy post"))
        separate = ("Deck", "Service mat", "Canopy post", "Canvas stripe", "Scalloped valance", "Name tag")
        a.add(stall+" counter", "Furniture", 14.50+j*.30, .72, [p for p in items if name(p) not in separate])
        canvas = named(items, "Canvas stripe", "Scalloped valance")
        for k, x in enumerate(sorted({vector(p)[0] for p in canvas})):
            a.add(f"{stall} awning {k+1}", "Awning", 15.24+j*.33+k*.083, .38, [p for p in canvas if vector(p)[0] == x])

    for k, lights in enumerate(("Exchange lights", "Workshop lights")):
        a.add(lights, "Lights", 16.85+k*.28, .65, a.parts("Citrine Highlands/" + lights))
    a.add("Arrival court", "Pave", 14.8, 2.25, a.parts("Harbor Plaza/Arrival court"))
    gardens = a.parts("Citrine Highlands/Compass gardens")
    a.add("Benches and feet", "Furniture", 15.5, .79, [p for p in gardens if name(p).startswith("Bench")])
    a.add("Garden lamps", "Lights", 16.89, .75, named(gardens, "Lamp foot", "Enamel post", "Lantern collar", "Lantern glass", "Lantern hood"))
    a.add("Cableway", "Tram", 14.2, 2.25, a.parts("Citrine Highlands/Ridge tramway"))
    a.add("Cableway buckets", "Cabins", 16.1, 1, a.parts("Citrine Highlands/Moving cabins"))
    wagon = [p for p in a.parts("Citrine Highlands/Ore siding") if name(p) not in ("Sleeper", "Rail") and 20 < vector(p)[2] < 31]
    a.add("Stone wagon", "Wagon", 12.55, 5.8, wagon, (93.8, 0, -9))


if __name__ == "__main__":
    atlas = Atlas()
    terrain(atlas)
    crossing(atlas)
    settlement(atlas)
    atlas.write()
