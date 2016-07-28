----------------------------
--note:最热城市、最舒服的城市接口
--author:kermit
--date:2016-07-26
----------------------------

todaycity = {}

--执行参数处理
function todaycity.check(request)
    return true
end

--执行模块
function todaycity.run(request)

    --1,执行REDIS连接,基本变量定义
    local tday = os.date("%Y%m%d")
    local city_most_high,city_most_avg,city_most_low = 'city_most_high','city_most_avg','city_most_low'
    local province_most_high,province_most_avg,province_most_low = 'province_most_high','province_most_avg','province_most_low'
    local list_score = help.intval(tday)
    local redis = require 'library.redis'
    local redisSource = redis:new()
    local ok, err = redisSource:connect(config.redis.host, config.redis.port)
    if not ok then
        local message = 'Error:redis connected failed,' .. err
        ngx.log(ngx.ERR, message); ngx.say(message); ngx.exit(200)
    end
    redisSource:auth(config.redis.auth)

    local datas={
        city_high = json.decode(redisSource:hget(city_most_high, list_score)),
        city_avg = json.decode(redisSource:hget(city_most_avg, list_score)),
        city_low = json.decode(redisSource:hget(city_most_low, list_score)),
        province_high = json.decode(redisSource:hget(province_most_high, list_score)),
        province_avg = json.decode(redisSource:hget(province_most_avg, list_score)),
        province_low = json.decode(redisSource:hget(province_most_low, list_score)),
        }
    --ngx.say(help.html(datas))
    --ngx.exit(200)
    return json.encode(datas)
end

return todaycity