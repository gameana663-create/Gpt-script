-- Review V18 - treino dirigido ao final com memoria de tentativas
-- O objetivo inicial e provisório. Use MARCAR FINAL estando na chegada.
-- Execute apenas em ambientes em que voce tem autorizacao.
local P=game:GetService("Players")
local W=game:GetService("Workspace")
local H=game:GetService("HttpService")
local U=game:GetService("UserInputService")
local R=game:GetService("RunService")
local player=P.LocalPlayer
if not player then return end
if _G.ReviewV18 and _G.ReviewV18.destroy then pcall(_G.ReviewV18.destroy) end
local bot={running=false,closed=false,goal=Vector3.new(-678.74,458.5,553.51),
 goalConfirmed=false,attempts=0,success=0,history={},best={},learned={},bad={},message="Marque o final para maior precisao"}
_G.ReviewV18=bot
local function chr()
 local c=player.Character
 return c,c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart")
end
local function vec(p) return {x=math.floor(p.X*100+.5)/100,y=math.floor(p.Y*100+.5)/100,z=math.floor(p.Z*100+.5)/100} end
local function flat(a,b) return (Vector3.new(a.X,0,a.Z)-Vector3.new(b.X,0,b.Z)).Magnitude end
local function goalDist(p)
 return flat(p,bot.goal)+math.abs(p.Y-bot.goal.Y)*1.3
end
local function ground(p)
 local par=RaycastParams.new()
 par.FilterType=Enum.RaycastFilterType.Exclude
 par.FilterDescendantsInstances={player.Character}
 par.IgnoreWater=true
 local hit=W:Raycast(p+Vector3.new(0,20,0),Vector3.new(0,-65,0),par)
 if hit and hit.Instance.CanCollide and hit.Normal.Y>.7 then return hit.Position,hit.Instance end
end
local function cell(p)
 return math.floor(p.X/12)..":"..math.floor(p.Y/9)..":"..math.floor(p.Z/12)
end
local function candidates(root)
 local options={}
 local from=root.Position
 local base=goalDist(from)
 for radius=7,36,7 do
  for i=0,23 do
   local angle=math.pi*i/12
   local sample=from+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
   local floor=ground(sample)
   if floor then
    local dy=floor.Y-(from.Y-3)
    local dist=flat(from,floor)
    if dy>=-14 and dy<=9 and dist>3 then
     local p=floor+Vector3.new(0,3,0)
     local key=cell(p)
     local progress=base-goalDist(p)
     local penalty=(bot.bad[key] or 0)*18
     local bonus=(bot.learned[key] or 0)*12
     local score=progress*3+bonus-penalty+math.random()*13-math.max(0,dist-20)*1.8
     table.insert(options,{pos=p,key=key,score=score,progress=progress,dy=dy,dist=dist})
    end
   end
  end
 end
 table.sort(options,function(a,b)return a.score>b.score end)
 return options
end
local function saveJSON()
 return H:JSONEncode({version="ReviewV18",mode="goal_learning",placeId=game.PlaceId,
  goal=vec(bot.goal),goalConfirmed=bot.goalConfirmed,attempts=bot.attempts,
  success=bot.success,best=bot.best,history=bot.history,learned=bot.learned})
