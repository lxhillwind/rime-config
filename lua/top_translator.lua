-- copied from:
-- https://ksqsf.moe/posts/2023-06-01-rime-double-pinyin/

-- lua/top_translator.lua
local top = {}
local fixed = nil

function top.init(env)
    -- 创建 translator 组件，供后续调用
    fixed = Component.Translator(env.engine, "", "table_translator@fixed")
end

function top.fini(env)
end

function top.func(input, seg, env)
    local context = env.engine.context
    local inputCode = context.input
    if (inputCode == input) then
        local res = fixed:query(input, seg)
        for cand in res:iter() do
            yield(cand)
        end
    end
end

return top
