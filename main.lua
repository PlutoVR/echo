local speech = require 'lua-deepspeech'
local root = lovr.filesystem.getRealDirectory('data')

function lovr.load()
  microphone = lovr.audio.newMicrophone(nil, 1024, 16000, 16, 1)
  microphone:startRecording()

  speech.init({
    model = root .. '/data/deepspeech-0.9.3-models.pbmm',
    scorer = root .. '/data/deepspeech-0.9.3-models.scorer'
  })

  sampleRate = speech.getSampleRate()
  assert(sampleRate == 16000, string.format('Unsupported sample rate %d', sampleRate))
  stream = speech.newStream()
end

function lovr.update(dt)
  if microphone:getSampleCount() > 1024*5 then
    local soundData = microphone:getData()
    stream:feed(soundData:getBlob():getPointer(), soundData:getSampleCount()) 
    print(stream:decode())
    stream:clear()  
  end
end

function lovr.draw()
  lovr.graphics.cube('fill')
  lovr.graphics.print('hello world', 0, 1.7, -3, .5)
end
