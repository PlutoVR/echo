local control = {}

function control:init()
  self.settings = { active = true, theme = 'dark', fontSize = 'medium' }

  self.buttons = {
    activate = {
      model = lovr.graphics.newModel('models/x.glb'),
      xOffset = 1,
      onClick = function() self.settings.active = not self.settings.active end
    },
    darkMode = {
      model = lovr.graphics.newModel('models/dark.glb'),
      xOffset = 0,
      onClick = function() self.settings.theme = 'dark' end
    },
    lightMode = {
      model = lovr.graphics.newModel('models/light.glb'),
      xOffset = .15,
      onClick = function() self.settings.theme = 'light' end
    },
    fontSmall = {
      model = lovr.graphics.newModel('models/small.glb'),
      xOffset = .4,
      onClick = function() self.settings.fontSize = 'small' end
    },
    fontMedium = {
      model = lovr.graphics.newModel('models/medium.glb'),
      xOffset = .55,
      onClick = function() self.settings.fontSize = 'medium' end
    },
    fontLarge = {
      model = lovr.graphics.newModel('models/large.glb'),
      xOffset = .7,
      onClick = function() self.settings.fontSize = 'large' end
    },
  }
  self.buttonScale = .6
end

function control:update(dt)
  self:handleActivate()
  self:handleThemeSelection()
end

function control:draw()
  lovr.graphics.setColor(white)
  for k,v in pairs(self.buttons) do
    v.model:draw(v.xOffset, 0, 0, self.buttonScale, math.pi / 2, 1, 0, 0)
  end
end

function control:handleThemeSelection()
  local trigger = lovr.headset.wasPressed('left', 'trigger')
  if trigger then
    local click = (self.settings.theme == 'dark') and self.buttons.lightMode.onClick or self.buttons.darkMode.onClick
    click()
  end
end

function control:handleActivate()
  if lovr.headset.wasPressed('right', 'trigger') then
    self.buttons.activate.onClick()
  end
end

return control