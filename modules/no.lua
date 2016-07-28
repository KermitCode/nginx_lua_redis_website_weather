----------------------------
--note:今日最热省份
--author:kermit
--date:2016-07-26
----------------------------

todayprovince = {}

--执行参数处理
function todayprovince.check(request)

    return true

end

--执行模块
function todayprovince.run(request)

    --1,执行REDIS连接
    local redis = require 'library.redis'
    local redisSource = redis:new()
    local ok, err = redisSource:connect(config.redis.host, config.redis.port)
    if not ok then
        local message = 'Error:redis connected failed,' .. err
        ngx.log(ngx.ERR, message); ngx.say(message); ngx.exit(200)
    end
    redisSource:auth(config.redis.auth)

    --2,提取今日数据
    local tday = os.date("%Y%m%d")
    local list_key = 'province_weather'
    local list_score = help.intval(tday)
    local daydata = redisSource:zrangebyscore(list_key, list_score, list_score)
    local uptime = redisSource:get('province_uptime')
    daydata = json.decode(daydata[1])

    --比高时
    local function sort_high(a, b)
      local r
      if a.tem2 == b.tem2 then
        if a.tem1 == b.tem1 then  r = a.tem2 > b.tem2
        else r = a.tem1 > b.tem1
        end
      else r = a.tem2 > b.tem2
      end
      return r
    end

    local function sort_low(a, b)
      local r
      if a.tem1 == b.tem1 then
        if a.tem2 == b.tem2 then  r = a.tem1 > b.tem1
        else r = a.tem2 < b.tem2
        end
      else r = a.tem1 < b.tem1
      end
      return r
    end

    --3根据请求更换排序参数
    local sort_key = ''
    if request.sortkey == 'low' then
        --求最低温度
        table.sort(daydata, function(a,b) return sort_low(a, b)  end)
    elseif request.sortkey == 'avg' then
        --平均温度
        table.sort(daydata, function(a,b) return a['temavg'] > b['temavg']  end)
    else
        --默认求最高温度
        table.sort(daydata, function(a,b) return sort_high(a, b)  end)
    end

    --4,读取模板
    local outhtml = loadTemplate('main')

    --5,组装数据
    local maintable = '<table class="table table-bordered"><thead><tr>'
    local index,class = 0,''
    local oldhigh,oldlow=0,0
    local first = 1
    maintable = maintable..'<th>排名</th><th>省份</th><th>最高温度</th><th>最低温度</th><th>平均气温</th><th>省会城市</th><th>天气变化</th><th>风力</th></tr></thead><tbody>'
    for k,row in pairs(daydata) do
        if row.tem2 ~= oldhigh or row.tem1 ~= oldlow then index = index + 1 end
        if first <= 5 then class=' class="danger" '
        elseif math.fmod(index,2) == 1 then class=' class="info" '
        else class = '' end
        maintable = maintable .. '<tr'..class..'><td class="reds">'..index..'</td><td>'..row.quName..'</td><td>'..row.tem2..'</td><td>'..row.tem1..'</td><td>'..row.temavg..'</td>'
        maintable = maintable .. '<td>'..row.cityname..'</td><td>'..row.stateDetailed..'</td><td>'..row.windState..'</td></tr>'
        oldhigh,oldlow = row.tem2,row.tem1
        first = first +1
    end
    maintable = maintable .. '</tbody></table>'

    --6,数据替换及返回
    outhtml = string.gsub(outhtml, '<pagetitle>' , '今日全国最热省份排行榜')
    outhtml = string.gsub(outhtml, '<uptime>' , uptime)
    outhtml = string.gsub(outhtml, '<maintable>' , maintable)
    return outhtml

end

return todayprovince