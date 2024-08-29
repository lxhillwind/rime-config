-- copied from:
-- https://ksqsf.moe/posts/2023-06-01-rime-double-pinyin/

-- lua/top_translator.lua
local top = {}
local fixed_full = nil
local fixed_8105 = nil

function top.init(env)
    -- 创建 translator 组件，供后续调用
    fixed_full = Component.Translator(env.engine, "", "table_translator@fixed_full")
    fixed_8105 = Component.Translator(env.engine, "", "table_translator@fixed_8105")
end

function top.fini(env)
end

function top.func(input, seg, env)
    local context = env.engine.context
    local support_extended_set = context:get_option(env.name_space)
    if (env.engine.context.input == input) then
        local tr = fixed_8105
        if support_extended_set then
            tr = fixed_full
        end
        local fixed_res = tr:query(input, seg)
        for cand in fixed_res:iter() do
            yield(cand)
        end
    end
end

return top
