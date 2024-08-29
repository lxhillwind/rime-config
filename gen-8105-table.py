#!/usr/bin/env python3

import sys
import re

all_8105_ch = set()

with open('cn_dicts/8105.dict.yaml') as f:
    for line in f.readlines():
        line = line.strip()
        arr = re.match('^(.)\t([a-z]+)\t?([0-9]*)$', line)
        if not arr:
            continue
        ch, _, _ = arr.groups()
        all_8105_ch.add(ch)


with sys.stdin as f:
    for line in f.readlines():
        line = line.strip()
        arr = re.match('^(.)\t([a-z]+)\t?([0-9]*)$', line)
        if not arr:
            continue
        ch, _, _ = arr.groups()
        if ch in all_8105_ch:
            print(line)