end
bot.export=saveJSON
local gui=Instance.new("ScreenGui")
gui.Name="ReviewV18"
gui.ResetOnSpawn=false
pcall(function() gui.Parent=game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent=player:WaitForChild("PlayerGui") end
local frame=Instance.new("Frame",gui)
frame.Size=UDim2.fromOffset(294,270)
frame.Position=UDim2.new(0,14,.32,0)
frame.BackgroundColor3=Color3.fromRGB(23,28,39)
frame.BorderSizePixel=0
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
local title=Instance.new("TextLabel",frame)
title.Position=UDim2.fromOffset(9,5)
title.Size=UDim2.fromOffset(276,29)
title.BackgroundTransparency=1
title.Text="REVIEW V18 | APRENDER A CHEGAR"
title.TextColor3=Color3.fromRGB(130,225,255)
title.TextSize=14
title.Font=Enum.Font.GothamBold
local status=Instance.new("TextLabel",frame)
status.Position=UDim2.fromOffset(10,38)
status.Size=UDim2.fromOffset(274,77)
status.BackgroundTransparency=1
status.TextWrapped=true
status.TextYAlignment=Enum.TextYAlignment.Top
status.TextXAlignment=Enum.TextXAlignment.Left
status.TextColor3=Color3.new(1,1,1)
status.TextSize=12
status.Font=Enum.Font.Code
local function button(label,x,y,w)
 local b=Instance.new("TextButton",frame)
 b.Position=UDim2.fromOffset(x,y)
 b.Size=UDim2.fromOffset(w,34)
 b.BackgroundColor3=Color3.fromRGB(42,88,119)
 b.TextColor3=Color3.new(1,1,1)
 b.TextSize=12
 b.Font=Enum.Font.GothamBold
 b.Text=label
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 return b
end
local start=button("INICIAR",10,120,132)
local stop=button("PARAR",151,120,132)
local goalButton=button("MARCAR FINAL",10,160,132)
local bestButton=button("SALVAR MELHOR",151,160,132)
local copy=button("COPIAR JSON",10,200,132)
local close=button("FECHAR",151,200,132)
local tip=Instance.new("TextLabel",frame)
tip.Position=UDim2.fromOffset(10,240)
tip.Size=UDim2.fromOffset(274,22)
tip.BackgroundTransparency=1
tip.Text="Treino experimental | destino editavel"
tip.TextSize=11
tip.TextColor3=Color3.fromRGB(190,190,195)
local dragging=false
local dragFrom,frameFrom
title.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  dragging=true;dragFrom=input.Position;frameFrom=frame.Position
 end
end)
title.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
local dragConnection=U.InputChanged:Connect(function(input)
 if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
  local d=input.Position-dragFrom
  frame.Position=UDim2.new(frameFrom.X.Scale,frameFrom.X.Offset+d.X,frameFrom.Y.Scale,frameFrom.Y.Offset+d.Y)
 end
end)
local statusConnection=R.Heartbeat:Connect(function()
 local _,_,root=chr()
 local dist=root and math.floor(goalDist(root.Position)) or -1
 status.Text=(bot.running and "TREINANDO" or "PARADO").." | Final: "..(bot.goalConfirmed and "marcado" or "provisorio")..
  "\nDistancia: "..dist.." | Tentativas: "..bot.attempts.." | Acertos: "..bot.success..
  "\nMelhores: "..#bot.best.." | "..bot.message
end)
goalButton.MouseButton1Click:Connect(function()
 local _,_,root=chr()
 if root then
  bot.goal=root.Position
  bot.goalConfirmed=true
  bot.message="Final marcado! Volte ao inicio e aperte INICIAR"
 end
end)
local function attempt(hum,root,target,mode)
 local from=root.Position
 local startTime=os.clock()
 local timeout=mode=="longjump" and 3.6 or 3.1
 local jumped=false
 hum:MoveTo(target.pos)
 if mode=="jump" or mode=="longjump" then hum.Jump=true;jumped=true end
 while bot.running and not bot.closed and os.clock()-startTime<timeout do
  local _,h,r=chr()
  if not h or not r or h.Health<=0 then break end
  if flat(r.Position,target.pos)<4.8 and math.abs(r.Position.Y-target.pos.Y)<6 then break end
  if mode=="longjump" and os.clock()-startTime>.35 and h.FloorMaterial~=Enum.Material.Air then
   h.Jump=true
  end
  task.wait(.12)
 end
 local _,h,r=chr()
 local finish=r and r.Position or from
 local alive=h and h.Health>0
 local grounded=alive and h.FloorMaterial~=Enum.Material.Air
 local moved=flat(from,finish)
 local progress=goalDist(from)-goalDist(finish)
 local reached=flat(finish,target.pos)<6 and math.abs(finish.Y-target.pos.Y)<7
 local good=grounded and reached and progress>1.5
 local result={from=vec(from),to=vec(finish),target=vec(target.pos),mode=mode,
  progress=math.floor(progress*10)/10,travel=math.floor(moved*10)/10,
  success=good,elapsed=math.floor((os.clock()-startTime)*100)/100}
 return result,good,progress
