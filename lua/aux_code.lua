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
    if opt.phrase == nil then opt.phrase = true end
    if opt.filter == nil then opt.filter = true end

    AuxFilter.opt = opt
    AuxFilter.aux_code, AuxFilter.code_map = AuxFilter.readAuxTxt(env.name_space)
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
            if AuxFilter.opt.phrase then
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

------------------
-- filter 主函數 --
------------------
function AuxFilter.func(input, env)
    local context = env.engine.context
    local inputCode = context.input
    local phraseMap = nil

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

    -- 调整长度为4的候选次序; 词组优先. (仅当未使用 "自定义短语" 时)
    if not AuxFilter.opt.phrase and #inputCode == 4 then
        local candSingle = {}
        local check = true
        for cand in input:iter() do
            if check then
                if cand.start == 0 and cand._end == #inputCode and utf8.len(cand.text) == 1 then
                    table.insert(candSingle, cand)
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
        for cand in input:iter() do
            local found = false
            local testThis = cand.start == 0 and (
            -- 最后一位是前边的辅助码, 或者是最后一个字的辅助码 (参与组词);
            -- 例如, vi'dc'u -> 知道u (x+1=y) / vi'dcz -> 知道 (x=y);
            -- 后者的情况只适用于 script_translator 包含超过2位的情况,
            -- 即使用音形码 (辅助码) 作为音节元素.
            --
            -- 如果是一般的 script_translator (双拼), 应为每2个音节构成一个字,
            -- 即最后一位可能是前边任何一个字的辅助码; 这时只检查 x+1=y 即可.
            cand._end + 1 == #inputCode or cand._end == #inputCode
            ) and utf8.len(cand.text) * 2 + 1 == #inputCode

            for _, codePoint in utf8.codes(cand.text) do
                if testThis and not found then
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

            if not found then
                table.insert(insertLater, cand)
            end
        end

        if not hasMatched then
            for _, cand in ipairs(insertLater) do
                yield(cand)
            end
        end
        return
    else
        -- 直接yield所有待选项，不进入后续迭代，提升性能
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
end

function AuxFilter.fini(env)
    -- env.notifier:disconnect()
end

return AuxFilter
