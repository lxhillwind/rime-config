import re
from collections import defaultdict

d_8105 = defaultdict(set)

with open('./8105_xhup.dict.yaml') as f:
    for line in f.readlines():
        line = line.rstrip()
        m = re.match(r'^(\S+)\t([a-z_]+)\t.*$', line)
        if not m:
            continue
        ch, code = m.groups()
        d_8105[ch].add(re.sub('_.*', '', code))

with open('../lua/flypy.ini') as f:
    for line in f.readlines():
        line = line.rstrip()
        m = re.match(r'^([a-z]+),([0-9]+)=(.*)$', line)
        if not m:
            continue
        code, _, ch = m.groups()
        if len(code) < 2:
            continue
        if ch not in d_8105 or code[:2] not in d_8105[ch]:
            print(ch, re.sub('^(..)', r'\1_', code), 0, sep='\t')
