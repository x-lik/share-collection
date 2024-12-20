--- 合成管理
--- 管理类似合成这种行为的数据
--- 具体实现需要自行处理
fusion = fusion or {}

-- 合件组成 fusion->part
fusion._s2f = fusion._s2f or {}
-- 合件需求 fusion quantity requirement
fusion._sqr = fusion._sqr or {}
-- 零件目标 part->fusion
fusion._f2s = fusion._f2s or {}

--- 分析并返回依赖需求名称
---@param ref Tpl
---@return string,string
function fusion.refName(ref)
    local tplClass, refClass
    local cn = ref._className
    if (cn == ItemTplClass) then
        tplClass = cn
        refClass = ItemClass
    elseif (cn == AbilityTplClass) then
        tplClass = cn
        refClass = AbilityClass
    elseif (cn == ItemClass or cn == AbilityClass) then
        tplClass = ref._tpl._className
        refClass = cn
    end
    return tplClass, refClass
end

--- 合成公式配置
--- 第一个参数为目标对象，后面为同类型的其他组成对象
--- 如需要的组成对象数量为N，则重复注入N次即可
---@param ref Tpl 合成目标
---@vararg Tpl
---@return void
function fusion.formula(ref, ...)
    must(class.instanceof(ref, TplClass), "ref@Tpl")
    local sid = ref:id()
    local tcn = ref._className
    if (nil ~= fusion._s2f[sid]) then
        for i = #fusion._s2f[sid], 1, -1 do
            local fid = fusion._s2f[sid][i]
            local ffs = fusion._f2s[fid]
            if (nil ~= ffs) then
                table.delete(ffs, sid, 1)
            end
        end
        fusion._sqr[sid] = nil
    end
    fusion._s2f[sid] = nil
    for _, s in ipairs({ ... }) do
        if (tcn == s._className) then
            local fid = s:id()
            if (nil == fusion._s2f[sid]) then
                fusion._s2f[sid] = {}
                fusion._sqr[sid] = {}
            end
            table.insert(fusion._s2f[sid], fid)
            if (nil == fusion._sqr[sid][fid]) then
                fusion._sqr[sid][fid] = 1
                if (nil == fusion._f2s[fid]) then
                    fusion._f2s[fid] = {}
                end
                table.insert(fusion._f2s[fid], sid)
            else
                fusion._sqr[sid][fid] = fusion._sqr[sid][fid] + 1
            end
        end
    end
end

--- 合并
--- 分析Tpl或实际对应的Tpl拆分过程，返回合并结果零件集，不会对实际实例造成影响
--- 零件Tpl支持 ItemTpl|Item|AbilityTpl|Ability
---@vararg Tpl
---@return Tpl[]
function fusion.conflate(...)
    local parts = { ... }
    if (#parts < 1) then
        return {}
    end
    local tplClass, _ = fusion.refName(parts[1])
    local fakeSlot = Array()
    for _, v in ipairs(parts) do
        if (class.instanceof(v, tplClass)) then
            local id
            if (tplClass == v._className) then
                id = v:id()
            else
                id = v:tpl():id()
            end
            if (fakeSlot:keyExists(id)) then
                fakeSlot:set(id, fakeSlot:get(id) + 1)
            else
                fakeSlot:set(id, 1)
            end
        end
    end
    parts = nil
    -- 合成流程
    local matching = 1
    while (matching > 0) do
        matching = 0
        fakeSlot:forEach(function(fid, has0)
            if (nil ~= fusion._f2s[fid]) then
                for _, sid in ipairs(fusion._f2s[fid]) do
                    if (has0 >= fusion._sqr[sid][fid]) then
                        local match = true
                        local s2f = fusion._s2f[sid]
                        for _, fid2 in ipairs(s2f) do
                            local has = fakeSlot:get(fid2) or 0
                            local need = fusion._sqr[sid][fid2]
                            if (has < need) then
                                match = false
                                break
                            end
                        end
                        if (match) then
                            matching = matching + 1
                            for _, fid2 in ipairs(s2f) do
                                local n = fakeSlot:get(fid2) - 1
                                if (n <= 0) then
                                    fakeSlot:set(fid2, nil)
                                else
                                    fakeSlot:set(fid2, n)
                                end
                            end
                            local n = (fakeSlot:get(sid) or 0) + 1
                            fakeSlot:set(sid, n)
                        end
                    end
                end
            end
        end)
    end
    local surplus = {}
    fakeSlot:forEach(function(id, n)
        for _ = 1, n do
            table.insert(surplus, class.i2o(id))
        end
    end)
    class.destroy(fakeSlot)
    return surplus
end

--- 拆分
--- 分析Tpl或实际对应的Tpl拆分过程，返回拆分结果零件集，不会对实际实例造成影响
---@param ref Tpl 合件 ItemTpl|Item|AbilityTpl|Ability
---@param isRecursion boolean 是否拆分到原子级，默认false
---@return Tpl[]
function fusion.separate(ref, isRecursion)
    must(class.instanceof(ref, TplClass), "ref@Tpl")
    local surplus = {}
    local sid = ref:id()
    local s2f = fusion._s2f[sid]
    if (nil == s2f) then
        return surplus
    end
    if (type(isRecursion) ~= "boolean") then
        isRecursion = false
    end
    if (true == isRecursion) then
        s2f = {}
        local re
        re = function(rsid)
            for _, rfid in ipairs(fusion._s2f[rsid]) do
                if (nil == fusion._s2f[rfid]) then
                    s2f[#s2f + 1] = rfid
                else
                    re(rfid)
                end
            end
        end
        re(sid)
    end
    for _, fid in ipairs(s2f) do
        table.insert(surplus, class.i2o(fid))
    end
    return surplus
end