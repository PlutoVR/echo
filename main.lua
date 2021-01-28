local root = lovr.filesystem.getRealDirectory('data')

function lovr.load()
  darkMode = true

  captions = 'captions'
  wasPressed = false
  chunkSize = 512
  textScale = .1
  
  lightModeBackground = {245/255, 235/255, 245/255, .9}
  lightModeText = 0x141414
  darkModeBackground = {20/255, 20/255, 20/255, .9}
  darkModeText = 0xf7f7f7

  textColor = darkModeText
  backgroundColor = darkModeBackground

  microphone = lovr.audio.newMicrophone(nil, chunkSize * 2, 16000, 16, 1)
  microphone:startRecording()

  speechChannel = lovr.thread.getChannel('speech')
  speechChannel:push(root)
  speechChannel:push(captions)
  speechChannel:push(chunkSize)
  speechChannel:push(microphone)

  screenshots = {
    lovr.graphics.newTexture(root .. '/images/PANO_20150408_183912.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/obduction-nvidia-ansel-360-photosphere.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/VikingVillage_thumb.jpg', { mipmaps = false }),
    lovr.graphics.newTexture(root .. '/images/PANO_20191112_182609.jpg', { mipmaps = false }),
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
    captions = speechChannel:pop()
  end
end

function lovr.draw()
  lovr.graphics.setColor(1, 1, 1, 1)
  lovr.graphics.skybox(screenshots[3])

  lovr.graphics.setColor(backgroundColor)
  lovr.graphics.plane('fill', 0, 1.7, -3.001, 2, 1)

  lovr.graphics.setColor(textColor)
  lovr.graphics.print(captions, 0, 2, -3, textScale)
  lovr.graphics.setColor(1, 1, 1, 1)

end