"""Pack the cinematic matte paintings for offline play (Pillow, zstandard)."""

import base64
from pathlib import Path

from PIL import Image
import zstandard


def pack(source, output):
    image = source.convert("RGB").resize((552, 368), Image.Resampling.LANCZOS).quantize(256)
    palette = bytes(image.getpalette())
    rgba = b"".join(palette[i:i + 3] + b"\xff" for i in range(0, len(palette), 3))
    packed = zstandard.ZstdCompressor(level=18).compress(rgba + image.tobytes())
    output.write_bytes(base64.b64encode(packed))


def main():
    folder = Path(__file__).resolve().parent
    output = folder.parents[1] / "src/client/MineOrigins/Plates"
    output.mkdir(parents=True, exist_ok=True)
    atlases = {
        "Keeper": ("Orbit", None, "Find", None),
        "Headland": ("Basalt", "Tide", "Meadow", "Harbor"),
    }
    for filename, tiles in atlases.items():
        with Image.open(folder / f"{filename}.png") as source:
            width, height = source.width // 2, source.height // 2
            for index, name in enumerate(tiles):
                if name is None:
                    continue
                x, y = index % 2 * width, index // 2 * height
                crop = source.crop((x + 1, y + 1, x + width - 1, y + height - 1))
                pack(crop, output / f"{name}.txt")
    with Image.open(folder / "DrillCore.png") as sample:
        pack(sample, output / "Workshop.txt")


if __name__ == "__main__":
    main()
