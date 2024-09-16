-- 改动自 https://github.com/HowcanoeWang/rime-lua-aux-code
--
-- ./origin-aux_code 包含了其原本的代码和版权信息.

local AuxT9 = {}

-- local log = require 'log'
-- log.outfile = "/tmp/aux_code.log"

function AuxT9.init(env)
    -- log.info("** AuxCode filter", env.name_space)
    local config = env.engine.schema.config
    local opt = {}
    opt.filter = config:get_bool('aux_code/filter')
    opt.file = config:get_string('aux_code/file')
    if opt.filter == nil then opt.filter = true end

    AuxT9.opt = opt
    AuxT9.aux_code, AuxT9.code_map = AuxT9.readAuxTxt(opt.file)
    AuxT9.numToAlphabet = {
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
function AuxT9.readAuxTxt(txtpath)
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
            if AuxT9.opt.filter then
                if code:len() >= 3 and code:len() <= 4 then
                    local i = code:sub(3, 3)
                    if not auxCodes[ch] then
                        auxCodes[ch] = ''
                    end
                    auxCodes[ch] = auxCodes[ch] .. i
                end
            end
        end
    end
    file:close()
    -- 確認 code 能打印出來
    -- for key, value in pairs(AuxT9.aux_code) do
    --     log.info(key, table.concat(value, ','))
    -- end

    return auxCodes, codeMap
end

------------------
-- filter 主函數 --
------------------
function AuxT9.func(input, env)
    local context = env.engine.context
    local inputCode = context.input

    -- 输入长度为4 / 7时 (对应单字(3+1) 或词组(2*3+1); +辅助码), 进行辅助码筛选.
    if AuxT9.opt.filter and (
        (#inputCode == 4 or #inputCode == 7)
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
                        local charAuxCodes = AuxT9.aux_code[char] -- 每個字的輔助碼組
                        local alphabet = AuxT9.numToAlphabet[lastChar]
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

    -- 所有条件都没有匹配上: 直接 yield.
    for cand in input:iter() do
        yield(cand)
    end
end

function AuxT9.fini(env)
    -- env.notifier:disconnect()
end

return AuxT9
