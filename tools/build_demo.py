"""Publish an atomic, cache-safe set of static demo modules; no npm build needed."""
from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parents[1] / 'docs' / 'demo'
sources = sorted(p for p in root.glob('*.js') if p.name != 'release.js')
inputs = sources + [root / 'style.css', root / 'index.template.html']
release = hashlib.sha256(b''.join(p.name.encode() + p.read_text(encoding='utf-8').encode('utf-8') for p in inputs)).hexdigest()[:12]
out = root / 'dist'
out.mkdir(exist_ok=True)
# Preserve old files: already-open/cached HTML must still resolve its own release.
for source in sources:
    text = source.read_text(encoding='utf-8')
    text = re.sub(r'([\'"])\./([\w-]+)\.js\1', lambda m: f'{m[1]}./{m[2]}-{release}.js{m[1]}', text)
    (out / f'{source.stem}-{release}.js').write_text(text, encoding='utf-8')
(out / f'release-{release}.js').write_text(f'export const RELEASE = "{release}";\n')
css = (root / 'style.css').read_text(encoding='utf-8')
css = re.sub(r'url\(([\'\"]?)assets/', r'url(\1../assets/', css)
(out / f'style-{release}.css').write_text(css, encoding='utf-8')
html = (root / 'index.template.html').read_text(encoding='utf-8')
html = html.replace('href="style.css"', f'href="dist/style-{release}.css"')
html = html.replace('src="app.js"', f'src="dist/app-{release}.js"')
(root / 'index.html').write_text(html, encoding='utf-8')
(root / 'release.json').write_text(json.dumps({'release': release}) + '\n')
print('Demo release:', release)
