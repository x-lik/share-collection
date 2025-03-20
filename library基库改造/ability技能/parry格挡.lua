--- 底层技能 格挡/回避 只能用在瞬间伤害之后
---@param whichUnit Unit
function ability.parry(whichUnit)
    sync.must()
    J.UnitAddAbility(whichUnit.handle(), LK_SLK_ID_AVOID_ADD)
    J.SetUnitAbilityLevel(whichUnit.handle(), LK_SLK_ID_AVOID_ADD, 2)
    J.UnitRemoveAbility(whichUnit.handle(), LK_SLK_ID_AVOID_ADD)
    time.setTimeout(0, function(_)
        J.UnitAddAbility(whichUnit.handle(), LK_SLK_ID_AVOID_SUB)
        J.SetUnitAbilityLevel(whichUnit.handle(), LK_SLK_ID_AVOID_SUB, 2)
        J.UnitRemoveAbility(whichUnit.handle(), LK_SLK_ID_AVOID_SUB)
    end)
end