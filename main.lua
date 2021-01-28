local root = lovr.filesystem.getRealDirectory('data')

function lovr.load()
  darkMode = true

  captions = { 'captions', 'test', 'yoyoyoyoyoyoyoyoyoyoyoyoyoyoyo' }
  fadingCaption = ''
  fadingCaptionOpacity = 1
  wasPressed = false
  chunkSize = 1024
  textScale = .125
  currentLine = 1
  maxLineLength = 32

  lightModeBackground = { 245/255, 235/255, 245/255, .9 }
  lightModeText = 0x141414
  darkModeBackground = { 20/255, 20/255, 20/255, .9 }
  darkModeText = { .9, .9, .9, 1 }

  textColor = darkModeText
  backgroundColor = darkModeBackground

  microphone = lovr.audio.newMicrophone(nil, chunkSize * 2, 16000, 16, 1)
  microphone:startRecording()

  speechChannel = lovr.thread.getChannel('speech')
  speechChannel:push(root)
  speechChannel:push(chunkSize)
  speechChannel:push(microphone)

  speech = lovr.thread.newThread([[
    local speech = require 'lua-deepspeech'
    local lovr = {
      thread = require 'lovr.thread',
      audio = require 'lovr.audio',
      data = require 'lovr.data',
      timer = require 'lovr.timer'
    }
    local channel = lovr.thread.getChannel('speech')

    local root = channel:pop()
    local chunkSize = channel:pop()
    local microphone = channel:pop()

    local captions = ''
    local prevTime = 0

    speech.init({
      model = root .. '/data/deepspeech-0.9.3-models.pbmm',
      scorer = root .. '/data/deepspeech-0.9.3-models.scorer'
    })

    sampleRate = speech.getSampleRate()
    assert(sampleRate == 16000, string.format('Unsupported sample rate %d', sampleRate))
    local stream = speech.newStream()
    print('~~ mic: '..microphone:getName())

    while true do
      if microphone:getSampleCount() > chunkSize then
        local soundData = microphone:getData()
        stream:feed(soundData:getBlob():getPointer(), soundData:getSampleCount())
      end
      local time = lovr.timer.getTime()
      if time - prevTime > 1.5 then
        prevTime = time
        captions = stream:decode()
        stream:clear()
        channel:push(captions)
      end
    end
  ]])
  speech:start()

  screenshots = {
    lovr.graphics.newTexture(root .. '/images/PANO_20150408_183912.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/obduction-nvidia-ansel-360-photosphere.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/VikingVillage_thumb.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/PANO_20191112_182609.jpg', { mipmaps = false })
  }
end

function lovr.update(dt)
  -- down = lovr.headset.isDown('right', 'trigger')
  -- if down and not microphone:isRecording() then
  --   wasPressed = true
    -- microphone:startRecording()
  -- elseif wasPressed and not down then
  --   wasPressed = false
  --   captions = stream:decode()
  --   microphone:stopRecording()
  --   stream:clear()
  -- end

  trigger = lovr.headset.wasPressed('left', 'trigger')
  if trigger then
    print(darkMode)
    darkMode = not darkMode
  end

  if darkMode then
    backgroundColor = darkModeBackground
    textColor = darkModeText
  else
    backgroundColor = lightModeBackground
    textColor = lightModeText
  end

  local message, present = speechChannel:peek()
  if present and type(message) == "string" then
    local t = speechChannel:pop()
    addCaption(t)
  end

  fadingCaptionOpacity = math.max(fadingCaptionOpacity - (dt * 5), 0)
end

function lovr.draw()
  lovr.graphics.setColor(0xffffff)

  lovr.graphics.skybox(screenshots[2])

  lovr.graphics.setColor(backgroundColor)
  lovr.graphics.plane('fill', 0, 1, -2.001, 2, .65)

  lovr.graphics.setColor(textColor)
  lovr.graphics.print(captions[1], 0, 1.15, -2, textScale)
  lovr.graphics.print(captions[2], 0, 1, -2, textScale)
  lovr.graphics.print(captions[3], 0, .85, -2, textScale)

  if not isEmpty(fadingCaption) then
    local r, g, b, a = unpack(textColor)
    lovr.graphics.setColor(r, g, b, fadingCaptionOpacity)
    lovr.graphics.print(fadingCaption, 0, 1.28, -2, textScale)
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