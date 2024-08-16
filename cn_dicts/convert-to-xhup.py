#!/usr/bin/env python3

import sys
import re

data = {}
# 在固定编码中 (table_translator), 优先级为 1 / 2 的二简码在三简码中会后挪 (从3开始排);
# 但是 script_translator 中只遵循字频 / 词频;
# 因此, 在 script_translator 中直接将这种二简码对应汉字的三简码去掉,
# 以确保连贯性.
remove_from_3 = {}

with open('../lua/all-utf8.ini') as f:
    for line in f.readlines():
        line = line.strip()
        arr = re.match('^([a-z]+),([0-9]+)=(.+)$', line)
        if not arr:
            continue
        [code, seq, ch] = arr.groups()
        seq = int(seq)
        if not 2 <= len(code) <= 4:
            continue
        if len(code) == 2 and seq < 3:
            if ch not in remove_from_3:
                remove_from_3[ch] = set()
            # 保留拼音信息, 以免是多音字.
            remove_from_3[ch].add(code)
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
                if ch in remove_from_3 and pinyin in remove_from_3[ch] and len(code) > 2:
                    continue
                code = re.sub('^([a-z]{2})', r'\1_', code)
                if freq == '':
                    print(ch, code, sep='\t')
                else:
                    print(ch, code, freq, sep='\t')
        else:
            print(line)
