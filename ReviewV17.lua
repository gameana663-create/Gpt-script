-- Review V17 | Explorador experimental de parkour
-- Uso: execute no seu proprio ambiente de teste Roblox.
-- Explora superficies por raycast, tenta saltos e exporta rota JSON.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
if not player then return end
if _G.ReviewV17 and _G.ReviewV17.destroy then pcall(_G.ReviewV17.destroy) end

local state = {running=false, destroyed=false, route={}, attempts=0, targetIndex=1, visited={}, lastMessage="Pronto"}
_G.ReviewV17 = state
local CHECKPOINTS = {
 Vector3.new(-384.5,238,1011.5), Vector3.new(-178.5,264.5,1191.5),
 Vector3.new(-412.5,296.5,1204.5), Vector3.new(-123.16,300.5,922.56),
 Vector3.new(-334.18,337.5,681.82), Vector3.new(-12.52,368.5,1459.8),
 Vector3.new(-256.93,379.5,1475.99), Vector3.new(47.2,396.5,660.05),
 Vector3.new(-678.74,458.5,553.51)
}
-- Coordenadas acima sao SpawnLocations, nao a ordem confirmada da corrida.
-- O algoritmo escolhe inicialmente o checkpoint mais proximo.
local function character()
 local c=player.Character
 return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end
local function vec(v) return {x=math.floor(v.X*100)/100,y=math.floor(v.Y*100)/100,z=math.floor(v.Z*100)/100} end
local function distance2(a,b)
 return (Vector3.new(a.X,0,a.Z)-Vector3.new(b.X,0,b.Z)).Magnitude
end
local function rayGround(point,ignore)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=ignore or {}
 params.IgnoreWater=true
 local hit=Workspace:Raycast(point+Vector3.new(0,18,0),Vector3.new(0,-65,0),params)
 if hit and hit.Normal.Y > .68 and hit.Instance.CanCollide then
  return hit.Position,hit.Instance
 end
 return nil,nil
end
local function platformCandidates(root,goal)
 local list={}
 local ignore={player.Character}
 for radius=8,44,9 do
  for k=0,15 do
   local angle=k*math.pi/8
   local p=root.Position+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
   local floor,part=rayGround(p,ignore)
   if floor and part then
    local delta=floor.Y-root.Position.Y+3
    local flat=distance2(root.Position,floor)
    if delta<11 and delta>-22 and flat>3 then
     local key=math.floor(floor.X/5)..":"..math.floor(floor.Y/5)..":"..math.floor(floor.Z/5)
     local visits=state.visited[key] or 0
     local improvement=distance2(root.Position,goal)-distance2(floor,goal)
     local score=improvement*2-flat*.15-math.abs(delta)*1.8-visits*35
     if delta>7 then score=score-12 end
     table.insert(list,{point=floor+Vector3.new(0,3,0),score=score,key=key,jump=delta>2 or flat>12})
    end
   end
  end
 end
 table.sort(list,function(a,b)return a.score>b.score end)
 return list
end
local gui=Instance.new("ScreenGui")
gui.Name="ReviewV17GUI"
gui.ResetOnSpawn=false
pcall(function()gui.Parent=game:GetService("CoreGui")end)
if not gui.Parent then gui.Parent=player:WaitForChild("PlayerGui") end
local frame=Instance.new("Frame",gui)
frame.Size=UDim2.fromOffset(270,212)
frame.Position=UDim2.new(0,14,.36,0)
frame.BackgroundColor3=Color3.fromRGB(23,27,38)
frame.BorderSizePixel=0
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
local title=Instance.new("TextLabel",frame)
title.Size=UDim2.new(1,-16,0,30)
title.Position=UDim2.fromOffset(8,5)
title.BackgroundTransparency=1
title.Text="REVIEW V17  |  Parkour Explorer"
title.TextColor3=Color3.fromRGB(120,225,255)
title.Font=Enum.Font.GothamBold
title.TextSize=14
local status=Instance.new("TextLabel",frame)
status.Size=UDim2.new(1,-18,0,52)
status.Position=UDim2.fromOffset(9,37)
status.BackgroundTransparency=1
status.TextWrapped=true
status.TextYAlignment=Enum.TextYAlignment.Top
status.TextColor3=Color3.new(1,1,1)
status.Font=Enum.Font.Code
status.TextSize=12
local function button(label,x,y,w)
 local b=Instance.new("TextButton",frame)
 b.Position=UDim2.fromOffset(x,y)
 b.Size=UDim2.fromOffset(w,34)
 b.Text=label
 b.TextColor3=Color3.new(1,1,1)
 b.BackgroundColor3=Color3.fromRGB(45,80,110)
 b.Font=Enum.Font.GothamBold
 b.TextSize=12
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 return b
end
local start=button("INICIAR",9,98,121)
local stop=button("PARAR",139,98,121)
local export=button("COPIAR JSON",9,140,121)
local clear=button("LIMPAR ROTA",139,140,121)
local close=button("X",237,5,25)
close.Size=UDim2.fromOffset(25,25)
local hint=Instance.new("TextLabel",frame)
hint.Position=UDim2.fromOffset(8,181)
hint.Size=UDim2.new(1,-16,0,22)
hint.BackgroundTransparency=1
hint.Text="Experimental: requer ajuste por mapa"
hint.TextColor3=Color3.fromRGB(180,190,200)
hint.TextSize=11
local function log(msg) state.lastMessage=msg end
local function record(kind,pos,extra)
 table.insert(state.route,{kind=kind,pos=vec(pos),time=os.clock(),checkpoint=state.targetIndex,info=extra})
