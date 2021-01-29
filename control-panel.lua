local control = {}

function control:init()
  self.settings = { active = true, theme = 'dark', fontSize = 'medium' }

  self.buttons = {
    activate = {
      model = lovr.graphics.newModel('models/x.glb'),
      xOffset = 1,
      hover = { ['hand/left'] = false, ['hand/right'] = false },
      onClick = function() self.settings.active = not self.settings.active end
    },
    darkMode = {
      model = lovr.graphics.newModel('models/dark.glb'),
      xOffset = 0,
      hover = { ['hand/left'] = false, ['hand/right'] = false },
      onClick = function() self.settings.theme = 'dark' end
    },
    lightMode = {
      model = lovr.graphics.newModel('models/light.glb'),
      xOffset = .15,
      hover = { ['hand/left'] = false, ['hand/right'] = false },
      onClick = function() self.settings.theme = 'light' end
    },
    fontSmall = {
      model = lovr.graphics.newModel('models/small.glb'),
      xOffset = .4,
      hover = { ['hand/left'] = false, ['hand/right'] = false },
      onClick = function() self.settings.fontSize = 'small' end
    },
    fontMedium = {
      model = lovr.graphics.newModel('models/medium.glb'),
      xOffset = .55,
      hover = { ['hand/left'] = false, ['hand/right'] = false },
      onClick = function() self.settings.fontSize = 'medium' end
    },
    fontLarge = {
      model = lovr.graphics.newModel('models/large.glb'),
      xOffset = .7,
      hover = { ['hand/left'] = false, ['hand/right'] = false },
      onClick = function() self.settings.fontSize = 'large' end
    },
  }
  self.buttonScale = .6
  self.buttonHeight = .2*self.buttonScale
  self.buttonWidth = .2*self.buttonScale
  self.offsetX, self.offsetY, self.offsetZ = 0, 0, 0

  self.tips = {}
end

function control:raycast(rayPos, rayDir, planePos, planeDir)
  local dot = rayDir:dot(planeDir)
  if math.abs(dot) < .001 then
    return nil
  else
    local distance = (planePos - rayPos):dot(planeDir) / dot
    if distance > 0 then
      return rayPos + rayDir * distance
    else
      return nil
    end
  end
end

function control:updatePointer()
  for i, hand in ipairs(lovr.headset.getHands()) do
    self.tips[hand] = self.tips[hand] or lovr.math.newVec3()

    -- Ray info:
    local rayPosition = vec3(lovr.headset.getPosition(hand))
    local rayDirection = vec3(quat(lovr.headset.getOrientation(hand)):direction())

    for _, button in pairs(self.buttons) do
      local buttonPosition = lovr.math.newVec3(self.offsetX + button.xOffset, self.offsetY, self.offsetZ)
      -- Call the raycast helper function to get the intersection point of the ray and the button plane
      local hit = self:raycast(rayPosition, rayDirection, buttonPosition, vec3(0, 0, 1))

      local inside = false
      if hit then
        local bx, by, bw, bh = buttonPosition.x, buttonPosition.y, self.buttonWidth / 2, self.buttonHeight / 2
        inside = (hit.x > bx - bw) and (hit.x < bx + bw) and (hit.y > by - bh) and (hit.y < by + bh)
      end

      -- If the ray intersects the plane, do a bounds test to make sure the x/y position of the hit
      -- is inside the button, then mark the button as hover/active based on the trigger state.
      if inside then
        button.hover[hand] = true
        if lovr.headset.wasReleased(hand, 'trigger') then
          button.onClick()
        end
      else
        button.hover[hand] = false
      end

      -- Set the end position of the pointer.  If the raycast produced a hit position then use that,
      -- otherwise extend the pointer's ray outwards by 50 meters and use it as the tip.
      self.tips[hand]:set(inside and hit or (rayPosition + rayDirection * 50))
    end
  end
end

function control:update(dt)
  self:updatePointer()
end

function control:drawUI(x, y, z)
  self.offsetX, self.offsetY, self.offsetZ = x, y, z
  lovr.graphics.setColor(white)
  lovr.graphics.push()
  lovr.graphics.translate(x, y, z)
  for _, b in pairs(self.buttons) do
    local scale = (b.hover['hand/left'] or b.hover['hand/right']) and self.buttonScale * 1.25 or self.buttonScale
    b.model:draw(b.xOffset, 0, 0, scale, math.pi / 2, 1, 0, 0)
  end
  lovr.graphics.pop()
end

function control:drawPointer()
  for hand, tip in pairs(self.tips) do
    local position = vec3(lovr.headset.getPosition(hand))

    lovr.graphics.setColor(1, 1, 1)
    lovr.graphics.sphere(position, .01)

    lovr.graphics.line(position, tip)
    lovr.graphics.setColor(1, 1, 1)
  end
end

return control