local root = lovr.filesystem.getRealDirectory('data')

function lovr.load()
  captions = { 'captions', 'test', 'yoyoyoyoyoyoyoyoyoyoyoyoyoyoyo' }
  fadingCaption = ''
  fadingCaptionOpacity = 1
  wasPressed = false
  chunkSize = 1024
  textScale = .125
  textColor = { 1, 1, 1, 1 } --0xf7f7f7
  backgroundColor = 0x3933f3
  currentLine = 1
  maxLineLength = 32
  active = true

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
  if lovr.headset.wasPressed('right', 'trigger') then
    active = not active
  end

  updateCaptions()
  fadingCaptionOpacity = math.max(fadingCaptionOpacity - (dt * 5), 0)
end

function updateCaptions()
  local message, present = speechChannel:peek()
  if present and type(message) == "string" then
    local t = speechChannel:pop()
    if string.find(t, 'cap on') then
      active = true
    elseif string.find(t, 'cap off') then
      active = false
    else
      addCaption(t)
    end
  end
end

function lovr.draw()
  lovr.graphics.setColor(0xffffff)
  lovr.graphics.skybox(screenshots[2])

  if not active then return end

  drawCaptions()
end

function drawCaptions()
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