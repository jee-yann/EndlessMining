"""Bake the two original 256px ejecta plates.

From the project root run this script with NumPy, SciPy and zstandard installed.
The RGBA atlas is stored with the place. Roblox applies bilinear filtering as it
moves through the shot. Studio and clients that permit local image creation
use these pixels; the native ballistic material also works independently.
"""
import base64
import json
from pathlib import Path

import numpy as np
from scipy.ndimage import gaussian_filter
import zstandard

SIZE, DEPTH = 256, 80


def plate(seed, hot):
    rng = np.random.default_rng(seed)
    shape = (DEPTH, SIZE, SIZE)
    z, y, x = np.ogrid[-1:1:complex(DEPTH), 1:-1:complex(SIZE), -1:1:complex(SIZE)]

    def noise(wavelength):
        field = rng.standard_normal(shape, dtype=np.float32)
        field = gaussian_filter(field, (wavelength * DEPTH / SIZE, wavelength, wavelength))
        return np.clip(field / (3.0 * np.std(field)), -1.35, 1.35)

    large, grain = noise(10), noise(3.4)
    xx = x + 0.13 * large + 0.047 * grain
    yy = y + 0.13 * noise(12) + 0.038 * noise(4)
    zz = z + 0.12 * noise(9)
    # Overlapping vortices give the plume a folded, uneven contour.
    lobes = [
        (-.32, -.22, .08, .41, .38, .37), (.06, -.20, -.06, .56, .48, .42),
        (.39, -.07, .10, .31, .36, .31), (-.36, .12, -.08, .36, .37, .41),
        (-.08, .36, .12, .36, .38, .35), (.24, .25, -.10, .41, .36, .40),
        (.48, .11, -.14, .18, .24, .20), (-.31, .41, .1, .18, .21, .18),
    ]
    surface = np.full(shape, -4, np.float32)
    for cx, cy, cz, a, b, c in lobes:
        d = np.sqrt(((xx-cx)/a)**2 + ((yy-cy)/b)**2 + ((zz-cz)/c)**2)
        np.maximum(surface, 1-d, out=surface)
    ink = np.clip((surface + .11 + grain*.095) * 1.7, 0, 1)
    nz, ny, nx = np.gradient(gaussian_filter(ink, (1, 2.1, 2.1)))
    norm = np.maximum(np.sqrt(nz*nz*.10 + ny*ny + nx*nx), .004)
    sun = np.clip((-nx*.45 + ny*.68 - nz*.20)/norm, -1, 1)
    luminance = .48 + .22*sun + .17*large + .08*grain - .10*np.abs(x)
    if hot:
        luminance = .46 + sun*.15 + .42*large + .09*grain + .28*surface - .22*y
    trans = np.ones((SIZE, SIZE), np.float32)
    tone = np.zeros_like(trans)
    for k in range(DEPTH-1, -1, -1):
        alpha = 1-np.exp(-ink[k]*(.20 if hot else .14))
        tone += trans * alpha * np.clip(luminance[k], 0, 1)
        trans *= 1-alpha
    alpha = 1-trans
    value = np.divide(tone, alpha, out=np.zeros_like(tone), where=alpha>.0001)
    stops = (["512F45","944047","DF6240","FF9F50","FFD995","FFF4CD"]
             if hot else ["584F60","77636D","977E7B","AC9890","CFB9A4","EBD6B8"])
    palette = np.array([tuple(bytes.fromhex(s)) for s in stops])
    channels = [np.interp(value, np.linspace(0, 1, len(stops)), palette[:,i]) for i in range(3)]
    return np.rint(np.dstack((*channels, alpha*255))).astype(np.uint8)


