local speech = require 'lua-deepspeech'
local root = lovr.filesystem.getRealDirectory('data')

function lovr.load()
  captions = 'captions'
  wasPressed = false

  microphone = lovr.audio.newMicrophone(nil, 512*2, 16000, 16, 1)
  speech.init({
    model = root .. '/data/deepspeech-0.9.3-models.pbmm',
    scorer = root .. '/data/deepspeech-0.9.3-models.scorer'
  })

  sampleRate = speech.getSampleRate()
  assert(sampleRate == 16000, string.format('Unsupported sample rate %d', sampleRate))
  stream = speech.newStream()
  print('~~ mic: '..microphone:getName())

  textScale = .5
  textColor = 0xf7f7f7
  backgroundColor = 0x3933f3

  screenshots = {
    lovr.graphics.newTexture(root .. '/images/PANO_20150408_183912.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/obduction-nvidia-ansel-360-photosphere.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/VikingVillage_thumb.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/PANO_20191112_182609.jpg', { mipmaps = false })
  }
end

function lovr.update(dt)
  down = lovr.headset.isDown('right', 'trigger')
  if down and not microphone:isRecording() then
    wasPressed = true
    microphone:startRecording()
  elseif wasPressed and not down then
    wasPressed = false
    captions = stream:decode()
    microphone:stopRecording()
    stream:clear()
  end

  if microphone:getSampleCount() > 512 then
    local soundData = microphone:getData()
    stream:feed(soundData:getBlob():getPointer(), soundData:getSampleCount())
  end
end

function lovr.draw()
  lovr.graphics.skybox(screenshots[3])

  lovr.graphics.setColor(backgroundColor)
  lovr.graphics.plane('fill', 0, 1.7, -3.001, 1)
  lovr.graphics.setColor(textColor)
  lovr.graphics.print(captions, 0, 1.7, -3, textScale)
end
