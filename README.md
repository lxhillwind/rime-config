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

### [flypy_simp.schema.yaml](flypy_simp.schema.yaml)
- 辅助码作为音节的一部分, 参与组词; 使用白霜词库 (rime-frost).
- Tab 键引导使用形码组词.
- 其中包含了上述 lua 插件的使用说明;

引用如下:

```yaml
  engine/filters:
    ## - simplifier # 简体词库, 不需要这个.
    - lua_filter@*aux_code
    - uniquifier

  ## lua_filter: aux_code 的配置
  #aux_code/file: all-utf8.ini  # 这个文件太大了, 可能在 Windows 上读取比较慢.
  aux_code/file: aux-chars-234.ini
  aux_code/phrase: false  # 取消注释来禁用自定义短语加入候选
  #aux_code/filter: false  # 取消注释来禁用辅助码筛词
```

### [flypy_simp.dict.yaml](flypy_simp.dict.yaml)

简体字库 / 词库; 作为入口, 本身文件不大.

### [_he_single.schema.yaml](_he_single.schema.yaml)

将单字以固态词典的方式提供, 确保候选顺序.

### [cn_dicts/convert-to-xhup.py](cn_dicts/convert-to-xhup.py)

转换双拼词库为音形码词库; 依赖 ./lua/all-utf8.ini.

### [gen-8105-ini.py](gen-8105-ini.py)

用于从较大的 lua/all-utf8.ini 文件中提取出 8105 常用字的脚本.

### [gen-8105-table.py](gen-8105-table.py)

用于从较大的 rime 格式码表文件中提取出 8105 常用字的脚本.

### [quanpin.schema.yaml](quanpin.schema.yaml)

全拼.

### [tiger.schema.yaml](tiger.schema.yaml)

虎码.

### _he_single_8105.schema.yaml / _tiger_8105.schema.yaml

鹤形 / 虎码的 8105 子集的方案文件.

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

### lua/aux-chars-234.ini
- lua/all-utf8.ini 的缩减版 (仅包含码长为 2-4 / 且位于 8105 常用字的部分);
- 在 Windows 平台上可能加载速度提升比较明显.

```dosini
# from ./lua/all-utf8.ini; only keep code length 2-4 and in 8105 dict.
#
# :exe 'normal 2jdG' | exe 'r !python3 ./gen-8105-ini.py < ./lua/all-utf8.ini'
# :+1,$v/\v^[a-z]{2,4},/d
```

### _he_single.dict.yaml
- rime 格式的自定义短语 (用于以词库的方式实现固定编码; 可能它性能更好?);
- 相比上述 lua 实现的 "自定义短语" 的缺点: 如果字词次序有空洞, 候选位置无法保证;
- 文件头:

```yaml
# encoding: utf-8
# generated from ./lua/all-utf8.ini;
# 3rd column: 100 - seq
---
name: _he_single
version: '2024-08-10'
sort: by_weight
...


# exe 'normal 4jdG' | r ./delimiter.ini | exe 'r ./lua/all-utf8.ini'
# :+3,$v/\v^[a-z]/d
# :+2,$s/,/=/
# :+1,$!awk -F= '{ OFS="\t"; print($3, $1, 100 - $2) }'
```

### delimiter.ini
- 一简码和二简码的分隔符;
- 用来区分固定字和 script_translator 的单字;
- 例如, a => `啊 按 |`, aa => `啊 阿 |`; delimiter.ini 就是包含 `|` 的:

```dosini
# 其他行省略
a,3=|
aa,3=|
```


### cn_dicts/8105_xhup.dict.yaml

- 在 [flypy_simp.dict.yaml](flypy_simp.dict.yaml) 中引用;
- 这个文件的文件头如下:

**注意在使用如下 ./cn_dicts/convert-to-xhup.py 进行转换前, 需要使用
[flypy_simp.dict.yaml](flypy_simp.dict.yaml) 中记载的命令将全拼转换为 (小鹤) 双拼.**

```yaml
# Rime dictionary
# encoding: utf-8
#
---
name: 8105_xhup
version: "2024-08-15"
sort: by_weight
...

# how to update:
# :exe 'normal jdG' | r !python3 ./convert-to-xhup.py < 8105.dict.yaml
```

### tiger.dict.yaml

虎码的码表

### _he_single_8105.dict.yaml / _tiger_8105.dict.yaml

鹤形 / 虎码的 8105 子集

## 致谢

- <https://github.com/HowcanoeWang/rime-lua-aux-code> RIME输入法辅助码音形分离插件; 本仓库的 lua 代码改动自此.
- <https://ksqsf.moe/posts/2023-06-01-rime-double-pinyin/> 同时启用 script / table 翻译器并保留造词功能; [lua/top_translator.lua](lua/top_translator.lua) 文件复制自此.
- <https://github.com/gaboolic/rime-frost> 本仓库使用此处的 cn_dicts 作为字频来源 / 词库.
