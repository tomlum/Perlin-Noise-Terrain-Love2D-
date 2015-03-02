function love.load()
  math.randomseed(os.time()) 
love.graphics.setNewFont(20)

  love.window.setMode(800, 800, {vsync=true})
  noyes = {n = {}, w = 800, h = 800}
  nonrandomlistcounter = 0
  function nextnonrandomint()
    if nonrandomlistcounter > 255 then nonrandomlistcounter = 0
    else nonrandomlistcounter = nonrandomlistcounter + 1
    end
    return nonrandomlistcounter
  end
  

  sparsity = .2
  clouddefinition = 2
  clouddepth = 7
  colortype = "landscape"
  drawspecific = false
  specific = 1
  faderatio = 1.5
  ps = 1
  spacing = 0
  
  nonrandom = false
  smoothing = true

  textr = 255
  textg = 255
  textb = 255

  function hof(x,y)
    if x > y then return x
    else return y
    end
  end

  function colorscale(vv)
    if colortype == "smoke" then
      love.graphics.setBackgroundColor(0,0,0)
      love.graphics.setColor(255,255,255,vv)
      textr = 100
      textg = 100
      textb = 10
    elseif colortype == "cloud" then
      love.graphics.setBackgroundColor(80,80,255)
      love.graphics.setColor(255,255,255,vv)
      textr = 100
      textg = 10
      textb = 10
    elseif colortype == "antarctica" then
      love.graphics.setBackgroundColor(40,40,140)
      if vv < 100 then
        love.graphics.setColor(255,255,255,vv+(255-vv)/3)
      else
        love.graphics.setColor(255,255,255,vv/2)
      end
      textr = 100
      textg = 100
      textb = 10
    elseif colortype == "magma" then
      love.graphics.setBackgroundColor(0,0,0)
      textr = 100
      textg = 100
      textb = 255
      if vv < 80 then
        love.graphics.setColor(255*(vv/80),0,0)
      elseif vv >= 80 then
        love.graphics.setColor(255,255*((vv-80)/(255-80)),0)
      end
    elseif colortype == "topography" then
      textr = 255
      textg = 10
      textb = 255
      if vv <= 100 then
        local v = vv
        love.graphics.setColor(255*((100-v)/100),255*(v/100),0)
      elseif vv <= 255 then
        local v = vv-100
        love.graphics.setColor(0,255*((155-v)/155),255*(v/155))
      end
    elseif colortype == "landscape" then
      textr = 250
      textg = 0
      textb = 0
      if vv < 90 then
        love.graphics.setColor(255,255,255)
      elseif vv < 100 then
        love.graphics.setColor(100,100,100)
      elseif vv < 130 then
        love.graphics.setColor(0,60,0)
      elseif vv <= 255 then
        love.graphics.setColor(0,0,100)
      end
    end

  end

  function initnoise(noi)
    for i = 0, noi.w do
      noi.n[i] = {}
      for j = 0, noi.h do
        if nonrandom then
          noi.n[i][j] = nextnonrandomint()
        else
          
        if math.random()<sparsity then
          noi.n[i][j] = 0
        else
          noi.n[i][j] = math.random(20,255)
        end
        end
      end
    end
  end

  function makezoomnoise(noi,order)
    newnoi = {n = {}, h = noi.h, w = noi.w}

    for i = 0, newnoi.w do
      newnoi.n[i] = {}
      for j = 0, newnoi.h do
        newnoi.n[i][j] = math.random(1,255)
      end
    end

    for bi = math.floor(noi.w/order), 1, -1 do
      for bj = math.floor(noi.h/order), 1, -1 do
        for j = order, 0, -1 do
          newnoi.n[bi][(bj*order)-j] = noi.n[bi][bj]
          for i = order, 0, -1 do
            newnoi.n[(bi*order)-i][(bj*order)-j] = noi.n[bi][bj]
          end 
        end
      end
    end
    return makesmoothnoise(newnoi)
  end


  function makesmoothnoise(noi)
    if smoothing then
    newnoi = {n = {}, h = noi.h, w = noi.w}
    for i = 0, noi.w do
      newnoi.n[i] = {}
      for j = 0, noi.h do
        local pu = noi.n[i][(j-1)%noi.h]
        local pl = noi.n[(i-1)%noi.h][j]
        local pr = noi.n[(i+1)%noi.h][j]
        local pd = noi.n[i][(j+1)%noi.h]
        local pc = noi.n[i][j]
        newnoi.n[i][j] = (pc+pu+pl+pr+pd)/5
      end
    end
    return newnoi
  else
    return noi
    end
  end


  function drawnoise(noi,order)
    for i = 0, #noi.n do
      noi[i] = {}
      for j = 0, #noi.n[i] do
        love.graphics.setColor(255,255,255, noi.n[i][j]/order)
        colorscale(noi.n[i][j]/order)
        love.graphics.rectangle("fill",(i-1)*(ps+spacing),(j-1)*(ps+spacing),ps,ps)
      end
    end
  end


  function cloudmaker(noise, depth)
    local zooms = {}
    zooms[0] = makesmoothnoise(noise)
    for i = 1, depth do 
      zooms[i] = makezoomnoise(zooms[i-1],2)
    end



    local newnoise = zooms[depth-1]
    for i = depth-1, 1, -1 do
      newnoise = (compressnoise(newnoise, zooms[i], (depth-i)^faderatio))
    end
    if drawspecific then
      return zooms[specific-1]
    else
      return newnoise
    end
  end


  function compressnoise(n1,n2,order)
    local corder = order+clouddefinition
    noise = {n = {}, h = n1.h, w = n1.w}
    for i = 0, n1.w do
      noise.n[i] = {}
      for j = 0, n1.h do
        noise.n[i][j] = 0
        noise.n[i][j] = n1.n[i][j]*(1-(1/corder)) + n2.n[i][j]*(1/corder)
      end
    end

    return makesmoothnoise(noise)
  end



  initnoise(noyes)
  noyescloud = (cloudmaker(noyes, clouddepth))

