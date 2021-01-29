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

  captionBox = { x = 0, y = 1.5, z = -2, width = 1.5, height = .65 }
  captions = { '', '', '' }
  fadingCaption = ''
  fadingCaptionOpacity = 1
  fadingAllOpacity = 1
  fadeAllTimer = lovr.timer.getTime() + 10
  currentLine = 1

  lightModeBackground = { 235/255, 225/255, 235/255, .75 }
  lightModeText = { 20/255, 20/255, 20/255, 1 }
  darkModeBackground = { 20/255, 10/255, 20/255, .9 }
  darkModeText = { .9, .9, .9, 1 }

  fontSizeModifiers = {
    small = { textScale = .055, maxLineLength = 52, lineOffset = .07, boxHeightModifier = .5 },
    medium = { textScale = .09, maxLineLength = 32, lineOffset = .1185, boxHeightModifier = .75 },
    large = { textScale = .13, maxLineLength = 22, lineOffset = .14, boxHeightModifier = 1 }
  }

  screenshots = {
    lovr.graphics.newTexture('/images/obduction-nvidia-ansel-360-photosphere.jpg', { mipmaps = false }),
  }

  createCaptionBoxShader()
end

function lovr.update(dt)
  controlPanel:update(dt)
  speech:update(dt)

  active = controlPanel.settings.active
  darkMode = controlPanel.settings.theme == 'dark'
  size = controlPanel.settings.fontSize
  fadingCaptionOpacity = math.max(fadingCaptionOpacity - (dt * 6), 0)

  local time = lovr.timer.getTime()
  if time >= fadeAllTimer then
    fadingAllOpacity = math.max(fadingAllOpacity - (dt * 5), 0)
  end
  if fadingAllOpacity == 0 then
    resetCaptions()
  end
end

function lovr.draw()
  lovr.graphics.setColor(white)
  lovr.graphics.skybox(screenshots[1])
  controlPanel:drawPointer()

  if not active then
    controlPanel:drawAppIcon()
    return
  end

  drawCaptions()

  local x, y, z, angle, ax, ay, az, scale
  x, y, z = captionBox.x - ((captionBox.width / 2) - .25), captionBox.y - (((captionBox.height / 2) * fontSizeModifiers[size].boxHeightModifier) + .1), captionBox.z
  controlPanel:drawUI(x, y, z)

  lovr.graphics.setColor(white)
end

function drawCaptions()
  local backgroundColor = darkMode and darkModeBackground or lightModeBackground
  lovr.graphics.setColor(backgroundColor)
  lovr.graphics.setShader(roundrect)
  lovr.graphics.plane('fill', captionBox.x, captionBox.y, captionBox.z - .001, captionBox.width, captionBox.height * fontSizeModifiers[size].boxHeightModifier)
  lovr.graphics.setShader()

  local textColor = darkMode and darkModeText or lightModeText
  local r, g, b, a = unpack(textColor)
  lovr.graphics.setColor(r, g, b, fadingAllOpacity)
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
    fadingAllOpacity = 1
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
    fadeAllTimer = lovr.timer.getTime() + 5
  end
end

function scrollUp()
  fadingCaptionOpacity = 1
  fadingCaption = captions[1]
  captions[1] = captions[2]
  captions[2] = captions[3]
  captions[3] = ''
end

function resetCaptions()
  captions[1] = ''
  captions[2] = ''
  captions[3] = ''
  currentLine = 1
end

function createCaptionBoxShader()
  roundrect = lovr.graphics.newShader(
    [[
      out vec2 size;
      vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
        size = vec2(length(vec3(transform[0])), length(vec3(transform[1])));
        return projection * transform * vertex;
      }
    ]], [[
      in vec2 size;
      uniform float radius;
      vec4 color(vec4 graphicsColor, sampler2D image, vec2 uv) {
        float r = min(radius, min(size.x, size.y));
        uv *= 2.;
        uv -= 1.;
        uv *= size;
        vec2 b = size;
        vec2 d = abs(uv) - (b - r);
        float sdf = length(max(d, vec2(0))) + min(max(d.x, d.y), 0.) - r;
        float fw = fwidth(sdf);
        float alpha = smoothstep(fw, -fw, sdf);
        return vec4(graphicsColor.rgb, graphicsColor.a * alpha);
      }
    ]]
  )
  roundrect:send('radius', .15)
end