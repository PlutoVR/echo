local speech = {}

local root = lovr.filesystem.getRealDirectory('data')

function speech:init()
  self.active = true
  self.chunkSize = 1024
  self.microphone = lovr.audio.newMicrophone(nil, self.chunkSize * 2, 16000, 16, 1)
  self.microphone:startRecording()

  self.speechChannel = lovr.thread.getChannel('speech')
  self.speechChannel:push(root)
  self.speechChannel:push(self.chunkSize)
  self.speechChannel:push(self.microphone)

  self.speechThread = lovr.thread.newThread([[
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
  self.speechThread:start()
end

function speech:update(dt)
  self:updateCaptions()
end

function speech:updateCaptions()
  local message, present = self.speechChannel:peek()
  if present and type(message) == "string" then
    local t = self.speechChannel:pop()
    if string.find(t, 'cap on') then
      self.active = true
    elseif string.find(t, 'cap off') then
      self.active = false
    else
      addCaption(t)
    end
  end
end

return speech