#!/usr/bin/env python3
"""Package the portable addon without editor caches, demo, or project settings."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addons" / "forma_ui"
DESTINATION = ROOT / "dist" / "forma_ui-0.1.0.zip"


def main() -> None:
    DESTINATION.parent.mkdir(exist_ok=True)
    files = sorted(path for path in ADDON.rglob("*") if path.is_file())
    with ZipFile(DESTINATION, "w", ZIP_DEFLATED) as archive:
        for path in files:
            if ".godot" in path.parts or path.suffix in {".tmp", ".pyc"}:
                continue
            archive.write(path, path.relative_to(ROOT))
    with ZipFile(DESTINATION) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("Addon archive failed integrity validation")
        print(f"Packaged {len(archive.namelist())} files: {DESTINATION}")


if __name__ == "__main__":
    main()
