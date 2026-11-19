"""Build and verify an isolated BagSmithTest ZIP. Never modifies the WoW install.

Usage: python tools/package_test_addon.py --output-dir PATH
Requires the same lupa dependency as tools/run_tests.py.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]


def convert(data, relative):
    if relative.suffix.lower() not in ('.lua', '.xml', '.toc', '.md', '.txt') or 'Libs' in relative.parts:
        return data
    text = data.decode('utf-8-sig').replace('BagSmith', 'BagSmithTest').replace('BAGSMITH', 'BAGSMITHTEST')
    text = re.sub(r'/bagsmith\b', '/bagsmithtest', text)
    text = re.sub(r'/bs\b', '/bstest', text)
    text = text.replace('BagSmithTest Options', 'BagSmith Options')
    if relative.suffix == '.toc':
        text = text.replace('## Title: BagSmithTest', '## Title: BagSmith 2.0 Test')
        text = text.replace('## Author: BagSmithTest', '## Author: BagSmith')
        text = text.replace('## Notes: Spreadsheet-style bags for WoW Forever.',
                            '## Notes: Isolated 2.0 alpha test. Disable regular BagSmith while testing.')
    return text.encode('utf-8')


def verify(folder):
    from lupa.lua51 import LuaRuntime
    lua = LuaRuntime(unpack_returned_tuples=True)
    for path in (folder / 'BagSmithTest').rglob('*.lua'):
        lua.execute('assert(loadstring(...))', path.read_text(encoding='utf-8-sig'))
    mock = (ROOT / 'tests/mock.lua').read_text(encoding='utf-8')
    lua.globals().mockSource = mock.replace('BagSmith', 'BagSmithTest').replace('BAGSMITH', 'BAGSMITHTEST')
    lua.execute('''package.preload.mock=function() return assert(loadstring(mockSource))() end
passes=0; fails=0
function check(ok,msg) if ok then passes=passes+1 else fails=fails+1; print('FAIL: '..msg) end end''')
    test = (ROOT / 'tests/core_2_0_0_tests.lua').read_text(encoding='utf-8')
    previous = Path.cwd()
    try:
        os.chdir(folder)
        lua.execute('local _ = true\n' + test.replace('BagSmith', 'BagSmithTest').replace('BAGSMITH', 'BAGSMITHTEST'))
    finally:
        os.chdir(previous)
    assert lua.globals().fails == 0, 'Packaged addon regression failure'
    for name in ('BagSmith', 'BagSmithDB', 'BagSmithCharDB'):
        assert lua.globals()[name] is None, f'Original namespace touched: {name}'
    return lua.globals().passes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, required=True)
    args = parser.parse_args()
    toc = (ROOT / 'BagSmith/BagSmith.toc').read_text(encoding='utf-8')
    version = re.search(r'^## Version: (.+)$', toc, re.M)[1].strip()
    args.output_dir = args.output_dir.resolve()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    destination = args.output_dir / f'BagSmith-{version}-Test.zip'
    if destination.exists():
        raise FileExistsError(f'Refusing to overwrite existing release: {destination}')
    with tempfile.TemporaryDirectory(prefix='.bagsmith-package-', dir=args.output_dir) as temporary:
        stage = Path(temporary).resolve()
        assert stage.parent == args.output_dir, "Staging must stay within the release directory"
        for path in sorted((ROOT / 'BagSmith').rglob('*')):
            if not path.is_file():
                continue
            relative = path.relative_to(ROOT / 'BagSmith')
            target = stage / 'BagSmithTest' / relative
            if relative.name == 'BagSmith.toc':
                target = target.with_name('BagSmithTest.toc')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(convert(path.read_bytes(), relative))
        passes = verify(stage)
        files = {p.relative_to(stage).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                 for p in sorted((stage / 'BagSmithTest').rglob('*')) if p.is_file()}
        (stage / 'TESTING.txt').write_text(
            f'BagSmith {version} - isolated test addon\n\n'
            'Extract BagSmithTest into World of Warcraft/_forever_/Interface/AddOns.\n'
            'Back up an existing BagSmithTest folder before replacing it.\n'
            'Enable BagSmith 2.0 Test and disable regular BagSmith while testing.\n'
            'Restart WoW if this is a new addon folder; otherwise /reload.\n'
            'Test settings are separate (BagSmithTestDB / BagSmithTestCharDB).\n'
            'Commands: /bstest and /bagsmithtest.\n\n'
            'Display: List, Standard, Compact, Split. Group by: All, Category, Bag.\n'
            'Sidebar sections start expanded. Headers stay single-line.\n'
            'Open currencies or BagSmith Options to dismiss the other drawer.\n'
            'Review both skins, narrow windows, fonts, bank and Global Inventory.\n'
            'Automated mock checks passed; actual in-game review is still needed.\n', encoding='utf-8')
        (stage / 'MANIFEST.json').write_text(json.dumps(
            {'version': version, 'upstream': '6004e6e', 'checks_passed': passes, 'files': files}, indent=2), encoding='utf-8')
        with ZipFile(destination, 'x', ZIP_DEFLATED) as archive:
            for path in sorted(stage.rglob('*')):
                if path.is_file():
                    archive.write(path, path.relative_to(stage).as_posix())
        with ZipFile(destination) as archive:
            assert archive.testzip() is None
            for name, digest in files.items():
                assert hashlib.sha256(archive.read(name)).hexdigest() == digest
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix('.zip.sha256').write_text(f'{digest}  {destination.name}\n')
    print(f'{destination.resolve()}\n{len(files)} addon files; {passes} checks passed; ZIP hashes verified')


if __name__ == '__main__':
    main()