end
local function exportJSON()
 local payload={version="ReviewV17",placeId=game.PlaceId,generated=os.time(),checkpointOrder="nearest-neighbor experimental",route=state.route}
 return HttpService:JSONEncode(payload)
end
state.export=exportJSON
local function nearestCheckpoint(pos)
 local best,bestD=nil,math.huge
 for i,cp in ipairs(CHECKPOINTS) do
  local d=(pos-cp).Magnitude
  if d<bestD then best,bestD=i,d end
 end
 return best,bestD
end
local function pickTarget(pos)
 local best,bestD=nil,math.huge
 for i,cp in ipairs(CHECKPOINTS) do
  if not state.completed or not state.completed[i] then
   local d=(pos-cp).Magnitude
   if d<bestD then best,bestD=i,d end
  end
 end
 return best
end
local function moveToward(hum,root,point,jump,timeout)
 local began=os.clock()
 local startPos=root.Position
 hum:MoveTo(point)
 if jump then hum.Jump=true end
 while state.running and not state.destroyed and os.clock()-began<timeout do
  local _,h,r=character()
  if not h or not r or h.Health<=0 then return false,"respawn" end
  if (r.Position-point).Magnitude<6 then return true,"reached" end
  if jump and os.clock()-began>.45 and h.FloorMaterial~=Enum.Material.Air then h.Jump=true end
  task.wait(.13)
 end
 if not state.running then return false,"stopped" end
 if (root.Position-startPos).Magnitude<2.5 then return false,"stuck" end
 return false,"timeout"
end
local function worker()
 state.completed={}
 local _,_,root=character()
 if root then
  local nearest,dist=nearestCheckpoint(root.Position)
  if nearest and dist<24 then
   state.completed[nearest]=true
   record("start_checkpoint",CHECKPOINTS[nearest],nearest)
  end
 end
 while state.running and not state.destroyed do
  local _,hum,r=character()
  if not hum or not r or hum.Health<=0 then
   log("Aguardando respawn...")
   task.wait(1)
   continue
  end
  local idx=pickTarget(r.Position)
  if not idx then log("Todos os 9 pontos visitados!");state.running=false;break end
  state.targetIndex=idx
  local goal=CHECKPOINTS[idx]
  if (r.Position-goal).Magnitude<14 then
   state.completed[idx]=true
   record("checkpoint",r.Position,idx)
   log("Checkpoint "..idx.." registrado")
   task.wait(.5)
   continue
  end
  local candidates=platformCandidates(r,goal)
  local best=candidates[1]
  if not best then
   log("Sem plataforma detectada; explorando...")
   hum.Jump=true
   task.wait(.8)
   continue
  end
  state.visited[best.key]=(state.visited[best.key] or 0)+1
  state.attempts=state.attempts+1
  log("Alvo "..idx.." | tentativa "..state.attempts.." | score "..math.floor(best.score))
  local before=r.Position
  record("attempt",before,{destination=vec(best.point),jump=best.jump})
  local success,reason=moveToward(hum,r,best.point,best.jump,3.5)
  local _,_,nowRoot=character()
  if nowRoot then
   record(success and "success" or "failed",nowRoot.Position,reason)
   if not success then
    state.visited[best.key]=state.visited[best.key]+2
   end
  end
  task.wait(.2)
 end
end
start.MouseButton1Click:Connect(function()
 if state.running then return end
 state.running=true
 log("Exploracao iniciada")
 task.spawn(worker)
end)
stop.MouseButton1Click:Connect(function()
 state.running=false
 local _,hum,root=character()
 if hum and root then hum:MoveTo(root.Position) end
 log("Parado")
end)
export.MouseButton1Click:Connect(function()
 local json=exportJSON()
 if type(setclipboard)=="function" then
  setclipboard(json)
  log("JSON copiado! "..#state.route.." eventos")
 elseif type(writefile)=="function" then
  writefile("ReviewV17_route.json",json)
  log("JSON salvo em ReviewV17_route.json")
 else
  print("[ReviewV17 JSON]",json)
  log("JSON enviado ao console")
 end
end)
clear.MouseButton1Click:Connect(function()
 state.route={}
 state.visited={}
 state.attempts=0
 log("Rota limpa")
end)
local drag,dragStart,frameStart=false,nil,nil
title.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  drag=true;dragStart=input.Position;frameStart=frame.Position
 end
end)
title.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=false end
end)
local UIS=game:GetService("UserInputService")
local dragConn=UIS.InputChanged:Connect(function(input)
 if drag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
  local delta=input.Position-dragStart
  frame.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+delta.X,frameStart.Y.Scale,frameStart.Y.Offset+delta.Y)
 end
end)
local statusConn=RunService.Heartbeat:Connect(function()
 status.Text=(state.running and "RODANDO" or "PARADO").." | "..#state.route.." eventos\n"..state.lastMessage
end)
function state.destroy()
 state.running=false
 state.destroyed=true
 dragConn:Disconnect()
 statusConn:Disconnect()
 gui:Destroy()
 if _G.ReviewV17==state then _G.ReviewV17=nil end
end
close.MouseButton1Click:Connect(state.destroy)
log("Pronto! Iniciar para explorar.")
