"""Run tests/*_spec.lua on LuaJIT (Lua 5.1, same as WoW) via lupa, without luarocks/busted.

    pip install lupa
    python tools/run_specs.py
"""

import sys
from pathlib import Path

import lupa.luajit21 as lupa

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    passed = failed = 0
    for spec in sorted((ROOT / 'tests').glob('*_spec.lua')):
        lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        lua.execute(f'package.path = "{ROOT.as_posix()}/?.lua;" .. package.path')
        results = lua.eval('dofile("tests/busted_shim.lua")')
        try:
            lua.execute(f'dofile("tests/{spec.name}")')
        except lupa.LuaError as exc:
            print(f'{spec.name}: failed to load\n    {exc}')
            failed += 1
            continue
        passed += results.passed
        failed += results.failed
        for failure in results.failures.values():
            print(f'FAIL {spec.name}: {failure}')
        print(f'{spec.name}: {results.passed} passed, {results.failed} failed')
    print(f'\n{passed} passed, {failed} failed')
    return 1 if failed else 0


if __name__ == '__main__':
    import os
    os.chdir(ROOT)
    sys.exit(main())
