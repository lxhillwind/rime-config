#!/usr/bin/env python3

import sys
import re

all_8105 = {}

with open('cn_dicts/8105.dict.yaml') as f:
    for line in f.readlines():
        line = line.strip()
        arr = re.match('^(.)\t([a-z]+)\t?([0-9]*)$', line)
        if not arr:
            continue
        ch, pinyin, _ = arr.groups()
        if pinyin not in all_8105:
            all_8105[pinyin] = set()
        all_8105[pinyin].add(ch)


with sys.stdin as f:
    for line in f.readlines():
        line = line.strip()
        arr = re.match('^([a-z]+),([0-9]+)=(.+)$', line)
        if not arr:
            continue
        [code, seq, ch] = arr.groups()
        if len(code) > 4:
            continue
        if len(code) < 3:
            print(line)
        else:
            pinyin = code[:2]
            if ch in all_8105.get(pinyin, set()):
                print(line)
