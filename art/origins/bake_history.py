"""Bake the island's actual geometry into exposures for the private history set.

Run from any directory after changing map/CitrineCove.rbxmx. Object transforms stay
in portal coordinates. The construction order is authored by trade, height and
position so each exposure can be mounted whole on a low frame rate client.
"""

import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "map/CitrineCove.rbxmx"
DEST = ROOT / "src/client/MineOrigins/HistoryAtlas.luau"
GATE_FLOOR = (0, 24.205, 5.25)
BASE_PARTS = {"Part", "WedgePart", "SpawnLocation"}
IDENTITY = (1, 0, 0, 0, 1, 0, 0, 0, 1)
FPS = 8


def prop(item, key):
    return item.find(f"./Properties/*[@name='{key}']")


def name(item):
    return prop(item, "Name").text


def vector(item, key="CFrame"):
    field = prop(item, key)
    return tuple(float(field.findtext(axis)) for axis in "XYZ")


def number(value):
    return "0" if abs(value) < 0.000004 else f"{value:.6f}".rstrip("0").rstrip(".")


def row(values):
    return "{" + ", ".join(json.dumps(v) if isinstance(v, str) else number(v) for v in values) + "}"


def fraction(value, span=1):
    return max(0, min(1, value / span))


def planting(x, z):
    return 3.85 + 1.95 * fraction((z + 100) / 238 + math.sin(x * 0.041) * 0.22)


def shoal(x, z):
    return 2.0 + 1.75 * fraction((z + 127) / 288 + 0.17 * math.sin(x * 0.044))


def patch(x, z):
    # The docks are cut into the western valley first, then the front court,
    # eastern lots and finally the northern rock wall.
    return fraction(0.44 + x / 340 - z / 425)


