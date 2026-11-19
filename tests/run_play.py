"""Run the Studio input and multiplayer checks against disposable Rojo builds."""

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests"


def make_project(folder, mode):
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    tree = project["tree"]

    def resolve_paths(node):
        if isinstance(node, dict):
            for key, child in node.items():
                if key == "$path":
                    node[key] = str(ROOT / child)
                else:
                    resolve_paths(child)

    resolve_paths(tree)
    tree["ReplicatedStorage"].setdefault("$attributes", {}).update(
        MuteTestMusic=True, MiningTestMode=mode
    )
    tree["ServerScriptService"]["Server"].setdefault("$attributes", {})["StudioMineSeed"] = 73129
    tree["ServerScriptService"]["MiningPlaytest"] = {
        "$path": str(TESTS / "play" / "Driver.server.luau")
    }
    tree["StarterPlayer"]["StarterPlayerScripts"]["MiningPlaytest"] = {
        "$path": str(TESTS / "play" / "Miner.client.luau")
    }
    path = folder / f"{mode}.project.json"
    path.write_text(json.dumps(project), encoding="utf-8")
    return path


def run(studio, folder, mode, marker):
    project = make_project(folder, mode)
    place = folder / f"{mode}.rbxlx"
    log = folder / f"{mode}.log"
    subprocess.run(["rojo", "build", project, "-o", place], check=True)
    startup = None
    if sys.platform == "win32":
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = subprocess.SW_HIDE
    subprocess.run(
        [
            studio, "--task", "RunScript", "--localPlaceFile", place,
            "--runScriptFile", TESTS / "Play.spec.luau", "--outputFile", log,
            "--quitAfterExecution",
        ],
        check=True,
        startupinfo=startup,
        timeout=250,
    )
    output = log.read_text(encoding="utf-8", errors="replace")
    results = [line for line in output.splitlines() if line.startswith(marker + " ")]
    if not results or any(not line.startswith(marker + " PASS ") for line in results):
        raise RuntimeError(f"{mode} failed in Studio.\n{output[-4000:]}")
    print(results[-1], flush=True)


if __name__ == "__main__":
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument("studio", type=Path, help="path to the Studio executable")
    studio = args.parse_args().studio.resolve(strict=True)
    with tempfile.TemporaryDirectory(prefix="endless-mining-") as temp:
        run(studio, Path(temp), "Swing", "MINING_SWING_RESULT")
        run(studio, Path(temp), "Multiplayer", "MINING_PLAYTEST_RESULT")
