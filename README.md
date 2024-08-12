# rime-config

## 本仓库包含如下内容

### [lua/aux_code.lua](lua/aux_code.lua)
- 实现了 **自定义短语** 功能, 用于以挂接辅助码的方式来支持编码方案 (例如小鹤音形, 五笔等);

![自定义短语](pic/自定义短语.png)

- 实现了 **直接辅助码** 功能, 将 "自定义短语" 中的编码第三位作为辅助码来筛选词语;
    - 在输入编码为 5 / 7 / 9 时生效, 对应二字词 / 三字词 / 四字词 (更长的输入就没有必要了);
    - 为了实现的简单, 辅助码仅支持 1 位;
    - 辅助码支持词中任意字;

![直接辅助码](pic/辅助码.png)

- 由于版权因素, 本仓库并不提供 "自定义短语" 文件 (即下方说明的 "lua/all-utf8.ini").

### [lua/top_translator.lua](lua/top_translator.lua)
- 复制自 <https://ksqsf.moe/posts/2023-06-01-rime-double-pinyin/>; 用于处理混用 table_translator 和 script_translator 时的造词问题.

### [default.custom.yaml](default.custom.yaml)
- 个人配置入口.

### [double_pinyin_flypy.schema.yaml](double_pinyin_flypy.schema.yaml)
- 来自 <https://github.com/rime/rime-double-pinyin> 仓库; 用作 flypy_simp 的配置基础.

### [flypy_simp.schema.yaml](flypy_simp.schema.yaml)
- 类似 double_pinyin_flypy.schema.yaml, 微调了 /schema 的定义; 主要是为了引出新的方案.

### [flypy_simp.custom.yaml](flypy_simp.custom.yaml)
- 辅助码作为音节的一部分, 参与组词; 使用自定义的词库, 依赖 "简化字八股文".
- Tab 键引导使用形码组词.
- 其中包含了上述 lua 插件的使用说明;

引用如下:

```yaml
  # 需要放在 simplifier filter 之后
  engine/filters/@after 0: lua_filter@*aux_code@all-utf8.ini
  #aux_code/phrase: false  # 取消注释来禁用自定义短语加入候选
  #aux_code/filter: false  # 取消注释来禁用辅助码筛词
```

### [essay-zh-hans.txt](essay-zh-hans.txt)

"简化字八股文" <https://github.com/rime/rime-essay-simp>;

在 flypy_simp.dict.yaml 中用到.

## 本仓库未包含的文件

### lua/all-utf8.ini
- `编码,序号=字词` 格式的 "自定义短语" (不满足这个格式的行会被忽略);
- 当然, 你可以将其改成其他文件名; 只要在方案中引用此插件时进行对应修改即可.
- 文件头示例:

```dosini
a,1=啊
a,2=按
aa,1=啊
aa,2=阿
aae,1=阿
aaj,1=锕
aak,1=嗄
aak,2=吖
aak,3=啊
```

### single.txt
- rime 格式的自定义短语 (用于以词库的方式实现固定编码; 可能它性能更好?);
- 相比上述 lua 实现的 "自定义短语" 的缺点: 如果字词次序有空洞, 候选位置无法保证;
- 文件头示例:

```yaml
# single.txt
# encoding: utf-8
# generated from ./lua/all-utf8.ini;
# 3rd column: 100 - seq
---
name: single
version: '2024-08-10'
sort: by_weight
...

啊	a	99
按	a	98
啊	aa	99
阿	aa	98
阿	aae	99
锕	aaj	99
嗄	aak	99
吖	aak	98
啊	aak	97
```

### flypy_simp.dict.yaml

- 替代 luna_pinyin 的词库 (全拼); 便于使用音形码来构建词语.
- 文件头示例:

```yaml
# Rime dictionary
# encoding: utf-8
---
name: flypy_simp
version: "2024.08.11"
sort: by_weight
use_preset_vocabulary: true
vocabulary: essay-zh-hans
...

# generated from ./lua/all-utf8.ini;
# 保留码长为 2-4 的字;
# 部分多音字的常用读音只有2简码, 没有全码, 去掉2简码会导致缺字.
#
# 将 _ 作为双拼音节和辅助码的分隔符; 方案的 speller 需要相应调整.
啊	aa_
阿	aa_
阿	aa_e
锕	aa_j
嗄	aa_k
吖	aa_k
啊	aa_k
```

## 致谢

- <https://github.com/HowcanoeWang/rime-lua-aux-code> RIME输入法辅助码音形分离插件; 本仓库的 lua 代码改动自此.
- <https://ksqsf.moe/posts/2023-06-01-rime-double-pinyin/> 同时启用 script / table 翻译器并保留造词功能; [lua/top_translator.lua](lua/top_translator.lua) 文件复制自此.
