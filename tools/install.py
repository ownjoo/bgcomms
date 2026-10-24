"""Install the working copy of BG Comms into your local WoW client(s) for testing.

Copies exactly what the release zip would hold (the .toc, the files it lists, LICENSE) into a
fresh Interface/AddOns/BattlegroundComms, stamping the version as dev-<commit>. Releases themselves
come from the tag-triggered GitHub workflow, not from here.

    python tools/install.py                      # every client with an AddOns folder
    python tools/install.py --client _forever_   # just one (created if missing)

After installing: /reload in game, or restart the client if files were added or removed.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON = 'BattlegroundComms'
TOC = f'{ADDON}.toc'
WOW_DIR = Path(r'C:\Program Files (x86)\World of Warcraft')
CLIENTS = ('_retail_', '_forever_', '_classic_beta_', '_anniversary_')
VERSION_TOKEN = '@project-version@'


def addon_files(root: Path) -> list[str]:
    """The .toc, every file it lists (in order), Bindings.xml and LICENSE, as forward-slash paths."""
    files = [TOC]
    for line in (root / TOC).read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            files.append(line.replace('\\', '/'))
    files += ['Bindings.xml', 'LICENSE']   # WoW loads Bindings.xml by name
    for name in files:
        if not (root / name).is_file():
            raise FileNotFoundError(f'{name} is listed for the addon but missing from {root}')
    return files


def render_toc(text: str, version: str) -> str:
    return text.replace(VERSION_TOKEN, version)


def install(root: Path, addons_dir: Path, version: str) -> Path:
    files = addon_files(root)
    dest = addons_dir / ADDON
    if dest.exists():
        shutil.rmtree(dest)
    for name in files:
        target = dest / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if name == TOC:
            target.write_text(render_toc((root / name).read_text(encoding='utf-8'), version), encoding='utf-8')
        else:
            shutil.copy2(root / name, target)
    return dest


def target_clients(wow_dir: Path, clients: list[str] | None) -> list[Path]:
    """AddOns folders to install into: the named clients, or every installed one that has one."""
    if clients:
        return [wow_dir / c / 'Interface' / 'AddOns' for c in clients]
    return [wow_dir / c / 'Interface' / 'AddOns' for c in CLIENTS if (wow_dir / c / 'Interface' / 'AddOns').is_dir()]


def dev_version(root: Path) -> str:
    try:
        sha = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], cwd=root, capture_output=True,
                             text=True, check=True).stdout.strip()
        dirty = subprocess.run(['git', 'status', '--porcelain'], cwd=root, capture_output=True,
                               text=True, check=True).stdout.strip()
        return f'dev-{sha}' + ('-dirty' if dirty else '')
    except (OSError, subprocess.CalledProcessError):
        return 'dev'


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--wow-dir', type=Path, default=WOW_DIR)
    parser.add_argument('--client', action='append', help=f'client folder, e.g. {CLIENTS[0]} (repeatable)')
    args = parser.parse_args()

    targets = target_clients(args.wow_dir, args.client)
    if not targets:
        raise SystemExit(f'no client AddOns folders found under {args.wow_dir}; pass --client')
    version = dev_version(ROOT)
    for addons_dir in targets:
        addons_dir.mkdir(parents=True, exist_ok=True)
        print(f'installed {version} -> {install(ROOT, addons_dir, version)}')


if __name__ == '__main__':
    main()
