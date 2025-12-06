-- 改动自 https://github.com/HowcanoeWang/rime-lua-aux-code
--
-- ./origin-aux_code 包含了其原本的代码和版权信息.
local T9 = {}

function T9.init(env)
    local config = env.engine.schema.config
    local file = config:get_string('aux_code/file')
    T9.aux_code, T9.code_map = T9.readAuxTxt(file)
    T9.numToAlphabet = {
        ['1'] = 'sz',
        ['2'] = 'abc',
        ['3'] = 'def',
        ['4'] = 'ghi',
        ['5'] = 'jkl',
        ['6'] = 'mno',
        ['7'] = 'pqr',
        ['8'] = 'tuv',
        ['9'] = 'wxy',
    }
end

----------------
-- 閱讀輔碼文件 --
----------------
function T9.readAuxTxt(txtpath)
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
            if code:len() >= 3 and code:len() <= 4 then
                local i = code:sub(3, 3)
                if not auxCodes[ch] then
                    auxCodes[ch] = ''
                end
                auxCodes[ch] = auxCodes[ch] .. i
            end
        end
    end
    file:close()

    return auxCodes, codeMap
end

------------------
-- filter 主函數 --
------------------
function T9.func(input, env)
    local context = env.engine.context
    local inputCode = context.input

    local cand_11 = {
        0, 0, '，', -- 123
        0, 0, '。', -- 456
        '？', '、', '！' --789
    }

    if #inputCode == 3 and inputCode:sub(1, 2) == '11' then
        local i = cand_11[inputCode:sub(3, 3) + 0]
        if i ~= 0 then
            yield(Candidate('user_phrase', 0, #inputCode, i, ''))
        end
    end

    -- 将最后2位对应的音节组合放在注释里, 便于用户输入第3位来唯一确认音节.
    -- 音节信息与方案文件是一致的.
    if #inputCode % 3 == 2 then
        local counter = 0
        while counter < 9 do
            counter = counter + 1
            local i = inputCode:sub(#inputCode - 1, #inputCode - 1)
            local j = inputCode:sub(#inputCode, #inputCode)
            local i_idx = (counter - 1) // 3 + 1
            local j_idx = (counter - 1) % 3 + 1
            local i_items = T9.numToAlphabet[i]
            local j_items = T9.numToAlphabet[j]
            local comment = ''
            if #i_items >= i_idx then
                comment = comment .. i_items:sub(i_idx, i_idx)
            end
            if #j_items >= j_idx then
                comment = comment .. j_items:sub(j_idx, j_idx)
            end
            if #comment ~= 2 then
                -- inputCode[-2:] is 11
                comment = cand_11[counter]
            end
            yield(Candidate('user_phrase', 0, #inputCode, comment, ''))
        end
    end

    -- 输入长度为4 / 7时 (对应单字(3+1) 或词组(2*3+1); +辅助码), 进行辅助码筛选.
    if (#inputCode == 4 or #inputCode == 7) then
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
                        local charAuxCodes = T9.aux_code[char] -- 每個字的輔助碼組
                        local alphabet = T9.numToAlphabet[lastChar]
                        if charAuxCodes and alphabet and charAuxCodes:find('[' .. alphabet .. ']') then -- 輔助碼存在
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

    for cand in input:iter() do
        yield(cand)
    end
end

function T9.fini(env)
    -- env.notifier:disconnect()
end

return T9
