-----------------------------------
--Note  :工具函数类-开发李艳林
--Author:liyanlin@baofeng.com
--Time  :2016-06-15
-----------------------------------

help = {}

--1,显示数据的函数，包括显示table,
function help.show(t)

    if(t == nil) then
        print('nil')
    elseif(type(t) ~= 'table') then
        print(t)
    else
        print(help._show_table(t, 1, 0))
    end

end

--2,提供前台html显示数据,
function help.html(t)

    if(t == nil) then
        return 'nil'
    elseif(type(t) ~= 'table') then
        return t
    else
        return help._show_table(t, 1, 1)
    end

end

---,显示table时递归调用的函数
function help._show_table(t, level, html)

    local show, temp, despt, enter = '', ''
    if html == 0  then
        despt, enter = "  ", "\n"
    else
        despt, enter = '&nbsp;', "<br>\n"
    end
    local space = string.rep(despt, (level-1)*2)
    local sapce4 = string.rep(despt, 2)

    if(type(t) ~= 'table') then
        return 'error: params t is not a table.'
    else
        --取得表名
        show = show .. tostring(t) .. "{" .. enter .. space
        for k,v in pairs(t) do
            --递归显示table
            if type(v) == 'table' then
                temp = help._show_table(v, level+1, html)
            elseif(type(v) == 'string') then
                temp = '\"' .. tostring(v) .. '\"'
            else
                temp = tostring(v)
            end
            show = show .. sapce4 .. tostring(k) .. " = " .. temp .. "," .. enter .. space
        end
        show = show .. "}"
    end
    return show

end

--3,必传参数检验
function help.check_must_params(params, must_params)

    --必须传的参数判断
    for _, key in pairs(must_params) do
        if not params[ key ] then
            return '缺少参数:' .. key
        end
    end

    return nil

end

--4，计算中文字符串的长度
function help.utfstrlen(str)

    local len = #str;
    local left = len;
    local cnt = 0;
    local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
    while left ~= 0 do
        local tmp=string.byte(str,-left);
        local i=#arr;
        while arr[i] do
            if tmp>=arr[i] then left=left-i;break;end
            i=i-1;
        end
        cnt=cnt+1;
    end
    return cnt;

end

--5，加载模块函数
function help.load_module(module_name)
    local m = nil
    local _, err = pcall(function(mod)
            m = require(mod)
    end, module_name)
    return m, err
end

--6，数据返回
--data：要返回的数据
--msg:错误提示信息message
--res：调用结果result，0成功/否则为错误码
function help.response(data, msg, res)
    local msg  = msg or ''
    local data = data or {}
    local res  = res or 0
    return {
        msg  = msg,
        data = data,
        res  = res,
    }
end

--7,判断传参是否是正整数
function help.intzval(val)
    if not tonumber(val) then return false end
    val = tonumber(val)
    if val < 1 then return false end
    local intval = math.floor(val)
    if val ~= intval then return false end
    return intval
end

--8,判断传参是否是正整数或0
function help.intval(val)
    if not tonumber(val) then return false end
    val = tonumber(val)
    if val < 0 then return false end
    local intval = math.floor(val)
    if val ~= intval then return false end
    return intval
end

--9,对给出的table计算出
function help.revtab(tab)
    if(type(tab) ~= 'table') then
        return {}
    end
    local revtab = {}
    for k,v in pairs(tab) do
        revtab[v] = true
    end
    return revtab
end

--10,字符串切割
function help.split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return {}
    end
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

--11,生成URL
function help.makeurl(module, params)
    local url = ''
    for k,v in pairs(params) do
        url =  url .. '/' .. k .. '/' .. v
    end
    return '/' .. module..url
end

return help