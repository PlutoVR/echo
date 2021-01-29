io.stdout:setvbuf('no')
controlPanel = require 'control-panel'
local speech = require 'speech'

white = 0xffffff

function lovr.load()
  controlPanel:init()
  speech:init()
  active = controlPanel.settings.active
  darkMode = controlPanel.settings.theme == 'dark'
  size = controlPanel.settings.fontSize

  captionBox = { x = 0, y = 1, z = -2, width = 1.5, height = .65 }
  captions = { 'captions', 'test', 'yoyoyoyoyoyoyoyoyoyoyo' }
  fadingCaption = ''
  fadingCaptionOpacity = 1
  wasPressed = false
  currentLine = 1

  lightModeBackground = { 245/255, 235/255, 245/255, .9 }
  lightModeText = { 20/255, 20/255, 20/255, 1 }
  darkModeBackground = { 20/255, 20/255, 20/255, .9 }
  darkModeText = { .9, .9, .9, 1 }

  fontSizeModifiers = {
    small = { textScale = .055, maxLineLength = 52, lineOffset = .07, boxHeightModifier = .5 },
    medium = { textScale = .09, maxLineLength = 32, lineOffset = .1185, boxHeightModifier = .75 },
    large = { textScale = .13, maxLineLength = 22, lineOffset = .14, boxHeightModifier = 1 }
  }

  screenshots = {
    lovr.graphics.newTexture('/images/PANO_20150408_183912.jpg', { mipmaps = false }),
    lovr.graphics.newTexture('/images/obduction-nvidia-ansel-360-photosphere.jpg', { mipmaps = false }),
    lovr.graphics.newTexture('/images/VikingVillage_thumb.jpg', { mipmaps = false }),
    lovr.graphics.newTexture('/images/PANO_20191112_182609.jpg', { mipmaps = false })
  }
end

function lovr.update(dt)
  controlPanel:update(dt)
  speech:update(dt)

  active = controlPanel.settings.active and speech.active
  darkMode = controlPanel.settings.theme == 'dark'
  fadingCaptionOpacity = math.max(fadingCaptionOpacity - (dt * 5), 0)
end


function lovr.draw()
  lovr.graphics.setColor(0xffffff)
  lovr.graphics.skybox(screenshots[2])

  if not active then return end

  drawCaptions()
  lovr.graphics.push()
  lovr.graphics.translate(captionBox.x - ((captionBox.width / 2) - .05), captionBox.y - (((captionBox.height / 2) * fontSizeModifiers[size].boxHeightModifier) + .1), captionBox.z)
  controlPanel:draw()
  lovr.graphics.pop()
  lovr.graphics.setColor(0xffffff)
end

function drawCaptions()
  local backgroundColor = darkMode and darkModeBackground or lightModeBackground
  lovr.graphics.setColor(backgroundColor)
  lovr.graphics.plane('fill', captionBox.x, captionBox.y, captionBox.z - .001, captionBox.width, captionBox.height * fontSizeModifiers[size].boxHeightModifier)

  local textColor = darkMode and darkModeText or lightModeText
  lovr.graphics.setColor(textColor)
  lovr.graphics.print(captions[1], captionBox.x, captionBox.y + fontSizeModifiers[size].lineOffset, captionBox.z, fontSizeModifiers[size].textScale)
  lovr.graphics.print(captions[2], captionBox.x, captionBox.y, captionBox.z, fontSizeModifiers[size].textScale)
  lovr.graphics.print(captions[3], captionBox.x, captionBox.y - fontSizeModifiers[size].lineOffset, captionBox.z, fontSizeModifiers[size].textScale)

  if not isEmpty(fadingCaption) then
    local r, g, b, a = unpack(textColor)
    lovr.graphics.setColor(r, g, b, fadingCaptionOpacity)
    lovr.graphics.print(fadingCaption, captionBox.x, captionBox.y + (fontSizeModifiers[size].lineOffset * 2), captionBox.z, fontSizeModifiers[size].textScale)
    if fadingCaptionOpacity == 0 then
      fadingCaption = ''
    end
  end
end

function isEmpty(str)
  return str == ''
end

function addCaption(text)
  if not isEmpty(text) then
    if (#captions[currentLine] + #text) <= fontSizeModifiers[size].maxLineLength then
      captions[currentLine] = captions[currentLine] .. ' ' .. text
    else
      if currentLine == 3 then
        scrollUp()
      else
        currentLine = currentLine + 1
      end
      captions[currentLine] = text
    end
  end
end

function scrollUp()
  fadingCaptionOpacity = 1
  fadingCaption = captions[1]
  captions[1] = captions[2]
  captions[2] = captions[3]
  captions[3] = ''
end