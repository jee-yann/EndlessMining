"""Rebuild the distant, non-interactive northern coast in the editable place."""

from math import cos, sin, sqrt
from pathlib import Path
import re

MAP = Path(__file__).resolve().parents[2] / "map/CitrineCove.rbxmx"
SEA = 20.4


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])


def unit(v):
    length = sqrt(dot(v, v))
    return tuple(x / length for x in v)


def values(keys, nums):
    return "".join(f"<{key}>{n:.7g}</{key}>" for key, n in zip(keys, nums))


def cut(face, color, name, output):
    a, b, c = face
    ab, ac, bc = sub(b,a), sub(c,a), sub(c,b)
    if dot(ab,ab) > max(dot(ac,ac), dot(bc,bc)):
        a, c = c, a
    elif dot(ac,ac) > dot(bc,bc):
        a, b = b, a
    ab, ac, bc = sub(b,a), sub(c,a), sub(c,b)
    normal, along = unit(cross(ac,ab)), unit(bc)
    up = cross(along,normal)
    for sign, corner in ((1,b),(-1,c)):
        depth = abs(dot(sub(corner,a),along))
        if depth < .025:
            continue
        center = tuple((x+y)/2 for x,y in zip(corner,a))
        rotation = [v for i in range(3) for v in (normal[i]*sign,up[i],along[i]*sign)]
        output.append(f'''        <Item class="WedgePart" referent="NORTHCAPE{len(output):04d}">
          <Properties>
            <string name="Name">{name}</string>
            <bool name="Anchored">true</bool><bool name="CanCollide">false</bool><bool name="CanTouch">false</bool><bool name="CanQuery">false</bool>
            <bool name="CastShadow">true</bool>
            <Vector3 name="size">{values("XYZ", (.075, abs(dot(ab,up)),depth))}</Vector3>
            <CoordinateFrame name="CFrame">{values("XYZ",center)}{values([f"R{i}{j}" for i in range(3) for j in range(3)],rotation)}</CoordinateFrame>
            <Color3uint8 name="Color3uint8">{0xff000000 | int(color,16)}</Color3uint8>
            <token name="Material">272</token><token name="TopSurface">0</token><token name="BottomSurface">0</token>
          </Properties>
        </Item>''')


def ridge(spine, z, breadth, output):
    # Water-carved inlets widen below saddles. Broken folds cut obliquely
    # across the taller peaks so that the faces do not read as parallel cones.
    rows = []
    for i, (x, h) in enumerate(spine):
        bend = sin(.043*x + 1.2)
        cap = max(0, min(1, h/26))
        crest = z - 9*cos(.034*x) + 7*sin(.066*x)
        fan = breadth * (.81 + .17*bend + .09*cos(.085*x))
        slip = (3.7 + 8*sin(.054*x)) * cap
        rows.append([
            (x, SEA - 3.5, crest + fan + 5*bend),
            (x + 1.5*bend*cap, SEA + h*.23, crest + fan*.68),
            (x - slip*.42, SEA + h*(.46+.09*bend), crest + fan*.39),
            (x + slip, SEA + h*(.87+.06*cos(.083*x)), crest + fan*.13),
            (x, SEA + h, crest),
            (x - slip, SEA + h*.49, crest - fan*.42),
            (x, SEA - 3.5, crest - fan*.91),
        ])
    palette = [
        ("607C82","657E82","688588"), ("687E78","738780","758881"),
        ("788A80","859489","778D87"), ("8C968D","939991","8A938E"),
        ("738687","788988","6A8085"), ("596E79","647A80","63767D"),
    ]
    for i, (a,b) in enumerate(zip(rows,rows[1:])):
        for k, tones in enumerate(palette):
            name = "Mountain flank" if k < 3 else "Summit facet" if k == 3 else "Far slope"
            tri = ((a[k],b[k],a[k+1]),(b[k],b[k+1],a[k+1]))
            if (i+k)%3 == 1:
                tri = ((a[k],b[k],b[k+1]),(a[k],b[k+1],a[k+1]))
            for j, points in enumerate(tri):
                cut(points, tones[(i//2+k+j)%3], name, output)


def bake():
    faces = []
    # A low western skerry and two sea-carved ridges share the same offshore
    # shelf as the former scenic peaks, behind the traversable cableway mesas.
    ridge([(-280,-1),(-269,9),(-251,21),(-237,24),(-221,15),(-206,6),(-199,-1)], -168, 28, faces)
    ridge([(-197,-2),(-178,17),(-160,36),(-148,42),(-137,39),(-117,63),(-99,90),
           (-87,97),(-74,85),(-61,89),(-43,73),(-28,60),(-11,54),(7,45),
           (21,48),(38,36),(57,26),(72,13),(82,-2)], -170, 59, faces)
    ridge([(62,-2),(76,11),(91,27),(110,38),(126,62),(139,77),(151,70),
           (163,74),(180,54),(193,45),(212,47),(233,29),(249,17),(269,-2)], -198, 48, faces)
    source = MAP.read_bytes().decode()
    pattern = re.compile(r'^[ \t]*<Item class="WedgePart"[^>]*>\s*<Properties>\s*<string name="Name">(?:Mountain flank|Summit facet|Far slope)</string>.*?</Properties>\s*</Item>\r?\n', re.M | re.S)
    placed = False
    def replace(_):
        nonlocal placed
        if placed:
            return ""
        placed = True
        return "\n".join(faces) + "\n"
    result, count = pattern.subn(replace, source)
    assert count and placed
    MAP.write_bytes(result.encode())


if __name__ == "__main__":
    bake()
