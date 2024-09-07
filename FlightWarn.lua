FlightWarnSettings = {
  ["enableStraightLine"] = true,
  ["delayStraightLine"] = 60,
  ["soundStraightLine"] = "Interface\\AddOns\\FlightWarn\\Sounds\\blip_8.ogg",
  ["enableFatigue"] = true,
  ["delayFatigue"] = 5,
  ["repeatFatigue"] = 10,
  ["soundFatigue"] = "Interface\\AddOns\\FlightWarn\\Sounds\\alarmclockbeeps.ogg",
}


-- function to call appropriately PlaySound* function based on sound string
local function PlaySoundHelper(sound, channel)
  local soundlc = strlower(sound)
  
  if ((string.sub(soundlc, -4) == ".wav") or (string.sub(soundlc, -4) == ".mp3") or (string.sub(soundlc, -4) == ".ogg")) then
    PlaySoundFile(sound, channel)
  else
    PlaySound(sound, channel)
  end
end


local function GetRealSpeed()
  local p = "player"
  if IsPossessBarVisible() then p = "pet" end
  if UnitUsingVehicle("player") or UnitHasVehicleUI("player") then p = "vehicle" end

  return floor((GetUnitSpeed(p) * 100 / BASE_MOVEMENT_SPEED) + 0.5)
end


local startFlightTime = nil
local previousAngle = nil
local previousSpeed = nil
local flightFatigueTimer = nil
local lastFatigueWarn = nil
FlightWarn = CreateFrame("Frame")
FlightWarn:HookScript("OnUpdate", function(self, time)
  --user is flying and moving
  if IsFlying() and GetRealSpeed() > 0 then
    --user was not flying last update
    if not startFlightTime then
      startFlightTime = GetTime()
      previousAngle = GetPlayerFacing()
      previousSpeed = GetRealSpeed()
    --user was flying before
    else
      local newAngle = GetPlayerFacing()
      local newSpeed = GetRealSpeed()
      --user is facing different direction, reset start time
      if newAngle ~= previousAngle or newSpeed ~= previousSpeed then
        startFlightTime = GetTime()
      end
      previousAngle = newAngle
      previousSpeed = newSpeed

      local exhaustionName, _, _, exhaustionScale = GetMirrorTimerInfo(1)
      local exhaustionTime = GetMirrorTimerProgress("EXHAUSTION")
      --if player has been flying into fatigue for 5s, play sound     
      if exhaustionName == "EXHAUSTION" and exhaustionScale == -1 and exhaustionTime > 0 and exhaustionTime < (60000 - (FlightWarnSettings.delayFatigue * 1000)) then
        --repeat warning every 10s
        if not lastFatigueWarn or GetTime() - lastFatigueWarn >= FlightWarnSettings.repeatFatigue then
          if FlightWarnSettings.enableFatigue then
            PlaySoundHelper(FlightWarnSettings.soundFatigue, "Master")
            print("You have been flying into fatigue for at least "..FlightWarnSettings.delayFatigue.." seconds!")
          end
          lastFatigueWarn = GetTime()
        end
      end

      --if player has been flying same direction for a minute, play sound
      if GetTime() - startFlightTime >= FlightWarnSettings.delayStraightLine then
        if FlightWarnSettings.enableStraightLine then
          PlaySoundHelper(FlightWarnSettings.soundStraightLine, "Master")
          print("You have been flying in a straight line for "..FlightWarnSettings.delayStraightLine.." seconds!")
        end

        --reset timer
        startFlightTime = GetTime()
      end
    end
  --user is not flying, clear flying time
  elseif startFlightTime then
    startFlightTime = nil
    previousAngle = nil
    previousSpeed = nil
  end
end)
