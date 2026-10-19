-- VECTRIC LUA SCRIPT
-- Copyright 2025-2026 Bill Florac
-- SPDX-License-Identifier: MIT
-- Licensed under the MIT License; see LICENSE.txt in this folder.
--
-- Script to create various versions of a toolpath to flatten the top of a slab

--require("mobdebug").start()

-- 1.0.0 - added Depth field to calculate count

-- 1.0.4 - implemented True Spiral, added clear toolpath button

-- 1.0.5 - added default buttons for stanard tooling

-- 1.0.6 - added route path images

-- globals
g_version = "1.0.6"

--[[-----------------------------------------------------------------------------------------------
-- Create a tool path
-- Uses a fixed distance of .25: above table to rapid to (SafeZGap and StartZGap)
-- Plunge rate it fixed at 1/2 feed rate
-- Stepover is set here but not used
--]]  
function CreateToolpath(name, vectors, start_depth, tool_number)

   -- note, this works to set height on vector but using StartHeight allows user to see (and adjust) it.
   -- vectors:SetZHeight(-0.05)
   
   -- Create tool we will use to machine vectors
   local tool = Tool(
                    tostring(bit_dia)..'" End Mill', 
                    Tool.END_MILL       -- BALL_NOSE, END_MILL, VBIT
                    )
                     
   tool.InMM = false
   tool.ToolDia = bit_dia  --global var
   
   -- we dont seem to have access to cut depth so we use stepdown as our depth
   tool.Stepdown = start_depth
   tool.Stepover = 1.0
   tool.RateUnits = Tool.INCHES_MIN  -- MM_SEC, MM_MIN, METRES_MIN, INCHES_SEC, INCHES_MIN, FEET_MIN
   tool.FeedRate = feed_rate
   tool.PlungeRate = feed_rate / 2
   tool.SpindleSpeed = spindle_rpm
   tool.ToolNumber = tool_number
   tool.VBitAngle = 90.0     -- used for vbit only
   tool.ClearStepover = 1.0  -- used for vbit only

   -- we will set home position and safe z relative to material block size  
   local mtl_block = MaterialBlock()  
   local mtl_box = mtl_block.MaterialBox
   local mtl_box_blc = mtl_box.BLC
  
   -- Create object used to set home position and safez gap above material surface
   local pos_data = ToolpathPosData()
   -- here, the z is the place it moves at start and end
   pos_data:SetHomePosition(mtl_box_blc.x, mtl_box_blc.y, home_height) --mtl_box.TRC.z + (mtl_block.Thickness * 0.2) )
   -- this is heigh to between moves
   pos_data.SafeZGap = .5 
   -- this eats up SafeZGap so it must always be less than SafeZGap, this allows us to start plunge speed before 0 height
   pos_data.StartZGap = .25
   
   -- rapid move to lower left corner at home_height
   -- rapid move z to .5
   -- rapid move z to .25
   -- plunge from .25 into wood
   
   -- home_height must be => SaveZGap
   -- SafeZGap - StartZGap must be >= 0
   
  
   -- object used to pass data on toolpath settings
   local toolpath_options = ExternalToolpathOptions()
   toolpath_options.StartDepth = start_depth
   toolpath_options.CreatePreview = true
   
   -- Create our toolpath
   -- we put the cut depth into the name to help sort the cuts out
   local toolpath = ExternalToolpath(
                                    name .. " (" .. start_depth .. ")",
                                    tool,
                                    pos_data,
                                    toolpath_options,
                                    vectors
                                  )
                                  
 
   if toolpath:Error() then
      DisplayMessageBox("Error creating toolpath")
      return
   end

   local toolpath_manager = ToolpathManager()
   local success = toolpath_manager:AddExternalToolpath(toolpath)
   return success  
end

--[[-----------------------------------------------------------------------------------------------
-- Build a raster toolpath going in the Y axis
--]]  
function BuildZigZagTB()
  -- calculate passes
  
  local gap = .25             -- start a little outside (just in case)
  local peri
  -- get three pass wrapper
  if perimeter_cut then
    peri = CutPerimeter()
    gap = -.125
  end;

  -- radius of our step over
  local rad = stepover / 2    -- 1/2 circle at U-turns

  -- storage
  local vectors = Contour(0.0)

  -- some local vars
  local x_pos = -(bit_dia+gap)
  local y_pos =  -(bit_dia+gap)
  local y_step = slab_height + (2 * gap)
  local x_max = slab_width + (bit_dia/2)
  local dir_up = true;

  -- move outside, the first point is where bit will lower
  vectors:AppendPoint(Point2D(x_pos,y_pos))
  
  -- now move into place, so edges is at at bottom of arc (in two steps)
  local y_pos =  -rad-gap
  vectors:LineTo(x_pos, y_pos)
  local x_pos = -(bit_dia/2)-gap
  vectors:LineTo(x_pos, y_pos)
  
  -- draw arc and first line
  vectors:ArcTo(Point2D(x_pos + rad, y_pos + rad), Point2D(x_pos, y_pos + rad), true) 
  x_pos = x_pos + rad
  y_pos = y_pos + rad + y_step
  vectors:LineTo(x_pos, y_pos)
  
  
  -- each loop draws arc and then line
  while true do
    x_pos = x_pos + stepover
    if x_pos > x_max then
      break
    end
    if dir_up then
      vectors:ArcTo(Point2D(x_pos, y_pos), Point2D(x_pos - rad, y_pos), false) 
      y_pos = y_pos - y_step
      vectors:LineTo(x_pos, y_pos)
      dir_up = false
    else
      vectors:ArcTo(Point2D(x_pos, y_pos), Point2D(x_pos - rad, y_pos), true) 
      y_pos = y_pos + y_step
      vectors:LineTo(x_pos, y_pos)
      dir_up = true
    end;
  end
 

  local rect_group = ContourGroup(true)
  if perimeter_cut then
    rect_group:AddTail(peri)
  end
  rect_group:AddTail(vectors)
  return rect_group
