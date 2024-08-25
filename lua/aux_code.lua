-- 改动自 https://github.com/HowcanoeWang/rime-lua-aux-code
--
-- ./origin-aux_code 包含了其原本的代码和版权信息.

local AuxFilter = {}

-- local log = require 'log'
-- log.outfile = "/tmp/aux_code.log"

function AuxFilter.init(env)
    -- log.info("** AuxCode filter", env.name_space)
    local config = env.engine.schema.config
    local opt = {}
    opt.phrase = config:get_bool('aux_code/phrase')
    opt.filter = config:get_bool('aux_code/filter')
    opt.file = config:get_string('aux_code/file')
    if opt.phrase == nil then opt.phrase = true end
    if opt.filter == nil then opt.filter = true end

    AuxFilter.opt = opt
    AuxFilter.aux_code, AuxFilter.code_map = AuxFilter.readAuxTxt(opt.file)
end

----------------
-- 閱讀輔碼文件 --
----------------
function AuxFilter.readAuxTxt(txtpath)
    -- log.info("** AuxCode filter", 'read Aux code txt:', txtpath)

    local userPath = rime_api.get_user_data_dir() .. "/lua/"
    local fileAbsolutePath = userPath .. txtpath
    local file = io.open(fileAbsolutePath, "r")
    local auxCodes = {}
    local codeMap = {}
    if not file then
        error("Unable to open auxiliary code file.")
        return auxCodes, codeMap
    end

    for line in file:lines() do
        line = line:match("[^\r\n]+") -- 去掉換行符，不然 value 是帶著 \n 的
        local code, seq, ch = line:match("([a-z]+),([0-9]+)=(.+)")
        if code and seq and ch then
            if AuxFilter.opt.filter then
                if code:len() >= 3 and code:len() <= 4 then
                    local i = code:sub(3, 3)
                    if not auxCodes[ch] then
                        auxCodes[ch] = ''
                    end
                    auxCodes[ch] = auxCodes[ch] .. i
                end
            end
            -- if AuxFilter.opt.phrase then
            -- 为了让 script_translator 的输出是排序的, 这个总是需要读取.
            if true then
                if not codeMap[code] then
                    codeMap[code] = {}
                end
                seq = tonumber(seq)
                codeMap[code][seq] = ch
            end
        end
    end
    file:close()
    -- 確認 code 能打印出來
    -- for key, value in pairs(AuxFilter.aux_code) do
    --     log.info(key, table.concat(value, ','))
    -- end

    return auxCodes, codeMap
end

local function unicode_range_check(char)
    if AuxFilter.support_extended_set then return true end

    local byte1, byte2, byte3, byte4 = string.byte(char, 1, 4)

    if byte1 >= 0xF0 then
        -- 4-byte UTF-8 character (not a CJK character in the BMP)
        return false
    elseif byte1 >= 0xE0 then
        -- 3-byte UTF-8 character
        local codepoint = (byte1 - 0xE0) * 0x1000 + (byte2 - 0x80) * 0x40 + (byte3 - 0x80)
        return (
            -- ref: https://zh.wikipedia.org/zh-cn/%E4%B8%AD%E6%97%A5%E9%9F%93%E7%B5%B1%E4%B8%80%E8%A1%A8%E6%84%8F%E6%96%87%E5%AD%97
            -- 中日韩统一表意文字 (基本)
            (codepoint >= 0x4e00 and codepoint <= 0x9fa5)
            or codepoint == 0x3007  -- 〇
            or (codepoint >= 0xfa0e and codepoint <= 0xfa29) -- 另外12个字
            -- 中日韩统一表意文字 (扩展区A)
            or (codepoint >= 0x3400 and codepoint <= 0x4db5)
        )
    elseif byte1 >= 0xC0 then
        -- 2-byte UTF-8 character (not a CJK character)
        return false
    else
        -- 1-byte UTF-8 character (ASCII)
        return false
    end
end

