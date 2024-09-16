#!/usr/bin/env python3

print('# generated by t9.schema.py; do not edit.')
print('data:')

keymap = ["sz'", 'abc', 'def', 'ghi', 'jkl', 'mno', 'pqr', 'tuv', 'wxy']
for k1 in range(0, 9):
  for k2 in range(0, 9):
    for k3 in range(0, 9):
      idx_1 = k3 // 3
      idx_2 = k3 % 3
      key_1 = keymap[k1][idx_1]
      key_2 = keymap[k2][idx_2]
      print(f'- xform/^{key_1}{key_2}$/{k1 + 1}{k2 + 1}{k3 + 1}/')