end

--[[-----------------------------------------------------------------------------------------------
-- Build a raster toolpath going in the X axis
--]]  
function BuildZigZagLR()
  -- calculate passes
  
  local gap = .25             -- start a little outside (just in case)
  local peri
  -- get three pass wrapper
  if perimeter_cut then
    peri = CutPerimeter()
    gap = -.125
  end;

  -- radius of our step over
  local rad = stepover / 2    -- 1/2 circle at U-turns

  -- storage
  local vectors = Contour(0.0)

  -- some local vars
  local x_pos = -(bit_dia+gap)
  local y_pos =  -(bit_dia+gap)
  local x_step = slab_width + (2 * gap)
  local y_max = slab_height + (bit_dia/2)
  local dir_left = true;

  -- move outside, the first point is where bit will lower
  vectors:AppendPoint(Point2D(x_pos,y_pos))
  
  -- now move into place, so edges is at at bottom of arc (in two steps)
  local x_pos =  -rad-gap
  vectors:LineTo(x_pos, y_pos)
  local y_pos = -(bit_dia/2)-gap
  vectors:LineTo(x_pos, y_pos)
  
  -- draw arc and first line
  vectors:ArcTo(Point2D(x_pos + rad, y_pos + rad), Point2D(x_pos + rad, y_pos), false) 
  x_pos = x_pos + rad + x_step
  y_pos = y_pos + rad
  vectors:LineTo(x_pos, y_pos)
  
  
  -- each loop draws arc and then line
  while true do
    y_pos = y_pos + stepover
    if y_pos > y_max then
      break
    end
    if dir_left then
      vectors:ArcTo(Point2D(x_pos, y_pos), Point2D(x_pos, y_pos-rad), true) 
      x_pos = x_pos - x_step
      vectors:LineTo(x_pos, y_pos)
      dir_left = false
    else
      vectors:ArcTo(Point2D(x_pos, y_pos), Point2D(x_pos, y_pos-rad), false) 
      x_pos = x_pos + x_step
      vectors:LineTo(x_pos, y_pos)
      dir_left = true
    end;
  end

  local rect_group = ContourGroup(true)
  if perimeter_cut then
    rect_group:AddTail(peri)
  end
  rect_group:AddTail(vectors)
  return rect_group
end


--[[
function BuildZigZagLR()
  -- calculate passes
  local pass_count = math.ceil(slab_height / stepover / 2)
  pass_count = pass_count  + 1

  local rad = stepover / 2    -- 1/2 circle at U-turns
  local gap = .25             -- start a little outside (just in case)
  local offset = -(bit_dia/2) -- this is distance we back off to clear wood (well, to center of bit)
  
  local vectors = Contour(0.0)
  
  vectors:AppendPoint(Point2D(-(bit_dia+gap),-(bit_dia+gap)))
  vectors:LineTo(Point2D     (-gap-rad, -(bit_dia+gap)))
  
  for x = 1, pass_count do
    if x == 1 then
      -- get to radius and turn up hill
      vectors:LineTo(Point2D(-gap-rad, offset - rad))               -- bottom left to right
      vectors:ArcTo(Point2D( -gap,offset), Point2D(-gap,offset - rad), false)     
    else
      -- make a U trun from left to right
      offset = offset + stepover
      vectors:ArcTo(Point2D(-gap, offset), Point2D(-gap, offset - rad), false)     
    end
    
    -- make a U trun from righ to left
    vectors:LineTo(Point2D( slab_width + gap, offset))       -- right bottom to top
    vectors:ArcTo(Point2D (slab_width + gap, offset + rad + rad), Point2D(slab_width + gap, offset + rad), true)
    
    offset = offset + stepover
    vectors:LineTo(Point2D(- gap, offset)) -- right bottom to top
  end
  
  -- move to selection origin
  --xform = TranslationMatrix2D(Vector2D(slab_x, slab_y))
  --vectors:Transform(xform)
  
  -- all done, add it to our group and exit
  local rect_group = ContourGroup(true)
  rect_group:AddTail(vectors)
  return rect_group
end
]]