------------------
-- filter 主函數 --
------------------
function AuxFilter.func(input, env)
    local context = env.engine.context
    local inputCode = context.input
    local phraseMap = nil
    AuxFilter.support_extended_set = context:get_option(env.name_space)

    -- 处理 "自定义短语"
    if AuxFilter.opt.phrase then
        phraseMap = AuxFilter.code_map[inputCode]
    end
    if phraseMap then
        local keys = {}
        for i in pairs(phraseMap) do
            table.insert(keys, i)
        end
        table.sort(keys)

        local counter = 0
        for cand in input:iter() do
            counter = counter + 1
            while phraseMap[counter] do
                yield(Candidate('user_phrase', 0, #inputCode, phraseMap[counter], ''))
                table.remove(keys, 1)
                counter = counter + 1
            end
            yield(cand)
        end
        -- 如果输入法产生的候选词不够, 就会产生空洞;
        -- 直接将剩下的自定义短语按照顺序生成 Candidate.
        if #keys > 0 then
            for _, i in ipairs(keys) do  -- 使用 ipairs, 确保顺序.
                yield(Candidate('user_phrase', 0, #inputCode, phraseMap[i], ''))
            end
        end

        return
    end

    -- 进入造词模式时, 让候选字总是按照指定排序.
    if inputCode:find('_', 1, true) then
        local insertBefore = {}
        local insertAfter = {}
        local preedit = nil
        local insertOrder = {}
        local stopProcessing = false
        for cand in input:iter() do
            if stopProcessing then
                yield(cand)
            else
                if preedit == nil and utf8.len(cand.text) == 1 then
                    preedit = cand.preedit
                    preedit = preedit:gsub('_', '')
                    local Map = AuxFilter.code_map[preedit]
                    if Map then
                        for k, v in ipairs(Map) do
                            insertOrder[v] = k
                        end
                    end
                end
                if utf8.len(cand.text) == 1 then
                    if insertOrder[cand.text] then
                        insertBefore[insertOrder[cand.text]] = cand
                    else
                        table.insert(insertAfter, cand)
                    end
                else
                    for _, i in ipairs(insertBefore) do
                        yield(i)
                    end
                    insertBefore = {}
                    for _, i in ipairs(insertAfter) do
                        yield(i)
                    end
                    insertAfter = {}
                    yield(cand)
                    stopProcessing = true
                end
            end
        end
        if #insertBefore > 0 or #insertAfter > 0 then
            for _, i in ipairs(insertBefore) do
                yield(i)
            end
            insertBefore = {}
            for _, i in ipairs(insertAfter) do
                yield(i)
            end
            insertAfter = {}
        end

        return
    end

    -- 三简码检查是否出候选.
    if not AuxFilter.opt.phrase and #inputCode == 3 then
        for cand in input:iter() do
            if cand.start == 0 and cand._end == #inputCode and utf8.len(cand.text) == 1 then
                if unicode_range_check(cand.text) then
                    yield(cand)
                end
            else
                yield(cand)
            end
        end

        return
    end

    -- 调整长度为4的候选次序; 词组优先. (仅当未使用 "自定义短语" 时)
    if not AuxFilter.opt.phrase and #inputCode == 4 then
        local candSingle = {}
        local check = true
        for cand in input:iter() do
            if check then
                if cand.start == 0 and cand._end == #inputCode and utf8.len(cand.text) == 1 then
                    if unicode_range_check(cand.text) then
                        table.insert(candSingle, cand)
                    end
                else
                    check = false
                    local reOrder = false
                    if cand.start == 0 and cand._end == #inputCode and utf8.len(cand.text) == 2 then
                        reOrder = true
                    end
                    if reOrder then yield(cand) end
                    for _, i in ipairs(candSingle) do
                        yield(i)
                    end
                    if not reOrder then yield(cand) end
                end
            else
                yield(cand)
            end
        end
        if check then
            -- 候选项只有全匹配单字的话, 会进入这个分支.
            check = false
            for _, i in ipairs(candSingle) do
                yield(i)
            end
        end

        return
    end

    -- 输入长度为大于4且小于10的奇数时 (对应2-4字词语), 进行辅助码筛选.
    if AuxFilter.opt.filter and (
        (#inputCode > 4 and #inputCode < 10 and #inputCode % 2 == 1)
        ) then
        local insertLater = {}
        local lastChar = inputCode:sub(#inputCode, #inputCode)
        local hasMatched = false
        local counter = 0
        for cand in input:iter() do
            counter = counter + 1
            local found = false
            local testThis = cand.start == 0 and (
            -- 最后一位是前边的辅助码, 或者是最后一个字的辅助码 (*不参与组词*);
            -- 例如, vi'dc'u -> 知道u (x+1=y) / vi'dc'z -> 知道 (x=y);
            cand._end + 1 == #inputCode
            )

            if testThis then
                for _, codePoint in utf8.codes(cand.text) do
                    if not found then
                        local char = utf8.char(codePoint)
                        local charAuxCodes = AuxFilter.aux_code[char] -- 每個字的輔助碼組
                        if charAuxCodes:find(lastChar, 1, true) then -- 輔助碼存在
                            found = true
                            -- log.error(inputCode .. ' => ' .. cand.text)
                            yield(Candidate(cand.type, cand.start, cand._end + 1, cand.text, ''))
                            hasMatched = true
                        end
                    end
                end
            else
                if hasMatched and counter >= 10 then
                    return
                end
            end

            if not hasMatched and not found then
                table.insert(insertLater, cand)
            end
        end

        if not hasMatched then
            for _, cand in ipairs(insertLater) do
                yield(cand)
            end
        end

        return
    end

    -- 所有条件都没有匹配上: 直接 yield.
    for cand in input:iter() do
        yield(cand)
    end
end

function AuxFilter.fini(env)
    -- env.notifier:disconnect()
end

return AuxFilter
