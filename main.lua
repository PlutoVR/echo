io.stdout:setvbuf('no')
local root = lovr.filesystem.getRealDirectory('data')
controlPanel = require 'control-panel'
local speech = require 'speech'

white = 0xffffff

function lovr.load()
  controlPanel:init()
  speech:init()
  active = controlPanel.settings.active
  darkMode = controlPanel.settings.theme == 'dark'

  captionBox = { x = 0, y = 1, z = -2 }
  captions = { 'captions', 'test', 'yoyoyoyoyoyoyoyoyoyoyoyoyoyoyo' }
  fadingCaption = ''
  fadingCaptionOpacity = 1
  wasPressed = false
  textScale = .125
  currentLine = 1
  maxLineLength = 32

  lightModeBackground = { 245/255, 235/255, 245/255, .9 }
  lightModeText = 0x141414
  darkModeBackground = { 20/255, 20/255, 20/255, .9 }
  darkModeText = { .9, .9, .9, 1 }

  screenshots = {
    lovr.graphics.newTexture(root .. '/images/PANO_20150408_183912.jpg', { mipmaps = false }),
    lovr.graphics.newTexture('/images/obduction-nvidia-ansel-360-photosphere.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/VikingVillage_thumb.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/PANO_20191112_182609.jpg', { mipmaps = false })
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
  lovr.graphics.translate(captionBox.x - .9, captionBox.y - .4, captionBox.z)
  controlPanel:draw()
  lovr.graphics.pop()
  lovr.graphics.setColor(0xffffff)
end

function drawCaptions()
  local backgroundColor = darkMode and darkModeBackground or lightModeBackground
  lovr.graphics.setColor(backgroundColor)
  lovr.graphics.plane('fill', captionBox.x, captionBox.y, captionBox.z - .001, 2, .65)

  local textColor = darkMode and darkModeText or lightModeText
  lovr.graphics.setColor(textColor)
  lovr.graphics.print(captions[1], captionBox.x, captionBox.y + .15, captionBox.z, textScale)
  lovr.graphics.print(captions[2], captionBox.x, captionBox.y, captionBox.z, textScale)
  lovr.graphics.print(captions[3], captionBox.x, captionBox.y - .15, captionBox.z, textScale)

  if not isEmpty(fadingCaption) then
    local r, g, b, a = unpack(textColor)
    lovr.graphics.setColor(r, g, b, fadingCaptionOpacity)
    lovr.graphics.print(fadingCaption, captionBox.x, captionBox.y + .28, captionBox.z, textScale)
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
    if (#captions[currentLine] + #text) <= maxLineLength then
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