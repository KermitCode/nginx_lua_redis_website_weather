-----------------------------------
--Note  :业务辅助函数-开发李艳林
--Author:liyanlin@baofeng.com
--Time  :2016-07-27
-----------------------------------

modhelp = {}

--缓存的路径
cachePath = base_path .. "cache/"

--1,比高时
function modhelp.sort_high(a, b)
    local r
    if a.tem1 == b.tem1 then
        r = a.temavg > b.temavg
    else
        r = a.tem1 > b.tem1
    end
    return r
end

--2,比低时
function modhelp.sort_low(a, b)
    local r
    if a.tem2 == b.tem2 then
        r = a.temavg < b.temavg
    else
        r = a.tem2 < b.tem2
    end
    return r
end

--3,比最舒服
function modhelp.sort_avg(a, b)
    a.aoff = math.abs(a.tem1-25) + math.abs(a.tem2-25)
    b.boff = math.abs(b.tem1-25) + math.abs(b.tem2-25)
    a.a_off = math.abs(a.temavg-25)
    b.b_off = math.abs(b.temavg-25)
    if a.aoff == b.boff then
        return a.a_off < b.b_off
    else
        r = a.aoff < b.boff
    end
    return
end

--4,传入table,传入排序依据返回数据
function modhelp.sorttable(daydata, sortkey)
    if sortkey == 'low' then
        --求最低温度
        table.sort(daydata, function(a,b) return modhelp.sort_low(a, b)  end)
    elseif sortkey == 'avg' then
        --平均温度
        table.sort(daydata, function(a,b) return modhelp.sort_avg(a, b)  end)
    else
        --默认求最高温度
        table.sort(daydata, function(a,b) return modhelp.sort_high(a, b)  end)
    end
    return daydata
end

return modhelp