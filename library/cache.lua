-----------------------------------
--Note  :缓存函数类-开发李艳林
--Author:liyanlin@baofeng.com
--Time  :2016-07-27
-----------------------------------

cache = {}

--缓存的路径
cachePath = base_path .. "cache/"

--1,判断缓存文件是否存在,
function cache.checkCache(filename)
    local file,err=io.open(cachePath .. filename)
    if err then
        return nil
    else
        return true
    end
end

--2,写入缓存
function cache.writeCache(filename, html)
    local file = io.open(cachePath .. filename, "w")
    file:write(html)
    file:close()
    return true
end

--3,读取缓存
function cache.readCache(filename)
    local file = io.open(cachePath .. filename, "r");
    assert(file);
    local out = file:read("*a")
    return out
end

return cache