----------------------------
--note:持续抓取各城市天气数据入口
--author:kermit
--date:2016-07-14
----------------------------

--1,定义调试模式
debug = true
base_path = '/home/wwwroot/04007weather.cn/'  --全局路径前缀
package.path = base_path .. '?.lua;'
help   = require "library.help"
json   = require "library.json"
cache  = require "library.cache"
config = require 'config.config'

--2,提取URL中参数
local params = ngx.req.get_uri_args()
local uri = string.match(string.lower(ngx.var.uri),"/*(.-)/*$")
local uri_table = help.split(uri, "/")
if #uri_table < 1 then uri = 'todaycity'
elseif #uri_table == 1 then uri = uri_table[1]
else
    uri = uri_table[1]
    for i=2,#uri_table,2 do
        params[uri_table[i]] = uri_table[i+1]
    end
end

--3,检查是否有对应的module
file, err=io.open(base_path .. "modules/"..uri..'.lua')
if err then ngx.say('invalid url.'); ngx.log(ngx.ERR, err); ngx.exit(200) end

--4，尝试对应模块
local module,err = help.load_module("modules."..uri)
if err then ngx.say('module error:'.. err); ngx.log(ngx.ERR, err); ngx.exit(200) end

--5，加载模板
function loadTemplate(main)
    local temp_path = base_path ..'templates/'
    local filename = temp_path .. 'head.html'
    local file = io.open(filename, "r");assert(file);
    local outhtml = file:read("*a")

    filename = temp_path .. main ..'.html'
    local file = io.open(filename, "r");assert(file);
    outhtml = outhtml .. file:read("*a")

    filename = temp_path .. 'foot.html'
    local file = io.open(filename, "r");assert(file);
    outhtml = outhtml .. file:read("*a")
    file:close();
    return outhtml
end

--6，执行对应模块并返回数据
local response  = module.run(params)
ngx.say(response)
ngx.exit(200)