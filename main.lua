local speech = require 'lua-deepspeech'
local root = lovr.filesystem.getRealDirectory('data')

function lovr.load()
  microphone = lovr.audio.newMicrophone(nil, 512*2, 16000, 16, 1)
  captions = ''
  wasPressed = false
  speech.init({
    model = root .. '/data/deepspeech-0.9.3-models.pbmm',
    scorer = root .. '/data/deepspeech-0.9.3-models.scorer'
  })

  sampleRate = speech.getSampleRate()
  assert(sampleRate == 16000, string.format('Unsupported sample rate %d', sampleRate))
  stream = speech.newStream()
end

function lovr.update(dt)
  down = lovr.headset.isDown('right', 'trigger')

  if down and not microphone:isRecording() then
    wasPressed = true
    microphone:startRecording()
  elseif wasPressed and not down then
    microphone:stopRecording()
    wasPressed = false
    captions = stream:decode()
    stream:clear()
  end


  if microphone:getSampleCount() > 512 then
    local soundData = microphone:getData()
    stream:feed(soundData:getBlob():getPointer(), soundData:getSampleCount())
  end
end

function lovr.draw()
  lovr.graphics.cube('fill')
  lovr.graphics.print(captions, 0, 1.7, -3, .5)
end
