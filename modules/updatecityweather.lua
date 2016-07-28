----------------------------
--note:更新城市天气数据
--author:kermit
--date:2016-07-26
----------------------------

updatecityweather={}

--执行参数处理
function updatecityweather.check(request)

    return true

end

--执行模块
function updatecityweather.run(request)

    ngx.header.servernames = golbal_servername;

    --1,连接redis,读取城市列表
    local redis = require 'library.redis'
    local redisSource = redis:new()
    local ok, err = redisSource:connect(config.redis.host, config.redis.port)
    if not ok then
        local message = 'Error:redis connected failed,' .. err
        ngx.log(ngx.ERR, message); ngx.say(message); ngx.exit(200)
    end
    redisSource:auth(config.redis.auth)
    local cityTable =  redisSource:get('province')
    cityTable = json.decode(cityTable)

    --2,组建并发抓取的参数
    local t = os.time()
    local path_table,cityTableNew = {},{}
    for k,v in pairs(cityTable) do
        if v[1] ~= 'xisha' and v[1] ~= 'nanshadao' and v[1] ~='diaoyudao' then
            cityTableNew[v[1]] = v
            table.insert(path_table,{path = '/wmaps/xml/' ..v[1]..'.xml?'..t})
            --if k >1 then break end
        end
    end
    cityTable={}

    --3,执行并发抓取
    local http = require "library.http"
    local httpc = http.new()
    httpc:set_timeout(500)
    httpc:connect("flash.weather.com.cn", 80)
    local responses = httpc:request_pipeline(path_table)
    if err then ngx.say("ERROR:" .. err); ngx.exit(200); end

    --4循环读取出抓取结果并存入redis
    local xml = require("library.xmlSimple").newParser()
    local xmlTab = {}
    local tday = os.date("%Y%m%d")
    local list_key = 'city_weather'
    local list_score = tonumber(tday)
    local day_weather,state,temp_city = {},{},{}
    local tem1,tem2
    --循环出每个省的数据
    for i,r in ipairs(responses) do
        if r.status == 200 then
            xmlTab = xml:ParseXmlText(r:read_body())
            local pro = xmlTab:children()[1]:name()
            local city_table = xmlTab:children()[1]:children()
            --循环每个省下城市的数据
            local temp_pro = {}
            for _,v in pairs(city_table) do
                tem1 = tonumber(v["@tem1"])
                tem2 = tonumber(v["@tem2"])
                if tem2 < tem1 then
                    tem1,tem2 = tem2,tem1
                end
                temp_city = {
                    pyName = v["@pyName"],
                    cityname = v["@cityname"],
                    tem1 = tem1,
                    tem2 = tem2,
                    pos = v["@cityX"]..','.. v["@cityY"],
                    temavg = (tem1 + tem2)/2,
                    stateDetailed = v["@stateDetailed"],
                    windState = v["@windState"],
                    --tem3 = v["@temNow"],windDir="西风" windPower="2级"
                    humidity = v["@humidity"]
                }
                table.insert(temp_pro,temp_city)
            end
            day_weather[pro] = temp_pro
        end
    end

    --将今日天气数据入库
    redisSource:set('city_uptime', os.time())
    redisSource:zremrangebyscore(list_key, list_score, list_score)
    redisSource:zadd(list_key, list_score, json.encode(day_weather))

    return 'Success:update-city-' .. list_key .. '--day:'..tday ..'----on:' ..os.date("%Y-%m-%d %H:%M:%S")
end

return updatecityweather