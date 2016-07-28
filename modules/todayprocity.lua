----------------------------
--note:今日最热省份
--author:kermit
--date:2016-07-26
----------------------------

todaycity = {}

--执行参数处理
function todaycity.check(request)
    return true
end

--执行输出
function todaycity.getview(uptime, maintable, sortchar, sortkey, proname)
    local outhtml = loadTemplate('main')
    outhtml = string.gsub(outhtml, '<pagetitle>' , proname ..'省' .. sortchar ..'城市排行榜')
    outhtml = string.gsub(outhtml, '<uptime>' , os.date("%Y-%m-%d %H:%M:%S",uptime))
    outhtml = string.gsub(outhtml, 'active_province_' .. sortkey , 'active')
    outhtml = string.gsub(outhtml, '<maintable>' , maintable)
    return outhtml
end

--执行模块
function todaycity.run(request)

    --基本参数检验
    local sort_table = {low='最冷', high='最热', avg='最舒适'}
    local tday = request.day or os.date("%Y%m%d")
    request.city = request.city or 'shandong'
    if not sort_table[request.sortkey] then
        request.sortkey = 'high'
    end

    --1,执行REDIS连接,基本变量定义
    local tday = os.date("%Y%m%d")
    local list_key = 'city_weather'
    local list_score = help.intval(tday)
    local redis = require 'library.redis'
    local redisSource = redis:new()
    local ok, err = redisSource:connect(config.redis.host, config.redis.port)
    if not ok then
        local message = 'Error:redis connected failed,' .. err
        ngx.log(ngx.ERR, message); ngx.say(message); ngx.exit(200)
    end
    redisSource:auth(config.redis.auth)
    local uptime = help.intval(redisSource:get('city_uptime'))

    --2,读取省份取得省会拼音与省名对应table
    local cityTable =  redisSource:get('province')
    cityTable = json.decode(cityTable)
    local city_pro = {}
    for k,v in pairs(cityTable) do
        city_pro[v[1]] = v[2]
    end
    if not city_pro[request.city] then request.city = 'shandong' end

    --3,读取省份下各城市天所数据并缓存：先检查缓存
    local daydatas = redisSource:get('pro_'..request.city)
    local daydata = {}
    if tostring(type(daydatas)) ~= 'string' then
        --3，读取REDIS数据，组装：将省->城市数据组成所有城市并行数据
        daydata = redisSource:zrangebyscore(list_key, list_score, list_score)
        daydata = json.decode(daydata[1])
        daydata = daydata[request.city]
        --将新数据存入redis
        redisSource:setex('pro_'..request.city,7200, json.encode(daydata))
    else
        daydata = json.decode(daydatas)
    end

    --4，根据请求更换排序参数
    modhelp = require "modules.modhelp"
    daydata = modhelp.sorttable(daydata, request.sortkey)

    --5,组装数据
    local maintable = '<table class="table table-bordered"><thead><tr>'
    local index,class,clafirst = 0,'',''
    local oldhigh,oldlow=0,0
    local first = 1
    maintable = maintable..'<th>顺序</th><th>排名</th><th>城市</th><th>最高温度</th><th>最低温度</th><th>平均气温</th><th>天气变化</th><th>风力</th><th>湿度</th></tr></thead><tbody>'
    local most = {}
    for k,row in pairs(daydata) do

        local pro_pinyin = row.propy
        local pro_char = city_pro[pro_pinyin] or '-'

        if row.tem2 ~= oldhigh or row.tem1 ~= oldlow then index = index + 1 end
        if first <= 3 then class=' class="danger" '; clafirst = 'class="reds"'
            --循环期间将这天的最热、最冷、最适宜的前10位城市数据写入redis
            table.insert(most, {pro_char,row.tem1,row.tem2,row.temavg})
        elseif math.fmod(index,2) == 1 then class=' class="info" ';clafirst = ''
        else class = '' end

        maintable = maintable .. '<tr'..class..'><td>'..first..'</td><td class="reds">'..index..'</td><td><b>'..row.cityname..'</b></td>'
        maintable = maintable .. '<td '.. clafirst ..'>'..row.tem2..'&#176;C</td><td '.. clafirst ..'>'..row.tem1..'&#176;C</td><td '.. clafirst ..'>'..row.temavg..'&#176;C</td>'
        maintable = maintable .. '<td>'..row.stateDetailed..'</td><td>'..row.windState..'</td><td>'..row.humidity..'%</td></tr>'
        oldhigh,oldlow = row.tem2,row.tem1
        first = first +1
    end
    maintable = maintable .. '</tbody></table>'

    --6,返回数据
    return todaycity.getview(uptime, maintable, sort_table[request.sortkey], request.sortkey, city_pro[request.city])

end

return todaycity