-- Review V17 | Treinamento livre (sem checkpoints)
-- Explora plataformas e registra as melhores partes para exportar em JSON.
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
if not player then return end
if _G.ReviewV17 and _G.ReviewV17.destroy then pcall(_G.ReviewV17.destroy) end

local bot={running=false,dead=false,attempts=0,successes=0,history={},best={},visited={},message="Pronto"}
_G.ReviewV17=bot
local function char()
 local c=player.Character
 return c,c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart")
end
local function v3(v) return {x=math.floor(v.X*100+.5)/100,y=math.floor(v.Y*100+.5)/100,z=math.floor(v.Z*100+.5)/100} end
local function flat(a,b) return (Vector3.new(a.X,0,a.Z)-Vector3.new(b.X,0,b.Z)).Magnitude end
local function surface(at)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={player.Character}
 params.IgnoreWater=true
 local hit=Workspace:Raycast(at+Vector3.new(0,17,0),Vector3.new(0,-60,0),params)
 if hit and hit.Instance.CanCollide and hit.Normal.Y>.75 then return hit.Position end
end
local function candidates(root)
 local list={}
 for radius=8,40,8 do
  for i=0,19 do
   local a=i*math.pi/10
   local p=root.Position+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius)
   local ground=surface(p)
   if ground then
    local dy=ground.Y-(root.Position.Y-3)
    local dist=flat(ground,root.Position)
    if dy>=-13 and dy<=8 and dist>=5 then
     local key=math.floor(ground.X/6)..":"..math.floor(ground.Y/6)..":"..math.floor(ground.Z/6)
     local visits=bot.visited[key] or 0
     local novelty=1/(1+visits)
     local score=novelty*50+dy*2+math.min(dist,22)*.45-math.max(0,dist-22)*2+math.random()*12
     table.insert(list,{point=ground+Vector3.new(0,3,0),key=key,score=score,jump=(dy>1.5 or dist>11),dy=dy})
    end
   end
  end
 end
 table.sort(list,function(a,b)return a.score>b.score end)
 return list
end
local function exportData()
 return HttpService:JSONEncode({
  version="ReviewV17-FreeTraining",placeId=game.PlaceId,created=os.time(),
  mode="training_without_checkpoints",attempts=bot.attempts,successes=bot.successes,
  best=bot.best,history=bot.history
 })
