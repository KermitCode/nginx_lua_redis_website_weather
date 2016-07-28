---
-- 全局配置
--

return {
    -- ngx_lua共享内存
    share_dict = {
        name = "weather_shm"
    },


    user_danmu_interval = 7,  --用户发弹幕的时间间隔

    --写redis服务器配置
    redis = {
        host = '127.0.0.1',
        port = 6379,
        auth = '', --记得写密码，或者把redis设为只能本地登录
        connect_timeout = 2000,
        keepalive_timeout = 60000,
        pool_size = 100
    },

}
