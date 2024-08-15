-- copied from:
-- https://ksqsf.moe/posts/2023-06-01-rime-double-pinyin/

-- lua/top_translator.lua
local top = {}
local fixed = nil
local smart = nil

function top.init(env)
   -- 创建 translator 组件，供后续调用
   fixed = Component.Translator(env.engine, "", "table_translator@single")
   -- 注意主翻译器的引用方式: @translator
   smart = Component.Translator(env.engine, "", "script_translator@translator")
end

function top.fini(env)
end

function top.func(input, seg, env)
   if (env.engine.context.input == input) then
      local fixed_res = fixed:query(input, seg)
      for cand in fixed_res:iter() do
         yield(cand)
      end
   end

   local smart_res = smart:query(input, seg)
   for cand in smart_res:iter() do
      yield(cand)
   end
end

return top