def timing(path, piece, x, y, z):
    top, area, *_ = path + ["", ""]
    low = piece.lower()
    if top == "Island and lagoon":
        if piece in ("Lagoon", "Shallow water", "Water glint"):
            return None  # The lagoon runs all the way to the horizon in this view.
        if piece.startswith("Distant"):
            return "Offshore banks", 0
        return (
            ("Terraced shore fill", 7.25 + 0.98 * patch(x, z))
            if z > 1
            else ("Bank below the terraces", shoal(x, z))
        )
    if top == "Honey bluffs":
        return "Weathered sandstone", 3.35 + 0.8 * patch(x, z) + y * 0.006
    if top == "Coastal grove":
        return "Coastal grove", (8.36 + 0.72 * patch(x, z) if z > 0 and y < 12 else planting(x, z))
    if top == "Wildflowers":
        return "Meadow in blossom", 5.50 + patch(x, z) * 0.8
    if top == "Spring falls":
        return "Spring above the shore", 4.28 + (0.35 if "Falling" in piece or "foam" in piece else 0)
    if top == "EditFace":
        return "Rock beneath the dig", 3.43
    if top == "Working gallery":
        if "lamp" in low or "lantern" in low:
            return "Gallery lamps", 14.78 + (z + 72) / 250
        if "lintel" in low or piece == "Entrance sill":
            return "Gallery floor and headers", 12.89
        return "Quarry rock", 3.35 + 0.65 * patch(x, z)
    if top == "Citrine Mine":
        if piece in (
            "Cave jamb",
            "Cave shoulder",
            "Capstone",
            "Amber keystone bed",
            "Crystal facet",
            "Crystal point",
        ):
            return "Citrine outcrop", 3.82 + y * 0.008
        if piece in ("Portal footing", "Cut basalt pier", "Arch voussoir"):
            return "Dressed arch stones", 12.88 + y * 0.044 + (0.06 if x > 0 else 0)
        if piece in ("Mine sign", "Painted edge"):
            return "Mine sign", 14.45
        return "Entrance fittings", 14.76 + y * 0.02
    if top == "Sand path and bridge":
        if piece == "Landing":  # The camera set has no second spawn.
            return None
        if piece == "Bridge bearer":
            return "Footbridge bearers", 9.10
        if piece == "Bridge plank":
            return "Footbridge deck boards", 9.35 + fraction((39 - z) / 14) * 0.8
        if piece == "Bridge decking":
            return "Footbridge deck", 10.18
        if piece == "Bridge post":
            return "Footbridge posts", 9.10 + fraction((39 - z) / 14) * 0.45
        if piece in ("Handrail", "Post cap"):
            return "Footbridge handrails", 10.2 + fraction((39 - z) / 14) * 0.35
        if piece == "Landing path":
            return "Path from the landing", 8.56 + fraction((101 - z) / 64) * 0.54
        return "Way into the mine", 10.35 + fraction((30 - z) / 36) * 0.78
    if top == "Shore market" or (top == "Harbor Plaza" and area in ("Jobs", "Store", "Supplies", "Book")):
        # The same order repeats from bay to bay. Adjacent workshops overlap,
        # producing a row of roofs being tiled from west to east.
        bay = {"Supplies": 0, "Sell": 0.15, "Upgrades": 0.45, "Book": 0.67, "Jobs": 0.68, "Store": 0.80}.get(
            area, 0
        )
        center = {"Supplies": -46, "Sell": -20, "Upgrades": 20, "Book": 46, "Jobs": -20, "Store": 20}.get(
            area, x
        )
        if any(word in low for word in ("deck", "floor", "service mat", "plinth", "pad inlay")):
            t = 9.65
        elif any(
            word in low
            for word in ("upright", "post", "canopy post", "wall", "edging", "frame", "counter board", "foot")
        ):
            t = 10.12 + min(0.30, y * 0.027)
        elif any(word in low for word in ("canvas", "canopy", "scallop", "hem")):
            t = 10.82 + fraction((x - center + 8) / 16) * 0.69
            if "hem" in low or "valance" in low or "scallop" in low:
                t += 0.13
        elif any(word in low for word in ("counter", "shelf", "back", "cork")):
            t = 10.59 + y * 0.021
        else:
            t = 11.76 + fraction(y / 17) * 0.38
        return area + " workshop", t + bay
    if top == "Harbor Plaza":
        if area == "Arrival court":
            if "Compass" in piece:
                return "Landing compass", 13.66 + y * 0.018
            return "Graded plaza paving", 10.15 + fraction((110 - z) / 78) * 1.55 + (
                0.23 if piece == "Lane stripe" else 0
            )
        if area == "Beacon Point":
            if "island" in low:
                return "Beacon headland", 3.5
            return "Harbor beacon", 13.0 + fraction(y / 28) * 2.28
        if area == "Loading dock":
            if "piling" in low:
                return "Dock pilings", 8.4 + (z + 12) / 240
            if "deck" in low:
                return "Dock planking", 9.12 + (x + 75) / 30
            return "Loading crane", 12.25 + fraction(y / 17) * 1.15
        if area == "Miners Court":
            if "foundation" in low or "paving" in low:
                return "Court foundations", 11 + fraction(x + 33, 66) * 0.78
            return "Miners Court", 12.2 + fraction(y / 23) * 1.65 + fraction(x + 33, 66) * 0.42
    if top == "Citrine Highlands":
        if area == "Outer meadows":
            if piece in ("Headland turf", "Tidal shallows"):
                return (
                    ("Terraced shore fill", 7.25 + 0.98 * patch(x, z))
                    if z > -8
                    else ("Bay shore", shoal(x, z))
                )
            if piece == "Bridge pile":
                return "Boardwalk piles", 8.55 + 0.62 * patch(x, z)
            if piece in ("Footboard", "Timber deck"):
                return "Boardwalk", 9.16 + fraction(z + 62, 220) * 1.80
            return "Boardwalk rails", 11.1 + 0.46 * patch(x, z)
        if area in ("Rock rim", "Cableway ridge"):
            if piece in ("Quartz shaft", "Quartz crown", "Quartz glint"):
                return None  # Floating decorative skyline off the playable ridge.
            if piece in ("Mountain flank", "Summit facet", "Far slope"):
                return "Offshore mountains", 0
            if area == "Rock rim" and z > -14:
                # The low quay walls are built from the first spoil removed
                # from the hills. They run across the former natural beach.
                rock = 7.61 + 1.84 * fraction(0.44 + x / 318 - z / 430)
                if "Fir" in piece:
                    return "Pines behind the quay", rock + 1.16
                return "Sea wall above the new terraces", rock + (
                    0.53 if piece in ("Slate crown", "Turf on the rim") else 0
                )
            if piece in ("Fir trunk", "Fir boughs"):
                return "Pines on the rim", planting(x, z) + 0.28
            return "Rocky island rim", 3.1 + 1.40 * patch(x, z)
        if area == "Turquoise cascade":
            if piece in ("Mesa face", "Meadow cap"):
                return "Cascade banks", 3.95
            return "Upper falls", 4.45 + fraction(-z / 46) * 0.38
        if area == "Compass gardens":
            if piece in ("Fir trunk", "Fir boughs", "Meadow flower", "Leaf tuft", "Grass bed"):
                return "Planted beds", 12.68 + patch(x, z)
            return "Benches and gardens", 13.45 + patch(x, z) + (0.46 if "lamp" in low else 0)
        if area == "Ore siding":
            if piece == "Sleeper":
                return "Track sleepers", 12.45 + fraction((82 - z) / 82) * 1.26
            if piece == "Rail":
                return "Rail into the siding", 14.15
            return "Ore wagons", 14.25 + fraction((80 - z) / 80) * 0.52 + fraction(y / 7) * 0.2
        if area == "Cableway trail":
            if any(w in low for w in ("slope", "wild stone", "ridgeline turf")):
                return "Upper ridge", 3.98 + 0.5 * patch(x, z)
            if "pine" in low:
                return "Ridge pines", planting(x, z) + 0.18
            if "footing" in low:
                return "Tower footings", 12.60 + fraction(x + 130, 260) * 0.55
            return "Ridge trail", 12.07 + fraction(x + 130, 260) * 1.45
        if area == "Ridge tramway":
            # The original rails include both tower trestles and overhead cables.
            return "Cableway trestles", 13.22 + fraction(y / 53) * 1.31 + fraction(x + 105, 210) * 0.38
        if area == "Moving cabins":
            return "Cableway buckets", 15.12 + fraction(x + 72, 145) * 0.32
        if area in ("Exchange lights", "Workshop lights"):
            return "Market lanterns", 14.86 + fraction(x + 28, 56) * 0.45
    return "Waterfront fittings", 13.2 + fraction(y / 33) * 0.85