--[[-----------------------------------------------------------------------------------------------
-- Build path of three passes, one 1/8" out, one on and 1/8" inside perimeter. Clockwise
-- Return Contour
--]]  
function CutPerimeter()

  gap = (bit_dia / 2) +.125
    
  local rect = Contour(0.0)
  
  rect:AppendPoint(Point2D(-bit_dia,-bit_dia))
  
  rect:LineTo(Point2D(-gap, -gap))
  rect:LineTo(Point2D(-gap, slab_height + gap))
  rect:LineTo(Point2D(slab_width + gap, slab_height + gap))
  rect:LineTo(Point2D(slab_width + gap, -gap))
  rect:LineTo(Point2D(-gap, -gap))
  
  
  gap = gap - .125
  rect:LineTo(Point2D(-gap, -gap))
  rect:LineTo(Point2D(-gap, slab_height + gap))
  rect:LineTo(Point2D(slab_width + gap, slab_height + gap))
  rect:LineTo(Point2D(slab_width + gap, -gap))
  rect:LineTo(Point2D(-gap, -gap))
  
  
  gap = gap - .125
  rect:LineTo(Point2D(-gap, -gap))
  rect:LineTo(Point2D(-gap, slab_height + gap))
  rect:LineTo(Point2D(slab_width + gap, slab_height + gap))
  rect:LineTo(Point2D(slab_width + gap, -gap))
  rect:LineTo(Point2D(-gap, -gap))
  
  -- all done, add it to our group and exit
  --local rect_group = ContourGroup(true)
  --rect_group:AddTail(rect)
  --return rect_group
  return rect
end


--[[-----------------------------------------------------------------------------------------------
-- Build a looping toolpath that only cuts with a climb
-- This always cuts in the Y direction moving inward on the material from left to right
--]]  
function BuildRectangles()
  local rect_count = math.ceil(slab_width / stepover)
  rect_count = rect_count + 1

  local offset = -stepover
  local rad = stepover / 2 
  --local rad = bit_dia / 2
  --if rad > 0.5 then
  --  rad = 0.5
  --end
  local gap = (bit_dia / 2) + .25
  if (2 * rad) > gap then
    gap = 2 * rad
  end
    
  local rect = Contour(0.0)
  
  rect:AppendPoint(Point2D(-bit_dia,-bit_dia))
  rect:LineTo(Point2D(-gap,-gap))
  
  
  --rect_count = 2
  for x = 1, rect_count do
    offset = offset + stepover
    

    rect:LineTo(Point2D(offset - rad,-gap))               -- bottom left to right
    rect:ArcTo(Point2D(offset, -gap + rad), Point2D(offset-rad, -rad+gap), true)     
    
    rect:LineTo(Point2D(offset, slab_height + gap - rad)) -- right bottom to top
    rect:ArcTo(Point2D(offset - rad, slab_height + gap), Point2D(offset - rad, slab_height + gap - rad), true)     
    
    rect:LineTo(Point2D(-gap + rad, slab_height + gap))   -- top right to left
    rect:ArcTo(Point2D(-gap, slab_height + gap - rad), Point2D(-gap + rad, slab_height + gap - rad), true)     
    
    if x ~= rect_count then
      rect:LineTo(Point2D(-gap      , -gap + rad))        -- left top to bottom
      rect:ArcTo(Point2D (-gap + rad, -gap      ), Point2D(-gap + rad, -gap + rad), true)     
    else
      rect:LineTo(Point2D(-gap,-gap))                     -- left top to bottom
    end
  end

  -- all done, add it to our group and exit
  local rect_group = ContourGroup(true)
  rect_group:AddTail(rect)
  return rect_group
end

--[[-----------------------------------------------------------------------------------------------
-- Build a true spiral. We assume the object is round and centered inside the bounding box (smallest of X, Y)
-- Always goes counter clockwise so it climb cuts
--]]  
function BuildTrueSpiral()
-- Archimedean spiral
-- r = a + bθ

  -- take greater of two
  local width = slab_width;
  local x_scale = 1
  local y_scale = slab_height/slab_width
  
  if slab_height > width then
    width = slab_height
    x_scale = slab_width/slab_height
    y_scale = 1
  end;

  -- center on material
  local x_offset = slab_width /2;
  local y_offset = slab_height /2;

  local i = 0;
  local x = 0;
  local y = 0;
  local angle = 0;
  local r = (width/2) + bit_dia/2;
  local loops = r / stepover;

  -- move per loop
  local d = r / (loops * 360);
  local rect = Contour(0.0);
  -- start outside of material by 1 bit diameter
  rect:AppendPoint(Point2D(x_offset, slab_height + bit_dia))
  
  -- in 1 degree moves
  while angle < math.rad(360*loops) do
    x = x_offset + r * math.sin(angle)
    y = y_offset + r * math.cos(angle)
    rect:LineTo(Point2D(x,y))
    angle = angle + math.rad(1)
    r = r - d;
  end;
  
  -- scale to bounding box
  xform = ScalingMatrix2D(Point2D(slab_width/2, slab_height/2), Vector2D(x_scale,y_scale))
  rect:Transform(xform)
  
  local pos
  local span0
  local span1
  pos = rect:GetHeadPosition();
  span0, pos = rect:GetNext(pos);
  span1, pos = rect:GetNext(pos);
  span0:SetStartPoint2D(Point2D(span0.StartPoint2D.X, span1.StartPoint2D.Y+bit_dia/2));
 
    
  -- all done, add it to our group and exit
  local rect_group = ContourGroup(true)
  rect_group:AddTail(rect)
  return rect_group
end

