# nginx_lua_redis_website_weather
使用lua开发的简单web站点（nginx_lua_redis_website_weather）

相关介绍：http://www.04007.cn/article/190.html

目前挂在网上的地址：http://weather.04007.cn/

功能:用shell定时执行两个update的lua程序，一个是每天更新全国（含各省份的天气数据进入redis).二个是每天更新全国各个省（并发同时抓取)下所有城市的
天气数据。都保存进redis.我这边此时的redis数据有：
city_most_avg(1)
city_most_high(1)
city_most_low(1)
city_uptime
city_weather(2)
citypage_cachetime_avg
citypage_cachetime_high
citypage_cachetime_low
pro_fujian
pro_sanxi
pro_shanghai
province
province_most_avg(1)
province_most_high(1)
province_most_low(1)
province_uptime
province_weather(1)
state_data(8)
前台使用nginx+lua展现web.对模板只做了一些简单的替换而已。这套程序非常适合于想学lua的人，拿着这套程序改改就基本能掌握lua了。
文件里还附带了一张页面的截图。