end


function love.update()


  if love.keyboard.isDown("1") then
    drawspecific = false
    clouddepth = 1
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("2") then
    drawspecific = false
    clouddepth = 2
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("3") then
    drawspecific = false
    clouddepth = 3
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("4") then
    drawspecific = false
    clouddepth = 4
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("5") then
    drawspecific = false
    clouddepth = 5
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("6") then
    drawspecific = false
    clouddepth = 6
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("7") then
    drawspecific = false
    clouddepth = 7
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("8") then
    drawspecific = false
    clouddepth = 8
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("9") then
    drawspecific = false
    clouddepth = 9
    noyescloud = (cloudmaker(noyes, clouddepth))
  elseif love.keyboard.isDown("0") then
    drawspecific = false
    clouddepth = 10
    noyescloud = (cloudmaker(noyes, clouddepth))
  end

  if love.keyboard.isDown("q") then

    specific = 1
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))
  elseif love.keyboard.isDown("w") then

    specific = 2
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))
  elseif love.keyboard.isDown("e") then

    specific = 3
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))
  elseif love.keyboard.isDown("r") then

    specific = 4
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))
  elseif love.keyboard.isDown("t") then
    specific = 5
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))

  elseif love.keyboard.isDown("y") then
    specific = 6
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))

  elseif love.keyboard.isDown("u") then
    specific = 7
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))

  elseif love.keyboard.isDown("i") then
    specific = 8
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))

  elseif love.keyboard.isDown("o") then
    specific = 9
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))
  elseif love.keyboard.isDown("p") then
    specific = 10
    drawspecific = true
    noyescloud = cloudmaker(noyes,hof(specific,clouddepth))
  end


  if love.keyboard.isDown("a") then
    colortype = "smoke"
  elseif love.keyboard.isDown("s") then
    colortype = "cloud"
  elseif love.keyboard.isDown("d") then
    colortype = "magma"
  elseif love.keyboard.isDown("f") then
    colortype = "topography"
  elseif love.keyboard.isDown("g") then
    colortype = "landscape"
  elseif love.keyboard.isDown("h") then
    colortype = "antarctica"
  end

  if love.keyboard.isDown("up") then
    ps = ps+1
  elseif love.keyboard.isDown("down") and ps>=1 then
    ps = ps-1
  elseif love.keyboard.isDown("left") and spacing >=1 then
    spacing = spacing - 1
  elseif love.keyboard.isDown("right") then
    spacing = spacing + 1
  end
  
  if love.keyboard.isDown("z") then
    nonrandom = false
    initnoise(noyes)
    noyescloud = (cloudmaker(noyes, clouddepth))
    elseif love.keyboard.isDown("x") then
    nonrandom = true
    initnoise(noyes)
    noyescloud = (cloudmaker(noyes, clouddepth))
  end
  
  if love.keyboard.isDown("c") then
    smoothing = true
    noyescloud = (cloudmaker(noyes, clouddepth))
    elseif love.keyboard.isDown("v") then
    smoothing = false
    noyescloud = (cloudmaker(noyes, clouddepth))
  end
  
   if love.keyboard.isDown(" ") then
    initnoise(noyes)
    noyescloud = (cloudmaker(noyes, clouddepth))
  end



end

function love.draw()
  drawnoise(noyescloud, 1)
  love.graphics.setColor(255,255,255)
  love.graphics.rectangle("fill", 0,0,800,130)
  love.graphics.setColor(textr,textg,textb)
  
   love.graphics.print("Spacebar || New Noise", 350,100,0)
  
  love.graphics.print("1-0 || Cloud Depth: "..tostring(clouddepth), 10,10,0)
  
  if drawspecific  then 
     love.graphics.print("q-p || Specific Layer: "..tostring(not drawspecific), 10,30,0)
  else
  love.graphics.print("q-p || Specific Layer: "..tostring(clouddepth), 10,30,0)
  end
  love.graphics.print("a-h || Color Type:  "..tostring(colortype), 11,50,0)
  love.graphics.print("z/x || Random Noise?:  "..tostring(not nonrandom), 14,70,0)
  love.graphics.print("c/v || Smoothing?:  "..tostring(smoothing), 14,90,0)
  
  love.graphics.print("up/down || pixel size:  "..tostring(ps), 500,10,0)
  love.graphics.print("left/right || pixel spacing:  "..tostring(spacing), 500,30,0)
end