--[[-----------------------------------------------------------------------------------------------
-- Build a sudo spiral, it just traverses the bounding box from outside in
-- Always goes counter clockwise so it climb cuts
--]]  
function BuildSpiral()
  local offset = 0
  
  local rad = bit_dia/2
  if rad > 0.5 then
    rad = 0.5
  end
  
  local rect = Contour(0.0)
  
  local blx =  -bit_dia/2
  local bly =  -bit_dia/2
  
  local tlx =  blx
  local tly =  slab_height + bit_dia/2
  
  local trx =  slab_width + bit_dia/2
  local try =  tly
  
  local brx =  trx
  local bry =  bly
  
  local fx =  blx + stepover
  local fy =  bry
  
  local point_1 = Point2D(-bit_dia,-bit_dia)
  local point_2 = Point2D(blx,bly)
  rect:AppendPoint(point_1)
  rect:LineTo(point_2)
  
  local xcount = (slab_width+bit_dia*2)/2 / stepover
  local ycount = (slab_height+bit_dia*2)/2 / stepover
  local count = math.ceil(xcount)
  if xcount > ycount then
    count = math.ceil(ycount)
  end
  
  local max_x = trx
  local max_y = try
  local min_x = fx
  local min_y = fy
  
  local abort = false
  local holdx = 0
  local holdy = 0
  local holdr = 0
  
  for i = 1, count do
    if tly-blx < 2*rad then rad = 0 end
    if trx-tlx < 2*rad then rad = 0 end
    if try-bry < 2*rad then rad = 0 end
    if brx-fx < 2 *rad then rad = 0 end

    if (tly <= max_y) and (bly < tly) then
      if i == 1  then
        rect:LineTo(Point2D(blx, bly + rad))  -- lower left to upper left
      else 
        if rad == 0 then
          -- draw line
          rect:LineTo(Point2D(holdx, holdy))
        else
          -- draw arc
          rect:ArcTo(Point2D(holdx, holdy + holdr), Point2D(holdx + holdr, holdy + holdr), false)         
        end
      end;
       
       rect:LineTo(Point2D(tlx, tly - rad))  -- lower left to upper left
       rect:ArcTo(Point2D(tlx + rad, tly), Point2D(tlx + rad, tly - rad), false) 
      
      if (trx <= max_x) and (tlx < trx) then
        rect:LineTo(Point2D(trx - rad, try))  -- upper left to upper right
        rect:ArcTo(Point2D(trx, try - rad), Point2D(trx - rad, try - rad), false) 
      
        
        if (bry >= min_y)  and (try > bry) then
          rect:LineTo(Point2D(brx, bry + rad))  -- upper right to lower right
          rect:ArcTo(Point2D(brx - rad, bry), Point2D(brx - rad, bry + rad), false) 
          
          if (fx >= min_x) and (brx > fx) then
            rect:LineTo(Point2D(fx + rad, fy))    -- lower right to final
            
            -- draw its ark before next line
            holdx = fx
            holdy = fy
            holdr = rad
            --rect:ArcTo(Point2D(fx, fy + rad), Point2D(fx + rad, fy + rad), false) 
          else
            abort = true
          end
        else
          abort = true
        end
      else
        abort = true;
      end
      --rect_group:AddTail(rect)
    else 
     abort = true;
    end
   
    if abort then
      break
     end

    -- save bounds so we can see if we cross them on the next apss
    max_x = trx
    max_y = try
    min_x = fy
    min_y = fy
    
    blx = fx
    bly = fy
    
    tlx = fx
    tly = tly - stepover
    
    trx = trx - stepover
    try = tly
    
    brx = trx
    bry = bly + stepover
    
    fx = blx + stepover
    fy = bry
  end
  
  -- all done, add it to our group and exit
  local rect_group = ContourGroup(true)
  rect_group:AddTail(rect)
  return rect_group
end

