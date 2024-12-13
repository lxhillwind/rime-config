import os
import re
from collections import defaultdict

code_map = {}
ch_map = defaultdict(list)

with open('ShanRenMaLTS.words.dict.yaml') as f:
    for line in f.readlines():
        line = line.rstrip()
        m = re.match(r'^(\S+)\t([a-z]+)\t?(\S*)$', line)
        if not m:
            continue
        ch, code, seq = m.groups()
        code_map[code] = ch
        ch_map[ch].append({'code': code, 'seq': seq})

for ch, items in ch_map.items():
    min_len = min([len(item['code']) for item in items])
    for item in [i for i in items if len(i['code']) == min_len]:
        code = item['code']
        shorter_code = code
        while True:
            shorter_code = shorter_code[:-1]
            if len(shorter_code) <= 0 or shorter_code in code_map:
                code = code[:len(shorter_code) + 1]
                if code not in code_map:
                    code_map[code] = ch
                    print(ch, code, item['seq'], sep='\t')
                break
