--- 地图坐标转屏幕相对左下角坐标
---@param x number
---@param y number
---@param z number
---@return number,number
function t2r(x, y, z)
    local clipSpaceSignY = 1
    local vec3 = { x, z, y }
    local fov = J.GetCameraField(CAMERA_FIELD_FIELD_OF_VIEW) / 2
    local far = J.GetCameraField(CAMERA_FIELD_TARGET_DISTANCE)
    local per = matrix.perspective44(fov, J.Japi.DzGetClientWidth() / (J.Japi.DzGetClientHeight()), 1, far, true, -1, clipSpaceSignY, 1)
    local eye = { J.GetCameraEyePositionX(), J.GetCameraEyePositionZ(), J.GetCameraEyePositionY() }
    local center = { J.GetCameraTargetPositionX(), J.GetCameraTargetPositionZ(), J.GetCameraTargetPositionY() }
    local up = { 0, 1, 0 }
    local at = matrix.lookAt44(eye, center, up)
    local multiMat = matrix.multiply(per, at)
    local ptf = matrix._preTransforms["4x4"][1]
    local out = matrix.transformMatrix44(vec3, multiMat)
    local ox, oy, oz = out[1], out[2], out[3]
    ox = ox * ptf[1] + oy * ptf[3] * clipSpaceSignY
    oy = ox * ptf[2] + oy * ptf[4] * clipSpaceSignY
    ox = (1 + ox) / 2
    oy = (1 + oy) / 2
    oz = oz / 2 + 0.5
    local rx, ry = (1 - ox) * 0.8, oy
    if (math.isNaN(rx) or math.isNaN(ry) or rx < 0 or rx > 0.8) then
        return -1, -1
    end
    return rx, ry
end