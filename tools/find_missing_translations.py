import json
from pathlib import Path

base = Path('lib/l10n/app_en.arb')
locales = ['fr','sw','rw']

base_keys = set()
with base.open(encoding='utf-8') as f:
    data = json.load(f)
    # ignore metadata keys starting with @
    base_keys = set(k for k in data.keys() if not k.startswith('@'))

missing = {}
for loc in locales:
    p = Path(f'lib/l10n/app_{loc}.arb')
    if not p.exists():
        missing[loc] = None
        continue
    with p.open(encoding='utf-8') as f:
        d = json.load(f)
        keys = set(k for k in d.keys() if not k.startswith('@'))
        missing_keys = sorted(list(base_keys - keys))
        missing[loc] = missing_keys

for loc, keys in missing.items():
    if keys is None:
        print(f'{loc}: file not found')
    else:
        print(f'{loc}: {len(keys)} missing')
        for k in keys:
            print('  -', k)
