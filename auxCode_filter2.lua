-- 使用触发键对双拼进行形码的输入
-- 参考: https://github.com/HowcanoeWang/rime-lua-aux-code
-- Mintimate修改: 
--   1. 支持设置在输入触发键后，才显示形码注释
--   2. 为了适应本项目，修改配置选项入口为axu_code

local AuxFilter = {}

local function alt_lua_punc( s )
    if s then
        return s:gsub( '([%.%+%-%*%?%[%]%^%$%(%)%%])', '%%%1' )
    else
        return ''
    end
end

-- 日志模块
-- local log = require 'log'
-- log.outfile = "aux_code.log"

function AuxFilter.init(env)
    -- log.info("** AuxCode filter", env.name_space)

    

    AuxFilter.aux_code = AuxFilter.readAuxTxt(env.name_space)

    local engine = env.engine
    local config = engine.schema.config

    -- 設定預設觸發鍵為分號，並從配置中讀取自訂的觸發鍵
    env.trigger_key = config:get_string("axu_code/trigger_word") or ";"
    -- 对内容进行替换
    env.trigger_key_string = alt_lua_punc( env.trigger_key )
    
    -- 设定是否显示辅助码，默认为显示
    env.show_aux_notice = config:get_string("axu_code/show_aux_notice") or "always"

    ----------------------------
    -- 持續選詞上屏，保持輔助碼分隔符存在 --
    ----------------------------
    env.notifier = engine.context.select_notifier:connect(function(ctx)
        -- 含有輔助碼分隔符才處理
        if not string.find(ctx.input, env.trigger_key_string) and env.show_aux_notice ~= "always" then
            return
        end

        -- ctx.input是用户输入的双拼原型，preedit.text是用户选择了某个字后汉字与双拼的组合。
        -- 用「你好」举例。
        -- ctx.input nihc;rx
        -- preedit.text 你 hc;
        local preedit = ctx:get_preedit()
        local removeAuxInput = ctx.input:match("([^,]+)" .. env.trigger_key_string)
        local reeditTextFront = preedit.text:match("([^,]+)" .. env.trigger_key_string)

        -- ctx.text 隨著選字的進行，oaoaoa； 有如下的輸出：
        -- ---- 有輔助碼 ----
        -- >>> 啊 oaoa；au
        -- >>> 啊吖 oa；au
        -- >>> 啊吖啊；au
        -- ---- 無輔助碼 ----
        -- >>> 啊 oaoa；
        -- >>> 啊吖 oa；
        -- >>> 啊吖啊；
        -- 這邊把已經上屏的字段 (preedit:text) 進行分割；
        -- 如果已經全部選完了，分割後的結果就是 nil，否則都是 吖卡 a 這種字符串
        -- 驗證方式：
        -- log.info('select_notifier', ctx.input, removeAuxInput, preedit.text, reeditTextFront)

        -- 當最終不含有任何字母時 (候選)，就跳出分割模式，並把輔助碼分隔符刪掉
        ctx.input = removeAuxInput
        if reeditTextFront and reeditTextFront:match("[a-z]") then
            -- 給詞尾自動添加分隔符，上面的 re.match 會把分隔符刪掉
            ctx.input = ctx.input .. env.trigger_key
        else
            -- 剩下的直接上屏
            ctx:commit()
        end
    end)
end

----------------
-- 阅读辅码文件 --
----------------

function AuxFilter.readAuxTxt(txtpath)
    --log.info("** AuxCode filter", 'read Aux code txt:', txtpath)
    if AuxFilter.cache then
        return AuxFilter.cache
    end

    local defaultFile = 'ZRM_Aux-code_4.3.txt'
    local userPath = rime_api.get_user_data_dir() .. "/lua/aux_code/"
    local fileAbsolutePath = userPath .. txtpath .. ".txt"

    local file = io.open(fileAbsolutePath, "r") or io.open(userPath .. defaultFile, "r")
    if not file then
        error("Unable to open auxiliary code file.")
        return {}
    end

    local auxCodes = {}
    for line in file:lines() do
        line = line:match("[^\r\n]+") -- 去掉換行符，不然 value 是帶著 \n 的
        local key, value = line:match("([^=]+)=(.+)") -- 分割 = 左右的變數
        if key and value then
            auxCodes[key] = auxCodes[key] or {}
            table.insert(auxCodes[key], value)
            -- { "啊": {"kk", "..."}, "个"：{"rl", "..."}}
        end
    end
    file:close()
    -- 確認 code 能打印出來
    -- for key, value in pairs(AuxFilter.aux_code) do
    --     log.info(key, table.concat(value, ','))
    -- end

    AuxFilter.cache = auxCodes
    return AuxFilter.cache