end
bot.export=exportData
local function makeGui()
 local g=Instance.new("ScreenGui")
 g.Name="ReviewV17Training"
 g.ResetOnSpawn=false
 pcall(function()g.Parent=game:GetService("CoreGui")end)
 if not g.Parent then g.Parent=player:WaitForChild("PlayerGui") end
 local f=Instance.new("Frame",g)
 f.Size=UDim2.fromOffset(288,240)
 f.Position=UDim2.new(0,16,.34,0)
 f.BackgroundColor3=Color3.fromRGB(24,27,38)
 f.BorderSizePixel=0
 Instance.new("UICorner",f).CornerRadius=UDim.new(0,10)
 local title=Instance.new("TextLabel",f)
 title.Position=UDim2.fromOffset(10,6)
 title.Size=UDim2.fromOffset(244,28)
 title.BackgroundTransparency=1
 title.Text="REVIEW V17 | TREINAMENTO LIVRE"
 title.TextColor3=Color3.fromRGB(120,225,255)
 title.Font=Enum.Font.GothamBold
 title.TextSize=13
 title.TextXAlignment=Enum.TextXAlignment.Left
 local status=Instance.new("TextLabel",f)
 status.Position=UDim2.fromOffset(10,38)
 status.Size=UDim2.fromOffset(267,59)
 status.BackgroundTransparency=1
 status.TextColor3=Color3.new(1,1,1)
 status.Font=Enum.Font.Code
 status.TextSize=12
 status.TextWrapped=true
 status.TextYAlignment=Enum.TextYAlignment.Top
 status.TextXAlignment=Enum.TextXAlignment.Left
 local function button(text,x,y,w)
  local b=Instance.new("TextButton",f)
  b.Position=UDim2.fromOffset(x,y)
  b.Size=UDim2.fromOffset(w,35)
  b.BackgroundColor3=Color3.fromRGB(44,86,118)
  b.TextColor3=Color3.new(1,1,1)
  b.Font=Enum.Font.GothamBold
  b.TextSize=12
  b.Text=text
  Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
  return b
 end
 local start=button("INICIAR",10,103,130)
 local stop=button("PARAR",148,103,130)
 local save=button("SALVAR MELHOR",10,144,130)
 local copy=button("COPIAR JSON",148,144,130)
 local clear=button("LIMPAR",10,185,130)
 local close=button("FECHAR",148,185,130)
 local dragging=false
 local origin,startPos
 title.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
   dragging=true;origin=input.Position;startPos=f.Position
  end
 end)
 title.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
 end)
 local dragConn=UIS.InputChanged:Connect(function(input)
  if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
   local d=input.Position-origin
   f.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
  end
 end)
 local statusConn=RunService.Heartbeat:Connect(function()
  status.Text=(bot.running and "TREINANDO" or "PARADO").." | Tentativas: "..bot.attempts.." | Acertos: "..bot.successes.."\nMelhores salvas: "..#bot.best.."\n"..bot.message
 end)
 start.MouseButton1Click:Connect(function()
  if bot.running then return end
  bot.running=true
  bot.message="Explorando sem destino fixo..."
  task.spawn(function()
   while bot.running and not bot.dead do
    local _,hum,root=char()
    if not hum or not root or hum.Health<=0 then
     bot.message="Aguardando personagem..."
     task.wait(1)
     continue
    end
    local options=candidates(root)
    if #options==0 then
     bot.message="Procurando superficie..."
     hum.Jump=true
     task.wait(.6)
     continue
    end
    local chosen=options[math.random(1,math.min(#options,3))]
    bot.visited[chosen.key]=(bot.visited[chosen.key] or 0)+1
    bot.attempts=bot.attempts+1
    local from=root.Position
    local began=os.clock()
    hum:MoveTo(chosen.point)
    if chosen.jump then hum.Jump=true end
    local reached=false
    while bot.running and not bot.dead and os.clock()-began<3 do
     local _,h,r=char()
     if not h or not r or h.Health<=0 then break end
     if flat(r.Position,chosen.point)<5 and math.abs(r.Position.Y-chosen.point.Y)<7 then
      reached=true;break
     end
     task.wait(.13)
    end
    local _,h,r=char()
    local finish=r and r.Position or from
    local landed=h and h.Health>0 and h.FloorMaterial~=Enum.Material.Air
    local success=reached and landed
    local delta=flat(from,finish)
    local gain=finish.Y-from.Y
    local score=math.floor(delta+math.max(0,gain)*4+(success and 35 or 0))
    local item={from=v3(from),to=v3(finish),target=v3(chosen.point),
      jump=chosen.jump,success=success,score=score,travel=math.floor(delta*10)/10,
      heightGain=math.floor(gain*10)/10,elapsed=math.floor((os.clock()-began)*100)/100}
    table.insert(bot.history,item)
    if #bot.history>300 then table.remove(bot.history,1) end
    if success then
     bot.successes=bot.successes+1
     bot.message="Acerto! Nota "..score.." | salvar melhor"
    else
     bot.visited[chosen.key]=bot.visited[chosen.key]+2
     bot.message="Tentativa falhou; testando outro salto"
    end
    task.wait(.25)
   end
  end)
 end)
 stop.MouseButton1Click:Connect(function()
  bot.running=false
  local _,h,r=char()
  if h and r then h:MoveTo(r.Position) end
  bot.message="Treino pausado"
 end)
 save.MouseButton1Click:Connect(function()
  -- Salva a melhor tentativa BEM-SUCEDIDA ainda nao salva,
  -- priorizando as 25 tentativas mais recentes.
  local chosen=nil
  local first=math.max(1,#bot.history-24)
  for i=first,#bot.history do
   local item=bot.history[i]
   if item.success and (not chosen or item.score>chosen.score) then
    local already=false
    for _,old in ipairs(bot.best) do if old==item then already=true;break end end
    if not already then chosen=item end
   end
  end
  if chosen then
   table.insert(bot.best,chosen)
   table.sort(bot.best,function(a,b)return a.score>b.score end)
   bot.message="Melhor parte salva! Nota "..chosen.score
  else
   bot.message="Sem acerto novo nas ultimas 25 tentativas"
  end
 end)
 copy.MouseButton1Click:Connect(function()
  local json=exportData()
  if type(setclipboard)=="function" then
   setclipboard(json);bot.message="JSON copiado ("..#bot.best.." melhores)"
  elseif type(writefile)=="function" then
   writefile("ReviewV17_training.json",json);bot.message="JSON salvo em arquivo"
  else
   print("[REVIEW JSON]",json);bot.message="JSON enviado ao console"
  end
 end)
 clear.MouseButton1Click:Connect(function()
  bot.history={};bot.best={};bot.visited={};bot.attempts=0;bot.successes=0
  bot.message="Historico e melhores limpos"
 end)
 function bot.destroy()
  bot.running=false;bot.dead=true
  dragConn:Disconnect();statusConn:Disconnect();g:Destroy()
  if _G.ReviewV17==bot then _G.ReviewV17=nil end
 end
 close.MouseButton1Click:Connect(bot.destroy)
end
makeGui()
