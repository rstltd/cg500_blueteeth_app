import os
import sys

with open('coverage/lcov.info', 'r') as f:
    content = f.read()

total_lines = 0
covered_lines = 0
file_stats = []

current_file = ''
file_covered = 0
file_total = 0

for line in content.split('\n'):
    if line.startswith('SF:'):
        path = line[3:]
        # Handle both Windows and Unix paths
        if '/' in path:
            current_file = path.split('/')[-1]
        else:
            current_file = path.split('\\')[-1]
    elif line.startswith('DA:'):
        parts = line[3:].split(',')
        if len(parts) >= 2:
            total_lines += 1
            file_total += 1
            if int(parts[1]) > 0:
                covered_lines += 1
                file_covered += 1
    elif line.startswith('end_of_record'):
        if file_total > 0:
            pct = (file_covered / file_total) * 100
            uncovered = file_total - file_covered
            file_stats.append((current_file, file_covered, file_total, pct, uncovered))
        current_file = ''
        file_covered = 0
        file_total = 0

coverage_pct = (covered_lines / total_lines) * 100 if total_lines > 0 else 0
target_lines = int(total_lines * 0.50)
needed = target_lines - covered_lines

# Check for filter argument
show_widgets = len(sys.argv) > 1 and sys.argv[1] == 'widgets'

print('=== Coverage Summary ===')
print(f'Total lines: {total_lines}')
print(f'Covered lines: {covered_lines}')
print(f'Coverage: {coverage_pct:.1f}%')
print(f'Target (50%): {target_lines} lines')
print(f'Still need: {needed} lines')
print()

if show_widgets:
    print('=== Widgets and Services with uncovered lines (top 15) ===')
    widget_stats = [(n, c, t, p, u) for n, c, t, p, u in file_stats
                    if 'widget' in n.lower() or 'service' in n.lower()]
    widget_stats.sort(key=lambda x: x[4], reverse=True)
    for name, cov, tot, pct, uncov in widget_stats[:15]:
        print(f'{name}: {uncov} uncovered ({pct:.1f}% covered)')
else:
    print('=== Files with most uncovered lines (top 10) ===')
    file_stats.sort(key=lambda x: x[4], reverse=True)
    for name, cov, tot, pct, uncov in file_stats[:10]:
        print(f'{name}: {uncov} uncovered ({pct:.1f}% covered)')