def fit_brushes(tile, seed, count=72):
    # The Roblox implosion mask is a smooth white gaussian of sigma 0.13
    # at 88% central coverage. Approximate the premultiplied reference with
    # translucent, tinted ellipses so an image-restricted client can paint it.
    rng = np.random.default_rng(seed)
    n = 32
    reference = tile.reshape(n, SIZE//n, n, SIZE//n, 4).mean(axis=(1,3)) / 255
    target = reference.reshape(-1,4).astype(np.float32)
    target[:,:3] *= target[:,3:4]
    canvas = np.zeros_like(target)
    yy, xx = np.mgrid[0:n,0:n].reshape(2,-1).astype(np.float32)
    xx, yy = (xx+.5)/n, (yy+.5)/n
    weights = np.array([1,1,1,1.85], np.float32)
    arcs = []
    for i in range(count):
        diff = target-canvas
        error = (diff**2)@weights
        cent = rng.choice(n*n, size=196, replace=True, p=error/error.sum())
        cx = xx[cent]+rng.uniform(-.015,.015,len(cent))
        cy = yy[cent]+rng.uniform(-.015,.015,len(cent))
        size = np.maximum(.017, rng.uniform(.018, .17, len(cent))*(1-.42*i/count))
        stretch = rng.uniform(.60,1.45,len(cent))
        sx, sy = size*stretch, size/stretch
        rot = rng.uniform(0,np.pi,len(cent))
        dx, dy = xx[None,:]-cx[:,None], yy[None,:]-cy[:,None]
        co, sn = np.cos(rot)[:,None], np.sin(rot)[:,None]
        rx = (co*dx+sn*dy)/sx[:,None]
        ry = (-sn*dx+co*dy)/sy[:,None]
        gauss = (.88*np.exp(-.5*(rx**2+ry**2))).astype(np.float32)
        sq = gauss**2
        energy = sq.sum(axis=1)
        dr, cc = gauss@diff, sq@canvas
        corr = gauss @ ((diff*canvas)@weights)
        norm = sq @ ((canvas**2)@weights)
        best = None
        for strength in (.47,.74,1.0):
            rgba = np.clip((dr/strength+cc)/energy[:,None], 0,1)
            rgba[:,3] = 1
            gain = 2*strength*((rgba*dr)@weights-corr) - strength**2*(
                energy*((rgba**2)@weights)-2*((rgba*cc)@weights)+norm)
            idx = int(np.argmax(gain))
            if best is None or gain[idx] > best[0]:
                best = (gain[idx],idx,strength,rgba[idx])
        _,j,strength,color=best
        blend=gauss[j,:,None]*strength
        canvas += blend*(color-canvas)
        tint="".join(f"{round(float(v)*255):02X}" for v in color[:3])
        arcs.append((cx[j],cy[j],sx[j]/.13,sy[j]/.13,np.degrees(rot[j]),strength,tint))
    return arcs


def save_brushes(hot, ash):
    lines=["-- Generated from the premultiplied 256px ejecta artwork. See art/origins/paint_ejecta.py.","return {"]
    for kind,tile,seed in [("melt",hot,583),("ash",ash,913)]:
        lines.append("\t"+kind+" = {")
        for x,y,w,h,rot,strength,color in fit_brushes(tile,seed):
            lines.append(f'\t\t{{{x:.4f}, {y:.4f}, {w:.4f}, {h:.4f}, {rot:.2f}, {strength:.2f}, "{color}"}},')
        lines.append("\t},")
    lines+=["}",""]
    Path("src/client/MineOrigins/EjectaBrushes.luau").write_bytes("\n".join(lines).encode("ascii"))


if __name__ == "__main__":
    hot, ash = plate(781,True),plate(8793,False)
    save_brushes(hot, ash)
    atlas = np.concatenate((hot,ash), axis=1)
    compressed = zstandard.ZstdCompressor(level=18).compress(atlas.tobytes())
    payload = {"ClassName":"StringValue", "Properties":{"Value":base64.b64encode(compressed).decode("ascii")}}
    target = Path("src/client/MineOrigins/EjectaRaster.model.json")
    target.write_bytes((json.dumps(payload, separators=(",", ":"))+"\n").encode("ascii"))
