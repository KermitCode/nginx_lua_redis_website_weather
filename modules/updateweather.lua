----------------------------
--note:更新天气数据
--author:kermit
--date:2016-07-26
----------------------------

updateweather={}

--执行参数处理
function updateweather.check(request)

    return true

end

--执行模块
function updateweather.run(request)

    --1,抓取天气数据
    ngx.header.servernames = golbal_servername;
    local http = require "library.http"
    local httpc = http.new()
    local res, err = httpc:request_uri("http://flash.weather.com.cn", {
            method = "GET",
            path = '/wmaps/xml/china.xml',
          })
    if err then ngx.say("ERROR:" .. err); ngx.exit(200); end

    --2,执行REDIS连接
    local redis = require 'library.redis'
    local redisSource = redis:new()
    local ok, err = redisSource:connect(config.redis.host, config.redis.port)
    if not ok then
        local message = 'Error:redis connected failed,' .. err
        ngx.log(ngx.ERR, message); ngx.say(message); ngx.exit(200)
    end
    redisSource:auth(config.redis.auth)

    --3,XML解析数据
    local xml = require("library.xmlSimple").newParser()
    local xmlTab = xml:ParseXmlText(res.body)

    --4,数据存储redis
    local tday = os.date("%Y%m%d")
    local list_key = 'province_weather'
    local list_score = tonumber(tday)
    local day_weather={}
    local state = {}
    local tem1,tem2
    local temp_pro={}
    for k,v in pairs(xmlTab.china.city) do
        tem1 = tonumber(v["@tem1"])
        tem2 = tonumber(v["@tem2"])
        if tem2 < tem1 then
            tem1,tem2 = tem2,tem1
        end
        local temp_data = {
            pyName = v["@pyName"],
            tem1 = tem1,
            tem2 = tem2,
            temavg = (tem1 + tem2)/2,
            quName = v["@quName"],
            cityname = v["@cityname"],
            stateDetailed = v["@stateDetailed"],
            windState = v["@windState"]
        }
        table.insert(day_weather, temp_data)
        --得出状态数据
        if v["@state1"] == v["@state2"] then
            state[v["@state1"]] = v["@stateDetailed"]
        end
        --得出省份列表,得出之后可以不用再更新。
        --table.insert(temp_pro, {v["@pyName"], v["@quName"], v["@cityname"]})
        --redisSource:set('province', json.encode(temp_pro)) --此名在循环外执行
    end

    --将状态数据保存
    local hash_key = 'state_data';
    for id,sta in pairs(state) do
        redisSource:hset(hash_key, id, sta)
    end

    --将今日天气数据入库
    redisSource:set('province_uptime', os.time())
    redisSource:zremrangebyscore(list_key, list_score, list_score)
    redisSource:zadd(list_key, list_score, json.encode(day_weather))

    return 'Success:update-province-' .. list_key .. '--day:'..tday ..'----on:' ..os.date("%Y-%m-%d %H:%M:%S")
end

return updateweather