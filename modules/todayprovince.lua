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

--执行输出
function todayprovince.getview(uptime, maintable, sortchar, sortkey)
    local outhtml = loadTemplate('main')
    outhtml = string.gsub(outhtml, '<pagetitle>' , '今日全国'.. sortchar ..'省份排行榜')
    outhtml = string.gsub(outhtml, '<uptime>' , os.date("%Y-%m-%d %H:%M:%S",uptime))
    outhtml = string.gsub(outhtml, 'active_province_' .. sortkey , 'active')
    outhtml = string.gsub(outhtml, '<maintable>' , maintable)
    return outhtml
end

--执行模块
function todayprovince.run(request)

    --基本参数检验
    local sort_table = {low='最冷', high='最热', avg='最舒适'}
    local tday = request.day or os.date("%Y%m%d")
    if not sort_table[request.sortkey] then
        request.sortkey = 'high'
    end

    --1,定义必用变量，执行REDIS连接
    local list_key = 'province_weather'
    local list_score = help.intval(tday)
    local redis = require 'library.redis'
    local redisSource = redis:new()
    local ok, err = redisSource:connect(config.redis.host, config.redis.port)
    if not ok then
        local message = 'Error:redis connected failed,' .. err
        ngx.log(ngx.ERR, message); ngx.say(message); ngx.exit(200)
    end
    redisSource:auth(config.redis.auth)
    local uptime = help.intval(redisSource:get('province_uptime')) or 0

    --2,检查缓存:今天的不缓存，历史的数据全部走缓存
    local cacheFile = 'province_cache/'..tday..'.'..request.sortkey
    local cacheStatus = cache.checkCache(cacheFile)
    if tday ~= os.date("%Y%m%d") and not cacheStatus then tday = os.date("%Y%m%d") end
    if tday ~= os.date("%Y%m%d") and cacheStatus then
        local cacheChar = cache.readCache(cacheFile)
        return todayprovince.getview(uptime, cacheChar, sort_table[request.sortkey], request.sortkey)
    end

    --3,提取当日数据
    local daydata = redisSource:zrangebyscore(list_key, list_score, list_score)
    if not daydata then ngx.say('no data.');ngx.exit(200) end
    daydata = json.decode(daydata[1])

    --3根据请求更换排序参数
    modhelp = require "modules.modhelp"
    daydata = modhelp.sorttable(daydata, request.sortkey)

    --5,组装数据
    local maintable = '<table class="table table-bordered"><thead><tr>'
    local index,class,clafirst = 0,'',''
    local oldhigh,oldlow=0,0
    local first = 1
    maintable = maintable..'<th>顺序</th><th>排名</th><th>省份</th><th>最高温度</th><th>最低温度</th><th>平均气温</th><th>省会城市</th><th>天气变化</th><th>风力</th><th>下辖市</th></tr></thead><tbody>'
    local most = {}
    for k,row in pairs(daydata) do
        if row.tem2 ~= oldhigh or row.tem1 ~= oldlow then index = index + 1 end
        if first <= 5 then class=' class="danger" '; clafirst = 'class="reds"'
            --循环期间将这天的最热、最冷、最适宜的前10位城市数据写入redis
            table.insert(most, {row.quName,row.tem1,row.tem2,row.temavg})
        elseif math.fmod(index,2) == 1 then class=' class="info" ';clafirst = ''
        else class = '' end
        maintable = maintable .. '<tr'..class..'><td>'..first..'</td><td class="reds">'..index..'</td><td><b>'..row.quName..'</b></td>'
        maintable = maintable .. '<td '.. clafirst ..'>'..row.tem2..'&#176;C</td><td '.. clafirst ..'>'..row.tem1..'&#176;C</td><td '.. clafirst ..'>'..row.temavg..'&#176;C</td>'
        maintable = maintable .. '<td>'..row.cityname..'</td><td>'..row.stateDetailed..'</td><td>'..row.windState..'</td>'
        maintable = maintable .. '<td><a href="'.. help.makeurl('todayprocity', {city=row.pyName,sortkey=request.sortkey}).. '">查看'.. row.quName ..'省' .. sort_table[request.sortkey] ..'城市排行榜</a></td></tr>'
        oldhigh,oldlow = row.tem2,row.tem1
        first = first +1
    end
    maintable = maintable .. '</tbody></table>'

    --6,数据替换及返回
    cache.writeCache(cacheFile, maintable)
    --将前10位城市写入数据库
    if request.save == '1' then
        most_key = 'province_most_'.. request.sortkey
        redisSource:hset(most_key, list_score, json.encode(most))
        return 'Success:save province_most_' .. request.sortkey .. '--day:'..tday ..'----on:' ..os.date("%Y-%m-%d %H:%M:%S")
    end
    return todayprovince.getview(uptime, maintable, sort_table[request.sortkey], request.sortkey)
end

return todayprovince