end
local function train()
 local modes={"walk","jump","longjump"}
 local lastPos=nil
 local stuckCount=0
 while bot.running and not bot.closed do
  local _,hum,root=chr()
  if not hum or not root or hum.Health<=0 then
   bot.message="Aguardando respawn..."
   task.wait(.7)
   continue
  end
  if goalDist(root.Position)<11 then
   bot.message="Destino alcancado! Treino pausado."
   bot.running=false
   break
  end
  if lastPos and flat(root.Position,lastPos)<2 then stuckCount=stuckCount+1 else stuckCount=0 end
  lastPos=root.Position
  local opts=candidates(root)
  if #opts==0 then
   bot.message="Sem superficie; tentando pulo"
   hum.Jump=true
   task.wait(.7)
   continue
  end
  -- Evita insistir sempre na mesma direcao quando nao progride.
  local choiceIndex=stuckCount>2 and math.random(2,math.min(#opts,8)) or math.random(1,math.min(#opts,3))
  local choice=opts[choiceIndex]
  local mode
  if choice.dy>2 or choice.dist>12 then
   mode=(bot.bad[choice.key] or 0)>1 and "longjump" or "jump"
  else
   mode=modes[math.random(1,#modes)]
  end
  bot.attempts=bot.attempts+1
  bot.message="Testando "..mode.." ("..bot.attempts..")"
  local result,good,progress=attempt(hum,root,choice,mode)
  table.insert(bot.history,result)
  if #bot.history>400 then table.remove(bot.history,1) end
  if good then
   bot.success=bot.success+1
   bot.learned[choice.key]=(bot.learned[choice.key] or 0)+1
   bot.bad[choice.key]=math.max(0,(bot.bad[choice.key] or 0)-1)
   bot.message="Progresso +"..result.progress.." | "..mode
  else
   bot.bad[choice.key]=(bot.bad[choice.key] or 0)+1
   bot.message="Falhou; mudando estrategia"
  end
  task.wait(.2)
 end
end
start.MouseButton1Click:Connect(function()
 if bot.running then return end
 bot.running=true
 bot.message="Treinando ate o destino..."
 task.spawn(train)
end)
stop.MouseButton1Click:Connect(function()
 bot.running=false
 local _,hum,root=chr()
 if hum and root then hum:MoveTo(root.Position) end
 bot.message="Treino pausado"
end)
bestButton.MouseButton1Click:Connect(function()
 local candidate=nil
 for i=math.max(1,#bot.history-39),#bot.history do
  local item=bot.history[i]
  if item.success and item.progress>0 then
   local exists=false
   for _,saved in ipairs(bot.best) do if saved==item then exists=true;break end end
   if not exists and (not candidate or item.progress>candidate.progress) then candidate=item end
  end
 end
 if candidate then
  table.insert(bot.best,candidate)
  table.sort(bot.best,function(a,b)return a.progress>b.progress end)
  bot.message="Melhor trecho salvo: +"..candidate.progress
 else
  bot.message="Sem trecho novo valido nas ultimas 40 tentativas"
 end
end)
copy.MouseButton1Click:Connect(function()
 local json=saveJSON()
 if type(setclipboard)=="function" then
  setclipboard(json);bot.message="JSON copiado!"
 elseif type(writefile)=="function" then
  writefile("ReviewV18_route.json",json);bot.message="JSON salvo em arquivo"
 else
  print("[Review V18]",json);bot.message="JSON no console"
 end
end)
function bot.destroy()
 bot.running=false;bot.closed=true
 dragConnection:Disconnect()
 statusConnection:Disconnect()
 gui:Destroy()
 if _G.ReviewV18==bot then _G.ReviewV18=nil end
end
close.MouseButton1Click:Connect(bot.destroy)
