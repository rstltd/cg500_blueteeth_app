import os
import re
import sys

LCOV_PATH = 'coverage/lcov.info'
if not os.path.exists(LCOV_PATH):
    sys.exit(f"[ERROR] {LCOV_PATH} not found. It is generated output and is no "
             "longer tracked in git -- run `flutter test --coverage` from the "
             "project root first.")

with open(LCOV_PATH, 'r') as f:
    content = f.read()

# Parse each file's coverage
files = content.split('end_of_record')
results = []

for file_data in files:
    if 'SF:' not in file_data:
        continue

    sf_match = re.search(r'SF:(.+)', file_data)
    lf_match = re.search(r'LF:(\d+)', file_data)
    lh_match = re.search(r'LH:(\d+)', file_data)

    if sf_match and lf_match and lh_match:
        filename = sf_match.group(1).replace('\\', '/').replace('lib/', '')
        total_lines = int(lf_match.group(1))
        hit_lines = int(lh_match.group(1))
        coverage = (hit_lines / total_lines * 100) if total_lines > 0 else 0
        results.append((filename, hit_lines, total_lines, coverage))

# Sort by coverage percentage
results.sort(key=lambda x: -x[3])

# Group by layer
models = [r for r in results if r[0].startswith('models/')]
utils = [r for r in results if r[0].startswith('utils/')]
controllers = [r for r in results if r[0].startswith('controllers/')]
services = [r for r in results if r[0].startswith('services/')]
views = [r for r in results if r[0].startswith('views/')]
widgets = [r for r in results if r[0].startswith('widgets/')]
other = [r for r in results if not any(r[0].startswith(p) for p in ['models/', 'utils/', 'controllers/', 'services/', 'views/', 'widgets/'])]

def print_layer(name, data):
    if not data:
        return
    total_hit = sum(r[1] for r in data)
    total_lines = sum(r[2] for r in data)
    avg_coverage = (total_hit / total_lines * 100) if total_lines > 0 else 0
    print(f'\n=== {name} ({avg_coverage:.1f}%) ===')
    for filename, hit, total, cov in sorted(data, key=lambda x: -x[3]):
        print(f'  {filename}: {cov:.1f}% ({hit}/{total})')

print_layer('Models', models)
print_layer('Utils', utils)
print_layer('Controllers', controllers)
print_layer('Services', services)
print_layer('Views', views)
print_layer('Widgets', widgets)
print_layer('Other', other)

# Overall stats
total_hit = sum(r[1] for r in results)
total_lines = sum(r[2] for r in results)
overall = (total_hit / total_lines * 100) if total_lines > 0 else 0
print(f'\n=== OVERALL: {overall:.1f}% ({total_hit}/{total_lines}) ===')
