--- 名字可以写进common/className
UIAnimateClass = "UIAnimate"

--- 2D动画UI
---@class UIAnimate:UI
local _index = UI(UIAnimateClass, {
    ---@type number 步进
    _step = 0,
    ---@type number 播放中断点时间
    _halt = 0,
    ---@type number 播放周期
    _period = 0,
})

---@private
function _index:destruct()
    class.cache(UIAnimateClass)[self._key] = nil
    class.destroy(self._stepTimer)
    self._stepTimer = nil
end

--- 设置当停止播放时执行函数
--- halt不触发停止
---@param callFunc function
---@return self
function _index:onStop(callFunc)
    if (type(callFunc) == "function") then
        self._onStop = callFunc
    else
        self._onStop = nil
    end
    return self
end

--- 设置贴图动作集
---@param paths string[]
---@return self
function _index:motion(paths)
    self._motion = paths
    return self
end

--- 设置动作周期帧数
---@param frame number
---@return self
function _index:period(frame)
    if (type(frame) == "number" and frame > 0) then
        self._period = frame
        local t = self._stepTimer
        if (class.isObject(t, TimerAsyncClass)) then
            if (t:isInterval()) then
                t:period(frame / #self._motion)
            end
        end
    end
    return self
end

--- 设置动作中断间距
---@param frame number
---@return self
function _index:halt(frame)
    self._halt = frame
end

--- 是否正在播放
---@return boolean
function _index:isPlaying()
    return class.isObject(self._stepTimer, TimerAsyncClass)
end

---@param loop number 循环播放次数，默认1，-1则为无限循环
---@param isReset boolean 是否从头开始，默认nil(false)
---@return void
function _index:play(loop, isReset)
    if (type(self._motion) ~= "table" or #self._motion == 0) then
        return
    end
    if (type(loop) ~= "number") then
        loop = 1
    end
    if (class.isObject(self._stepTimer, TimerAsyncClass)) then
        class.destroy(self._stepTimer)
        self._stepTimer = nil
    end
    if (true == isReset) then
        self._step = 0
    end
    local frq = self._period / #self._motion
    self._stepTimer = async.setInterval(frq, function(curTimer)
        local m = self._motion
        if (nil == m) then
            self:stop()
            return
        end
        local step = self._step
        step = step + 1
        if (nil == m[step]) then
            if (loop > 0) then
                loop = loop - 1
            end
            if (loop == 0 or nil == m[1]) then
                self:stop()
                return
            end
            local halt = self._halt
            if (halt > 0) then
                class.destroy(curTimer)
                self._step = 0
                self._stepTimer = async.setTimeout(halt, function()
                    self._stepTimer = nil
                    self:play(loop, isReset)
                end)
                return
            end
            step = 1
        end
        self._step = step
        local path = japi.AssetsUI(self._kit, m[step], "image")
        japi.DZ_FrameSetTexture(self._handle, path, 0)
    end)
end

--- 停止播放
---@return void
function _index:stop()
    if (class.isObject(self._stepTimer, TimerAsyncClass)) then
        class.destroy(self._stepTimer)
        self._stepTimer = nil
        self._step = 1
        local onStop = self._onStop
        if (type(onStop) == "function") then
            onStop(self)
        end
    end
end

--- 创建 UI 帧动画
---@param key string 索引名
---@param parent UI|nil 默认 UI_Game
---@return UIAnimate
function UIAnimate(key, parent)
    must(type(key) == "string", "key@string")
    local cache = class.cache(UIAnimateClass)
    if (nil == cache[key]) then
        cache[key] = oUI({
            _key = key,
            _parent = parent or UIGame,
            _fdfName = "LK_BACKDROP",
            _fdfType = "BACKDROP"
        }, _index)
    end
    return cache[key]
end