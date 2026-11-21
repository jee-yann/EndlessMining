"""Triangulate original pressure crescents and ground spray for the meteor strike.

The coordinates are pencil units. Each color layer follows a closed contour of
quadratic Bézier curves. Run this script to regenerate CinderDrawings.luau.
"""

import math
from pathlib import Path


# Layers are painted back to front. Each segment gives the control point's
# x and y, followed by the endpoint's x and y. The tip of an open crescent
# is where its outer and inner curves meet.
DRAWINGS = {
    "front": [
        (
            "FFC47C",
            (-56, 32),
            [(-41, 16, -18, 11), (-8, 8, 3, 10), (-7, 6, -21, 9), (-46, 14, -56, 32)],
        ),
        (
            "FFEEBE",
            (-49, 24),
            [
                (-36, 14, -22, 13),
                (-14, 11, -8, 11),
                (-18, 9, -28, 12),
                (-43, 17, -49, 24),
            ],
        ),
        ("F1A679", (10, 20), [(24, 29, 40, 48), (37, 36, 27, 28), (19, 23, 10, 20)]),
        ("FFE3AD", (32, 35), [(46, 41, 57, 58), (53, 44, 44, 39), (39, 36, 32, 35)]),
    ],
    "spray": [
        (
            "ECC4A0",
            (-55, 5),
            [(-36, 8, -17, 15), (-9, 18, -2, 26), (-7, 17, -19, 12), (-41, 5, -55, 5)],
        ),
        ("FFE3B0", (-33, 8), [(-24, 12, -17, 12), (-22, 9, -33, 8)]),
    ],
}


def signed_area_twice(start, end, point):
    """Return a positive value when point lies left of the directed edge."""
    return (
        (end[0] - start[0]) * (point[1] - start[1])
        - (end[1] - start[1]) * (point[0] - start[0])
    )


def sample_contour(start, segments):
    points = [start]
    for control_x, control_y, end_x, end_y in segments:
        control = (control_x, control_y)
        end = (end_x, end_y)
        midpoint = ((start[0] + end_x) / 2, (start[1] + end_y) / 2)
        bend = math.dist(control, midpoint)
        steps = max(1, min(6, math.ceil(math.sqrt(bend / 0.85))))
        for step in range(1, steps + 1):
            t = step / steps
            point = tuple(
                round(
                    (1 - t) ** 2 * start_value
                    + 2 * t * (1 - t) * control_value
                    + t * t * end_value,
                    3,
                )
                for start_value, control_value, end_value in zip(start, control, end)
            )
            if math.dist(points[-1], point) > 0.03:
                points.append(point)
        start = end

    if points[-1] == points[0]:
        points.pop()
    area = sum(
        x1 * y2 - y1 * x2
        for (x1, y1), (x2, y2) in zip(points, points[1:] + points[:1])
    )
    if area <= 0:
        points.reverse()
    return points


def triangulate(points):
    """Clip ears in contour order and return one-based Luau vertex indices."""
    remaining = list(range(len(points)))
    triangles = []
    while len(remaining) > 2:
        for position, tip in enumerate(remaining):
            previous = remaining[position - 1]
            following = remaining[(position + 1) % len(remaining)]
            corners = previous, tip, following
            a, b, c = (points[index] for index in corners)
            if signed_area_twice(a, b, c) <= 0.00001:
                continue

            # An ear is convex and encloses no other point of the polygon.
            edges = ((a, b), (b, c), (c, a))
            if any(
                all(
                    signed_area_twice(start, end, points[index]) >= -0.000001
                    for start, end in edges
                )
                for index in remaining
                if index not in corners
            ):
                continue

            triangles.extend(index + 1 for index in corners)
            remaining.pop(position)
            break
        else:
            if len(remaining) == 3:
                last_triangle = (points[index] for index in remaining)
                if abs(signed_area_twice(*last_triangle)) < 0.05:
                    break
            raise ValueError(f"Self-intersection near {points[remaining[0]]}")
    return triangles


def bake():
    root = Path(__file__).resolve().parents[2]
    destination = root / "src/client/MineOrigins/CinderDrawings.luau"
    lines = [
        "-- Original native contour drawings. "
        "Regenerate with art/origins/draw_fire.py.",
        "return {",
    ]
    for name, layers in DRAWINGS.items():
        lines.append(f"\t{name} = {{")
        for color, anchor, segments in layers:
            points = sample_contour(anchor, segments)
            coordinates = ", ".join(f"{x:g}, {y:g}" for x, y in points)
            indices = ", ".join(map(str, triangulate(points)))
            lines.extend([
                f'\t\t{{ "{color}",',
                f"\t\t\t{{ {coordinates} }},",
                f"\t\t\t{{ {indices} }},",
                "\t\t},",
            ])
        lines.append("\t},")
    lines.append("}")
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    bake()
