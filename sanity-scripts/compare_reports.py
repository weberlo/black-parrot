import sys
from collections import OrderedDict

assert len(sys.argv) == 3

[_, base_report, oth_report] = sys.argv
base_report_file = f'sat-counter-reports/rtl/{base_report}.rpt'
oth_report_file = f'sat-counter-reports/rtl/{oth_report}.rpt'

with open(base_report_file) as f:
    base_lines = list(map(lambda s: s.strip(), f.readlines()))

with open(oth_report_file) as f:
    oth_lines = list(map(lambda s: s.strip(), f.readlines()))

def parse_perf_nums(lines):
    perf_map = OrderedDict()
    curr_prog = None
    for i, line in enumerate(lines):
        if line == '==========':
            curr_prog = lines[i-1]
            perf_map[curr_prog] = OrderedDict()
        elif ':' in line:
            [field, value] = list(map(lambda s: s.strip(), line.split(':')))
            perf_map[curr_prog][field] = int(value)
    return perf_map

base_perf_map = parse_perf_nums(base_lines)
oth_perf_map = parse_perf_nums(oth_lines)

import pprint
#pprint.pprint(base_perf_map)
#pprint.pprint(oth_perf_map)

for prog in base_perf_map:
    print(prog)
    print('==========')
    base_prog_map = base_perf_map[prog]
    oth_prog_map = oth_perf_map[prog]
    for field in base_prog_map:
        base_val = base_prog_map[field]
        oth_val = oth_prog_map[field]
        diff = oth_val - base_val
        diff_str = f'+{diff}' if diff >= 0 else str(diff)
        if base_val == 0:
            diff_per = 0.0
        else:
            diff_per = diff / base_val
        diff_per_str = f'+{diff_per:0.2f}%' if diff_per >= 0.0 else f'{diff_per:0.2f}%'
        #print(f'  {field}: {base_val} -> {oth_val}\t\t\t\t({diff_str}) ({diff_per_str})')
        print('{0[0]:<10}{0[1]:<10}{0[2]:<5}{0[3]:<10}{0[4]:>10}{0[5]:>10}'.format([field, base_val, '->', oth_val, f'({diff_str})', f'({diff_per_str})']))
    print()
