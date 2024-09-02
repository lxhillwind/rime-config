#!/usr/bin/env python3

import sys
import re

data = {}

with open('../lua/flypy.ini') as f:
    for line in f.readlines():
        line = line.strip()
        arr = re.match('^([a-z]+),([0-9]+)=(.+)$', line)
        if not arr:
            continue
        [code, seq, ch] = arr.groups()
        if not 2 <= len(code) <= 4:
            continue
        if ch not in data:
            data[ch] = {}
        pinyin = code[:2]
        if pinyin not in data[ch]:
            data[ch][pinyin] = set()
        data[ch][pinyin].add(code)

with sys.stdin as f:
    for line in f.readlines():
        line = line.strip()
        arr = re.match('^([^\t]+)\t([a-z]+)\t?([0-9]*)$', line)
        if not arr:
            continue
        [ch, pinyin, freq] = arr.groups()
        if ch in data and pinyin in data[ch]:
            for code in data[ch][pinyin]:
                code = re.sub('^([a-z]{2})', r'\1_', code)
                if freq == '':
                    print(ch, code, sep='\t')
                else:
                    print(ch, code, freq, sep='\t')
        else:
            print(line)