--[[-----------------------------------------------------------------------------------------------
-- Callback from dialog, Set to WhiteSide 6210
-- Recommended RPM: 12,000-14,000 (max 16,000)
-- 3 flutes. 1/4" shaft
-- Cut Depth per Pass: 1/4"
-- Full Width, 1/8" Deep Cut:  0.89 HP / 669 Watts
-- based on tool lib from whiteside, the default speed is 15000 and feedrate of 100 (plung 5)
-- this results in chipload of .0022
-- slowing things down to 14000, we can use a feed rate 91 to get the same chipload
--]]  
function OnLuaButton_BitXBtn(dialog)
  local xstepover_type = dialog:GetRadioIndex("StepoverType")
  local xbit_dia = 1
  local xstepover = xbit_dia * .4     -- max = .707 * bitwidth (40%)
  if xstepover_type == 2 then
    xstepover = xstepover / xbit_dia * 100
  end
  dialog:UpdateDoubleField("BitDia", xbit_dia)
  dialog:UpdateDoubleField("Stepover", xstepover)
  dialog:UpdateDoubleField("FeedRate", 91)
  dialog:UpdateDoubleField("SpindleRPM", 14000)
  return true  -- ESSENTIAL that handler has this at end (don't just return)
end;

--[[-----------------------------------------------------------------------------------------------
-- Callback from dialog, Set to WhiteSide 6220
-- Recommended RPM: 12,000-14,000 (max 16,000)
-- 4 flutes, 1/2" shaft
-- Cut Depth per Pass: 1/2"
-- Full Width Cut: 5 HP / 3.3 KW
-- based on tool lib from whiteside, the default speed is 15000 and feedrate of 200 (plunge 20)
-- this results in chipload of .0033
-- slowing things down to 14000, we can use a feed rate 185 to get the same chipload
--]]  
function OnLuaButton_BitYBtn(dialog)
  local xstepover_type = dialog:GetRadioIndex("StepoverType")
  local xbit_dia = 2
  local xstepover = xbit_dia * .4     -- max = .707 * bitwidth (default 40%)
  if xstepover_type == 2 then
    xstepover = xstepover / xbit_dia * 100
  end
  dialog:UpdateDoubleField("BitDia", xbit_dia)
  dialog:UpdateDoubleField("Stepover", xstepover)
  dialog:UpdateDoubleField("FeedRate", 185)
  dialog:UpdateDoubleField("SpindleRPM", 14000)
  return true  -- ESSENTIAL that handler has this at end (don't just return)
end;

--[[-----------------------------------------------------------------------------------------------
-- Callback from dialog, Set to Amana 2255
-- Hardwood max = 18,000 / 300" / 0.006" at 1/8" Depth (per chart)  (14000 / 500 / .012" for MDF)
--                 14000 / 250" / 0.006  (joinery)
-- Cut Depth per Pass: 1/4"
-- Full Width Cut: 8 HP / 6 KW
   3 flutes
--]]  
function OnLuaButton_BitZBtn(dialog)
  local xstepover_type = dialog:GetRadioIndex("StepoverType")
  local xbit_dia = 2
  local xstepover = xbit_dia * .4     -- max = .707 * bitwidth (default 40%)
  if xstepover_type == 2 then
    xstepover = xstepover / xbit_dia * 100
  end
  dialog:UpdateDoubleField("BitDia", xbit_dia)
  dialog:UpdateDoubleField("Stepover", xstepover)
  dialog:UpdateDoubleField("FeedRate", 250)
  dialog:UpdateDoubleField("SpindleRPM", 14400)
  return true  -- ESSENTIAL that handler has this at end (don't just return)
end;

--[[-----------------------------------------------------------------------------------------------
-- Callback from dialog, Help dialog values
--]]  
function OnLuaButton_HelpBtn(dialog)
  local script_path = debug.getinfo(1).source:match("@?(.*[\\/])")
  local help_file = script_path .. "SlabWorks_Help.htm"
  -- Try rundll32 for potentially faster launch
  os.execute('start "" "' .. help_file .. '"')
  
   return true  -- ESSENTIAL that handler has this at end (don't just return)
end;

--[[-----------------------------------------------------------------------------------------------
-- Callback from dialog, Reset dialog values
--]]  
function OnLuaButton_ResetBtn(dialog)
  set_defaults()
  
  dialog:UpdateDoubleField("BitDia", bit_dia)
  dialog:UpdateDoubleField("SpindleRPM", spindle_rpm)
  
  local hold_stepover = stepover
  if stepover_type == 2 then
    hold_stepover = stepover / bit_dia * 100
  end
  dialog:UpdateDoubleField("Stepover", hold_stepover)
  dialog:UpdateRadioIndex("StepoverType", stepover_type) --  1 = actual, 2 = percent
  dialog:UpdateRadioIndex("ToolpathType", toolpath_type) --  1 = linear t/b, 2 = linear l/r, 3 = Climb Only, 4 = Spiral, 5 = true spiral
  dialog:UpdateDoubleField("CutDepth", cut_depth)
  dialog:UpdateDoubleField("DepthOffset", depth_offset)
  dialog:UpdateDoubleField("FeedRate", feed_rate)
  dialog:UpdateDoubleField("HomeHeight", home_height)
  dialog:UpdateIntegerField("RepeatCount", repeat_count)
  dialog:UpdateDoubleField("TotalDepth", total_depth)
  dialog:UpdateCheckBox("AltToolNumber", alt_toolnumber)
  dialog:UpdateCheckBox("PerimeterCut", perimeter_cut)
  
  --dialog:UpdateCheckBox("AutoInc", auto_inc)
  
   return true  -- ESSENTIAL that handler has this at end (don't just return)
end;

--[[-----------------------------------------------------------------------------------------------
-- Callback from dialog when stepover type changes
--]]  
function OnLuaButton_StepoverType1(dialog)
  local xbit_dia = dialog:GetDoubleField("BitDia") 
  local xstepover = dialog:GetDoubleField("Stepover")
  -- for most thing we keep the current value of stepover type on the dialog but for this
  -- we dont get it because we know what was clicked by the event
  -- we need to know what it was before the event so we just save it in globle

  -- change to new format
  if stepover_type == 2 then
    xstepover = xstepover * xbit_dia / 100
  end
  stepover_type = 1;
  
  dialog:UpdateDoubleField("Stepover", xstepover)
   return true  -- ESSENTIAL that handler has this at end (don't just return)
end;
  
--[[-----------------------------------------------------------------------------------------------
-- Callback from dialog when stepover type changes
--]]  
function OnLuaButton_StepoverType2(dialog)
  local xbit_dia = dialog:GetDoubleField("BitDia") 
  local xstepover = dialog:GetDoubleField("Stepover")
  -- for most thing we keep the current value of stepover type on the dialog but for this
  -- we dont get it because we know what was clicked by the event
  -- we need to know what it was before the event so we just save it in globle
  
  -- change to new format
  if stepover_type == 1 then
    xstepover = xstepover / xbit_dia * 100
  end
  stepover_type = 2;
  
  dialog:UpdateDoubleField("Stepover", xstepover)
  return true  -- ESSENTIAL that handler has this at end (don't just return)
end;

--[[-----------------------------------------------------------------------------------------------
-- delete all Slap toolpaths
--]]  
function OnLuaButton_ClearBtn(dialog)
  local toolpath_manager = ToolpathManager()
  local pos = toolpath_manager:GetTailPosition()
  
  while pos ~= nil do
    toolpath, pos = toolpath_manager:GetPrev(pos)
    if string.sub(toolpath.Name,1,4) == "Slab" then
      toolpath_manager:DeleteToolpath(toolpath);
    end
  end;
  depth_offset = 0
  dialog:UpdateDoubleField("DepthOffset", depth_offset) 
  return true;
end;

  
--[[-----------------------------------------------------------------------------------------------
-- Create and apply the tool path
--]]  
function OnLuaButton_ApplyButton(dialog)
    if get_dialog_values(dialog) then
      -- 1 = linear t/b, 2 = linear l/r, 3 = Climb Only, 4 = Spiral, 5 = true spiral
      -- create toolpath selected
      if     toolpath_type == 1 then rect_group = BuildZigZagTB() 
      elseif toolpath_type == 2 then rect_group = BuildZigZagLR() 
      elseif toolpath_type == 3 then rect_group = BuildRectangles() 
      elseif toolpath_type == 4 then rect_group = BuildSpiral() 
      elseif toolpath_type == 5 then rect_group = BuildTrueSpiral()
      end
    
      -- setup toolpath
      local toolpath_manager = ToolpathManager()
      local pos = toolpath_manager:GetHeadPosition()
      
      -- attempt to increment name by 1
      local toolpath
      local tool = nil
      local slab_cnt  = 1
      -- local last_stepdown = depth_offset
      while pos ~= nil do
        toolpath, pos = toolpath_manager:GetNext(pos)
        if string.sub(toolpath.Name,1,4) == "Slab" then
          tool = toolpath.Tool.ToolNumber
          slab_cnt = slab_cnt + 1
          --last_stepdown = toolpath.Tool.Stepdown
        end
      end;
      -- local this_stepdown = cut_depth
      -- if auto_inc then
        -- this_stepdown = last_stepdown + cut_depth
      -- end
      local this_stepdown = depth_offset + cut_depth
            
      -- alternate tool numbers
      if alt_toolnumber then
        if tool ~= nil then 
          if tool == 1 then 
            tool = 2
          else
            tool = 1
          end
        else
          tool = 1
        end
      else
        tool = 1
      end
    
      -- ok, all set create toolpath
      local total_stepdown = this_stepdown
      for cnt = 1, repeat_count do
        -- not allowed to go to zero!
        if total_stepdown >= slab_thickness then
          break
        end
        local tp_name = "Slab  " .. slab_cnt .. " T" .. tool
        CreateToolpath(tp_name , rect_group, total_stepdown, tool )
        --if auto_inc then
          total_stepdown = total_stepdown + cut_depth
        --end
        slab_cnt = slab_cnt + 1
        if alt_toolnumber then
          if tool == 1 then
            tool = 2
          else
            tool = 1
          end
        end
      end
      depth_offset = total_stepdown - cut_depth
      dialog:UpdateDoubleField("DepthOffset", depth_offset)      
      --if auto_inc then
      --  cut_depth = total_cut_depth
      --  dialog:UpdateCheckBox("AutoInc", auto_inc)
      --end  
    end
   
   return true  -- ESSENTIAL that handler has this at end (don't just return)
end

--[[-----------------------------------------------------------------------------------------------
-- Get the values from the dialog box and return true if they are all valid
--]]  
function get_dialog_values(dialog)
  -- verify bit_dia
  local xbit_dia = dialog:GetDoubleField("BitDia") 
  if (xbit_dia < .24 ) or (xbit_dia > 2) then
    DisplayMessageBox('Bit diameter must be between .25 and 2"')
    return false
  end
  
  -- verify rpm
  local xspindle_rpm = dialog:GetDoubleField("SpindleRPM")
  if (xspindle_rpm < 6000) or (xspindle_rpm > 24000) then
    DisplayMessageBox('RPM must be between 6000 and 24000')
    return false
  end
    
  -- verify stepover as either actual or %  
  local xstepover_type = dialog:GetRadioIndex("StepoverType")
  local xstepover = dialog:GetDoubleField("Stepover")
  if xstepover_type == 2 then
    xstepover = xbit_dia * xstepover/100
  end
  if xstepover > (xbit_dia * .7) then
    if xstepover_type == 2 then
      DisplayMessageBox('Stepover must be << 70%')
    else
      local msg = 'Stepover must be << ' .. tostring(xbit_dia * .7)
      DisplayMessageBox(msg)
    end
    return false
  end;
  
  -- verify toolpath_type (we do not have full spiral yet)
  local xtoolpath_type = dialog:GetRadioIndex("ToolpathType")
  --if xtoolpath_type == 5 then 
  --    DisplayMessageBox('"True Spriral" is not supported yet')
  --    return false
  --end;
  
  -- verify cut depth min
  local xcut_depth = dialog:GetDoubleField("CutDepth")
  if (xcut_depth < .010) then
      DisplayMessageBox('Cut depth must be >= 0.01')
      return false
  end;

  -- verify cut_depth max but do not fail if wrong
  if (xcut_depth > 1) then
    DisplayMessageBox('WARNING: your cut depth is > 1"')
  end

  local xdepth_offset = dialog:GetDoubleField("DepthOffset")
  if (xdepth_offset < 0) then
    DisplayMessageBox('Offset must be >= 0')
      return false
  end;
  
  -- verify feed_rate
  local xfeed_rate = dialog:GetDoubleField("FeedRate")
  if (xfeed_rate < 50) or (xfeed_rate > 400) then
      DisplayMessageBox('Feedrate must be between 50 and 400')
      return false
  end;
  
  -- verify home_height
  local xhome_height = dialog:GetDoubleField("HomeHeight")
  if (xhome_height < 0.5) or (xhome_height > 4) then
      DisplayMessageBox('Home height must be between 0.5 and 4.0')
      return false
  end;
  
  local xrepeat_count = dialog:GetIntegerField("RepeatCount")
  if (xrepeat_count < 1) or (xrepeat_count > 20) then
      DisplayMessageBox('Repeat must be between 1 and 20')
      return false
  end;
  
  local xtotal_depth = dialog:GetDoubleField("TotalDepth")
  if (xtotal_depth < xcut_depth) or (xtotal_depth > 6) then
      DisplayMessageBox('Depth must be between ' .. tostring(xcut_depth) .. ' and 6.0')
      return false
  end;
  
  local xalt_toolnumber = dialog:GetCheckBox("AltToolNumber")
  
  local xperimeter_cut = dialog:GetCheckBox("PerimeterCut")
 
  --local xauto_inc = dialog:GetCheckBox("AutoInc")
   
   
  -- got here so all valid, save them 
  bit_dia = xbit_dia
  spindle_rpm = xspindle_rpm
  stepover_type = xstepover_type
  stepover = xstepover
  toolpath_type =  xtoolpath_type
  cut_depth = xcut_depth
  depth_offset = xdepth_offset
  feed_rate = xfeed_rate
  home_height = xhome_height
  repeat_count = xrepeat_count
  total_depth = xtotal_depth
  alt_toolnumber = xalt_toolnumber
  perimeter_cut = xperimeter_cut
  --auto_inc = xauto_inc
  
  return true
end

--[[-----------------------------------------------------------------------------------------------
-- Fill value in to dialog box
--]]  
function fill_dialog_values(dialog)
    dialog:AddLabelField("SlabWidth", string.format("%.3f", slab_width))
    dialog:AddLabelField("SlabHeight", string.format("%.3f", slab_height))
    dialog:AddLabelField("SlabThickness", string.format("%.3f", slab_thickness))
    
    dialog:AddDoubleField("BitDia", bit_dia)
    dialog:AddDoubleField("SpindleRPM", spindle_rpm)
    
    -- convert display to show % if asked
    local hold_stepover = stepover
    if stepover_type == 2 then
      hold_stepover = stepover / bit_dia * 100
    end
    dialog:AddDoubleField("Stepover", hold_stepover)
    dialog:AddRadioGroup("StepoverType", stepover_type) --  1 = actual, 2 = percent
    dialog:AddRadioGroup("ToolpathType", toolpath_type) --  1 = linear t/b, 2 = linear l/r, 3 = Climb Only, 4 = Spiral, 5 = true spiral
    dialog:AddDoubleField("CutDepth", cut_depth)
    dialog:AddDoubleField("DepthOffset", depth_offset)
    dialog:AddDoubleField("FeedRate", feed_rate)
    
    dialog:AddDoubleField("HomeHeight", home_height)
    dialog:AddLabelField("GadgetVersion", g_version)
    dialog:AddIntegerField("RepeatCount", repeat_count)
    dialog:AddDoubleField("TotalDepth", total_depth)
    dialog:AddCheckBox("AltToolNumber", alt_toolnumber)
    dialog:AddCheckBox("PerimeterCut", perimeter_cut)
    
    --dialog:AddCheckBox("AutoInc", auto_inc)
  
  return true
end

--[[-----------------------------------------------------------------------------------------------
-- reset global variables
--]]  
function set_defaults()
  -- slab width, height and thickness are from the material and not resetable
  local toolpath_manager = ToolpathManager()
  local pos = toolpath_manager:GetHeadPosition()
  
  -- set offset to match last
  local toolpath
  local offset = 0.0
  while pos ~= nil do
    toolpath, pos = toolpath_manager:GetNext(pos)
    if string.sub(toolpath.Name,1,4) == "Slab" then
      offset = toolpath.Tool.Stepdown
    end
  end;
  
  bit_dia = 2.0
  stepover = bit_dia * .4     -- max = .707 * bitwidth
  stepover_type  = 1 -- actual
  spindle_rpm = 14000
  default_cut_depth = 0.05
  cut_depth = default_cut_depth
  depth_offset = offset;
  feed_rate = 250
  home_height = 1
  toolpath_type = 1
  repeat_count = 1
  total_depth = default_cut_depth * repeat_count
  alt_toolnumber = false
  perimeter_cut = false
  --auto_inc = true
 
end;


--[[-----------------------------------------------------------------------------------------------
-- Main
--]]  
function main(script_path)
 
  -- make sure we have a job
  local job = VectricJob()
  if not job.Exists then
    DisplayMessageBox("No job loaded")
    return false;  
  end
  
  -- make sure we surface from slab down
  local mtl_block = MaterialBlock()
  if mtl_block.ZOrigin ~= MaterialBlock.Z_TOP then
    DisplayMessageBox('Please set Z Zero Position to "Material Surface"')
    return false;  
  end  
 
  -- save some globals
  slab_thickness = mtl_block.Thickness
  slab_height = job.Height
  slab_width = job.Width
  
  
  -- various attepts at making sure user has correct post processor (all failed)
  --local layer_manager = job.LayerManager
  --local active_layer = layer_manager:GetActiveLayer()
  
  --local selection = job.Selection
  --if selection.IsEmpty  then
  --  MessageBox("Please select a vector to profile")
  --  return false  
  --end  
  
  --if selection.Count ~= 1  then
  --  MessageBox("Please select only one vector")
  --  return false  
  --end  
  
  --local bounding_box = selection:GetBoundingBox()
 
  --globals
  --slab_height = bounding_box.MaxY - bounding_box.MinY
  --slab_width = bounding_box.MaxX - bounding_box.MinX
  --slab_x = bounding_box.MinX
  --slab_y = bounding_box.MinY
  
  
  --local toolpath_saver = ToolpathSaver()
  --local postp_info = toolpath_saver.DefaultPost
  --if postp_info == nil then
  --  DisplayMessageBox("You need to have a post selected")
  --  return false;  
  --end
  
  --local post_name = postp_info.Name
  --if post_name ~= "Avid CNC (inch) (*.txt)" then
  --  DisplayMessageBox('Set post processor to "Avid CNC (inch) (*.txt)"')
  --  return false;  
  --end
  
  
  --local pp = job.PostProcessParameters
  --if pp.PostP == nil then
  --  DisplayMessageBox('Failed to access post processor from script!')
  --  return false
  --end
  --local post_name = ''
  --if pp ~= nil then
  --  post_name = pp:GetString('POST_NAME', 'unknown')
  --end
    
  
  
  -- set up globals
  set_defaults()
  
      -- setup toolpath
  --local toolpath_manager = ToolpathManager()
  --=local pos = toolpath_manager:GetHeadPosition()
      
  -- get last cut depth
  --local toolpath
  --while pos ~= nil do
  --  toolpath, pos = toolpath_manager:GetNext(pos)
  --  if string.sub(toolpath.Name,1,4) == "Slab" then
  --    cut_depth = toolpath.Tool.StepDown
  --  end
  --end;
  
  
  
  -- get values from registry (overrigting globals)
  local reg = Registry("SlabWorks")
  bit_dia = reg:GetDouble("BitDia", bit_dia)
  stepover = reg:GetDouble("Stepover", stepover)
  stepover_type = reg:GetInt("StepoverType", stepover_type)
  spindle_rpm = reg:GetDouble("SpindleRPM", spindle_rpm)
  cut_depth = reg:GetDouble("CutDepth", cut_depth)
  -- depth_offset = reg:GetDouble("DepthOffset", depth_offset)
  feed_rate = reg:GetDouble("FeedRate", feed_rate)
  home_height = reg:GetDouble("HomeHeight", home_height)
  toolpath_type = reg:GetInt("ToolPathType", toolpath_type)
  repeat_count = reg:GetInt("RepeatCount", repeat_count)
  
  -- we do not save total_depth to reg
  total_depth = cut_depth * repeat_count
    --total_depth = reg:GetDouble("TotalDepth", total_depth)
    
  alt_toolnumber = reg:GetBool("AltToolNumber", alt_toolnumber)
  perimeter_cut = reg:GetBool("PerimeterCut", perimeter_cut)
  --auto_inc = reg:GetBool("AutoInc", auto_inc)
    
  -- set up our dialog
  local html_path = "file:" .. script_path .. "\\SlabWorks.htm"
  local dialog = HTML_Dialog(false, html_path, 500, 775, "SlabWorks Toolpath Generator")
  
  -- fill dialog in
  fill_dialog_values(dialog)
  
  -- present dialog to user
  dialog:ShowDialog()
  
  -- save values to registry
  reg:SetDouble("BitDia", bit_dia)
  reg:SetDouble("Stepover", stepover)
  reg:SetInt("StepoverType", stepover_type)
  reg:SetDouble("SpindleRPM", spindle_rpm)
  reg:SetDouble("CutDepth", cut_depth)
  -- reg:SetDouble("DepthOffset", depth_offset)
  reg:SetDouble("FeedRate", feed_rate)
  reg:SetDouble("HomeHeight", home_height)
  reg:SetInt("ToolPathType", toolpath_type)
  reg:SetInt("RepeatCount", repeat_count)
  -- we do not save total_depth to reg
  --reg:SetInt("TotalDepth", total_depth)
  reg:SetBool("AltToolNumber", alt_toolnumber)
  reg:SetBool("PerimeterCut", perimeter_cut)
  --reg:SetBool("AutoInc", auto_inc)
    
  
  return true
end
  