--- 名字可以写进common/className
ReuseClass = "Reuse"

--- 重复利用器
--- 构建可重复利用的资源复用数据调用器
--- 可避免多次创建原生对象造成的性能下降与崩溃
---@class Reuse
local _index = Meta(ReuseClass)

---@protected
function _index:destruct()
    self._data = nil
    class.cache(ReuseClass)[self._key] = nil
end

--- 在数据中分配一个资源，如果资源不足则调用create函数生成一个
---@param call fun(this:any):void 资源被分配时定制的执行函数
---@param creator fun():any 资源不足时创建资源函数
---@return any
function _index:allocation(call, creator)
    local one
    if (#self._data > 0) then
        one = self._data[1]
        table.remove(self._data, 1)
    elseif (type(creator) == "function") then
        one = creator()
    end
    must(nil ~= one, "creatorReturnNil")
    if (type(call) == "function") then
        call(one)
    end
    return one
end

--- 资源回归数据中
---@param one any 资源
---@param call fun(this:any):void 资源回收时可配置执行函数
---@return void
function _index:recovery(one, call)
    if (type(call) == "function") then
        call(one)
    end
    table.insert(self._data, one)
end

--- 重复利用器
---@param key string 重复器唯一键
---@return Reuse
function Reuse(key)
    must(type(key) == "string", "key@string")
    local cache = class.cache(ReuseClass)
    if (nil == cache[key]) then
        sync.must()
        cache[key] = oMeta({ _key = key, _data = {} }, _index)
    end
    return cache[key]
end