end

-----------------------------------------------
-- 計算詞語整體的輔助碼
-- 目前定義為
--   把字或词组的所有辅码，第一个键堆到一起，第二个键堆到一起
--   例子：
--       候选(word) = 拜日
--          【拜】 的辅码有 charAuxCodes=
--             p a
--             p u
--             u a
--             u f
--             u u
--          【日】 的辅码有 charAuxCodes=
--             o r
--             r i
--             a a
--             u h
--       (竖着拍成左右两个字符串)
--   第一个辅码键的不重复列表为：fullAuxCodes[1]= urpao 
--   第二个辅码键的不重复列表为：fullAuxCodes[2]= urhafi
-- -----------------------------------------------
function AuxFilter.fullAux(env, word)
    local fullAuxCodes = {}
    -- log.info('候选词：', word)

     -- string.sub是根据字节来截取字符串的，而不是根据字符。所以不能用string.sub来截取中文字符串。
    local idx = 1
    for _, codePoint in utf8.codes(word) do
        local char = utf8.char(codePoint)
        -- local charAuxCode = AuxFilter.aux_code[char][1] -- 每個字的輔助碼組
        -- if charAuxCode then -- 輔助碼存在
        --     fullAuxCodes[idx] = charAuxCode
        -- end

        -- 适配emoji，否则上面的写法emoji项会报错。
        local charAuxCodes = AuxFilter.aux_code[char] -- 每個字的輔助碼組
        if charAuxCodes then
            fullAuxCodes[idx] = charAuxCodes[1]
        end

        idx = idx + 1
    end

    -- 將表格轉換為字符串
    -- for i, chars in pairs(fullAuxCodes) do
    --     fullAuxCodes[i] = table.concat(table_keys(chars), "")
    -- end


    return fullAuxCodes -- {"char1_auxCode1", "char2_auxCode2", ...}
end


-----------------------------------------------
---用于两个匹配形码
-----------------------------------------------
function MatchXM(s1, s2, wildcard)
    -- 设置默认通配符
    wildcard = wildcard or '`'

    -- 检查字符串长度
    if #s1 ~= 2 or #s2 ~= 2 then
        return false
    end

    -- 判断两个字符是否匹配，允许通配符
    local function is_match(c1, c2)
        return c1 == wildcard or c2 == wildcard or c1 == c2
    end

    -- 提取字符
    local c1, c2 = s1:sub(1,1), s1:sub(2,2)
    local d1, d2 = s2:sub(1,1), s2:sub(2,2)

    -- 判断是否匹配（原顺序或颠倒顺序）
    return (is_match(c1, d1) and is_match(c2, d2)) or
           (is_match(c1, d2) and is_match(c2, d1))
end

-----------------------------------------------
-- 判斷 auxStr 是否匹配 fullAux
-----------------------------------------------

--- >>> auxStr用户输入的辅助码，fullAux候选词的辅助码组合，depLength双拼字符长度（两个双拼字母算一个字符长度）。
function AuxFilter.match(fullAux, auxStr, dpLength)
    if #fullAux == 0 then
        return false
    end

    

    local fKeyMatched = true
    local sKeyMatched = true
    -- local singleMatched = true -- 当词组不存在时，保留首个单字作为备选

    -- 档fullaux长度为1时，代表待选项为单字。

    for i=1, #auxStr do
        if i <= dpLength then
            if fullAux[i] then -- 不与上一个if合并是因为合并后单字单字末位形码会进else的break，导致无法进一步筛选。
                -- if #fullAux == 1 then 
                --     local tempKeyMatched = auxStr:sub(i, i) == '`' or fullAux[i]:find(auxStr:sub(i, i)) ~= nil 
                -- end
                local tempKeyMatched = auxStr:sub(i, i) == '`' or fullAux[i]:find(auxStr:sub(i, i)) ~= nil --如果不加if检测，单字会在此处fullAux[i]报错，从而不能保留为备选项
                fKeyMatched = fKeyMatched and tempKeyMatched
            end
        elseif dpLength < i and i <= dpLength*2 then
            if fullAux[i - dpLength] then
                local tempKeyMatched = MatchXM(fullAux[i - dpLength], auxStr:sub(i-dpLength, i-dpLength) .. auxStr:sub(i, i)) --fullAux[i - dpLength]:find(auxStr:sub(i, i)) ~= nil
                sKeyMatched = sKeyMatched and tempKeyMatched
            end
        else
            break
        end
    end


    return fKeyMatched and sKeyMatched

