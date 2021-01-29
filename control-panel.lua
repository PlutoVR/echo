local control = {}

function control:init()
  self.settings = { active = false, theme = 'dark', fontSize = 'medium' }

  self.buttons = {
    activate = {
      model = lovr.graphics.newModel('models/x.glb'),
      xOffset = 1,
      hover = { ['hand/left'] = false, ['hand/right'] = false },
      onClick = function() self.settings.active = false end
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

  self.icon = {
    model = lovr.graphics.newModel('models/app.glb'),
    hover = { ['hand/left'] = false, ['hand/right'] = false },
    scale = .5,
    offset = lovr.math.newVec3(),
    onClick = function() self.settings.active = true end
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
        if lovr.headset.wasReleased(hand, 'trigger') then
          button.onClick()
        end
      end
      button.hover[hand] = inside

      -- Set the end position of the pointer.  If the raycast produced a hit position then use that,
      -- otherwise extend the pointer's ray outwards by 50 meters and use it as the tip.
      self.tips[hand]:set(inside and hit or (rayPosition + rayDirection * 50))
    end
  end
end

function control:update(dt)
  self:updatePointer()

  if not self.settings.active then
    local handPos = lovr.math.vec3(lovr.headset.getPose('right'))
    local iconHandPos = lovr.math.vec3(lovr.headset.getPose('left'))
    local d = handPos - (iconHandPos + self.icon.offset)
    local isSelecting =  (d.x * d.x + d.y * d.y + d.z * d.z) < (.1 ^ 2)
    self.icon.hover['hand/right'] = isSelecting
    if isSelecting and lovr.headset.wasReleased('right', 'trigger') then
      self.icon.onClick()
    end
  end
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

    if self.settings.active then
      lovr.graphics.line(position, tip)
      lovr.graphics.setColor(1, 1, 1)
    end
  end
end

function control:drawAppIcon()
  local x, y, z, angle, ax, ay, az = lovr.headset.getPose('left')
  local scale = (self.icon.hover['hand/left'] or self.icon.hover['hand/right']) and self.icon.scale * 1.15 or self.icon.scale
  local pos = lovr.math.vec3(x, y, z)
  local offsetPos = pos + self.icon.offset
  self.icon.model:draw(offsetPos, scale, angle, ax, ay, az)
end

return control