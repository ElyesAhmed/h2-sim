# Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.
#
# This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).
#
# h2sim is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# h2sim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with h2sim.  If not, see <http://www.gnu.org/licenses/>.

"""Compare tracked H2sim biochemistry files with an exact MRST Git revision.

Match relocated files by basename before declaring a file new. For new MATLAB
files, also look for substantial copied code elsewhere in MRST; retain those
source notices when adding H2sim attribution. Data and binary assets are never
relicensed by this tool.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import difflib
import hashlib
import json
from pathlib import Path
import re
import subprocess

YEAR = '2026'
MODULE = 'modules/h2-biochem/'
NOTICE = '''%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of The MATLAB Reservoir Simulation Toolbox (h2sim).

h2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

h2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with h2sim.  If not, see <http://www.gnu.org/licenses/>.
%}
'''


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args])


def text(data):
    try:
        source = data.decode('utf-8-sig')
    except UnicodeDecodeError:
        source = data.decode('latin-1')
    return source.replace('\r\n', '\n')


def code_lines(source):
    """Fingerprint substantive lines, omitting comments and license blocks."""
    lines = []
    block_depth = 0
    for line in source.splitlines():
        stripped = line.strip()
        if stripped == '%{':
            block_depth += 1
        elif stripped == '%}':
            block_depth = max(0, block_depth - 1)
        elif not block_depth and stripped and not stripped.startswith('%'):
            compact = re.sub(r'\s+', '', stripped)
            if len(compact) >= 12:
                lines.append(compact)
    return lines


def fingerprints(source):
    lines = code_lines(source)
    return {hashlib.sha256('\n'.join(lines[i:i+3]).encode()).digest()
            for i in range(len(lines) - 2)}


def load_sources(root):
    paths = text(git(root, 'ls-tree', '-r', '--name-only', 'HEAD')).splitlines()
    selected = [p for p in paths if p.startswith(MODULE) or p.endswith('.m')]
    requests = ''.join(f'HEAD:{p}\n' for p in selected).encode()
    process = subprocess.run(['git', '-C', str(root), 'cat-file', '--batch'],
                             input=requests, stdout=subprocess.PIPE, check=True)
    data = process.stdout
    offset = 0
    result = {}
    for path in selected:
        end = data.index(b'\n', offset)
        size = int(data[offset:end].split()[2])
        offset = end + 1
        result[path] = data[offset:offset+size]
        offset += size + 1
    return result


def update_years(source):
    def replace(match):
        years = match.group(1)
        first = years.split('-')[0]
        if int(years.split('-')[-1]) >= int(YEAR):
            return match.group(0)
        return 'Copyright ' + (YEAR if first == YEAR else first + '-' + YEAR)
    return re.sub(r'Copyright (\d{4}(?:-\d{4})?)(?= SINTEF)', replace, source)


def update_notice(source, inherited, possible_source):
    source = update_years(source)
    if inherited:
        return source, 'Retain original attribution; update existing SINTEF end year to 2026'
    # Keep inherited notices when a new file contains upstream source code.
    if possible_source:
        if NOTICE.strip() not in source:
            source = source.rstrip() + '\n\n' + NOTICE
        return source, 'Retain original notices; add MRST-format h2sim notice'
    source = re.sub(r'%\{(?:(?!%\}).)*Copyright(?:(?!%\}).)*%\}\n?',
                    '', source, flags=re.S)
    source = re.sub(r'(?m)^% Copyright [^\n]*\n?', '', source)
    source = source.rstrip() + '\n\n' + NOTICE
    return source, 'MRST-format notice with software name h2sim'


def audit(repo, mrst, update=False):
    sources = load_sources(mrst)
    module_sources = {p: data for p, data in sources.items() if p.startswith(MODULE)}
    by_name = defaultdict(list)
    gram_index = defaultdict(list)
    for path, data in sources.items():
        if path.startswith(MODULE):
            by_name[Path(path).name].append(path)
        if path.endswith('.m'):
            for gram in fingerprints(text(data)):
                gram_index[gram].append(path)
    paths = text(git(repo, 'ls-files', '--', 'h2-biochem')).splitlines()
    paths = [p for p in paths if Path(p).name not in {'MRST_COMPARISON.md', 'mrst_comparison.json'}]
    records = []
    for path in paths:
        data = (repo / path).read_bytes()
        upstream = MODULE + path.removeprefix('h2-biochem/')
        if upstream not in module_sources:
            matches = by_name[Path(path).name]
            upstream = matches[0] if path.endswith('.m') and len(matches) == 1 else None
        status = 'new'
        added = deleted = None
        change_kind = 'new'
        if upstream:
            old = module_sources[upstream]
            old_text = text(old)
            current = text(data)
            equal = current == old_text
            notice = lambda value: re.sub(r'Copyright \d{4}(?:-\d{4})?', 'Copyright YEAR', value)
            if equal:
                change_kind = 'unchanged'
            elif notice(current) == notice(old_text):
                change_kind = 'copyright-year-only'
            elif re.sub(r'\s+', '', notice(current)) == re.sub(r'\s+', '', notice(old_text)):
                change_kind = 'formatting-or-notice-only'
            else:
                change_kind = 'content'
            moved = upstream != MODULE + path.removeprefix('h2-biochem/')
            status = ('relocated-' if moved else '') + ('unchanged' if equal else 'modified')
            matcher = difflib.SequenceMatcher(None, old_text.splitlines(), current.splitlines(), autojunk=False)
            added = deleted = 0
            for tag, i, j, a, b in matcher.get_opcodes():
                if tag != 'equal':
                    deleted += j-i
                    added += b-a
        possible = None
        similarity = None
        action = 'Data, documentation or binary asset: preserve existing provenance'
        if path.endswith('.m'):
            current = text(data)
            if not upstream:
                grams = fingerprints(current)
                counts = Counter(p for gram in grams for p in gram_index.get(gram, []))
                if counts:
                    candidate, count = counts.most_common(1)[0]
                    similarity = count/max(len(grams), 1)
                    if (count >= 8 and similarity >= 0.35) or count >= 40:
                        possible = candidate
            revised, action = update_notice(current, bool(upstream), possible)
            if update and revised != current:
                (repo / path).write_text(revised)
        records.append(dict(path=path, status=status, change_kind=change_kind, upstream=upstream,
                            local_sha256=hashlib.sha256(data).hexdigest(),
                            upstream_sha256=hashlib.sha256(module_sources[upstream]).hexdigest() if upstream else None,
                            possible_derived_from=possible,
                            copied_fingerprint_fraction=round(similarity, 3) if similarity else None,
                            added_lines=added, deleted_lines=deleted, copyright_action=action))
    matched = {record['upstream'] for record in records if record['upstream']}
    return dict(mrst_revision=text(git(mrst, 'rev-parse', 'HEAD')).strip(),
                module=MODULE.rstrip('/'),
                hash_format='SHA-256 of raw file bytes; line endings may differ for unchanged text',
                comparison='Tracked H2sim files before this audit updates notices; LF-normalized text',
                summary=dict(Counter(record['status'] for record in records)),
                upstream_only=sorted(set(module_sources)-matched), files=records)


def write_report(report, path):
    lines = ['# H2sim biochemistry compared with MRST', '',
             f"Baseline: [MRST `{report['mrst_revision'][:12]}`](https://github.com/SINTEF-AppliedCompSci/MRST/tree/{report['mrst_revision']}/modules/h2-biochem).", '',
             'This inventory covers tracked files under `h2-biochem`, excluding these',
             'generated audit files. Relocated MATLAB examples',
             'are matched by basename. Modified files include code and documentation changes;',
             'line counts compare the files before this audit updates their notices.', '',
             'New MATLAB files use the exact MRST notice with MRST replaced by h2sim. Existing',
             'MRST files keep their attribution with existing SINTEF end years updated to 2026.',
             'For new files with substantial matching code elsewhere in MRST, the existing',
             'notices are retained alongside the H2sim notice. Similarity candidates are',
             'evidence of possible derivation, rather than proof of independent authorship.',
             'Database, document and binary-asset provenance is unchanged.', '',
             '## Summary', '']
    for category, count in sorted(report['summary'].items()):
        lines.append(f'- {category}: {count}')
    lines += ['', '## File inventory', '',
              '| H2sim path (relative to this folder) | Classification | MRST counterpart / possible source | Lines added / removed | Notice |',
              '| --- | --- | --- | --- | --- |']
    for record in report['files']:
        relative = record['path'].removeprefix('h2-biochem/')
        source = record['upstream'] or record['possible_derived_from']
        source = f"[{source}](https://github.com/SINTEF-AppliedCompSci/MRST/blob/{report['mrst_revision']}/{source})" if source else '—'
        counts = '—' if record['added_lines'] is None else f"+{record['added_lines']} / -{record['deleted_lines']}"
        lines.append(f"| [{relative}]({relative}) | {record['status']} ({record['change_kind']}) | {source} | {counts} | {record['copyright_action']} |")
    lines += ['', '## Files present only in the upstream module', '']
    lines.extend(f'- `{p}`' for p in report['upstream_only'])
    if not report['upstream_only']:
        lines.append('Every upstream module file has a direct or relocated counterpart.')
    lines += ['', '## Reproduce', '', '```bash',
              'python3 tools/audit_mrst_biochemistry.py --mrst-root /path/to/MRST \\',
              '    --report h2-biochem/MRST_COMPARISON.md --json h2-biochem/mrst_comparison.json',
              '```', '',
              'Check out the baseline revision in that MRST checkout first. Add',
              '`--update-copyright` only when applying the audited notice policy.', '']
    path.write_text('\n'.join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mrst-root', type=Path, required=True)
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--update-copyright', action='store_true')
    parser.add_argument('--report', type=Path)
    parser.add_argument('--json', type=Path)
    parser.add_argument('--diff', type=Path, help='Write source and README changes as a reviewable unified diff')
    args = parser.parse_args()
    report = audit(args.repo.resolve(), args.mrst_root.resolve(), args.update_copyright)
    if args.report:
        write_report(report, args.report)
    if args.json:
        args.json.write_text(json.dumps(report, indent=2)+'\n')
    if args.diff:
        changes = []
        for record in report['files']:
            path = record['path']
            if not (path.endswith('.m') or Path(path).name == 'README.md'):
                continue
            original = record['upstream']
            old = text(git(args.mrst_root, 'show', 'HEAD:' + original)) if original else ''
            new = (args.repo / path).read_text()
            changes.extend(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
                fromfile='a/' + original if original else '/dev/null', tofile='b/' + path))
        args.diff.parent.mkdir(parents=True, exist_ok=True)
        args.diff.write_text(''.join(changes))
    print(json.dumps({'baseline': report['mrst_revision'], 'summary': report['summary'],
                      'files': len(report['files']), 'upstream_only': report['upstream_only']}, indent=2))


if __name__ == '__main__':
    main()
