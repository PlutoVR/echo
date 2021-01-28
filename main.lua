local root = lovr.filesystem.getRealDirectory('data')

function lovr.load()
  captions = 'captions'
  wasPressed = false
  chunkSize = 512
  textScale = .1
  textColor = 0xf7f7f7
  backgroundColor = 0x3933f3

  microphone = lovr.audio.newMicrophone(nil, chunkSize * 2, 16000, 16, 1)
  microphone:startRecording()

  speechChannel = lovr.thread.getChannel('speech')
  speechChannel:push(root)
  speechChannel:push(captions)
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
    local captions = channel:pop()
    local chunkSize = channel:pop()
    local microphone = channel:pop()

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
      if time - prevTime > 2 then
        prevTime = time
        captions = stream:decode()
        channel:push(captions)
        stream:clear()
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

  local message, present = speechChannel:peek()
  if present and type(message) == "string" then
    captions = speechChannel:pop()
  end
end

function lovr.draw()
  lovr.graphics.skybox(screenshots[2])

  lovr.graphics.setColor(backgroundColor)
  lovr.graphics.plane('fill', 0, 1.7, -3.001, 2, 1)
  lovr.graphics.setColor(textColor)
  lovr.graphics.print(captions, 0, 2, -3, textScale)
end