def bake():
    island = ET.parse(SOURCE).getroot().find("Item")
    finishes, rotations, tracks = {}, {}, {}

    def visit(item, path):
        cls = item.get("class")
        label = name(item)
        if cls not in BASE_PARTS:
            if cls in ("Model", "Folder"):
                for child in item.findall("Item"):
                    visit(child, path + [label])
            return
        props = item.find("Properties")
        opacity = float(props.findtext("float[@name='Transparency']", "0"))
        if opacity >= 0.95:
            return
        at = tuple(round(v - o, 4) for v, o in zip(vector(item), GATE_FLOOR))
        stage = timing(path, label, *at)
        if not stage:
            return
        trade, age = stage
        shape = 3 if cls == "WedgePart" else int(props.findtext("token[@name='shape']", "1"))
        color = int(prop(item, "Color3uint8").text) & 0xFFFFFF
        finish = (
            shape,
            f"{color:06X}",
            int(props.findtext("token[@name='Material']", "272")),
            int(props.findtext("token[@name='TopSurface']", "0")),
            int(props.findtext("token[@name='BottomSurface']", "0")),
            opacity,
        )
        index = finishes.setdefault(finish, len(finishes) + 1)
        orientation = tuple(
            round(float(prop(item, "CFrame").findtext(f"R{a}{b}")), 6) for a in range(3) for b in range(3)
        )
        rot = rotations.setdefault(orientation, len(rotations) + 1) if orientation != IDENTITY else 0
        size = tuple(round(v, 4) for v in vector(item, "size"))

        def emit(pos, dimensions, style, time):
            info = (style, *[round(v, 4) for v in pos], *[round(v, 4) for v in dimensions])
            if rot or label == "Mine sign":
                info += (rot,)
            if label == "Mine sign":
                info += (1,)
            tracks.setdefault((int(time * FPS + 0.5), trade), []).append(info)

        def point(local):
            return tuple(at[k] + sum(orientation[3 * k + j] * local[j] for j in range(3)) for k in range(3))

        paving = label in (
            "Mine path",
            "Market square",
            "Painted promenade",
            "Central concourse",
            "Court foundation",
            "Court paving",
            "Landing path",
            "Basalt rim",
        )
        if (paving or trade == "Terraced shore fill") and shape == 1 and max(size[0], size[2]) > 18:
            nx, nz = math.ceil(size[0] / 15), math.ceil(size[2] / 15)
            w, d = size[0] / nx, size[2] / nz
            for i in range(nx):
                for j in range(nz):
                    p = point(((i + 0.5) * w - size[0] / 2, 0, (j + 0.5) * d - size[2] / 2))
                    lag = (
                        1.29 * patch(p[0], p[2])
                        if not paving
                        else 0.45 * fraction(1 - j / nz) + 0.19 * i / nx
                    )
                    time = 7.15 + lag if trade == "Terraced shore fill" else age + lag
                    emit(p, (w, size[1], d), index, time)
            return
        if trade == "Terraced shore fill" and shape == 3 and max(size[1:]) > 21:
            # Cross-sections through the original right triangular prism.
            # Each strip comprises the old vertical foot and its sloping edge.
            # Both share the source rotation, so the finished outline is exact.
            count = math.ceil(max(size[1:]) / 16)
            h, d = size[1] / count, size[2] / count
            fill = (1, *finish[1:])
            block = finishes.setdefault(fill, len(finishes) + 1)
            for j in range(count):
                zc = -size[2] / 2 + (j + 0.5) * d
                if j:
                    p = point((0, -size[1] / 2 + j * h / 2, zc))
                    emit(p, (size[0], j * h, d), block, 7.15 + 1.29 * patch(p[0], p[2]))
                p = point((0, -size[1] / 2 + (j + 0.5) * h, zc))
                emit(p, (size[0], h, d), index, 7.15 + 1.29 * patch(p[0], p[2]))
            return
        emit(at, size, index, age)

    for child in island.findall("Item"):
        visit(child, [])
    lines = [
        "-- Geometry and shot exposures baked from the playable map by art/origins/bake_history.py.",
        "return {",
        "\tfinishes = {",
    ]
    lines.extend("\t\t" + row(style) + "," for style in finishes)
    lines.extend(["\t},", "\torientations = {"])
    lines.extend("\t\t" + row(rot) + "," for rot in rotations)
    lines.extend(["\t},", "\texposures = {"])
    for (frame, trade), pieces in sorted(tracks.items()):
        lines.append(f"\t\t{{ {frame}, {json.dumps(trade)}, {{")
        lines.extend("\t\t\t" + row(piece) + "," for piece in pieces)
        lines.append("\t\t} },")
    lines.extend(["\t},", "}"])
    DEST.write_bytes(("\n".join(lines) + "\n").encode("utf8"))
    print(f"{sum(map(len, tracks.values()))} island pieces in {len(tracks)} construction exposures")


if __name__ == "__main__":
    bake()