end

------------------
-- filter 主函數 --
------------------

-- input是cand对象列表，每个cand对象即为一个匹配到的字或词组。
function AuxFilter.func(input, env)
    local context = env.engine.context
    local inputCode = context.input
    local preedit = context:get_preedit()

    

    -- 分割部分正式開始
    local auxStr = ''
    local dpLength = 0

    -- 判断字符串中是否包含輔助碼分隔符
    if not string.find(inputCode, env.trigger_key_string) and env.show_aux_notice ~= "always" then
        -- 没有输入辅助码引导符，则直接yield所有待选项，不进入后续迭代，提升性能
        for cand in input:iter() do
            yield(cand)
        end
        return
    else
        -- 字符串中包含輔助碼分隔符

        -- >>> trigger_pattern为分割符，默认是;
        local trigger_pattern =  env.trigger_key_string

        -- >>> 如果分隔符存在，则取分隔符后面的正则[^,]+匹配成功的字符。
        local localSplit = inputCode:match(trigger_pattern .. "([^,]+)")
        if localSplit then
            auxStr = string.sub(localSplit, 1, -1)
            -- log.info('re.match ' .. local_split)
        end

        local reeditTextFront = preedit.text:match("([a-z]+)" .. trigger_pattern) -- 根据剩下的双拼码而改变长度。
        -- local localSplit2 = inputCode:match("([^,]+)" .. trigger_pattern)
        if reeditTextFront then
            dpLength = math.ceil((#reeditTextFront - 1) / 2)
            -- log.info('re.match ' .. local_split)
        end

        -- 更新逻辑：没有匹配上就不出现再候选框里，提升性能
        -- local insertLater = {}

        -- 遍歷每一個待選項

        -- >>> input是匹配项数组。
        for cand in input:iter() do
            --->>> 获取一个字的形码，仅单字时key有效
            local auxCodes = AuxFilter.aux_code[cand.text] -- 仅单字非 nil

            --->>> 读取匹配项的辅助码组
            local fullAuxCodes = AuxFilter.fullAux(env, cand.text)
            -- 查看 auxCodes
            -- log.info(cand.text, #auxCodes)
            -- for i, cl in ipairs(auxCodes) do
            --     log.info(i, table.concat(cl, ',', 1, #cl))
            -- end

            -- 给候选项添加辅助代码提示
            if env.show_aux_notice and auxCodes and #auxCodes > 0 then
                local codeComment = table.concat(auxCodes, ',')
                -- 处理 simplifier
                if cand:get_dynamic_type() == "Shadow" then
                    local shadowText = cand.text
                    local shadowComment = cand.comment
                    local originalCand = cand:get_genuine()
                    cand = ShadowCandidate(originalCand, originalCand.type, shadowText,
                        originalCand.comment .. shadowComment .. '(' .. codeComment .. ')')
                elseif env.show_aux_notice == "trigger" then
                    if string.find(inputCode,env.trigger_key_string) then
                        cand.comment = cand.comment .. '(' .. codeComment .. ')'
                    end
                else
                    -- 其他情况直接给注释添加辅助代码
                    cand.comment = cand.comment .. '(' .. codeComment .. ')'
                end
            end

            -- 過濾輔助碼
            if #auxStr == 0 then
                -- 沒有輔助碼、不需篩選，直接返回待選項
                yield(cand)
            elseif #auxStr > 0 and fullAuxCodes and (cand.type == 'user_phrase' or cand.type == 'phrase') and
                AuxFilter.match(fullAuxCodes, auxStr, dpLength) then
                -- 匹配到辅助码的待选项，直接插入到候选框中( 获得靠前的位置 )
                yield(cand)
            else
                -- 待选项字词 没有 匹配到当前的辅助码，插入到列表中，最后插入到候选框里( 获得靠后的位置 )
                -- table.insert(insertLater, cand)
                -- 更新逻辑：没有匹配上就不出现再候选框里，提升性能
            end
        end


        -- 把沒有匹配上的待選給添加上
        -- for _, cand in ipairs(insertLater) do
        --     yield(cand)
        -- end
        -- 更新逻辑：没有匹配上就不出现再候选框里，提升性能
        
    end

end

function AuxFilter.fini(env)
    env.notifier:disconnect()
end

return AuxFilter
