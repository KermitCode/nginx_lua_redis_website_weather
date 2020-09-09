# nginx_lua_redis_website_weather
使用lua+redis开发的简单web站点，每天抓取全国主要城市的天气数据存入redis,根据气温显示每日的最舒适的城市明细。（nginx_lua_redis_website_weather）
功能:用shell定时执行两个update的lua程序，一个是每天更新全国（含各省份的天气数据进入redis).二个是每天更新全国各个省（并发同时抓取)下所有城市的天气数据。都保存进redis.我这边此时的redis数据有：
city_most_avg(1)  city_most_high(1) city_most_low(1) --记录每天城市的各种极值天气

city_uptime city_weather(2) --城市的天气有及更新的时间

citypage_cachetime_avg  citypage_cachetime_high citypage_cachetime_low  --页面的缓存时间

pro_fujian  pro_sanxi pro_shanghai  province  --一些缓存为加快速度。也没进行其它的估化

province_most_avg(1)  province_most_high(1) province_most_low(1) --省份的极值天气

province_uptime province_weather(1) --省份的天气数据及更新时间

state_data(8) --一些状态，保存着可能有用

前台使用nginx+lua展现web.对模板只做了一些简单的替换而已。这套程序非常适合于想学lua的人，拿着这套程序改改就基本能掌握lua了。
文件里还附带了一张页面的截图。

此程序使用了github上的两个redis扩展,一个是http请求的，一个是xml解析的，很好用：

lua-resty-http，https://github.com/pintsized/lua-resty-http

Lua-Simple-XML-Parser,https://github.com/Cluain/Lua-Simple-XML-Parser  

页面展示如下：
<img src="https://raw.githubusercontent.com/KermitCode/nginx_lua_redis_website_weather/master/%E4%BB%8A%E6%97%A5%E5%85%A8%E5%9B%BD%E6%9C%80%E8%88%92%E9%80%82%E5%9F%8E%E5%B8%82%E6%8E%92%E8%A1%8C%E6%A6%9C-04007%E5%9F%8E%E5%B8%82%E6%B8%A9%E5%BA%A6.jpg">

#/bin/bash
#每天每隔3小时更新天气
#0 */3 * * * /home/shell/update04007weather.sh

定时任务：
#请求URL更新数据
curl 'http://weather.04007.cn/updateweather' >> weather_province.log
curl 'http://weather.04007.cn/updatecityweather' >> weather_city.log

#请求URL保存城市数据
curl 'http://weather.04007.cn/todayprovince/sortkey/avg/save/1' >> weather_province.log
curl 'http://weather.04007.cn/todayprovince/sortkey/low/save/1' >> weather_province.log
curl 'http://weather.04007.cn/todayprovince/sortkey/high/save/1' >> weather_province.log 

curl 'http://weather.04007.cn/todaycity/sortkey/avg/save/1' >> weather_city.log 
curl 'http://weather.04007.cn/todaycity/sortkey/low/save/1' >> weather_city.log 
curl 'http://weather.04007.cn/todaycity/sortkey/high/save/1' >> weather_city.log
