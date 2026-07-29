import os
import re
import sys

LCOV_PATH = 'coverage/lcov.info'

def analyze_coverage():
    if not os.path.exists(LCOV_PATH):
        sys.exit(f"[ERROR] {LCOV_PATH} not found. It is generated output and is "
                 "no longer tracked in git -- run `flutter test --coverage` from "
                 "the project root first.")

    with open(LCOV_PATH, 'r') as f:
        content = f.read()

    files = content.split('end_of_record')
    folder_stats = {}

    for file_block in files:
        if not file_block.strip():
            continue

        sf_match = re.search(r'SF:(.*)', file_block)
        if not sf_match:
            continue

        file_path = sf_match.group(1)

        # Skip if not in lib folder
        if not file_path.startswith('lib'):
            continue

        # Get relative path - handle Windows backslash
        rel_path = file_path[4:]  # Remove 'lib\' or 'lib/'
        if rel_path.startswith('\\') or rel_path.startswith('/'):
            rel_path = rel_path[1:]

        # Get folder
        parts = rel_path.replace('\\', '/').split('/')
        folder = parts[0] if len(parts) > 1 else 'root'

        # Count lines using DA: pattern
        da_lines = re.findall(r'DA:(\d+),(\d+)', file_block)
        if da_lines:
            found = len(da_lines)
            hit = sum(1 for _, count in da_lines if int(count) > 0)

            if folder not in folder_stats:
                folder_stats[folder] = {'hit': 0, 'found': 0, 'files': 0}

            folder_stats[folder]['hit'] += hit
            folder_stats[folder]['found'] += found
            folder_stats[folder]['files'] += 1

    print()
    print('=== Coverage Report ===')
    print()
    print('{:<20} {:>6} {:>10} {:>10} {:>10}'.format('Folder', 'Files', 'Lines', 'Covered', 'Coverage'))
    print('-' * 60)

    total_hit = 0
    total_found = 0

    for folder in sorted(folder_stats.keys()):
        stats = folder_stats[folder]
        pct = (stats['hit'] / stats['found'] * 100) if stats['found'] > 0 else 0
        print('{:<20} {:>6} {:>10} {:>10} {:>9.1f}%'.format(folder, stats['files'], stats['found'], stats['hit'], pct))
        total_hit += stats['hit']
        total_found += stats['found']

    print('-' * 60)
    total_pct = (total_hit / total_found * 100) if total_found > 0 else 0
    print('{:<20} {:>6} {:>10} {:>10} {:>9.1f}%'.format('TOTAL', '', total_found, total_hit, total_pct))

if __name__ == '__main__':
    analyze_coverage()
