
local t = {}

local function ScopedConnect(parentInstance, instance, event, signalFunc, syncFunc, removeFunc)
	local eventConnection = nil

	--Connection on parentInstance is scoped by parentInstance (when destroyed, it goes away)
	local tryConnect = function()
		if game:IsAncestorOf(parentInstance) then
			--Entering the world, make sure we are connected/synced
			if not eventConnection then
				eventConnection = instance[event]:connect(signalFunc)
				if syncFunc then syncFunc() end
			end
		else
			--Probably leaving the world, so disconnect for now
			if eventConnection then
				eventConnection:disconnect()
				if removeFunc then removeFunc() end
			end
		end
	end

	--Hook it up to ancestryChanged signal
	local connection = parentInstance.AncestryChanged:connect(tryConnect)
	
	--Now connect us if we're already in the world
	tryConnect()
	
	return connection
end

local function getScreenGuiAncestor(instance)
	local localInstance = instance
	while localInstance and not localInstance:IsA("ScreenGui") do
		localInstance = localInstance.Parent
	end
	return localInstance
end

local function CreateButtons(frame, buttons, yPos, ySize)
	local buttonNum = 1
	local buttonObjs = {}
	for i, obj in ipairs(buttons) do 
		local button = Instance.new("TextButton")
		button.Name = "Button" .. buttonNum
		button.Font = Enum.Font.Arial
		button.FontSize = Enum.FontSize.Size18
		button.AutoButtonColor = true
		button.Modal = true
		if obj["Style"] then
			button.Style = obj.Style
		else
			button.Style = Enum.ButtonStyle.RobloxButton
		end
		if obj["ZIndex"] then
			button.ZIndex = obj.ZIndex
		end
		button.Text = obj.Text
		button.TextColor3 = Color3.new(1,1,1)
		button.MouseButton1Click:connect(obj.Function)
		button.Parent = frame
		buttonObjs[buttonNum] = button

		buttonNum = buttonNum + 1
	end
	local numButtons = buttonNum-1

	if numButtons == 1 then
		frame.Button1.Position = UDim2.new(0.35, 0, yPos.Scale, yPos.Offset)
		frame.Button1.Size = UDim2.new(.4,0,ySize.Scale, ySize.Offset)
	elseif numButtons == 2 then
		frame.Button1.Position = UDim2.new(0.1, 0, yPos.Scale, yPos.Offset)
		frame.Button1.Size = UDim2.new(.8/3,0, ySize.Scale, ySize.Offset)

		frame.Button2.Position = UDim2.new(0.55, 0, yPos.Scale, yPos.Offset)
		frame.Button2.Size = UDim2.new(.35,0, ySize.Scale, ySize.Offset)
	elseif numButtons >= 3 then
		local spacing = .1 / numButtons
		local buttonSize = .9 / numButtons

		buttonNum = 1
		while buttonNum <= numButtons do
			buttonObjs[buttonNum].Position = UDim2.new(spacing*buttonNum + (buttonNum-1) * buttonSize, 0, yPos.Scale, yPos.Offset)
			buttonObjs[buttonNum].Size = UDim2.new(buttonSize, 0, ySize.Scale, ySize.Offset)
			buttonNum = buttonNum + 1
		end
	end
end

local function setSliderPos(newAbsPosX,slider,sliderPosition,bar,steps)

	local newStep = steps - 1 --otherwise we really get one more step than we want
	local relativePosX = math.min(1, math.max(0, (newAbsPosX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X ))
	local wholeNum, remainder = math.modf(relativePosX * newStep)
	if remainder > 0.5 then
		wholeNum = wholeNum + 1
	end
	relativePosX = wholeNum/newStep

	local result = math.ceil(relativePosX * newStep)
	if sliderPosition.Value ~= (result + 1) then --only update if we moved a step
		sliderPosition.Value = result + 1
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
	end
	
end

local function cancelSlide(areaSoak)
	areaSoak.Visible = false
	if areaSoakMouseMoveCon then areaSoakMouseMoveCon:disconnect() end
end

t.CreateStyledMessageDialog = function(title, message, style, buttons)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0, 165)
	frame.Position = UDim2.new(0.25, 0, 0.5, -72.5)
	frame.Name = "MessageDialog"
	frame.Active = true
	frame.Style = Enum.FrameStyle.RobloxRound	
	
	local styleImage = Instance.new("ImageLabel")
	styleImage.Name = "StyleImage"
	styleImage.BackgroundTransparency = 1
	styleImage.Position = UDim2.new(0,5,0,15)
	if style == "error" or style == "Error" then
		styleImage.Size = UDim2.new(0, 71, 0, 71)
		styleImage.Image = "http://www.roblox.com/asset/?id=42565285"
	elseif style == "notify" or style == "Notify" then
		styleImage.Size = UDim2.new(0, 71, 0, 71)
		styleImage.Image = "http://www.roblox.com/asset/?id=42604978"
	elseif style == "confirm" or style == "Confirm" then
		styleImage.Size = UDim2.new(0, 74, 0, 76)
		styleImage.Image = "http://www.roblox.com/asset/?id=42557901"
	else
		return t.CreateMessageDialog(title,message,buttons)
	end
	styleImage.Parent = frame
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = title
	titleLabel.TextStrokeTransparency = 0
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	titleLabel.Position = UDim2.new(0, 80, 0, 0)
	titleLabel.Size = UDim2.new(1, -80, 0, 40)
	titleLabel.Font = Enum.Font.ArialBold
	titleLabel.FontSize = Enum.FontSize.Size36
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Text = message
	messageLabel.TextStrokeTransparency = 0
	messageLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	messageLabel.Position = UDim2.new(0.025, 80, 0, 45)
	messageLabel.Size = UDim2.new(0.95, -80, 0, 55)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Arial
	messageLabel.FontSize = Enum.FontSize.Size18
	messageLabel.TextWrap = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.Parent = frame

	CreateButtons(frame, buttons, UDim.new(0, 105), UDim.new(0, 40) )

	return frame
end

t.CreateMessageDialog = function(title, message, buttons)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0.5, 0)
	frame.Position = UDim2.new(0.25, 0, 0.25, 0)
	frame.Name = "MessageDialog"
	frame.Active = true
	frame.Style = Enum.FrameStyle.RobloxRound

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = title
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
	titleLabel.Font = Enum.Font.ArialBold
	titleLabel.FontSize = Enum.FontSize.Size36
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	messageLabel.Position = UDim2.new(0.025, 0, 0.175, 0)
	messageLabel.Size = UDim2.new(0.95, 0, .55, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Arial
	messageLabel.FontSize = Enum.FontSize.Size18
	messageLabel.TextWrap = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.Parent = frame

	CreateButtons(frame, buttons, UDim.new(0.8,0), UDim.new(0.15, 0))

	return frame
end

t.CreateDropDownMenu = function(items, onSelect, forRoblox, whiteSkin, baseZ)
	local baseZIndex = 0
	if (type(baseZ) == "number") then
		baseZIndex = baseZ
	end
	local width = UDim.new(0, 100)
	local height = UDim.new(0, 32)

	local xPos = 0.055
	local frame = Instance.new("Frame")
	local textColor = Color3.new(1,1,1)
	if (whiteSkin) then
		textColor = Color3.new(0.5, 0.5, 0.5)
	end
	frame.Name = "DropDownMenu"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(width, height)

	local dropDownMenu = Instance.new("TextButton")
	dropDownMenu.Name = "DropDownMenuButton"
	dropDownMenu.TextWrap = true
	dropDownMenu.TextColor3 = textColor
	dropDownMenu.Text = "Choose One"
	dropDownMenu.Font = Enum.Font.ArialBold
	dropDownMenu.FontSize = Enum.FontSize.Size18
	dropDownMenu.TextXAlignment = Enum.TextXAlignment.Left
	dropDownMenu.TextYAlignment = Enum.TextYAlignment.Center
	dropDownMenu.BackgroundTransparency = 1
	dropDownMenu.AutoButtonColor = true
	if (whiteSkin) then
		dropDownMenu.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
	else
		dropDownMenu.Style = Enum.ButtonStyle.RobloxButton
	end
	dropDownMenu.Size = UDim2.new(1,0,1,0)
	dropDownMenu.Parent = frame
	dropDownMenu.ZIndex = 2 + baseZIndex

	local dropDownIcon = Instance.new("ImageLabel")
	dropDownIcon.Name = "Icon"
	dropDownIcon.Active = false
	if (whiteSkin) then
		dropDownIcon.Image = "rbxasset://textures/ui/dropdown_arrow.png"
		dropDownIcon.Size = UDim2.new(0,16,0,12)
		dropDownIcon.Position = UDim2.new(1,-17,0.5, -6)
	else
		dropDownIcon.Image = "http://www.roblox.com/asset/?id=45732894"
		dropDownIcon.Size = UDim2.new(0,11,0,6)
		dropDownIcon.Position = UDim2.new(1,-11,0.5, -2)
	end
	dropDownIcon.BackgroundTransparency = 1
	dropDownIcon.Parent = dropDownMenu
	dropDownIcon.ZIndex = 2 + baseZIndex
	
	local itemCount = #items
	local dropDownItemCount = #items
	local useScrollButtons = false
	if dropDownItemCount > 6 then
		useScrollButtons = true
		dropDownItemCount = 6
	end
	
	local droppedDownMenu = Instance.new("TextButton")
	droppedDownMenu.Name = "List"
	droppedDownMenu.Text = ""
	droppedDownMenu.BackgroundTransparency = 1
	--droppedDownMenu.AutoButtonColor = true
	if (whiteSkin) then
		droppedDownMenu.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
	else
		droppedDownMenu.Style = Enum.ButtonStyle.RobloxButton
	end
	droppedDownMenu.Visible = false
	droppedDownMenu.Active = true	--Blocks clicks
	droppedDownMenu.Position = UDim2.new(0,0,0,0)
	droppedDownMenu.Size = UDim2.new(1,0, (1 + dropDownItemCount)*.8, 0)
	droppedDownMenu.Parent = frame
	droppedDownMenu.ZIndex = 2 + baseZIndex

	local choiceButton = Instance.new("TextButton")
	choiceButton.Name = "ChoiceButton"
	choiceButton.BackgroundTransparency = 1
	choiceButton.BorderSizePixel = 0
	choiceButton.Text = "ReplaceMe"
	choiceButton.TextColor3 = textColor
	choiceButton.TextXAlignment = Enum.TextXAlignment.Left
	choiceButton.TextYAlignment = Enum.TextYAlignment.Center
	choiceButton.BackgroundColor3 = Color3.new(1, 1, 1)
	choiceButton.Font = Enum.Font.Arial
	choiceButton.FontSize = Enum.FontSize.Size18
	if useScrollButtons then
		choiceButton.Size = UDim2.new(1,-13, .8/((dropDownItemCount + 1)*.8),0) 
	else
		choiceButton.Size = UDim2.new(1, 0, .8/((dropDownItemCount + 1)*.8),0) 
	end
	choiceButton.TextWrap = true
	choiceButton.ZIndex = 2 + baseZIndex

	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = true
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 3 + baseZIndex

	local dropDownSelected = false

	local scrollUpButton 
	local scrollDownButton
	local scrollMouseCount = 0

	local setZIndex = function(baseZIndex)
		droppedDownMenu.ZIndex = baseZIndex +1
		if scrollUpButton then
			scrollUpButton.ZIndex = baseZIndex + 3
		end
		if scrollDownButton then
			scrollDownButton.ZIndex = baseZIndex + 3
		end
		
		local children = droppedDownMenu:GetChildren()
		if children then
			for i, child in ipairs(children) do
				if child.Name == "ChoiceButton" then
					child.ZIndex = baseZIndex + 2
				elseif child.Name == "ClickCaptureButton" then
					child.ZIndex = baseZIndex
				end
			end
		end
	end

	local scrollBarPosition = 1
	local updateScroll = function()
		if scrollUpButton then
			scrollUpButton.Active = scrollBarPosition > 1 
		end
		if scrollDownButton then
			scrollDownButton.Active = scrollBarPosition + dropDownItemCount <= itemCount 
		end

		local children = droppedDownMenu:GetChildren()
		if not children then return end

		local childNum = 1			
		for i, obj in ipairs(children) do
			if obj.Name == "ChoiceButton" then
				if childNum < scrollBarPosition or childNum >= scrollBarPosition + dropDownItemCount then
					obj.Visible = false
				else
					obj.Position = UDim2.new(0,0,((childNum-scrollBarPosition+1)*.8)/((dropDownItemCount+1)*.8),0)
					obj.Visible = true
				end
				obj.TextColor3 = textColor
				obj.BackgroundTransparency = 1

				childNum = childNum + 1
			end
		end
	end
	local toggleVisibility = function()
		dropDownSelected = not dropDownSelected

		areaSoak.Visible = not areaSoak.Visible
		dropDownMenu.Visible = not dropDownSelected
		droppedDownMenu.Visible = dropDownSelected
		if dropDownSelected then
			setZIndex(4 + baseZIndex)
		else
			setZIndex(2 + baseZIndex)
		end
		if useScrollButtons then
			updateScroll()
		end
	end
	droppedDownMenu.MouseButton1Click:connect(toggleVisibility)

	local updateSelection = function(text)
		local foundItem = false
		local children = droppedDownMenu:GetChildren()
		local childNum = 1
		if children then
			for i, obj in ipairs(children) do
				if obj.Name == "ChoiceButton" then
					if obj.Text == text then
						obj.Font = Enum.Font.ArialBold
						foundItem = true			
						scrollBarPosition = childNum						
						if (whiteSkin) then
							obj.TextColor3 = Color3.new(90/255,142/255,233/255)
						end
					else
						obj.Font = Enum.Font.Arial
						if (whiteSkin) then
							obj.TextColor3 = textColor
						end
					end
					childNum = childNum + 1
				end
			end
		end
		if not text then
			dropDownMenu.Text = "Choose One"
			scrollBarPosition = 1
		else
			if not foundItem then
				error("Invalid Selection Update -- " .. text)
			end

			if scrollBarPosition + dropDownItemCount > itemCount + 1 then
				scrollBarPosition = itemCount - dropDownItemCount + 1
			end

			dropDownMenu.Text = text
		end
	end
	
	local function scrollDown()
		if scrollBarPosition + dropDownItemCount <= itemCount then
			scrollBarPosition = scrollBarPosition + 1
			updateScroll()
			return true
		end
		return false
	end
	local function scrollUp()
		if scrollBarPosition > 1 then
			scrollBarPosition = scrollBarPosition - 1
			updateScroll()
			return true
		end
		return false
	end
	
	if useScrollButtons then
		--Make some scroll buttons
		scrollUpButton = Instance.new("ImageButton")
		scrollUpButton.Name = "ScrollUpButton"
		scrollUpButton.BackgroundTransparency = 1
		scrollUpButton.Image = "rbxasset://textures/ui/scrollbuttonUp.png"
		scrollUpButton.Size = UDim2.new(0,17,0,17) 
		scrollUpButton.Position = UDim2.new(1,-11,(1*.8)/((dropDownItemCount+1)*.8),0)
		scrollUpButton.MouseButton1Click:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollUpButton.MouseLeave:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollUpButton.MouseButton1Down:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
	
				scrollUp()
				local val = scrollMouseCount
				wait(0.5)
				while val == scrollMouseCount do
					if scrollUp() == false then
						break
					end
					wait(0.1)
				end				
			end)

		scrollUpButton.Parent = droppedDownMenu

		scrollDownButton = Instance.new("ImageButton")
		scrollDownButton.Name = "ScrollDownButton"
		scrollDownButton.BackgroundTransparency = 1
		scrollDownButton.Image = "rbxasset://textures/ui/scrollbuttonDown.png"
		scrollDownButton.Size = UDim2.new(0,17,0,17) 
		scrollDownButton.Position = UDim2.new(1,-11,1,-11)
		scrollDownButton.Parent = droppedDownMenu
		scrollDownButton.MouseButton1Click:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollDownButton.MouseLeave:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollDownButton.MouseButton1Down:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1

				scrollDown()
				local val = scrollMouseCount
				wait(0.5)
				while val == scrollMouseCount do
					if scrollDown() == false then
						break
					end
					wait(0.1)
				end				
			end)	

		local scrollbar = Instance.new("ImageLabel")
		scrollbar.Name = "ScrollBar"
		scrollbar.Image = "rbxasset://textures/ui/scrollbar.png"
		scrollbar.BackgroundTransparency = 1
		scrollbar.Size = UDim2.new(0, 18, (dropDownItemCount*.8)/((dropDownItemCount+1)*.8), -(17) - 11 - 4)
		scrollbar.Position = UDim2.new(1,-11,(1*.8)/((dropDownItemCount+1)*.8),17+2)
		scrollbar.Parent = droppedDownMenu
	end

	for i,item in ipairs(items) do
		-- needed to maintain local scope for items in event listeners below
		local button = choiceButton:clone()
		if forRoblox then
			button.RobloxLocked = true
		end		
		button.Text = item
		button.Parent = droppedDownMenu
		if (whiteSkin) then
			button.TextColor3 = textColor
		end

		button.MouseButton1Click:connect(function()
			--Remove Highlight
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(1,1,1)
			end
			button.BackgroundTransparency = 1

			updateSelection(item)
			onSelect(item)

			toggleVisibility()
		end)
		button.MouseEnter:connect(function()
			--Add Highlight	
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(0,0,0)
			end
			button.BackgroundTransparency = 0
		end)

		button.MouseLeave:connect(function()
			--Remove Highlight
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(1,1,1)
			end
			button.BackgroundTransparency = 1
		end)
	end

	--This does the initial layout of the buttons	
	updateScroll()
	
	frame.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(frame)
		end
	end)

	dropDownMenu.MouseButton1Click:connect(toggleVisibility)
	areaSoak.MouseButton1Click:connect(toggleVisibility)
	return frame, updateSelection
end

t.CreatePropertyDropDownMenu = function(instance, property, enum)

	local items = enum:GetEnumItems()
	local names = {}
	local nameToItem = {}
	for i,obj in ipairs(items) do
		names[i] = obj.Name
		nameToItem[obj.Name] = obj
	end

	local frame
	local updateSelection
	frame, updateSelection = t.CreateDropDownMenu(names, function(text) instance[property] = nameToItem[text] end)

	ScopedConnect(frame, instance, "Changed", 
		function(prop)
			if prop == property then
				updateSelection(instance[property].Name)
			end
		end,
		function()
			updateSelection(instance[property].Name)
		end)

	return frame
end

t.GetFontHeight = function(font, fontSize)
	if font == nil or fontSize == nil then
		error("Font and FontSize must be non-nil")
	end

	if font == Enum.Font.Legacy then
		if fontSize == Enum.FontSize.Size8 then
			return 12
		elseif fontSize == Enum.FontSize.Size9 then
			return 14
		elseif fontSize == Enum.FontSize.Size10 then
			return 15
		elseif fontSize == Enum.FontSize.Size11 then
			return 17
		elseif fontSize == Enum.FontSize.Size12 then
			return 18
		elseif fontSize == Enum.FontSize.Size14 then
			return 21
		elseif fontSize == Enum.FontSize.Size18 then
			return 27
		elseif fontSize == Enum.FontSize.Size24 then
			return 36
		elseif fontSize == Enum.FontSize.Size36 then
			return 54
		elseif fontSize == Enum.FontSize.Size48 then
			return 72
		else
			error("Unknown FontSize")
		end
	elseif font == Enum.Font.Arial or font == Enum.Font.ArialBold then
		if fontSize == Enum.FontSize.Size8 then
			return 8
		elseif fontSize == Enum.FontSize.Size9 then
			return 9
		elseif fontSize == Enum.FontSize.Size10 then
			return 10
		elseif fontSize == Enum.FontSize.Size11 then
			return 11
		elseif fontSize == Enum.FontSize.Size12 then
			return 12
		elseif fontSize == Enum.FontSize.Size14 then
			return 14
		elseif fontSize == Enum.FontSize.Size18 then
			return 18
		elseif fontSize == Enum.FontSize.Size24 then
			return 24
		elseif fontSize == Enum.FontSize.Size36 then
			return 36
		elseif fontSize == Enum.FontSize.Size48 then
			return 48
		else
			error("Unknown FontSize")
		end
	else
		error("Unknown Font " .. font)
	end
end

local function layoutGuiObjectsHelper(frame, guiObjects, settingsTable)
	local totalPixels = frame.AbsoluteSize.Y
	local pixelsRemaining = frame.AbsoluteSize.Y
	for i, child in ipairs(guiObjects) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			local isLabel = child:IsA("TextLabel")
			if isLabel then
				pixelsRemaining = pixelsRemaining - settingsTable["TextLabelPositionPadY"]
			else
				pixelsRemaining = pixelsRemaining - settingsTable["TextButtonPositionPadY"]
			end
			child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
			child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, pixelsRemaining)

			if child.TextFits and child.TextBounds.Y < pixelsRemaining then
				child.Visible = true
				if isLabel then
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.TextBounds.Y + settingsTable["TextLabelSizePadY"])
				else 
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.TextBounds.Y + settingsTable["TextButtonSizePadY"])
				end

				while not child.TextFits do
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.AbsoluteSize.Y + 1)
				end
				pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y		

				if isLabel then
					pixelsRemaining = pixelsRemaining - settingsTable["TextLabelPositionPadY"]
				else
					pixelsRemaining = pixelsRemaining - settingsTable["TextButtonPositionPadY"]
				end
			else
				child.Visible = false
				pixelsRemaining = -1
			end			

		else
			--GuiObject
			child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
			pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y
			child.Visible = (pixelsRemaining >= 0)
		end
	end
end

t.LayoutGuiObjects = function(frame, guiObjects, settingsTable)
	if not frame:IsA("GuiObject") then
		error("Frame must be a GuiObject")
	end
	for i, child in ipairs(guiObjects) do
		if not child:IsA("GuiObject") then
			error("All elements that are layed out must be of type GuiObject")
		end
	end

	if not settingsTable then
		settingsTable = {}
	end

	if not settingsTable["TextLabelSizePadY"] then
		settingsTable["TextLabelSizePadY"] = 0
	end
	if not settingsTable["TextLabelPositionPadY"] then
		settingsTable["TextLabelPositionPadY"] = 0
	end
	if not settingsTable["TextButtonSizePadY"] then
		settingsTable["TextButtonSizePadY"] = 12
	end
	if not settingsTable["TextButtonPositionPadY"] then
		settingsTable["TextButtonPositionPadY"] = 2
	end

	--Wrapper frame takes care of styled objects
	local wrapperFrame = Instance.new("Frame")
	wrapperFrame.Name = "WrapperFrame"
	wrapperFrame.BackgroundTransparency = 1
	wrapperFrame.Size = UDim2.new(1,0,1,0)
	wrapperFrame.Parent = frame

	for i, child in ipairs(guiObjects) do
		child.Parent = wrapperFrame
	end

	local recalculate = function()
		wait()
		layoutGuiObjectsHelper(wrapperFrame, guiObjects, settingsTable)
	end
	
	frame.Changed:connect(
		function(prop)
			if prop == "AbsoluteSize" then
				--Wait a heartbeat for it to sync in
				recalculate(nil)
			end
		end)
	frame.AncestryChanged:connect(recalculate)

	layoutGuiObjectsHelper(wrapperFrame, guiObjects, settingsTable)
end


t.CreateSlider = function(steps,width,position)
	local sliderGui = Instance.new("Frame")
	sliderGui.Size = UDim2.new(1,0,1,0)
	sliderGui.BackgroundTransparency = 1
	sliderGui.Name = "SliderGui"
	
	local sliderSteps = Instance.new("IntValue")
	sliderSteps.Name = "SliderSteps"
	sliderSteps.Value = steps
	sliderSteps.Parent = sliderGui
	
	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = false
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 4
	
	sliderGui.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(sliderGui)
		end
	end)
	
	local sliderPosition = Instance.new("IntValue")
	sliderPosition.Name = "SliderPosition"
	sliderPosition.Value = 0
	sliderPosition.Parent = sliderGui
	
	local id = math.random(1,100)
	
	local bar = Instance.new("TextButton")
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Name = "Bar"
	bar.BackgroundColor3 = Color3.new(0,0,0)
	if type(width) == "number" then
		bar.Size = UDim2.new(0,width,0,5)
	else
		bar.Size = UDim2.new(0,200,0,5)
	end
	bar.BorderColor3 = Color3.new(95/255,95/255,95/255)
	bar.ZIndex = 2
	bar.Parent = sliderGui
	
	if position["X"] and position["X"]["Scale"] and position["X"]["Offset"] and position["Y"] and position["Y"]["Scale"] and position["Y"]["Offset"] then
		bar.Position = position
	end
	
	local slider = Instance.new("ImageButton")
	slider.Name = "Slider"
	slider.BackgroundTransparency = 1
	slider.Image = "rbxasset://textures/ui/Slider.png"
	slider.Position = UDim2.new(0,0,0.5,-10)
	slider.Size = UDim2.new(0,20,0,20)
	slider.ZIndex = 3
	slider.Parent = bar
	
	local areaSoakMouseMoveCon = nil
	
	areaSoak.MouseLeave:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	areaSoak.MouseButton1Up:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	
	slider.MouseButton1Down:connect(function()
		areaSoak.Visible = true
		if areaSoakMouseMoveCon then areaSoakMouseMoveCon:disconnect() end
		areaSoakMouseMoveCon = areaSoak.MouseMoved:connect(function(x,y)
			setSliderPos(x,slider,sliderPosition,bar,steps)
		end)
	end)
	
	slider.MouseButton1Up:connect(function() cancelSlide(areaSoak) end)
	
	sliderPosition.Changed:connect(function(prop)
		sliderPosition.Value = math.min(steps, math.max(1,sliderPosition.Value))
		local relativePosX = (sliderPosition.Value - 1) / (steps - 1)
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
	end)
	
	bar.MouseButton1Down:connect(function(x,y)
		setSliderPos(x,slider,sliderPosition,bar,steps)
	end)
	
	return sliderGui, sliderPosition, sliderSteps

end



t.CreateSliderNew = function(steps,width,position)
	local sliderGui = Instance.new("Frame")
	sliderGui.Size = UDim2.new(1,0,1,0)
	sliderGui.BackgroundTransparency = 1
	sliderGui.Name = "SliderGui"
	
	local sliderSteps = Instance.new("IntValue")
	sliderSteps.Name = "SliderSteps"
	sliderSteps.Value = steps
	sliderSteps.Parent = sliderGui
	
	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = false
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 6
	
	sliderGui.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(sliderGui)
		end
	end)
	
	local sliderPosition = Instance.new("IntValue")
	sliderPosition.Name = "SliderPosition"
	sliderPosition.Value = 0
	sliderPosition.Parent = sliderGui
	
	local id = math.random(1,100)
	
	local sliderBarImgHeight = 7
	local sliderBarCapImgWidth = 4

	local bar = Instance.new("ImageButton")
	bar.BackgroundTransparency = 1
	bar.Image = "rbxasset://textures/ui/Slider-BKG-Center.png"
	bar.Name = "Bar"
	local displayWidth = 200
	if type(width) == "number" then
		bar.Size = UDim2.new(0,width - (sliderBarCapImgWidth * 2),0,sliderBarImgHeight)
		displayWidth = width - (sliderBarCapImgWidth * 2)
	else
		bar.Size = UDim2.new(0,200,0,sliderBarImgHeight)
	end
	bar.ZIndex = 3
	bar.Parent = sliderGui	
	if position["X"] and position["X"]["Scale"] and position["X"]["Offset"] and position["Y"] and position["Y"]["Scale"] and position["Y"]["Offset"] then
		bar.Position = position
	end

	local barLeft = bar:clone()
	barLeft.Name = "BarLeft"
	barLeft.Image = "rbxasset://textures/ui/Slider-BKG-Left-Cap.png"
	barLeft.Size = UDim2.new(0, sliderBarCapImgWidth, 0, sliderBarImgHeight)
	barLeft.Position = UDim2.new(position.X.Scale, position.X.Offset - sliderBarCapImgWidth, position.Y.Scale, position.Y.Offset)
	barLeft.Parent = sliderGui	
	barLeft.ZIndex = 3

	local barRight = barLeft:clone()
	barRight.Name = "BarRight"
	barRight.Image = "rbxasset://textures/ui/Slider-BKG-Right-Cap.png"
	barRight.Position = UDim2.new(position.X.Scale, position.X.Offset + displayWidth, position.Y.Scale, position.Y.Offset)
	barRight.Parent = sliderGui	

	local fillLeft = barLeft:clone()
	fillLeft.Name = "FillLeft"
	fillLeft.Image = "rbxasset://textures/ui/Slider-Fill-Left-Cap.png"
	fillLeft.Parent = sliderGui	
	fillLeft.ZIndex = 4

	local fill = fillLeft:clone()
	fill.Name = "Fill"
	fill.Image = "rbxasset://textures/ui/Slider-Fill-Center.png"
	fill.Parent = bar	
	fill.ZIndex = 4
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.Size = UDim2.new(0.5, 0, 1, 0)


--	bar.Visible = false

	local slider = Instance.new("ImageButton")
	slider.Name = "Slider"
	slider.BackgroundTransparency = 1
	slider.Image = "rbxasset://textures/ui/slider_new_tab.png"
	slider.Position = UDim2.new(0,0,0.5,-14)
	slider.Size = UDim2.new(0,28,0,28)
	slider.ZIndex = 5
	slider.Parent = bar
	
	local areaSoakMouseMoveCon = nil
	
	areaSoak.MouseLeave:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	areaSoak.MouseButton1Up:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	
	slider.MouseButton1Down:connect(function()
		areaSoak.Visible = true
		if areaSoakMouseMoveCon then areaSoakMouseMoveCon:disconnect() end
		areaSoakMouseMoveCon = areaSoak.MouseMoved:connect(function(x,y)
			setSliderPos(x,slider,sliderPosition,bar,steps)
		end)
	end)
	
	slider.MouseButton1Up:connect(function() cancelSlide(areaSoak) end)
	
	sliderPosition.Changed:connect(function(prop)
		sliderPosition.Value = math.min(steps, math.max(1,sliderPosition.Value))
		local relativePosX = (sliderPosition.Value - 1) / (steps - 1)
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
		fill.Size = UDim2.new(relativePosX, 0, 1, 0)
	end)
	
	bar.MouseButton1Down:connect(function(x,y)
		setSliderPos(x,slider,sliderPosition,bar,steps)
	end)

	return sliderGui, sliderPosition, sliderSteps

end





t.CreateTrueScrollingFrame = function()
	local lowY = nil
	local highY = nil
	
	local dragCon = nil
	local upCon = nil

	local internalChange = false

	local descendantsChangeConMap = {}

	local scrollingFrame = Instance.new("Frame")
	scrollingFrame.Name = "ScrollingFrame"
	scrollingFrame.Active = true
	scrollingFrame.Size = UDim2.new(1,0,1,0)
	scrollingFrame.ClipsDescendants = true

	local controlFrame = Instance.new("Frame")
	controlFrame.Name = "ControlFrame"
	controlFrame.BackgroundTransparency = 1
	controlFrame.Size = UDim2.new(0,18,1,0)
	controlFrame.Position = UDim2.new(1,-20,0,0)
	controlFrame.Parent = scrollingFrame
	
	local scrollBottom = Instance.new("BoolValue")
	scrollBottom.Value = false
	scrollBottom.Name = "ScrollBottom"
	scrollBottom.Parent = controlFrame
	
	local scrollUp = Instance.new("BoolValue")
	scrollUp.Value = false
	scrollUp.Name = "scrollUp"
	scrollUp.Parent = controlFrame

	local scrollUpButton = Instance.new("TextButton")
	scrollUpButton.Name = "ScrollUpButton"
	scrollUpButton.Text = ""
	scrollUpButton.AutoButtonColor = false
	scrollUpButton.BackgroundColor3 = Color3.new(0,0,0)
	scrollUpButton.BorderColor3 = Color3.new(1,1,1)
	scrollUpButton.BackgroundTransparency = 0.5
	scrollUpButton.Size = UDim2.new(0,18,0,18)
	scrollUpButton.ZIndex = 2
	scrollUpButton.Parent = controlFrame
	for i = 1, 6 do
		local triFrame = Instance.new("Frame")
		triFrame.BorderColor3 = Color3.new(1,1,1)
		triFrame.Name = "tri" .. tostring(i)
		triFrame.ZIndex = 3
		triFrame.BackgroundTransparency = 0.5
		triFrame.Size = UDim2.new(0,12 - ((i -1) * 2),0,0)
		triFrame.Position = UDim2.new(0,3 + (i -1),0.5,2 - (i -1))
		triFrame.Parent = scrollUpButton
	end
	scrollUpButton.MouseEnter:connect(function()
		scrollUpButton.BackgroundTransparency = 0.1
		local upChildren = scrollUpButton:GetChildren()
		for i = 1, #upChildren do
			upChildren[i].BackgroundTransparency = 0.1
		end
	end)
	scrollUpButton.MouseLeave:connect(function()
		scrollUpButton.BackgroundTransparency = 0.5
		local upChildren = scrollUpButton:GetChildren()
		for i = 1, #upChildren do
			upChildren[i].BackgroundTransparency = 0.5
		end
	end)

	local scrollDownButton = scrollUpButton:clone()
	scrollDownButton.Name = "ScrollDownButton"
	scrollDownButton.Position = UDim2.new(0,0,1,-18)
	local downChildren = scrollDownButton:GetChildren()
	for i = 1, #downChildren do
		downChildren[i].Position = UDim2.new(0,3 + (i -1),0.5,-2 + (i - 1))
	end
	scrollDownButton.MouseEnter:connect(function()
		scrollDownButton.BackgroundTransparency = 0.1
		local downChildren = scrollDownButton:GetChildren()
		for i = 1, #downChildren do
			downChildren[i].BackgroundTransparency = 0.1
		end
	end)
	scrollDownButton.MouseLeave:connect(function()
		scrollDownButton.BackgroundTransparency = 0.5
		local downChildren = scrollDownButton:GetChildren()
		for i = 1, #downChildren do
			downChildren[i].BackgroundTransparency = 0.5
		end
	end)
	scrollDownButton.Parent = controlFrame
	
	local scrollTrack = Instance.new("Frame")
	scrollTrack.Name = "ScrollTrack"
	scrollTrack.BackgroundTransparency = 1
	scrollTrack.Size = UDim2.new(0,18,1,-38)
	scrollTrack.Position = UDim2.new(0,0,0,19)
	scrollTrack.Parent = controlFrame

	local scrollbar = Instance.new("TextButton")
	scrollbar.BackgroundColor3 = Color3.new(0,0,0)
	scrollbar.BorderColor3 = Color3.new(1,1,1)
	scrollbar.BackgroundTransparency = 0.5
	scrollbar.AutoButtonColor = false
	scrollbar.Text = ""
	scrollbar.Active = true
	scrollbar.Name = "ScrollBar"
	scrollbar.ZIndex = 2
	scrollbar.BackgroundTransparency = 0.5
	scrollbar.Size = UDim2.new(0, 18, 0.1, 0)
	scrollbar.Position = UDim2.new(0,0,0,0)
	scrollbar.Parent = scrollTrack

	local scrollNub = Instance.new("Frame")
	scrollNub.Name = "ScrollNub"
	scrollNub.BorderColor3 = Color3.new(1,1,1)
	scrollNub.Size = UDim2.new(0,10,0,0)
	scrollNub.Position = UDim2.new(0.5,-5,0.5,0)
	scrollNub.ZIndex = 2
	scrollNub.BackgroundTransparency = 0.5
	scrollNub.Parent = scrollbar

	local newNub = scrollNub:clone()
	newNub.Position = UDim2.new(0.5,-5,0.5,-2)
	newNub.Parent = scrollbar
	
	local lastNub = scrollNub:clone()
	lastNub.Position = UDim2.new(0.5,-5,0.5,2)
	lastNub.Parent = scrollbar

	scrollbar.MouseEnter:connect(function()
		scrollbar.BackgroundTransparency = 0.1
		scrollNub.BackgroundTransparency = 0.1
		newNub.BackgroundTransparency = 0.1
		lastNub.BackgroundTransparency = 0.1
	end)
	scrollbar.MouseLeave:connect(function()
		scrollbar.BackgroundTransparency = 0.5
		scrollNub.BackgroundTransparency = 0.5
		newNub.BackgroundTransparency = 0.5
		lastNub.BackgroundTransparency = 0.5
	end)

	local mouseDrag = Instance.new("ImageButton")
	mouseDrag.Active = false
	mouseDrag.Size = UDim2.new(1.5, 0, 1.5, 0)
	mouseDrag.AutoButtonColor = false
	mouseDrag.BackgroundTransparency = 1
	mouseDrag.Name = "mouseDrag"
	mouseDrag.Position = UDim2.new(-0.25, 0, -0.25, 0)
	mouseDrag.ZIndex = 10
	
	local function positionScrollBar(x,y,offset)
		local oldPos = scrollbar.Position

		if y < scrollTrack.AbsolutePosition.y then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,0,0)
			return (oldPos ~= scrollbar.Position)
		end
		
		local relativeSize = scrollbar.AbsoluteSize.Y/scrollTrack.AbsoluteSize.Y

		if y > (scrollTrack.AbsolutePosition.y + scrollTrack.AbsoluteSize.y) then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,1 - relativeSize,0)
			return (oldPos ~= scrollbar.Position)
		end
		local newScaleYPos = (y - scrollTrack.AbsolutePosition.y - offset)/scrollTrack.AbsoluteSize.y
		if newScaleYPos + relativeSize > 1 then
			newScaleYPos = 1 - relativeSize
			scrollBottom.Value = true
			scrollUp.Value = false
		elseif newScaleYPos <= 0 then
			newScaleYPos = 0
			scrollUp.Value = true
			scrollBottom.Value = false
		else
			scrollUp.Value = false
			scrollBottom.Value = false
		end
		scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,newScaleYPos,0)
		
		return (oldPos ~= scrollbar.Position)
	end

	local function drillDownSetHighLow(instance)
		if not instance or not instance:IsA("GuiObject") then return end
		if instance == controlFrame then return end
		if instance:IsDescendantOf(controlFrame) then return end
		if not instance.Visible then return end

		if lowY and lowY > instance.AbsolutePosition.Y then
			lowY = instance.AbsolutePosition.Y
		elseif not lowY then
			lowY = instance.AbsolutePosition.Y
		end
		if highY and highY < (instance.AbsolutePosition.Y + instance.AbsoluteSize.Y) then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		elseif not highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		end
		local children = instance:GetChildren()
		for i = 1, #children do
			drillDownSetHighLow(children[i])
		end
	end

	local function resetHighLow()
		local firstChildren = scrollingFrame:GetChildren()

		for i = 1, #firstChildren do
			drillDownSetHighLow(firstChildren[i])
		end
	end

	local function recalculate()
		internalChange = true

		local percentFrame = 0
		if scrollbar.Position.Y.Scale > 0 then
			if scrollbar.Visible then
				percentFrame = scrollbar.Position.Y.Scale/((scrollTrack.AbsoluteSize.Y - scrollbar.AbsoluteSize.Y)/scrollTrack.AbsoluteSize.Y)
			else
				percentFrame = 0
			end
		end
		if percentFrame > 0.99 then percentFrame = 1 end

		local hiddenYAmount = (scrollingFrame.AbsoluteSize.Y - (highY - lowY)) * percentFrame
		
		local guiChildren = scrollingFrame:GetChildren()
		for i = 1, #guiChildren do
			if guiChildren[i] ~= controlFrame then
				guiChildren[i].Position = UDim2.new(guiChildren[i].Position.X.Scale,guiChildren[i].Position.X.Offset,
					0, math.ceil(guiChildren[i].AbsolutePosition.Y) - math.ceil(lowY) + hiddenYAmount)
			end
		end

		lowY = nil
		highY = nil
		resetHighLow()
		internalChange = false
	end

	local function setSliderSizeAndPosition()
		if not highY or not lowY then return end

		local totalYSpan = math.abs(highY - lowY)
		if totalYSpan == 0 then
			scrollbar.Visible = false
			scrollDownButton.Visible = false
			scrollUpButton.Visible = false

			if dragCon then dragCon:disconnect() dragCon = nil end
			if upCon then upCon:disconnect() upCon = nil end
			return
		end

		local percentShown = scrollingFrame.AbsoluteSize.Y/totalYSpan
		if percentShown >= 1 then
			scrollbar.Visible = false
			scrollDownButton.Visible = false
			scrollUpButton.Visible = false
			recalculate()
		else
			scrollbar.Visible = true
			scrollDownButton.Visible = true
			scrollUpButton.Visible = true

			scrollbar.Size = UDim2.new(scrollbar.Size.X.Scale,scrollbar.Size.X.Offset,percentShown,0)
		end

		local percentPosition = (scrollingFrame.AbsolutePosition.Y - lowY)/totalYSpan
		scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,percentPosition,-scrollbar.AbsoluteSize.X/2)

		if scrollbar.AbsolutePosition.y < scrollTrack.AbsolutePosition.y then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,0,0)
		end

		if (scrollbar.AbsolutePosition.y + scrollbar.AbsoluteSize.Y) > (scrollTrack.AbsolutePosition.y + scrollTrack.AbsoluteSize.y) then
			local relativeSize = scrollbar.AbsoluteSize.Y/scrollTrack.AbsoluteSize.Y
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,1 - relativeSize,0)
		end
	end
	
	local buttonScrollAmountPixels = 7
	local reentrancyGuardScrollUp = false
	local function doScrollUp()
		if reentrancyGuardScrollUp then return end
		
		reentrancyGuardScrollUp = true
			if positionScrollBar(0,scrollbar.AbsolutePosition.Y - buttonScrollAmountPixels,0) then
				recalculate()
			end
		reentrancyGuardScrollUp = false
	end
	
	local reentrancyGuardScrollDown = false
	local function doScrollDown()
		if reentrancyGuardScrollDown then return end
		
		reentrancyGuardScrollDown = true
			if positionScrollBar(0,scrollbar.AbsolutePosition.Y + buttonScrollAmountPixels,0) then
				recalculate()
			end
		reentrancyGuardScrollDown = false
	end

	local function scrollUp(mouseYPos)
		if scrollUpButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local upCon
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				upCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollUp()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollUp()
				if mouseYPos and mouseYPos > scrollbar.AbsolutePosition.y then
					break
				end
				if not scrollUpButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end

	local function scrollDown(mouseYPos)
		if scrollDownButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local downCon
			downCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				downCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollDown()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollDown()
				if mouseYPos and mouseYPos < (scrollbar.AbsolutePosition.y + scrollbar.AbsoluteSize.x) then
					break
				end
				if not scrollDownButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end
	
	scrollbar.MouseButton1Down:connect(function(x,y)
		if scrollbar.Active then
			scrollStamp = tick()
			local mouseOffset = y - scrollbar.AbsolutePosition.y
			if dragCon then dragCon:disconnect() dragCon = nil end
			if upCon then upCon:disconnect() upCon = nil end
			local prevY = y
			local reentrancyGuardMouseScroll = false
			dragCon = mouseDrag.MouseMoved:connect(function(x,y)
				if reentrancyGuardMouseScroll then return end
				
				reentrancyGuardMouseScroll = true
					if positionScrollBar(x,y,mouseOffset) then
						recalculate()
					end
				reentrancyGuardMouseScroll = false
				
			end)
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				dragCon:disconnect(); dragCon = nil
				upCon:disconnect(); drag = nil
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
		end
	end)

	local scrollMouseCount = 0

	scrollUpButton.MouseButton1Down:connect(function()
		scrollUp()
	end)
	scrollUpButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)

	scrollDownButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollDownButton.MouseButton1Down:connect(function()
		 scrollDown()
	end)
		
	scrollbar.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	
	local function heightCheck(instance)
		if highY and (instance.AbsolutePosition.Y + instance.AbsoluteSize.Y) > highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		elseif not highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		end
		setSliderSizeAndPosition()
	end
	
	local function highLowRecheck()
		local oldLowY = lowY
		local oldHighY = highY
		lowY = nil
		highY = nil
		resetHighLow()

		if (lowY ~= oldLowY) or (highY ~= oldHighY) then
			setSliderSizeAndPosition()
		end
	end

	local function descendantChanged(this, prop)
		if internalChange then return end
		if not this.Visible then return end

		if prop == "Size" or prop == "Position" then
			wait()
			highLowRecheck()
		end
	end

	scrollingFrame.DescendantAdded:connect(function(instance)
		if not instance:IsA("GuiObject") then return end

		if instance.Visible then
			wait() -- wait a heartbeat for sizes to reconfig
			highLowRecheck()
		end

		descendantsChangeConMap[instance] = instance.Changed:connect(function(prop) descendantChanged(instance, prop) end)
	end)

	scrollingFrame.DescendantRemoving:connect(function(instance)
		if not instance:IsA("GuiObject") then return end
		if descendantsChangeConMap[instance] then
			descendantsChangeConMap[instance]:disconnect()
			descendantsChangeConMap[instance] = nil
		end
		wait() -- wait a heartbeat for sizes to reconfig
		highLowRecheck()
	end)
	
	scrollingFrame.Changed:connect(function(prop)
		if prop == "AbsoluteSize" then
			if not highY or not lowY then return end

			highLowRecheck()
			setSliderSizeAndPosition()
		end
	end)

	return scrollingFrame, controlFrame
end

t.CreateScrollingFrame = function(orderList,scrollStyle)
	local frame = Instance.new("Frame")
	frame.Name = "ScrollingFrame"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1,0,1,0)
	
	local scrollUpButton = Instance.new("ImageButton")
	scrollUpButton.Name = "ScrollUpButton"
	scrollUpButton.BackgroundTransparency = 1
	scrollUpButton.Image = "rbxasset://textures/ui/scrollbuttonUp.png"
	scrollUpButton.Size = UDim2.new(0,17,0,17) 

	
	local scrollDownButton = Instance.new("ImageButton")
	scrollDownButton.Name = "ScrollDownButton"
	scrollDownButton.BackgroundTransparency = 1
	scrollDownButton.Image = "rbxasset://textures/ui/scrollbuttonDown.png"
	scrollDownButton.Size = UDim2.new(0,17,0,17) 
	
	local scrollbar = Instance.new("ImageButton")
	scrollbar.Name = "ScrollBar"
	scrollbar.Image = "rbxasset://textures/ui/scrollbar.png"
	scrollbar.BackgroundTransparency = 1
	scrollbar.Size = UDim2.new(0, 18, 0, 150)

	local scrollStamp = 0
		
	local scrollDrag = Instance.new("ImageButton")
	scrollDrag.Image = "http://www.roblox.com/asset/?id=61367186"
	scrollDrag.Size = UDim2.new(1, 0, 0, 16)
	scrollDrag.BackgroundTransparency = 1
	scrollDrag.Name = "ScrollDrag"
	scrollDrag.Active = true
	scrollDrag.Parent = scrollbar
	
	local mouseDrag = Instance.new("ImageButton")
	mouseDrag.Active = false
	mouseDrag.Size = UDim2.new(1.5, 0, 1.5, 0)
	mouseDrag.AutoButtonColor = false
	mouseDrag.BackgroundTransparency = 1
	mouseDrag.Name = "mouseDrag"
	mouseDrag.Position = UDim2.new(-0.25, 0, -0.25, 0)
	mouseDrag.ZIndex = 10

	local style = "simple"
	if scrollStyle and tostring(scrollStyle) then
		style = scrollStyle
	end
	
	local scrollPosition = 1
	local rowSize = 0
	local howManyDisplayed = 0
		
	local layoutGridScrollBar = function()
		howManyDisplayed = 0
		local guiObjects = {}
		if orderList then
			for i, child in ipairs(orderList) do
				if child.Parent == frame then
					table.insert(guiObjects, child)
				end
			end
		else
			local children = frame:GetChildren()
			if children then
				for i, child in ipairs(children) do 
					if child:IsA("GuiObject") then
						table.insert(guiObjects, child)
					end
				end
			end
		end
		if #guiObjects == 0 then
			scrollUpButton.Active = false
			scrollDownButton.Active = false
			scrollDrag.Active = false
			scrollPosition = 1
			return
		end

		if scrollPosition > #guiObjects then
			scrollPosition = #guiObjects
		end
		
		if scrollPosition < 1 then scrollPosition = 1 end
		
		local totalPixelsY = frame.AbsoluteSize.Y
		local pixelsRemainingY = frame.AbsoluteSize.Y
		
		local totalPixelsX  = frame.AbsoluteSize.X
		
		local xCounter = 0
		local rowSizeCounter = 0
		local setRowSize = true

		local pixelsBelowScrollbar = 0
		local pos = #guiObjects
		
		local currentRowY = 0

		pos = scrollPosition
		--count up from current scroll position to fill out grid
		while pos <= #guiObjects and pixelsBelowScrollbar < totalPixelsY do
			xCounter = xCounter + guiObjects[pos].AbsoluteSize.X
			--previous pos was the end of a row
			if xCounter >= totalPixelsX then
				pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
				currentRowY = 0
				xCounter = guiObjects[pos].AbsoluteSize.X
			end
			if guiObjects[pos].AbsoluteSize.Y > currentRowY then
				currentRowY = guiObjects[pos].AbsoluteSize.Y
			end
			pos = pos + 1
		end
		--Count wherever current row left off
		pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
		currentRowY = 0
		
		pos = scrollPosition - 1
		xCounter = 0
		
		--objects with varying X,Y dimensions can rarely cause minor errors
		--rechecking every new scrollPosition is necessary to avoid 100% of errors
		
		--count backwards from current scrollPosition to see if we can add more rows
		while pixelsBelowScrollbar + currentRowY < totalPixelsY and pos >= 1 do
			xCounter = xCounter + guiObjects[pos].AbsoluteSize.X
			rowSizeCounter = rowSizeCounter + 1
			if xCounter >= totalPixelsX then
				rowSize = rowSizeCounter - 1
				rowSizeCounter = 0
				xCounter = guiObjects[pos].AbsoluteSize.X
				if pixelsBelowScrollbar + currentRowY <= totalPixelsY then
					--It fits, so back up our scroll position
					pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
					if scrollPosition <= rowSize then
						scrollPosition = 1 
						break
					else
						scrollPosition = scrollPosition - rowSize
					end
					currentRowY = 0
				else
					break
				end
			end
			
			if guiObjects[pos].AbsoluteSize.Y > currentRowY then
				currentRowY = guiObjects[pos].AbsoluteSize.Y
			end

			pos = pos - 1
		end
		
		--Do check last time if pos = 0
		if (pos == 0) and (pixelsBelowScrollbar + currentRowY <= totalPixelsY) then
			scrollPosition = 1
		end

		xCounter = 0
		--pos = scrollPosition
		rowSizeCounter = 0
		setRowSize = true
		local lastChildSize = 0
		
		local xOffset,yOffset = 0
		if guiObjects[1] then
			yOffset = math.ceil(math.floor(math.fmod(totalPixelsY,guiObjects[1].AbsoluteSize.X))/2)
			xOffset = math.ceil(math.floor(math.fmod(totalPixelsX,guiObjects[1].AbsoluteSize.Y))/2)
		end
		
		for i, child in ipairs(guiObjects) do
			if i < scrollPosition then
				--print("Hiding " .. child.Name)
				child.Visible = false
			else
				if pixelsRemainingY < 0 then
					--print("Out of Space " .. child.Name)
					child.Visible = false
				else
					--print("Laying out " .. child.Name)
					--GuiObject
					if setRowSize then rowSizeCounter = rowSizeCounter + 1 end
					if xCounter + child.AbsoluteSize.X >= totalPixelsX then
						if setRowSize then
							rowSize = rowSizeCounter - 1
							setRowSize = false
						end
						xCounter = 0
						pixelsRemainingY = pixelsRemainingY - child.AbsoluteSize.Y
					end
					child.Position = UDim2.new(child.Position.X.Scale,xCounter + xOffset, 0, totalPixelsY - pixelsRemainingY + yOffset)
					xCounter = xCounter + child.AbsoluteSize.X
					child.Visible = ((pixelsRemainingY - child.AbsoluteSize.Y) >= 0)
					if child.Visible then
						howManyDisplayed = howManyDisplayed + 1
					end
					lastChildSize = child.AbsoluteSize				
				end
			end
		end

		scrollUpButton.Active = (scrollPosition > 1)
		if lastChildSize == 0 then 
			scrollDownButton.Active = false
		else
			scrollDownButton.Active = ((pixelsRemainingY - lastChildSize.Y) < 0)
		end
		scrollDrag.Active = #guiObjects > howManyDisplayed
		scrollDrag.Visible = scrollDrag.Active
	end



	local layoutSimpleScrollBar = function()
		local guiObjects = {}	
		howManyDisplayed = 0
		
		if orderList then
			for i, child in ipairs(orderList) do
				if child.Parent == frame then
					table.insert(guiObjects, child)
				end
			end
		else
			local children = frame:GetChildren()
			if children then
				for i, child in ipairs(children) do 
					if child:IsA("GuiObject") then
						table.insert(guiObjects, child)
					end
				end
			end
		end
		if #guiObjects == 0 then
			scrollUpButton.Active = false
			scrollDownButton.Active = false
			scrollDrag.Active = false
			scrollPosition = 1
			return
		end

		if scrollPosition > #guiObjects then
			scrollPosition = #guiObjects
		end
		
		local totalPixels = frame.AbsoluteSize.Y
		local pixelsRemaining = frame.AbsoluteSize.Y

		local pixelsBelowScrollbar = 0
		local pos = #guiObjects
		while pixelsBelowScrollbar < totalPixels and pos >= 1 do
			if pos >= scrollPosition then
				pixelsBelowScrollbar = pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y
			else
				if pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y <= totalPixels then
					--It fits, so back up our scroll position
					pixelsBelowScrollbar = pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y
					if scrollPosition <= 1 then
						scrollPosition = 1
						break
					else
						--local ("Backing up ScrollPosition from -- " ..scrollPosition)
						scrollPosition = scrollPosition - 1
					end
				else
					break
				end
			end
			pos = pos - 1
		end

		pos = scrollPosition
		for i, child in ipairs(guiObjects) do
			if i < scrollPosition then
				--print("Hiding " .. child.Name)
				child.Visible = false
			else
				if pixelsRemaining < 0 then
					--print("Out of Space " .. child.Name)
					child.Visible = false
				else
					--print("Laying out " .. child.Name)
					--GuiObject
					child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
					pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y
					if  (pixelsRemaining >= 0) then
						child.Visible = true
						howManyDisplayed = howManyDisplayed + 1
					else
						child.Visible = false
					end		
				end
			end
		end
		scrollUpButton.Active = (scrollPosition > 1)
		scrollDownButton.Active = (pixelsRemaining < 0)
		scrollDrag.Active = #guiObjects > howManyDisplayed
		scrollDrag.Visible = scrollDrag.Active
	end
	
		
	local moveDragger = function()	
		local guiObjects = 0
		local children = frame:GetChildren()
		if children then
			for i, child in ipairs(children) do 
				if child:IsA("GuiObject") then
					guiObjects = guiObjects + 1
				end
			end
		end
		
		if not scrollDrag.Parent then return end
		
		local dragSizeY = scrollDrag.Parent.AbsoluteSize.y * (1/(guiObjects - howManyDisplayed + 1))
		if dragSizeY < 16 then dragSizeY = 16 end
		scrollDrag.Size = UDim2.new(scrollDrag.Size.X.Scale,scrollDrag.Size.X.Offset,scrollDrag.Size.Y.Scale,dragSizeY)

		local relativeYPos = (scrollPosition - 1)/(guiObjects - (howManyDisplayed))
		if relativeYPos > 1 then relativeYPos = 1
		elseif relativeYPos < 0 then relativeYPos = 0 end
		local absYPos = 0
		
		if relativeYPos ~= 0 then
			absYPos = (relativeYPos * scrollbar.AbsoluteSize.y) - (relativeYPos * scrollDrag.AbsoluteSize.y)
		end
		
		scrollDrag.Position = UDim2.new(scrollDrag.Position.X.Scale,scrollDrag.Position.X.Offset,scrollDrag.Position.Y.Scale,absYPos)
	end

	local reentrancyGuard = false
	local recalculate = function()
		if reentrancyGuard then
			return
		end
		reentrancyGuard = true
		wait()
		local success, err = nil
		if style == "grid" then
			success, err = pcall(function() layoutGridScrollBar() end)
		elseif style == "simple" then
			success, err = pcall(function() layoutSimpleScrollBar() end)
		end
		if not success then print(err) end
		moveDragger()
		reentrancyGuard = false
	end
	
	local doScrollUp = function()
		scrollPosition = (scrollPosition) - rowSize
		if scrollPosition < 1 then scrollPosition = 1 end
		recalculate(nil)
	end
	
	local doScrollDown = function()
		scrollPosition = (scrollPosition) + rowSize
		recalculate(nil)
	end

	local scrollUp = function(mouseYPos)
		if scrollUpButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local upCon
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				upCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollUp()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollUp()
				if mouseYPos and mouseYPos > scrollDrag.AbsolutePosition.y then
					break
				end
				if not scrollUpButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end

	local scrollDown = function(mouseYPos)
		if scrollDownButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local downCon
			downCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				downCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollDown()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollDown()
				if mouseYPos and mouseYPos < (scrollDrag.AbsolutePosition.y + scrollDrag.AbsoluteSize.x) then
					break
				end
				if not scrollDownButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end
	
	local y = 0
	scrollDrag.MouseButton1Down:connect(function(x,y)
		if scrollDrag.Active then
			scrollStamp = tick()
			local mouseOffset = y - scrollDrag.AbsolutePosition.y
			local dragCon
			local upCon
			dragCon = mouseDrag.MouseMoved:connect(function(x,y)
				local barAbsPos = scrollbar.AbsolutePosition.y
				local barAbsSize = scrollbar.AbsoluteSize.y
				
				local dragAbsSize = scrollDrag.AbsoluteSize.y
				local barAbsOne = barAbsPos + barAbsSize - dragAbsSize
				y = y - mouseOffset
				y = y < barAbsPos and barAbsPos or y > barAbsOne and barAbsOne or y
				y = y - barAbsPos
				
				local guiObjects = 0
				local children = frame:GetChildren()
				if children then
					for i, child in ipairs(children) do 
						if child:IsA("GuiObject") then
							guiObjects = guiObjects + 1
						end
					end
				end
				
				local doublePercent = y/(barAbsSize-dragAbsSize)
				local rowDiff = rowSize
				local totalScrollCount = guiObjects - (howManyDisplayed - 1)
				local newScrollPosition = math.floor((doublePercent * totalScrollCount) + 0.5) + rowDiff
				if newScrollPosition < scrollPosition then
					rowDiff = -rowDiff
				end
				
				if newScrollPosition < 1 then
					newScrollPosition = 1
				end
				
				scrollPosition = newScrollPosition
				recalculate(nil)
			end)
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				dragCon:disconnect(); dragCon = nil
				upCon:disconnect(); drag = nil
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
		end
	end)

	local scrollMouseCount = 0

	scrollUpButton.MouseButton1Down:connect(
		function()
			scrollUp()
		end)
	scrollUpButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)


	scrollDownButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollDownButton.MouseButton1Down:connect(
		function()
			scrollDown()	
		end)
		
	scrollbar.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollbar.MouseButton1Down:connect(
		function(x,y)
			if y > (scrollDrag.AbsoluteSize.y + scrollDrag.AbsolutePosition.y) then
				scrollDown(y)
			elseif y < (scrollDrag.AbsolutePosition.y) then
				scrollUp(y)
			end
		end)


	frame.ChildAdded:connect(function()
		recalculate(nil)
	end)

	frame.ChildRemoved:connect(function()
		recalculate(nil)
	end)
	
	frame.Changed:connect(
		function(prop)
			if prop == "AbsoluteSize" then
				--Wait a heartbeat for it to sync in
				recalculate(nil)
			end
		end)
	frame.AncestryChanged:connect(function() recalculate(nil) end)

	return frame, scrollUpButton, scrollDownButton, recalculate, scrollbar
end
local function binaryGrow(min, max, fits)
	if min > max then
		return min
	end
	local biggestLegal = min

	while min <= max do
		local mid = min + math.floor((max - min) / 2)
		if fits(mid) and (biggestLegal == nil or biggestLegal < mid) then
			biggestLegal = mid
			
			--Try growing
			min = mid + 1
		else
			--Doesn't fit, shrink
			max = mid - 1
		end
	end
	return biggestLegal
end


local function binaryShrink(min, max, fits)
	if min > max then
		return min
	end
	local smallestLegal = max

	while min <= max do
		local mid = min + math.floor((max - min) / 2)
		if fits(mid) and (smallestLegal == nil or smallestLegal > mid) then
			smallestLegal = mid
			
			--It fits, shrink
			max = mid - 1			
		else
			--Doesn't fit, grow
			min = mid + 1
		end
	end
	return smallestLegal
end


local function getGuiOwner(instance)
	while instance ~= nil do
		if instance:IsA("ScreenGui") or instance:IsA("BillboardGui")  then
			return instance
		end
		instance = instance.Parent
	end
	return nil
end

t.AutoTruncateTextObject = function(textLabel)
	local text = textLabel.Text

	local fullLabel = textLabel:Clone()
	fullLabel.Name = "Full" .. textLabel.Name 
	fullLabel.BorderSizePixel = 0
	fullLabel.BackgroundTransparency = 0
	fullLabel.Text = text
	fullLabel.TextXAlignment = Enum.TextXAlignment.Center
	fullLabel.Position = UDim2.new(0,-3,0,0)
	fullLabel.Size = UDim2.new(0,100,1,0)
	fullLabel.Visible = false
	fullLabel.Parent = textLabel

	local shortText = nil
	local mouseEnterConnection = nil
	local mouseLeaveConnection= nil

	local checkForResize = function()
		if getGuiOwner(textLabel) == nil then
			return
		end
		textLabel.Text = text
		if textLabel.TextFits then 
			--Tear down the rollover if it is active
			if mouseEnterConnection then
				mouseEnterConnection:disconnect()
				mouseEnterConnection = nil
			end
			if mouseLeaveConnection then
				mouseLeaveConnection:disconnect()
				mouseLeaveConnection = nil
			end
		else
			local len = string.len(text)
			textLabel.Text = text .. "~"

			--Shrink the text
			local textSize = binaryGrow(0, len, 
				function(pos)
					if pos == 0 then
						textLabel.Text = "~"
					else
						textLabel.Text = string.sub(text, 1, pos) .. "~"
					end
					return textLabel.TextFits
				end)
			shortText = string.sub(text, 1, textSize) .. "~"
			textLabel.Text = shortText
			
			--Make sure the fullLabel fits
			if not fullLabel.TextFits then
				--Already too small, grow it really bit to start
				fullLabel.Size = UDim2.new(0, 10000, 1, 0)
			end
			
			--Okay, now try to binary shrink it back down
			local fullLabelSize = binaryShrink(textLabel.AbsoluteSize.X,fullLabel.AbsoluteSize.X, 
				function(size)
					fullLabel.Size = UDim2.new(0, size, 1, 0)
					return fullLabel.TextFits
				end)
			fullLabel.Size = UDim2.new(0,fullLabelSize+6,1,0)

			--Now setup the rollover effects, if they are currently off
			if mouseEnterConnection == nil then
				mouseEnterConnection = textLabel.MouseEnter:connect(
					function()
						fullLabel.ZIndex = textLabel.ZIndex + 1
						fullLabel.Visible = true
						--textLabel.Text = ""
					end)
			end
			if mouseLeaveConnection == nil then
				mouseLeaveConnection = textLabel.MouseLeave:connect(
					function()
						fullLabel.Visible = false
						--textLabel.Text = shortText
					end)
			end
		end
	end
	textLabel.AncestryChanged:connect(checkForResize)
	textLabel.Changed:connect(
		function(prop) 
			if prop == "AbsoluteSize" then 
				checkForResize() 	
			end 
		end)

	checkForResize()

	local function changeText(newText)
		text = newText
		fullLabel.Text = text
		checkForResize()
	end

	return textLabel, changeText
end

local function TransitionTutorialPages(fromPage, toPage, transitionFrame, currentPageValue)	
	if fromPage then
		fromPage.Visible = false
		if transitionFrame.Visible == false then
			transitionFrame.Size = fromPage.Size
			transitionFrame.Position = fromPage.Position
		end
	else
		if transitionFrame.Visible == false then
			transitionFrame.Size = UDim2.new(0.0,50,0.0,50)
			transitionFrame.Position = UDim2.new(0.5,-25,0.5,-25)
		end
	end
	transitionFrame.Visible = true
	currentPageValue.Value = nil

	local newsize, newPosition
	if toPage then
		--Make it visible so it resizes
		toPage.Visible = true

		newSize = toPage.Size
		newPosition = toPage.Position

		toPage.Visible = false
	else
		newSize = UDim2.new(0.0,50,0.0,50)
		newPosition = UDim2.new(0.5,-25,0.5,-25)
	end
	transitionFrame:TweenSizeAndPosition(newSize, newPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.3, true,
		function(state)
			if state == Enum.TweenStatus.Completed then
				transitionFrame.Visible = false
				if toPage then
					toPage.Visible = true
					currentPageValue.Value = toPage
				end
			end
		end)
end

t.CreateTutorial = function(name, tutorialKey, createButtons)
	local frame = Instance.new("Frame")
	frame.Name = "Tutorial-" .. name
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(0.6, 0, 0.6, 0)
	frame.Position = UDim2.new(0.2, 0, 0.2, 0)

	local transitionFrame = Instance.new("Frame")
	transitionFrame.Name = "TransitionFrame"
	transitionFrame.Style = Enum.FrameStyle.RobloxRound
	transitionFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
	transitionFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
	transitionFrame.Visible = false
	transitionFrame.Parent = frame

	local currentPageValue = Instance.new("ObjectValue")
	currentPageValue.Name = "CurrentTutorialPage"
	currentPageValue.Value = nil
	currentPageValue.Parent = frame

	local boolValue = Instance.new("BoolValue")
	boolValue.Name = "Buttons"
	boolValue.Value = createButtons
	boolValue.Parent = frame

	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.BackgroundTransparency = 1
	pages.Size = UDim2.new(1,0,1,0)
	pages.Parent = frame

	local function getVisiblePageAndHideOthers()
		local visiblePage = nil
		local children = pages:GetChildren()
		if children then
			for i,child in ipairs(children) do
				if child.Visible then
					if visiblePage then
						child.Visible = false
					else
						visiblePage = child
					end
				end
			end
		end
		return visiblePage
	end

	local showTutorial = function(alwaysShow)
		if alwaysShow or UserSettings().GameSettings:GetTutorialState(tutorialKey) == false then
			print("Showing tutorial-",tutorialKey)
			local currentTutorialPage = getVisiblePageAndHideOthers()

			local firstPage = pages:FindFirstChild("TutorialPage1")
			if firstPage then
				TransitionTutorialPages(currentTutorialPage, firstPage, transitionFrame, currentPageValue)	
			else
				error("Could not find TutorialPage1")
			end
		end
	end

	local dismissTutorial = function()
		local currentTutorialPage = getVisiblePageAndHideOthers()

		if currentTutorialPage then
			TransitionTutorialPages(currentTutorialPage, nil, transitionFrame, currentPageValue)
		end

		UserSettings().GameSettings:SetTutorialState(tutorialKey, true)
	end

	local gotoPage = function(pageNum)
		local page = pages:FindFirstChild("TutorialPage" .. pageNum)
		local currentTutorialPage = getVisiblePageAndHideOthers()
		TransitionTutorialPages(currentTutorialPage, page, transitionFrame, currentPageValue)
	end

	return frame, showTutorial, dismissTutorial, gotoPage
end 

local function CreateBasicTutorialPage(name, handleResize, skipTutorial, giveDoneButton)
	local frame = Instance.new("Frame")
	frame.Name = "TutorialPage"
	frame.Style = Enum.FrameStyle.RobloxRound
	frame.Size = UDim2.new(0.6, 0, 0.6, 0)
	frame.Position = UDim2.new(0.2, 0, 0.2, 0)
	frame.Visible = false
	
	local frameHeader = Instance.new("TextLabel")
	frameHeader.Name = "Header"
	frameHeader.Text = name
	frameHeader.BackgroundTransparency = 1
	frameHeader.FontSize = Enum.FontSize.Size24
	frameHeader.Font = Enum.Font.ArialBold
	frameHeader.TextColor3 = Color3.new(1,1,1)
	frameHeader.TextXAlignment = Enum.TextXAlignment.Center
	frameHeader.TextWrap = true
	frameHeader.Size = UDim2.new(1,-55, 0, 22)
	frameHeader.Position = UDim2.new(0,0,0,0)
	frameHeader.Parent = frame

	local skipButton = Instance.new("ImageButton")
	skipButton.Name = "SkipButton"
	skipButton.AutoButtonColor = false
	skipButton.BackgroundTransparency = 1
	skipButton.Image = "rbxasset://textures/ui/closeButton.png"
	skipButton.MouseButton1Click:connect(function()
		skipTutorial()
	end)
	skipButton.MouseEnter:connect(function()
		skipButton.Image = "rbxasset://textures/ui/closeButton_dn.png"
	end)
	skipButton.MouseLeave:connect(function()
		skipButton.Image = "rbxasset://textures/ui/closeButton.png"
	end)
	skipButton.Size = UDim2.new(0, 25, 0, 25)
	skipButton.Position = UDim2.new(1, -25, 0, 0)
	skipButton.Parent = frame
	
	
	if giveDoneButton then
		local doneButton = Instance.new("TextButton")
		doneButton.Name = "DoneButton"
		doneButton.Style = Enum.ButtonStyle.RobloxButtonDefault
		doneButton.Text = "Done"
		doneButton.TextColor3 = Color3.new(1,1,1)
		doneButton.Font = Enum.Font.ArialBold
		doneButton.FontSize = Enum.FontSize.Size18
		doneButton.Size = UDim2.new(0,100,0,50)
		doneButton.Position = UDim2.new(0.5,-50,1,-50)
		
		if skipTutorial then
			doneButton.MouseButton1Click:connect(function() skipTutorial() end)
		end
		
		doneButton.Parent = frame
	end

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "ContentFrame"
	innerFrame.BackgroundTransparency = 1
	innerFrame.Position = UDim2.new(0,0,0,25)
	innerFrame.Parent = frame

	local nextButton = Instance.new("TextButton")
	nextButton.Name = "NextButton"
	nextButton.Text = "Next"
	nextButton.TextColor3 = Color3.new(1,1,1)
	nextButton.Font = Enum.Font.Arial
	nextButton.FontSize = Enum.FontSize.Size18
	nextButton.Style = Enum.ButtonStyle.RobloxButtonDefault
	nextButton.Size = UDim2.new(0,80, 0, 32)
	nextButton.Position = UDim2.new(0.5, 5, 1, -32)
	nextButton.Active = false
	nextButton.Visible = false
	nextButton.Parent = frame

	local prevButton = Instance.new("TextButton")
	prevButton.Name = "PrevButton"
	prevButton.Text = "Previous"
	prevButton.TextColor3 = Color3.new(1,1,1)
	prevButton.Font = Enum.Font.Arial
	prevButton.FontSize = Enum.FontSize.Size18
	prevButton.Style = Enum.ButtonStyle.RobloxButton
	prevButton.Size = UDim2.new(0,80, 0, 32)
	prevButton.Position = UDim2.new(0.5, -85, 1, -32)
	prevButton.Active = false
	prevButton.Visible = false
	prevButton.Parent = frame

	if giveDoneButton then
		innerFrame.Size = UDim2.new(1,0,1,-75)
	else
		innerFrame.Size = UDim2.new(1,0,1,-22)
	end

	local parentConnection = nil

	local function basicHandleResize()
		if frame.Visible and frame.Parent then
			local maxSize = math.min(frame.Parent.AbsoluteSize.X, frame.Parent.AbsoluteSize.Y)
			handleResize(200,maxSize)
		end
	end

	frame.Changed:connect(
		function(prop)
			if prop == "Parent" then
				if parentConnection ~= nil then
					parentConnection:disconnect()
					parentConnection = nil
				end
				if frame.Parent and frame.Parent:IsA("GuiObject") then
					parentConnection = frame.Parent.Changed:connect(
						function(parentProp)
							if parentProp == "AbsoluteSize" then
								wait()
								basicHandleResize()
							end
						end)
					basicHandleResize()
				end
			end

			if prop == "Visible" then 
				basicHandleResize()
			end
		end)

	return frame, innerFrame
end

t.CreateTextTutorialPage = function(name, text, skipTutorialFunc)
	local frame = nil
	local contentFrame = nil

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1,1,1)
	textLabel.Text = text
	textLabel.TextWrap = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Font = Enum.Font.Arial
	textLabel.FontSize = Enum.FontSize.Size14
	textLabel.Size = UDim2.new(1,0,1,0)

	local function handleResize(minSize, maxSize)
		size = binaryShrink(minSize, maxSize,
			function(size)
				frame.Size = UDim2.new(0, size, 0, size)
				return textLabel.TextFits
			end)
		frame.Size = UDim2.new(0, size, 0, size)
		frame.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
	end

	frame, contentFrame = CreateBasicTutorialPage(name, handleResize, skipTutorialFunc)
	textLabel.Parent = contentFrame

	return frame
end

t.CreateImageTutorialPage = function(name, imageAsset, x, y, skipTutorialFunc, giveDoneButton)
	local frame = nil
	local contentFrame = nil

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = imageAsset
	imageLabel.Size = UDim2.new(0,x,0,y)
	imageLabel.Position = UDim2.new(0.5,-x/2,0.5,-y/2)

	local function handleResize(minSize, maxSize)
		size = binaryShrink(minSize, maxSize,
			function(size)
				return size >= x and size >= y
			end)
		if size >= x and size >= y then
			imageLabel.Size = UDim2.new(0,x, 0,y)
			imageLabel.Position = UDim2.new(0.5,-x/2, 0.5, -y/2)
		else
			if x > y then
				--X is limiter, so 
				imageLabel.Size = UDim2.new(1,0,y/x,0)
				imageLabel.Position = UDim2.new(0,0, 0.5 - (y/x)/2, 0)
			else
				--Y is limiter
				imageLabel.Size = UDim2.new(x/y,0,1, 0)
				imageLabel.Position = UDim2.new(0.5-(x/y)/2, 0, 0, 0)
			end
		end
		size = size + 50
		frame.Size = UDim2.new(0, size, 0, size)
		frame.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
	end

	frame, contentFrame = CreateBasicTutorialPage(name, handleResize, skipTutorialFunc, giveDoneButton)
	imageLabel.Parent = contentFrame

	return frame
end

t.AddTutorialPage = function(tutorial, tutorialPage)
	local transitionFrame = tutorial.TransitionFrame
	local currentPageValue = tutorial.CurrentTutorialPage

	if not tutorial.Buttons.Value then
		tutorialPage.NextButton.Parent = nil
		tutorialPage.PrevButton.Parent = nil
	end

	local children = tutorial.Pages:GetChildren()
	if children and #children > 0 then
		tutorialPage.Name = "TutorialPage" .. (#children+1)
		local previousPage = children[#children]
		if not previousPage:IsA("GuiObject") then
			error("All elements under Pages must be GuiObjects")
		end

		if tutorial.Buttons.Value then
			if previousPage.NextButton.Active then
				error("NextButton already Active on previousPage, please only add pages with RbxGui.AddTutorialPage function")
			end
			previousPage.NextButton.MouseButton1Click:connect(
				function()
					TransitionTutorialPages(previousPage, tutorialPage, transitionFrame, currentPageValue)
				end)
			previousPage.NextButton.Active = true
			previousPage.NextButton.Visible = true

			if tutorialPage.PrevButton.Active then
				error("PrevButton already Active on tutorialPage, please only add pages with RbxGui.AddTutorialPage function")
			end
			tutorialPage.PrevButton.MouseButton1Click:connect(
				function()
					TransitionTutorialPages(tutorialPage, previousPage, transitionFrame, currentPageValue)
				end)
			tutorialPage.PrevButton.Active = true
			tutorialPage.PrevButton.Visible = true
		end

		tutorialPage.Parent = tutorial.Pages
	else
		--First child
		tutorialPage.Name = "TutorialPage1"
		tutorialPage.Parent = tutorial.Pages
	end
end 

t.CreateSetPanel = function(userIdsForSets, objectSelected, dialogClosed, size, position, showAdminCategories, useAssetVersionId)

	if not userIdsForSets then
		error("CreateSetPanel: userIdsForSets (first arg) is nil, should be a table of number ids")
	end
	if type(userIdsForSets) ~= "table" and type(userIdsForSets) ~= "userdata" then
		error("CreateSetPanel: userIdsForSets (first arg) is of type " ..type(userIdsForSets) .. ", should be of type table or userdata")
	end
	if not objectSelected then
		error("CreateSetPanel: objectSelected (second arg) is nil, should be a callback function!")
	end
	if type(objectSelected) ~= "function" then
		error("CreateSetPanel: objectSelected (second arg) is of type " .. type(objectSelected) .. ", should be of type function!")
	end
	if dialogClosed and type(dialogClosed) ~= "function" then
		error("CreateSetPanel: dialogClosed (third arg) is of type " .. type(dialogClosed) .. ", should be of type function!")
	end
	
	if showAdminCategories == nil then -- by default, don't show beta sets
		showAdminCategories = false
	end

	local arrayPosition = 1
	local insertButtons = {}
	local insertButtonCons = {}
	local contents = nil
	local setGui = nil

	-- used for water selections
	local waterForceDirection = "NegX"
	local waterForce = "None"
	local waterGui, waterTypeChangedEvent = nil
	
	local Data = {}
	Data.CurrentCategory = nil
	Data.Category = {}
	local SetCache = {}
	
	local userCategoryButtons = nil
	
	local buttonWidth = 64
	local buttonHeight = buttonWidth
	
	local SmallThumbnailUrl = nil
	local LargeThumbnailUrl = nil
	local BaseUrl = game:GetService("ContentProvider").BaseUrl:lower()
	
	if useAssetVersionId then
		LargeThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=420&ht=420&assetversionid="
		SmallThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=75&ht=75&assetversionid="
	else
		LargeThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=420&ht=420&aid="
		SmallThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=75&ht=75&aid="
	end
		
	local function drillDownSetZIndex(parent, index)
		local children = parent:GetChildren()
		for i = 1, #children do
			if children[i]:IsA("GuiObject") then
				children[i].ZIndex = index
			end
			drillDownSetZIndex(children[i], index)
		end
	end
	
	-- for terrain stamping
	local currTerrainDropDownFrame = nil
	local terrainShapes = {"Block","Vertical Ramp","Corner Wedge","Inverse Corner Wedge","Horizontal Ramp","Auto-Wedge"}
	local terrainShapeMap = {}
	for i = 1, #terrainShapes do
		terrainShapeMap[terrainShapes[i]] = i - 1
	end	
	terrainShapeMap[terrainShapes[#terrainShapes]] = 6

	local function createWaterGui()
		local waterForceDirections = {"NegX","X","NegY","Y","NegZ","Z"}
		local waterForces = {"None", "Small", "Medium", "Strong", "Max"}

		local waterFrame = Instance.new("Frame")
		waterFrame.Name = "WaterFrame"
		waterFrame.Style = Enum.FrameStyle.RobloxSquare
		waterFrame.Size = UDim2.new(0,150,0,110)
		waterFrame.Visible = false

		local waterForceLabel = Instance.new("TextLabel")
		waterForceLabel.Name = "WaterForceLabel"
		waterForceLabel.BackgroundTransparency = 1
		waterForceLabel.Size = UDim2.new(1,0,0,12)
		waterForceLabel.Font = Enum.Font.ArialBold
		waterForceLabel.FontSize = Enum.FontSize.Size12
		waterForceLabel.TextColor3 = Color3.new(1,1,1)
		waterForceLabel.TextXAlignment = Enum.TextXAlignment.Left
		waterForceLabel.Text = "Water Force"
		waterForceLabel.Parent = waterFrame

		local waterForceDirLabel = waterForceLabel:Clone()
		waterForceDirLabel.Name = "WaterForceDirectionLabel"
		waterForceDirLabel.Text = "Water Force Direction"
		waterForceDirLabel.Position = UDim2.new(0,0,0,50)
		waterForceDirLabel.Parent = waterFrame

		local waterTypeChangedEvent = Instance.new("BindableEvent",waterFrame)
		waterTypeChangedEvent.Name = "WaterTypeChangedEvent"

		local waterForceDirectionSelectedFunc = function(newForceDirection)
			waterForceDirection = newForceDirection
			waterTypeChangedEvent:Fire({waterForce, waterForceDirection})
		end
		local waterForceSelectedFunc = function(newForce)
			waterForce = newForce
			waterTypeChangedEvent:Fire({waterForce, waterForceDirection})
		end

		local waterForceDirectionDropDown, forceWaterDirectionSelection = t.CreateDropDownMenu(waterForceDirections, waterForceDirectionSelectedFunc)
		waterForceDirectionDropDown.Size = UDim2.new(1,0,0,25)
		waterForceDirectionDropDown.Position = UDim2.new(0,0,1,3)
		forceWaterDirectionSelection("NegX")
		waterForceDirectionDropDown.Parent = waterForceDirLabel

		local waterForceDropDown, forceWaterForceSelection = t.CreateDropDownMenu(waterForces, waterForceSelectedFunc)
		forceWaterForceSelection("None")
		waterForceDropDown.Size = UDim2.new(1,0,0,25)
		waterForceDropDown.Position = UDim2.new(0,0,1,3)
		waterForceDropDown.Parent = waterForceLabel

		return waterFrame, waterTypeChangedEvent
	end

	-- Helper Function that contructs gui elements
	local function createSetGui()
	
		local setGui = Instance.new("ScreenGui")
		setGui.Name = "SetGui"
		
		local setPanel = Instance.new("Frame")
		setPanel.Name = "SetPanel"
		setPanel.Active = true
		setPanel.BackgroundTransparency = 1
		if position then
			setPanel.Position = position
		else
			setPanel.Position = UDim2.new(0.2, 29, 0.1, 24)
		end
		if size then
			setPanel.Size = size
		else
			setPanel.Size = UDim2.new(0.6, -58, 0.64, 0)
		end
		setPanel.Style = Enum.FrameStyle.RobloxRound
		setPanel.ZIndex = 6
		setPanel.Parent = setGui
		
			-- Children of SetPanel
			local itemPreview = Instance.new("Frame")
			itemPreview.Name = "ItemPreview"
			itemPreview.BackgroundTransparency = 1
			itemPreview.Position = UDim2.new(0.8,5,0.085,0)
			itemPreview.Size = UDim2.new(0.21,0,0.9,0)
			itemPreview.ZIndex = 6
			itemPreview.Parent = setPanel
			
				-- Children of ItemPreview
				local textPanel = Instance.new("Frame")
				textPanel.Name = "TextPanel"
				textPanel.BackgroundTransparency = 1
				textPanel.Position = UDim2.new(0,0,0.45,0)
				textPanel.Size = UDim2.new(1,0,0.55,0)
				textPanel.ZIndex = 6
				textPanel.Parent = itemPreview
					
					-- Children of TextPanel
					local rolloverText = Instance.new("TextLabel")
					rolloverText.Name = "RolloverText"
					rolloverText.BackgroundTransparency = 1
					rolloverText.Size = UDim2.new(1,0,0,48)
					rolloverText.ZIndex = 6
					rolloverText.Font = Enum.Font.ArialBold
					rolloverText.FontSize = Enum.FontSize.Size24
					rolloverText.Text = ""
					rolloverText.TextColor3 = Color3.new(1,1,1)
					rolloverText.TextWrap = true
					rolloverText.TextXAlignment = Enum.TextXAlignment.Left
					rolloverText.TextYAlignment = Enum.TextYAlignment.Top
					rolloverText.Parent = textPanel
					
				local largePreview = Instance.new("ImageLabel")
				largePreview.Name = "LargePreview"
				largePreview.BackgroundTransparency = 1
				largePreview.Image = ""
				largePreview.Size = UDim2.new(1,0,0,170)
				largePreview.ZIndex = 6
				largePreview.Parent = itemPreview
				
			local sets = Instance.new("Frame")
			sets.Name = "Sets"
			sets.BackgroundTransparency = 1
			sets.Position = UDim2.new(0,0,0,5)
			sets.Size = UDim2.new(0.23,0,1,-5)
			sets.ZIndex = 6
			sets.Parent = setPanel
			
				-- Children of Sets
				local line = Instance.new("Frame")
				line.Name = "Line"
				line.BackgroundColor3 = Color3.new(1,1,1)
				line.BackgroundTransparency = 0.7
				line.BorderSizePixel = 0
				line.Position = UDim2.new(1,-3,0.06,0)
				line.Size = UDim2.new(0,3,0.9,0)
				line.ZIndex = 6
				line.Parent = sets
				
				local setsLists, controlFrame = t.CreateTrueScrollingFrame()
				setsLists.Size = UDim2.new(1,-6,0.94,0)
				setsLists.Position = UDim2.new(0,0,0.06,0)
				setsLists.BackgroundTransparency = 1
				setsLists.Name = "SetsLists"
				setsLists.ZIndex = 6
				setsLists.Parent = sets
				drillDownSetZIndex(controlFrame, 7)
					
				local setsHeader = Instance.new("TextLabel")
				setsHeader.Name = "SetsHeader"
				setsHeader.BackgroundTransparency = 1
				setsHeader.Size = UDim2.new(0,47,0,24)
				setsHeader.ZIndex = 6
				setsHeader.Font = Enum.Font.ArialBold
				setsHeader.FontSize = Enum.FontSize.Size24
				setsHeader.Text = "Sets"
				setsHeader.TextColor3 = Color3.new(1,1,1)
				setsHeader.TextXAlignment = Enum.TextXAlignment.Left
				setsHeader.TextYAlignment = Enum.TextYAlignment.Top
				setsHeader.Parent = sets
			
			local cancelButton = Instance.new("TextButton")
			cancelButton.Name = "CancelButton"
			cancelButton.Position = UDim2.new(1,-32,0,-2)
			cancelButton.Size = UDim2.new(0,34,0,34)
			cancelButton.Style = Enum.ButtonStyle.RobloxButtonDefault
			cancelButton.ZIndex = 6
			cancelButton.Text = ""
			cancelButton.Modal = true
			cancelButton.Parent = setPanel
			
				-- Children of Cancel Button
				local cancelImage = Instance.new("ImageLabel")
				cancelImage.Name = "CancelImage"
				cancelImage.BackgroundTransparency = 1
				cancelImage.Image = "http://www.roblox.com/asset/?id=54135717"
				cancelImage.Position = UDim2.new(0,-2,0,-2)
				cancelImage.Size = UDim2.new(0,16,0,16)
				cancelImage.ZIndex = 6
				cancelImage.Parent = cancelButton
					
		return setGui
	end
	
	local function createSetButton(text)
		local setButton = Instance.new("TextButton")
		
		if text then setButton.Text = text
		else setButton.Text = "" end
		
		setButton.AutoButtonColor = false
		setButton.BackgroundTransparency = 1
		setButton.BackgroundColor3 = Color3.new(1,1,1)
		setButton.BorderSizePixel = 0
		setButton.Size = UDim2.new(1,-5,0,18)
		setButton.ZIndex = 6
		setButton.Visible = false
		setButton.Font = Enum.Font.Arial
		setButton.FontSize = Enum.FontSize.Size18
		setButton.TextColor3 = Color3.new(1,1,1)
		setButton.TextXAlignment = Enum.TextXAlignment.Left
		
		return setButton
	end
	
	local function buildSetButton(name, setId, setImageId, i,  count)
		local button = createSetButton(name)
		button.Text = name
		button.Name = "SetButton"
		button.Visible = true
		
		local setValue = Instance.new("IntValue")
		setValue.Name = "SetId"
		setValue.Value = setId
		setValue.Parent = button

		local setName = Instance.new("StringValue")
		setName.Name = "SetName"
		setName.Value = name
		setName.Parent = button

		return button
	end
	
	local function processCategory(sets)
		local setButtons = {}
		local numSkipped = 0
		for i = 1, #sets do
			if not showAdminCategories and sets[i].Name == "Beta" then
				numSkipped = numSkipped + 1
			else
				setButtons[i - numSkipped] = buildSetButton(sets[i].Name, sets[i].CategoryId, sets[i].ImageAssetId, i - numSkipped, #sets)
			end
		end
		return setButtons
	end
	
	local function handleResize()
		wait() -- neccessary to insure heartbeat happened
		
		local itemPreview = setGui.SetPanel.ItemPreview
		
		itemPreview.LargePreview.Size = UDim2.new(1,0,0,itemPreview.AbsoluteSize.X)
		itemPreview.LargePreview.Position = UDim2.new(0.5,-itemPreview.LargePreview.AbsoluteSize.X/2,0,0)
		itemPreview.TextPanel.Position = UDim2.new(0,0,0,itemPreview.LargePreview.AbsoluteSize.Y)
		itemPreview.TextPanel.Size = UDim2.new(1,0,0,itemPreview.AbsoluteSize.Y - itemPreview.LargePreview.AbsoluteSize.Y)
	end
	
	local function makeInsertAssetButton()
		local insertAssetButtonExample = Instance.new("Frame")
		insertAssetButtonExample.Name = "InsertAssetButtonExample"
		insertAssetButtonExample.Position = UDim2.new(0,128,0,64)
		insertAssetButtonExample.Size = UDim2.new(0,64,0,64)
		insertAssetButtonExample.BackgroundTransparency = 1
		insertAssetButtonExample.ZIndex = 6
		insertAssetButtonExample.Visible = false

		local assetId = Instance.new("IntValue")
		assetId.Name = "AssetId"
		assetId.Value = 0
		assetId.Parent = insertAssetButtonExample
		
		local assetName = Instance.new("StringValue")
		assetName.Name = "AssetName"
		assetName.Value = ""
		assetName.Parent = insertAssetButtonExample

		local button = Instance.new("TextButton")
		button.Name = "Button"
		button.Text = ""
		button.Style = Enum.ButtonStyle.RobloxButton
		button.Position = UDim2.new(0.025,0,0.025,0)
		button.Size = UDim2.new(0.95,0,0.95,0)
		button.ZIndex = 6
		button.Parent = insertAssetButtonExample

		local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.Image = ""
		buttonImage.Position = UDim2.new(0,-7,0,-7)
		buttonImage.Size = UDim2.new(1,14,1,14)
		buttonImage.BackgroundTransparency = 1
		buttonImage.ZIndex = 7
		buttonImage.Parent = button

		local configIcon = buttonImage:clone()
		configIcon.Name = "ConfigIcon"
		configIcon.Visible = false
		configIcon.Position = UDim2.new(1,-23,1,-24)
		configIcon.Size = UDim2.new(0,16,0,16)
		configIcon.Image = ""
		configIcon.ZIndex = 6
		configIcon.Parent = insertAssetButtonExample
		
		return insertAssetButtonExample
	end
	
	local function showLargePreview(insertButton)
		if insertButton:FindFirstChild("AssetId") then
			delay(0,function()
				game:GetService("ContentProvider"):Preload(LargeThumbnailUrl .. tostring(insertButton.AssetId.Value))
				setGui.SetPanel.ItemPreview.LargePreview.Image = LargeThumbnailUrl .. tostring(insertButton.AssetId.Value)
			end)
		end
		if insertButton:FindFirstChild("AssetName") then
			setGui.SetPanel.ItemPreview.TextPanel.RolloverText.Text = insertButton.AssetName.Value
		end
	end
	
	local function selectTerrainShape(shape)
		if currTerrainDropDownFrame then
			objectSelected(tostring(currTerrainDropDownFrame.AssetName.Value), tonumber(currTerrainDropDownFrame.AssetId.Value), shape)
		end
	end
	
	local function createTerrainTypeButton(name, parent)
		local dropDownTextButton = Instance.new("TextButton")
		dropDownTextButton.Name = name .. "Button"
		dropDownTextButton.Font = Enum.Font.ArialBold
		dropDownTextButton.FontSize = Enum.FontSize.Size14
		dropDownTextButton.BorderSizePixel = 0
		dropDownTextButton.TextColor3 = Color3.new(1,1,1)
		dropDownTextButton.Text = name
		dropDownTextButton.TextXAlignment = Enum.TextXAlignment.Left
		dropDownTextButton.BackgroundTransparency = 1
		dropDownTextButton.ZIndex = parent.ZIndex + 1
		dropDownTextButton.Size = UDim2.new(0,parent.Size.X.Offset - 2,0,16)
		dropDownTextButton.Position = UDim2.new(0,1,0,0)

		dropDownTextButton.MouseEnter:connect(function()
			dropDownTextButton.BackgroundTransparency = 0
			dropDownTextButton.TextColor3 = Color3.new(0,0,0)
		end)

		dropDownTextButton.MouseLeave:connect(function()
			dropDownTextButton.BackgroundTransparency = 1
			dropDownTextButton.TextColor3 = Color3.new(1,1,1)
		end)

		dropDownTextButton.MouseButton1Click:connect(function()
			dropDownTextButton.BackgroundTransparency = 1
			dropDownTextButton.TextColor3 = Color3.new(1,1,1)
			if dropDownTextButton.Parent and dropDownTextButton.Parent:IsA("GuiObject") then
				dropDownTextButton.Parent.Visible = false
			end
			selectTerrainShape(terrainShapeMap[dropDownTextButton.Text])
		end)

		return dropDownTextButton
	end
	
	local function createTerrainDropDownMenu(zIndex)
		local dropDown = Instance.new("Frame")
		dropDown.Name = "TerrainDropDown"
		dropDown.BackgroundColor3 = Color3.new(0,0,0)
		dropDown.BorderColor3 = Color3.new(1,0,0)
		dropDown.Size = UDim2.new(0,200,0,0)
		dropDown.Visible = false
		dropDown.ZIndex = zIndex
		dropDown.Parent = setGui

		for i = 1, #terrainShapes do
			local shapeButton = createTerrainTypeButton(terrainShapes[i],dropDown)
			shapeButton.Position = UDim2.new(0,1,0,(i - 1) * (shapeButton.Size.Y.Offset))
			shapeButton.Parent = dropDown
			dropDown.Size = UDim2.new(0,200,0,dropDown.Size.Y.Offset + (shapeButton.Size.Y.Offset))
		end

		dropDown.MouseLeave:connect(function()
			dropDown.Visible = false
		end)
	end

	
	local function createDropDownMenuButton(parent)
		local dropDownButton = Instance.new("ImageButton")
		dropDownButton.Name = "DropDownButton"
		dropDownButton.Image = "http://www.roblox.com/asset/?id=67581509"
		dropDownButton.BackgroundTransparency = 1
		dropDownButton.Size = UDim2.new(0,16,0,16)
		dropDownButton.Position = UDim2.new(1,-24,0,6)
		dropDownButton.ZIndex = parent.ZIndex + 2
		dropDownButton.Parent = parent
		
		if not setGui:FindFirstChild("TerrainDropDown") then
			createTerrainDropDownMenu(8)
		end
		
		dropDownButton.MouseButton1Click:connect(function()
			setGui.TerrainDropDown.Visible = true
			setGui.TerrainDropDown.Position = UDim2.new(0,parent.AbsolutePosition.X,0,parent.AbsolutePosition.Y)
			currTerrainDropDownFrame = parent
		end)
	end
	
	local function buildInsertButton()
		local insertButton = makeInsertAssetButton()
		insertButton.Name = "InsertAssetButton"
		insertButton.Visible = true

		if Data.Category[Data.CurrentCategory].SetName == "High Scalability" then
			createDropDownMenuButton(insertButton)
		end

		local lastEnter = nil
		local mouseEnterCon = insertButton.MouseEnter:connect(function()
			lastEnter = insertButton
			delay(0.1,function()
				if lastEnter == insertButton then
					showLargePreview(insertButton)
				end
			end)
		end)
		return insertButton, mouseEnterCon
	end
	
	local function realignButtonGrid(columns)
		local x = 0
		local y = 0 
		for i = 1, #insertButtons do
			insertButtons[i].Position = UDim2.new(0, buttonWidth * x, 0, buttonHeight * y)
			x = x + 1
			if x >= columns then
				x = 0
				y = y + 1
			end
		end
	end

	local function setInsertButtonImageBehavior(insertFrame, visible, name, assetId)
		if visible then
			insertFrame.AssetName.Value = name
			insertFrame.AssetId.Value = assetId
			local newImageUrl = SmallThumbnailUrl  .. assetId
			if newImageUrl ~= insertFrame.Button.ButtonImage.Image then
				delay(0,function()
					game:GetService("ContentProvider"):Preload(SmallThumbnailUrl  .. assetId)
					if insertFrame:findFirstChild("Button") then
						insertFrame.Button.ButtonImage.Image = SmallThumbnailUrl  .. assetId
					end
				end)
			end
			table.insert(insertButtonCons,
				insertFrame.Button.MouseButton1Click:connect(function()
					-- special case for water, show water selection gui
					local isWaterSelected = (name == "Water") and (Data.Category[Data.CurrentCategory].SetName == "High Scalability")
					waterGui.Visible = isWaterSelected
					if isWaterSelected then
						objectSelected(name, tonumber(assetId), nil)
					else
						objectSelected(name, tonumber(assetId))
					end
				end)
			)
			insertFrame.Visible = true
		else
			insertFrame.Visible = false
		end
	end
	
	local function loadSectionOfItems(setGui, rows, columns)
		local pageSize = rows * columns

		if arrayPosition > #contents then return end

		local origArrayPos = arrayPosition

		local yCopy = 0
		for i = 1, pageSize + 1 do 
			if arrayPosition >= #contents + 1 then
				break
			end

			local buttonCon
			insertButtons[arrayPosition], buttonCon = buildInsertButton()
			table.insert(insertButtonCons,buttonCon)
			insertButtons[arrayPosition].Parent = setGui.SetPanel.ItemsFrame
			arrayPosition = arrayPosition + 1
		end
		realignButtonGrid(columns)

		local indexCopy = origArrayPos
		for index = origArrayPos, arrayPosition do
			if insertButtons[index] then
				if contents[index] then

					-- we don't want water to have a drop down button
					if contents[index].Name == "Water" then
						if Data.Category[Data.CurrentCategory].SetName == "High Scalability" then
							insertButtons[index]:FindFirstChild("DropDownButton",true):Destroy()
						end
					end

					local assetId
					if useAssetVersionId then
						assetId = contents[index].AssetVersionId
					else
						assetId = contents[index].AssetId
					end
					setInsertButtonImageBehavior(insertButtons[index], true, contents[index].Name, assetId)
				else
					break
				end
			else
				break
			end
			indexCopy = index
		end
	end
	
	local function setSetIndex()
		Data.Category[Data.CurrentCategory].Index = 0

		rows = 7
		columns = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.X/buttonWidth)

		contents = Data.Category[Data.CurrentCategory].Contents
		if contents then
			-- remove our buttons and their connections
			for i = 1, #insertButtons do
				insertButtons[i]:remove()
			end
			for i = 1, #insertButtonCons do
				if insertButtonCons[i] then insertButtonCons[i]:disconnect() end
			end
			insertButtonCons = {}
			insertButtons = {}

			arrayPosition = 1
			loadSectionOfItems(setGui, rows, columns)
		end
	end
	
	local function selectSet(button, setName, setId, setIndex)
		if button and Data.Category[Data.CurrentCategory] ~= nil then
			if button ~= Data.Category[Data.CurrentCategory].Button then
				Data.Category[Data.CurrentCategory].Button = button

				if SetCache[setId] == nil then
					SetCache[setId] = game:GetService("InsertService"):GetCollection(setId)
				end
				Data.Category[Data.CurrentCategory].Contents = SetCache[setId]

				Data.Category[Data.CurrentCategory].SetName = setName
				Data.Category[Data.CurrentCategory].SetId = setId
			end
			setSetIndex()
		end
	end
	
	local function selectCategoryPage(buttons, page)
		if buttons ~= Data.CurrentCategory then
			if Data.CurrentCategory then
				for key, button in pairs(Data.CurrentCategory) do
					button.Visible = false
				end
			end

			Data.CurrentCategory = buttons
			if Data.Category[Data.CurrentCategory] == nil then
				Data.Category[Data.CurrentCategory] = {}
				if #buttons > 0 then
					selectSet(buttons[1], buttons[1].SetName.Value, buttons[1].SetId.Value, 0)
				end
			else
				Data.Category[Data.CurrentCategory].Button = nil
				selectSet(Data.Category[Data.CurrentCategory].ButtonFrame, Data.Category[Data.CurrentCategory].SetName, Data.Category[Data.CurrentCategory].SetId, Data.Category[Data.CurrentCategory].Index)
			end
		end
	end
	
	local function selectCategory(category)
		selectCategoryPage(category, 0)
	end
	
	local function resetAllSetButtonSelection()
		local setButtons = setGui.SetPanel.Sets.SetsLists:GetChildren()
		for i = 1, #setButtons do
			if setButtons[i]:IsA("TextButton") then
				setButtons[i].Selected = false
				setButtons[i].BackgroundTransparency = 1
				setButtons[i].TextColor3 = Color3.new(1,1,1)
				setButtons[i].BackgroundColor3 = Color3.new(1,1,1)
			end
		end
	end
	
	local function populateSetsFrame()
		local currRow = 0
		for i = 1, #userCategoryButtons do
			local button = userCategoryButtons[i]
			button.Visible = true
			button.Position = UDim2.new(0,5,0,currRow * button.Size.Y.Offset)
			button.Parent = setGui.SetPanel.Sets.SetsLists
			
			if i == 1 then -- we will have this selected by default, so show it
				button.Selected = true
				button.BackgroundColor3 = Color3.new(0,204/255,0)
				button.TextColor3 = Color3.new(0,0,0)
				button.BackgroundTransparency = 0
			end

			button.MouseEnter:connect(function()
				if not button.Selected then
					button.BackgroundTransparency = 0
					button.TextColor3 = Color3.new(0,0,0)
				end
			end)
			button.MouseLeave:connect(function()
				if not button.Selected then
					button.BackgroundTransparency = 1
					button.TextColor3 = Color3.new(1,1,1)
				end
			end)
			button.MouseButton1Click:connect(function()
				resetAllSetButtonSelection()
				button.Selected = not button.Selected
				button.BackgroundColor3 = Color3.new(0,204/255,0)
				button.TextColor3 = Color3.new(0,0,0)
				button.BackgroundTransparency = 0
				selectSet(button, button.Text, userCategoryButtons[i].SetId.Value, 0)
			end)

			currRow = currRow + 1
		end

		local buttons =  setGui.SetPanel.Sets.SetsLists:GetChildren()

		-- set first category as loaded for default
		if buttons then
			for i = 1, #buttons do
				if buttons[i]:IsA("TextButton") then
					selectSet(buttons[i], buttons[i].Text, userCategoryButtons[i].SetId.Value, 0)
					selectCategory(userCategoryButtons)
					break
				end
			end
		end
	end

	setGui = createSetGui()
	waterGui, waterTypeChangedEvent = createWaterGui()
	waterGui.Position = UDim2.new(0,55,0,0)
	waterGui.Parent = setGui
	setGui.Changed:connect(function(prop) -- this resizes the preview image to always be the right size
		if prop == "AbsoluteSize" then
			handleResize()
			setSetIndex()
		end
	end)
	
	local scrollFrame, controlFrame = t.CreateTrueScrollingFrame()
	scrollFrame.Size = UDim2.new(0.54,0,0.85,0)
	scrollFrame.Position = UDim2.new(0.24,0,0.085,0)
	scrollFrame.Name = "ItemsFrame"
	scrollFrame.ZIndex = 6
	scrollFrame.Parent = setGui.SetPanel
	scrollFrame.BackgroundTransparency = 1

	drillDownSetZIndex(controlFrame,7)

	controlFrame.Parent = setGui.SetPanel
	controlFrame.Position = UDim2.new(0.76, 5, 0, 0)

	local debounce = false
	controlFrame.ScrollBottom.Changed:connect(function(prop)
		if controlFrame.ScrollBottom.Value == true then
			if debounce then return end
			debounce = true
				loadSectionOfItems(setGui, rows, columns)
			debounce = false
		end
	end)

	local userData = {}
	for id = 1, #userIdsForSets do
		local newUserData = game:GetService("InsertService"):GetUserSets(userIdsForSets[id])
		if newUserData and #newUserData > 2 then
			-- start at #3 to skip over My Decals and My Models for each account
			for category = 3, #newUserData do
				if newUserData[category].Name == "High Scalability" then -- we want high scalability parts to show first
					table.insert(userData,1,newUserData[category])
				else
					table.insert(userData, newUserData[category])
				end
			end
		end
	
	end
	if userData then
		userCategoryButtons = processCategory(userData)
	end

	rows = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.Y/buttonHeight)
	columns = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.X/buttonWidth)

	populateSetsFrame()

	insertPanelCloseCon = setGui.SetPanel.CancelButton.MouseButton1Click:connect(function()
		setGui.SetPanel.Visible = false
		if dialogClosed then dialogClosed() end
	end)
	
	local setVisibilityFunction = function(visible)
		if visible then
			setGui.SetPanel.Visible = true
		else
			setGui.SetPanel.Visible = false
		end
	end
	
	local getVisibilityFunction = function()
		if setGui then
			if setGui:FindFirstChild("SetPanel") then
				return setGui.SetPanel.Visible
			end
		end
		
		return false
	end
	
	return setGui, setVisibilityFunction, getVisibilityFunction, waterTypeChangedEvent
end

t.CreateTerrainMaterialSelector = function(size,position)
	local terrainMaterialSelectionChanged = Instance.new("BindableEvent")
	terrainMaterialSelectionChanged.Name = "TerrainMaterialSelectionChanged"

	local selectedButton = nil

	local frame = Instance.new("Frame")
	frame.Name = "TerrainMaterialSelector"
	if size then
		frame.Size = size
	else
		frame.Size = UDim2.new(0, 245, 0, 230)
	end
	if position then
		frame.Position = position
	end
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Color3.new(0,0,0)
	frame.Active = true

	terrainMaterialSelectionChanged.Parent = frame

	local waterEnabled = true -- todo: turn this on when water is ready

	local materialToImageMap = {}
	local materialNames = {"Grass", "Sand", "Brick", "Granite", "Asphalt", "Iron", "Aluminum", "Gold", "Plank", "Log", "Gravel", "Cinder Block", "Stone Wall", "Concrete", "Plastic (red)", "Plastic (blue)"}
	if waterEnabled then
		table.insert(materialNames,"Water")
	end
	local currentMaterial = 1

	function getEnumFromName(choice)
		if choice == "Grass" then return 1 end
		if choice == "Sand" then return 2 end 
		if choice == "Erase" then return 0 end
		if choice == "Brick" then return 3 end
		if choice == "Granite" then return 4 end
		if choice == "Asphalt" then return 5 end
		if choice == "Iron" then return 6 end
		if choice == "Aluminum" then return 7 end
		if choice == "Gold" then return 8 end
		if choice == "Plank" then return 9 end
		if choice == "Log" then return 10 end
		if choice == "Gravel" then return 11 end
		if choice == "Cinder Block" then return 12 end
		if choice == "Stone Wall" then return 13 end
		if choice == "Concrete" then return 14 end
		if choice == "Plastic (red)" then return 15 end
		if choice == "Plastic (blue)" then return 16 end
		if choice == "Water" then return 17 end
	end

	function getNameFromEnum(choice)
		if choice == Enum.CellMaterial.Grass or choice == 1 then return "Grass"end
		if choice == Enum.CellMaterial.Sand or choice == 2 then return "Sand" end 
		if choice == Enum.CellMaterial.Empty or choice == 0 then return "Erase" end
		if choice == Enum.CellMaterial.Brick or choice == 3 then return "Brick" end
		if choice == Enum.CellMaterial.Granite or choice == 4 then return "Granite" end
		if choice == Enum.CellMaterial.Asphalt or choice == 5 then return "Asphalt" end
		if choice == Enum.CellMaterial.Iron or choice == 6 then return "Iron" end
		if choice == Enum.CellMaterial.Aluminum or choice == 7 then return "Aluminum" end
		if choice == Enum.CellMaterial.Gold or choice == 8 then return "Gold" end
		if choice == Enum.CellMaterial.WoodPlank or choice == 9 then return "Plank" end
		if choice == Enum.CellMaterial.WoodLog or choice == 10 then return "Log" end
		if choice == Enum.CellMaterial.Gravel or choice == 11 then return "Gravel" end
		if choice == Enum.CellMaterial.CinderBlock or choice == 12 then return "Cinder Block" end
		if choice == Enum.CellMaterial.MossyStone or choice == 13 then return "Stone Wall" end
		if choice == Enum.CellMaterial.Cement or choice == 14 then return "Concrete" end
		if choice == Enum.CellMaterial.RedPlastic or choice == 15 then return "Plastic (red)" end
		if choice == Enum.CellMaterial.BluePlastic or choice == 16 then return "Plastic (blue)" end

		if waterEnabled then
			if choice == Enum.CellMaterial.Water or choice == 17 then return "Water" end
		end
	end


	local function updateMaterialChoice(choice)
		currentMaterial = getEnumFromName(choice)
		terrainMaterialSelectionChanged:Fire(currentMaterial)
	end

	-- we so need a better way to do this
	for i,v in pairs(materialNames) do
		materialToImageMap[v] = {}
		if v == "Grass" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=56563112"
		elseif v == "Sand" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=62356652"
		elseif v == "Brick" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=65961537"
		elseif v == "Granite" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532153"
		elseif v == "Asphalt" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532038"
		elseif v == "Iron" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532093"
		elseif v == "Aluminum" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531995"
		elseif v == "Gold" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532118"
		elseif v == "Plastic (red)" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531848"
		elseif v == "Plastic (blue)" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531924"
		elseif v == "Plank" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532015"
		elseif v == "Log" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532051"
		elseif v == "Gravel" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532206"
		elseif v == "Cinder Block" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532103"
		elseif v == "Stone Wall" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531804"
		elseif v == "Concrete" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532059"
		elseif v == "Water" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=81407474"
		else materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=66887593" -- fill in the rest here!!
		end
	end

	local scrollFrame, scrollUp, scrollDown, recalculateScroll = t.CreateScrollingFrame(nil,"grid")
	scrollFrame.Size = UDim2.new(0.85,0,1,0)
	scrollFrame.Position = UDim2.new(0,0,0,0)
	scrollFrame.Parent = frame

	scrollUp.Parent = frame
	scrollUp.Visible = true
	scrollUp.Position = UDim2.new(1,-19,0,0)

	scrollDown.Parent = frame
	scrollDown.Visible = true
	scrollDown.Position = UDim2.new(1,-19,1,-17)

	local function goToNewMaterial(buttonWrap, materialName)
		updateMaterialChoice(materialName)
		buttonWrap.BackgroundTransparency = 0
		selectedButton.BackgroundTransparency = 1
		selectedButton = buttonWrap
	end

	local function createMaterialButton(name)	
		local buttonWrap = Instance.new("TextButton")
		buttonWrap.Text = ""
		buttonWrap.Size = UDim2.new(0,32,0,32)
		buttonWrap.BackgroundColor3 = Color3.new(1,1,1)
		buttonWrap.BorderSizePixel = 0
		buttonWrap.BackgroundTransparency = 1
		buttonWrap.AutoButtonColor = false
		buttonWrap.Name = tostring(name)
		
		local imageButton = Instance.new("ImageButton")
		imageButton.AutoButtonColor = false
		imageButton.BackgroundTransparency = 1
		imageButton.Size = UDim2.new(0,30,0,30)
		imageButton.Position = UDim2.new(0,1,0,1)
		imageButton.Name = tostring(name)
		imageButton.Parent = buttonWrap
		imageButton.Image = materialToImageMap[name].Regular

		local enumType = Instance.new("NumberValue")
		enumType.Name = "EnumType"
		enumType.Parent = buttonWrap
		enumType.Value = 0
		
		imageButton.MouseEnter:connect(function()
			buttonWrap.BackgroundTransparency = 0
		end)
		imageButton.MouseLeave:connect(function()
			if selectedButton ~= buttonWrap then
				buttonWrap.BackgroundTransparency = 1
			end
		end)
		imageButton.MouseButton1Click:connect(function()
			if selectedButton ~= buttonWrap then
				goToNewMaterial(buttonWrap, tostring(name))
			end
		end)
		
		return buttonWrap 
	end

	for i = 1, #materialNames do
		local imageButton = createMaterialButton(materialNames[i])
		
		if materialNames[i] == "Grass" then -- always start with grass as the default
			selectedButton = imageButton
			imageButton.BackgroundTransparency = 0
		end
		
		imageButton.Parent = scrollFrame
	end

	local forceTerrainMaterialSelection = function(newMaterialType)
		if not newMaterialType then return end
		if currentMaterial == newMaterialType then return end

		local matName = getNameFromEnum(newMaterialType)
		local buttons = scrollFrame:GetChildren()
		for i = 1, #buttons do
			if buttons[i].Name == "Plastic (blue)" and matName == "Plastic (blue)" then goToNewMaterial(buttons[i],matName) return end
			if buttons[i].Name == "Plastic (red)" and matName == "Plastic (red)" then goToNewMaterial(buttons[i],matName) return end
			if string.find(buttons[i].Name, matName) then
				goToNewMaterial(buttons[i],matName)
				return
			end
		end
	end

	frame.Changed:connect(function ( prop )
		if prop == "AbsoluteSize" then
			recalculateScroll()
		end
	end)

	recalculateScroll()
	return frame, terrainMaterialSelectionChanged, forceTerrainMaterialSelection
end

t.CreateLoadingFrame = function(name,size,position)
	game:GetService("ContentProvider"):Preload("http://www.roblox.com/asset/?id=35238053")

	local loadingFrame = Instance.new("Frame")
	loadingFrame.Name = "LoadingFrame"
	loadingFrame.Style = Enum.FrameStyle.RobloxRound

	if size then loadingFrame.Size = size
	else loadingFrame.Size = UDim2.new(0,300,0,160) end
	if position then loadingFrame.Position = position 
	else loadingFrame.Position = UDim2.new(0.5, -150, 0.5,-80) end

	local loadingBar = Instance.new("Frame")
	loadingBar.Name = "LoadingBar"
	loadingBar.BackgroundColor3 = Color3.new(0,0,0)
	loadingBar.BorderColor3 = Color3.new(79/255,79/255,79/255)
	loadingBar.Position = UDim2.new(0,0,0,41)
	loadingBar.Size = UDim2.new(1,0,0,30)
	loadingBar.Parent = loadingFrame

		local loadingGreenBar = Instance.new("ImageLabel")
		loadingGreenBar.Name = "LoadingGreenBar"
		loadingGreenBar.Image = "http://www.roblox.com/asset/?id=35238053"
		loadingGreenBar.Position = UDim2.new(0,0,0,0)
		loadingGreenBar.Size = UDim2.new(0,0,1,0)
		loadingGreenBar.Visible = false
		loadingGreenBar.Parent = loadingBar

		local loadingPercent = Instance.new("TextLabel")
		loadingPercent.Name = "LoadingPercent"
		loadingPercent.BackgroundTransparency = 1
		loadingPercent.Position = UDim2.new(0,0,1,0)
		loadingPercent.Size = UDim2.new(1,0,0,14)
		loadingPercent.Font = Enum.Font.Arial
		loadingPercent.Text = "0%"
		loadingPercent.FontSize = Enum.FontSize.Size14
		loadingPercent.TextColor3 = Color3.new(1,1,1)
		loadingPercent.Parent = loadingBar

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Position = UDim2.new(0.5,-60,1,-40)
	cancelButton.Size = UDim2.new(0,120,0,40)
	cancelButton.Font = Enum.Font.Arial
	cancelButton.FontSize = Enum.FontSize.Size18
	cancelButton.TextColor3 = Color3.new(1,1,1)
	cancelButton.Text = "Cancel"
	cancelButton.Style = Enum.ButtonStyle.RobloxButton
	cancelButton.Parent = loadingFrame

	local loadingName = Instance.new("TextLabel")
	loadingName.Name = "loadingName"
	loadingName.BackgroundTransparency = 1
	loadingName.Size = UDim2.new(1,0,0,18)
	loadingName.Position = UDim2.new(0,0,0,2)
	loadingName.Font = Enum.Font.Arial
	loadingName.Text = name
	loadingName.TextColor3 = Color3.new(1,1,1)
	loadingName.TextStrokeTransparency = 1
	loadingName.FontSize = Enum.FontSize.Size18
	loadingName.Parent = loadingFrame

	local cancelButtonClicked = Instance.new("BindableEvent")
	cancelButtonClicked.Name = "CancelButtonClicked"
	cancelButtonClicked.Parent = cancelButton
	cancelButton.MouseButton1Click:connect(function()
		cancelButtonClicked:Fire()
	end)

	local updateLoadingGuiPercent = function(percent, tweenAction, tweenLength)
		if percent and type(percent) ~= "number" then
			error("updateLoadingGuiPercent expects number as argument, got",type(percent),"instead")
		end

		local newSize = nil
		if percent < 0 then
			newSize = UDim2.new(0,0,1,0)
		elseif percent > 1 then
			newSize = UDim2.new(1,0,1,0)
		else
			newSize = UDim2.new(percent,0,1,0)
		end

		if tweenAction then
			if not tweenLength then
				error("updateLoadingGuiPercent is set to tween new percentage, but got no tween time length! Please pass this in as third argument")
			end

			if (newSize.X.Scale > 0) then
				loadingGreenBar.Visible = true
				loadingGreenBar:TweenSize(	newSize,
											Enum.EasingDirection.Out,
											Enum.EasingStyle.Quad,
											tweenLength,
											true)
			else
				loadingGreenBar:TweenSize(	newSize,
											Enum.EasingDirection.Out,
											Enum.EasingStyle.Quad,
											tweenLength,
											true,
											function() 
												if (newSize.X.Scale < 0) then
													loadingGreenBar.Visible = false
												end
											end)
			end

		else
			loadingGreenBar.Size = newSize
			loadingGreenBar.Visible = (newSize.X.Scale > 0)
		end
	end

	loadingGreenBar.Changed:connect(function(prop)
		if prop == "Size" then
			loadingPercent.Text = tostring( math.ceil(loadingGreenBar.Size.X.Scale * 100) ) .. "%"
		end
	end)

	return loadingFrame, updateLoadingGuiPercent, cancelButtonClicked
end

t.CreatePluginFrame = function (name,size,position,scrollable,parent)
	function createMenuButton(size,position,text,fontsize,name,parent)
		local button = Instance.new("TextButton",parent)
		button.AutoButtonColor = false
		button.Name = name
		button.BackgroundTransparency = 1
		button.Position = position
		button.Size = size
		button.Font = Enum.Font.ArialBold
		button.FontSize = fontsize
		button.Text =  text
		button.TextColor3 = Color3.new(1,1,1)
		button.BorderSizePixel = 0
		button.BackgroundColor3 = Color3.new(20/255,20/255,20/255)

		button.MouseEnter:connect(function ( )
			if button.Selected then return end
			button.BackgroundTransparency = 0
		end)
		button.MouseLeave:connect(function ( )
			if button.Selected then return end
			button.BackgroundTransparency = 1
		end)

		return button

	end

	local dragBar = Instance.new("Frame",parent)
	dragBar.Name = tostring(name) .. "DragBar"
	dragBar.BackgroundColor3 = Color3.new(39/255,39/255,39/255)
	dragBar.BorderColor3 = Color3.new(0,0,0)
	if size then
		dragBar.Size =  UDim2.new(size.X.Scale,size.X.Offset,0,20)  + UDim2.new(0,20,0,0)
	else
		dragBar.Size = UDim2.new(0,183,0,20)
	end
	if position then
		dragBar.Position = position
	end
	dragBar.Active = true
	dragBar.Draggable = true
	--dragBar.Visible = false
	dragBar.MouseEnter:connect(function (  )
		dragBar.BackgroundColor3 = Color3.new(49/255,49/255,49/255)
	end)
	dragBar.MouseLeave:connect(function (  )
		dragBar.BackgroundColor3 = Color3.new(39/255,39/255,39/255)
	end)

	-- plugin name label
	local pluginNameLabel = Instance.new("TextLabel",dragBar)
	pluginNameLabel.Name = "BarNameLabel"
	pluginNameLabel.Text = " " .. tostring(name)
	pluginNameLabel.TextColor3 = Color3.new(1,1,1)
	pluginNameLabel.TextStrokeTransparency = 0
	pluginNameLabel.Size = UDim2.new(1,0,1,0)
	pluginNameLabel.Font = Enum.Font.ArialBold
	pluginNameLabel.FontSize = Enum.FontSize.Size18
	pluginNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	pluginNameLabel.BackgroundTransparency = 1

	-- close button
	local closeButton = createMenuButton(UDim2.new(0,15,0,17),UDim2.new(1,-16,0.5,-8),"X",Enum.FontSize.Size14,"CloseButton",dragBar)
	local closeEvent = Instance.new("BindableEvent")
	closeEvent.Name = "CloseEvent"
	closeEvent.Parent = closeButton
	closeButton.MouseButton1Click:connect(function ()
		closeEvent:Fire()
		closeButton.BackgroundTransparency = 1
	end)

	-- help button
	local helpButton = createMenuButton(UDim2.new(0,15,0,17),UDim2.new(1,-51,0.5,-8),"?",Enum.FontSize.Size14,"HelpButton",dragBar)
	local helpFrame = Instance.new("Frame",dragBar)
	helpFrame.Name = "HelpFrame"
	helpFrame.BackgroundColor3 = Color3.new(0,0,0)
	helpFrame.Size = UDim2.new(0,300,0,552)
	helpFrame.Position = UDim2.new(1,5,0,0)
	helpFrame.Active = true
	helpFrame.BorderSizePixel = 0
	helpFrame.Visible = false

	helpButton.MouseButton1Click:connect(function(  )
		helpFrame.Visible = not helpFrame.Visible
		if helpFrame.Visible then
			helpButton.Selected = true
			helpButton.BackgroundTransparency = 0
			local screenGui = getScreenGuiAncestor(helpFrame)
			if screenGui then
				if helpFrame.AbsolutePosition.X + helpFrame.AbsoluteSize.X > screenGui.AbsoluteSize.X then --position on left hand side
					helpFrame.Position = UDim2.new(0,-5 - helpFrame.AbsoluteSize.X,0,0)
				else -- position on right hand side
					helpFrame.Position = UDim2.new(1,5,0,0)
				end
			else
				helpFrame.Position = UDim2.new(1,5,0,0)
			end
		else
			helpButton.Selected = false
			helpButton.BackgroundTransparency = 1
		end
	end)

	local minimizeButton = createMenuButton(UDim2.new(0,16,0,17),UDim2.new(1,-34,0.5,-8),"-",Enum.FontSize.Size14,"MinimizeButton",dragBar)
	minimizeButton.TextYAlignment = Enum.TextYAlignment.Top

	local minimizeFrame = Instance.new("Frame",dragBar)
	minimizeFrame.Name = "MinimizeFrame"
	minimizeFrame.BackgroundColor3 = Color3.new(73/255,73/255,73/255)
	minimizeFrame.BorderColor3 = Color3.new(0,0,0)
	minimizeFrame.Position = UDim2.new(0,0,1,0)
	if size then
		minimizeFrame.Size =  UDim2.new(size.X.Scale,size.X.Offset,0,50) + UDim2.new(0,20,0,0)
	else
		minimizeFrame.Size = UDim2.new(0,183,0,50)
	end
	minimizeFrame.Visible = false

	local minimizeBigButton = Instance.new("TextButton",minimizeFrame)
	minimizeBigButton.Position = UDim2.new(0.5,-50,0.5,-20)
	minimizeBigButton.Name = "MinimizeButton"
	minimizeBigButton.Size = UDim2.new(0,100,0,40)
	minimizeBigButton.Style = Enum.ButtonStyle.RobloxButton
	minimizeBigButton.Font = Enum.Font.ArialBold
	minimizeBigButton.FontSize = Enum.FontSize.Size18
	minimizeBigButton.TextColor3 = Color3.new(1,1,1)
	minimizeBigButton.Text = "Show"

	local separatingLine = Instance.new("Frame",dragBar)
	separatingLine.Name = "SeparatingLine"
	separatingLine.BackgroundColor3 = Color3.new(115/255,115/255,115/255)
	separatingLine.BorderSizePixel = 0
	separatingLine.Position = UDim2.new(1,-18,0.5,-7)
	separatingLine.Size = UDim2.new(0,1,0,14)

	local otherSeparatingLine = separatingLine:clone()
	otherSeparatingLine.Position = UDim2.new(1,-35,0.5,-7)
	otherSeparatingLine.Parent = dragBar

	local widgetContainer = Instance.new("Frame",dragBar)
	widgetContainer.Name = "WidgetContainer"
	widgetContainer.BackgroundTransparency = 1
	widgetContainer.Position = UDim2.new(0,0,1,0)
	widgetContainer.BorderColor3 = Color3.new(0,0,0)
	if not scrollable then
		widgetContainer.BackgroundTransparency = 0
		widgetContainer.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
	end

	if size then
		if scrollable then
			widgetContainer.Size = size
		else
			widgetContainer.Size = UDim2.new(0,dragBar.AbsoluteSize.X,size.Y.Scale,size.Y.Offset)
		end
	else
		if scrollable then
			widgetContainer.Size = UDim2.new(0,163,0,400)
		else
			widgetContainer.Size = UDim2.new(0,dragBar.AbsoluteSize.X,0,400)
		end
	end
	if position then
		widgetContainer.Position = position + UDim2.new(0,0,0,20)
	end

	local frame,control,verticalDragger = nil
	if scrollable then
		--frame for widgets
		frame,control = t.CreateTrueScrollingFrame()
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
		frame.BorderColor3 = Color3.new(0,0,0)
		frame.Active = true
		frame.Parent = widgetContainer
		control.Parent = dragBar
		control.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
		control.BorderSizePixel = 0
		control.BackgroundTransparency = 0
		control.Position = UDim2.new(1,-21,1,1)
		if size then
			control.Size = UDim2.new(0,21,size.Y.Scale,size.Y.Offset)
		else
			control.Size = UDim2.new(0,21,0,400)
		end
		control:FindFirstChild("ScrollDownButton").Position = UDim2.new(0,0,1,-20)

		local fakeLine = Instance.new("Frame",control)
		fakeLine.Name = "FakeLine"
		fakeLine.BorderSizePixel = 0
		fakeLine.BackgroundColor3 = Color3.new(0,0,0)
		fakeLine.Size = UDim2.new(0,1,1,1)
		fakeLine.Position = UDim2.new(1,0,0,0)

		verticalDragger = Instance.new("TextButton",widgetContainer)
		verticalDragger.ZIndex = 2
		verticalDragger.AutoButtonColor = false
		verticalDragger.Name = "VerticalDragger"
		verticalDragger.BackgroundColor3 = Color3.new(50/255,50/255,50/255)
		verticalDragger.BorderColor3 = Color3.new(0,0,0)
		verticalDragger.Size = UDim2.new(1,20,0,20)
		verticalDragger.Position = UDim2.new(0,0,1,0)
		verticalDragger.Active = true
		verticalDragger.Text = ""

		local scrubFrame = Instance.new("Frame",verticalDragger)
		scrubFrame.Name = "ScrubFrame"
		scrubFrame.BackgroundColor3 = Color3.new(1,1,1)
		scrubFrame.BorderSizePixel = 0
		scrubFrame.Position = UDim2.new(0.5,-5,0.5,0)
		scrubFrame.Size = UDim2.new(0,10,0,1)
		scrubFrame.ZIndex = 5
		local scrubTwo = scrubFrame:clone()
		scrubTwo.Position = UDim2.new(0.5,-5,0.5,-2)
		scrubTwo.Parent = verticalDragger
		local scrubThree = scrubFrame:clone()
		scrubThree.Position = UDim2.new(0.5,-5,0.5,2)
		scrubThree.Parent = verticalDragger

		local areaSoak = Instance.new("TextButton",getScreenGuiAncestor(parent))
		areaSoak.Name = "AreaSoak"
		areaSoak.Size = UDim2.new(1,0,1,0)
		areaSoak.BackgroundTransparency = 1
		areaSoak.BorderSizePixel = 0
		areaSoak.Text = ""
		areaSoak.ZIndex = 10
		areaSoak.Visible = false
		areaSoak.Active = true

		local draggingVertical = false
		local startYPos = nil
		verticalDragger.MouseEnter:connect(function ()
			verticalDragger.BackgroundColor3 = Color3.new(60/255,60/255,60/255)
		end)
		verticalDragger.MouseLeave:connect(function ()
			verticalDragger.BackgroundColor3 = Color3.new(50/255,50/255,50/255)
		end)
		verticalDragger.MouseButton1Down:connect(function(x,y)
			draggingVertical = true
			areaSoak.Visible = true
			startYPos = y
		end)
		areaSoak.MouseButton1Up:connect(function (  )
			draggingVertical = false
			areaSoak.Visible = false
		end)
		areaSoak.MouseMoved:connect(function(x,y)
			if not draggingVertical then return end

			local yDelta = y - startYPos
			if not control.ScrollDownButton.Visible and yDelta > 0 then
				return
			end

			if (widgetContainer.Size.Y.Offset + yDelta) < 150 then
				widgetContainer.Size = UDim2.new(widgetContainer.Size.X.Scale, widgetContainer.Size.X.Offset,widgetContainer.Size.Y.Scale,150)
				control.Size = UDim2.new (0,21,0,150)
				return 
			end 

			startYPos = y

			if widgetContainer.Size.Y.Offset + yDelta >= 0 then
				widgetContainer.Size = UDim2.new(widgetContainer.Size.X.Scale, widgetContainer.Size.X.Offset,widgetContainer.Size.Y.Scale,widgetContainer.Size.Y.Offset + yDelta)
				control.Size = UDim2.new(0,21,0,control.Size.Y.Offset + yDelta )
			end
		end)
	end

	local function switchMinimize()
		minimizeFrame.Visible = not minimizeFrame.Visible
		if scrollable then
			frame.Visible = not frame.Visible
			verticalDragger.Visible = not verticalDragger.Visible
			control.Visible = not control.Visible
		else
			widgetContainer.Visible = not widgetContainer.Visible
		end

		if minimizeFrame.Visible then
			minimizeButton.Text = "+"
		else
			minimizeButton.Text = "-"
		end
	end

	minimizeBigButton.MouseButton1Click:connect(function (  )
		switchMinimize()
	end)

	minimizeButton.MouseButton1Click:connect(function(  )
		switchMinimize()
	end)

	if scrollable then
		return dragBar, frame, helpFrame, closeEvent
	else
		return dragBar, widgetContainer, helpFrame, closeEvent
	end
end

t.Help = 
	function(funcNameOrFunc) 
		--input argument can be a string or a function.  Should return a description (of arguments and expected side effects)
		if funcNameOrFunc == "CreatePropertyDropDownMenu" or funcNameOrFunc == t.CreatePropertyDropDownMenu then
			return "Function CreatePropertyDropDownMenu.  " ..
				   "Arguments: (instance, propertyName, enumType).  " .. 
				   "Side effect: returns a container with a drop-down-box that is linked to the 'property' field of 'instance' which is of type 'enumType'" 
		end 
		if funcNameOrFunc == "CreateDropDownMenu" or funcNameOrFunc == t.CreateDropDownMenu then
			return "Function CreateDropDownMenu.  " .. 
			       "Arguments: (items, onItemSelected).  " .. 
				   "Side effect: Returns 2 results, a container to the gui object and a 'updateSelection' function for external updating.  The container is a drop-down-box created around a list of items" 
		end 
		if funcNameOrFunc == "CreateMessageDialog" or funcNameOrFunc == t.CreateMessageDialog then
			return "Function CreateMessageDialog.  " .. 
			       "Arguments: (title, message, buttons). " .. 
			       "Side effect: Returns a gui object of a message box with 'title' and 'message' as passed in.  'buttons' input is an array of Tables contains a 'Text' and 'Function' field for the text/callback of each button"
		end		
		if funcNameOrFunc == "CreateStyledMessageDialog" or funcNameOrFunc == t.CreateStyledMessageDialog then
			return "Function CreateStyledMessageDialog.  " .. 
			       "Arguments: (title, message, style, buttons). " .. 
			       "Side effect: Returns a gui object of a message box with 'title' and 'message' as passed in.  'buttons' input is an array of Tables contains a 'Text' and 'Function' field for the text/callback of each button, 'style' is a string, either Error, Notify or Confirm"
		end
		if funcNameOrFunc == "GetFontHeight" or funcNameOrFunc == t.GetFontHeight then
			return "Function GetFontHeight.  " .. 
			       "Arguments: (font, fontSize). " .. 
			       "Side effect: returns the size in pixels of the given font + fontSize"
		end
		if funcNameOrFunc == "LayoutGuiObjects" or funcNameOrFunc == t.LayoutGuiObjects then
		
		end
		if funcNameOrFunc == "CreateScrollingFrame" or funcNameOrFunc == t.CreateScrollingFrame then
			return "Function CreateScrollingFrame.  " .. 
			   "Arguments: (orderList, style) " .. 
			   "Side effect: returns 4 objects, (scrollFrame, scrollUpButton, scrollDownButton, recalculateFunction).  'scrollFrame' can be filled with GuiObjects.  It will lay them out and allow scrollUpButton/scrollDownButton to interact with them.  Orderlist is optional (and specifies the order to layout the children.  Without orderlist, it uses the children order. style is also optional, and allows for a 'grid' styling if style is passed 'grid' as a string.  recalculateFunction can be called when a relayout is needed (when orderList changes)"
		end
		if funcNameOrFunc == "CreateTrueScrollingFrame" or funcNameOrFunc == t.CreateTrueScrollingFrame then
			return "Function CreateTrueScrollingFrame.  " .. 
			   "Arguments: (nil) " .. 
			   "Side effect: returns 2 objects, (scrollFrame, controlFrame).  'scrollFrame' can be filled with GuiObjects, and they will be clipped if not inside the frame's bounds. controlFrame has children scrollup and scrolldown, as well as a slider.  controlFrame can be parented to any guiobject and it will readjust itself to fit."
		end
		if funcNameOrFunc == "AutoTruncateTextObject" or funcNameOrFunc == t.AutoTruncateTextObject then
			return "Function AutoTruncateTextObject.  " .. 
			   "Arguments: (textLabel) " .. 
			   "Side effect: returns 2 objects, (textLabel, changeText).  The 'textLabel' input is modified to automatically truncate text (with ellipsis), if it gets too small to fit.  'changeText' is a function that can be used to change the text, it takes 1 string as an argument"
		end
		if funcNameOrFunc == "CreateSlider" or funcNameOrFunc == t.CreateSlider then
			return "Function CreateSlider.  " ..
				"Arguments: (steps, width, position) " ..
				"Side effect: returns 2 objects, (sliderGui, sliderPosition).  The 'steps' argument specifies how many different positions the slider can hold along the bar.  'width' specifies in pixels how wide the bar should be (modifiable afterwards if desired). 'position' argument should be a UDim2 for slider positioning. 'sliderPosition' is an IntValue whose current .Value specifies the specific step the slider is currently on."
		end
		if funcNameOrFunc == "CreateSliderNew" or funcNameOrFunc == t.CreateSliderNew then
			return "Function CreateSliderNew.  " ..
				"Arguments: (steps, width, position) " ..
				"Side effect: returns 2 objects, (sliderGui, sliderPosition).  The 'steps' argument specifies how many different positions the slider can hold along the bar.  'width' specifies in pixels how wide the bar should be (modifiable afterwards if desired). 'position' argument should be a UDim2 for slider positioning. 'sliderPosition' is an IntValue whose current .Value specifies the specific step the slider is currently on."
		end
		if funcNameOrFunc == "CreateLoadingFrame" or funcNameOrFunc == t.CreateLoadingFrame then
			return "Function CreateLoadingFrame.  " ..
				"Arguments: (name, size, position) " ..
				"Side effect: Creates a gui that can be manipulated to show progress for a particular action.  Name appears above the loading bar, and size and position are udim2 values (both size and position are optional arguments).  Returns 3 arguments, the first being the gui created. The second being updateLoadingGuiPercent, which is a bindable function.  This function takes one argument (two optionally), which should be a number between 0 and 1, representing the percentage the loading gui should be at.  The second argument to this function is a boolean value that if set to true will tween the current percentage value to the new percentage value, therefore our third argument is how long this tween should take. Our third returned argument is a BindableEvent, that when fired means that someone clicked the cancel button on the dialog."
		end
		if funcNameOrFunc == "CreateTerrainMaterialSelector" or funcNameOrFunc == t.CreateTerrainMaterialSelector then
			return "Function CreateTerrainMaterialSelector.  " ..
				"Arguments: (size, position) " ..
				"Side effect: Size and position are UDim2 values that specifies the selector's size and position.  Both size and position are optional arguments. This method returns 3 objects (terrainSelectorGui, terrainSelected, forceTerrainSelection).  terrainSelectorGui is just the gui object that we generate with this function, parent it as you like. TerrainSelected is a BindableEvent that is fired whenever a new terrain type is selected in the gui.  ForceTerrainSelection is a function that takes an argument of Enum.CellMaterial and will force the gui to show that material as currently selected."
		end
	end
	
function waitForChild(instance, name)
	while not instance:FindFirstChild(name) do
		instance.ChildAdded:wait()
	end
end

-- Do a line/plane intersection.  The line starts at the camera.  The plane is at y == 0, normal(0, 1, 0)
--
-- vectorPos - End point of the line.
-- 
-- Return:
-- cellPos - The terrain cell intersection point if there is one, vectorPos if there isn't.
-- hit - Whether there was a plane intersection.  Value is true if there was, false if not.
function PlaneIntersection(vectorPos)
	local hit = false
	local currCamera = game.Workspace.CurrentCamera
	local startPos = Vector3.new(currCamera.CoordinateFrame.p.X, currCamera.CoordinateFrame.p.Y, currCamera.CoordinateFrame.p.Z)
	local endPos = Vector3.new(vectorPos.X, vectorPos.Y, vectorPos.Z)
	local normal = Vector3.new(0, 1, 0)
	local p3 = Vector3.new(0, 0, 0)
	local startEndDot = normal:Dot(endPos - startPos)
	local cellPos = vectorPos
	if startEndDot ~= 0  then
		local t = normal:Dot(p3 - startPos) / startEndDot
		if(t >=0 and t <=1) then
			local intersection = ((endPos - startPos) * t) + startPos
			cellPos = game.Workspace.Terrain:WorldToCell(intersection)
			hit = true
		end
	end

	return cellPos, hit
end


-- Purpose:
-- Checks for terrain touched by the mouse hit.
-- Will do a plane intersection if no terrain is touched.
--
-- mouse - Mouse to check the .hit for.
--
-- Return:
-- cellPos - Cell position hit.  Nil if none.
function GetTerrainForMouse(mouse)
	-- There was no target, so all it could be is a plane intersection.
	-- Check for a plane intersection.  If there isn't one then nothing will get hit.
	local cell = game.Workspace.Terrain:WorldToCellPreferSolid(Vector3.new(mouse.hit.x, mouse.hit.y, mouse.hit.z))
	local planeLoc = nil
	-- If nothing was hit, do the plane intersection.
	if 0 == game.Workspace.Terrain:GetCell(cell.X, cell.Y, cell.Z).Value then
		cell = nil
		planeLoc, hit = PlaneIntersection(Vector3.new(mouse.hit.x, mouse.hit.y, mouse.hit.z))
		if hit then
			cell = planeLoc
		end
	end
	return cell
end

-- setup helper functions
local insertBoundingBoxOverlapVector = Vector3.new(.3, .3, .3) -- we can still stamp if our character extrudes into the target stamping space by .3 or fewer units

-- rotates a model by yAngle radians about the global y-axis
local function rotatePartAndChildren(part, rotCF, offsetFromOrigin)
	-- rotate this thing, if it's a part
	if part:IsA("BasePart") then
		part.CFrame = (rotCF * (part.CFrame - offsetFromOrigin)) + offsetFromOrigin
	end

	-- recursively do the same to all children
	local partChildren = part:GetChildren()
	for c = 1, #partChildren do rotatePartAndChildren(partChildren[c], rotCF, offsetFromOrigin) end
end

local function modelRotate(model, yAngle)
	local rotCF = CFrame.Angles(0, yAngle, 0)
	local offsetFromOrigin = model:GetModelCFrame().p

	rotatePartAndChildren(model, rotCF, offsetFromOrigin)
end


local function collectParts(object, baseParts, scripts, decals)
	if object:IsA("BasePart") then
		baseParts[#baseParts+1] = object
	elseif object:IsA("Script") then
		scripts[#scripts+1] = object
	elseif object:IsA("Decal") then
		decals[#decals+1] = object
	end

	for index,child in pairs(object:GetChildren()) do
		collectParts(child, baseParts, scripts, decals)
	end
end

local function clusterPartsInRegion(startVector, endVector)
	local cluster = game.Workspace:FindFirstChild("Terrain")

	local startCell = cluster:WorldToCell(startVector)
	local endCell = cluster:WorldToCell(endVector)

	local startX = startCell.X
	local startY = startCell.Y
	local startZ = startCell.Z

	local endX = endCell.X
	local endY = endCell.Y
	local endZ = endCell.Z

	if startX < cluster.MaxExtents.Min.X then startX = cluster.MaxExtents.Min.X end
	if startY < cluster.MaxExtents.Min.Y then startY = cluster.MaxExtents.Min.Y end
	if startZ < cluster.MaxExtents.Min.Z then startZ = cluster.MaxExtents.Min.Z end

	if endX > cluster.MaxExtents.Max.X then endX = cluster.MaxExtents.Max.X end
	if endY > cluster.MaxExtents.Max.Y then endY = cluster.MaxExtents.Max.Y end
	if endZ > cluster.MaxExtents.Max.Z then endZ = cluster.MaxExtents.Max.Z end

	for x = startX, endX do
		for y = startY, endY do
			for z = startZ, endZ do
				if (cluster:GetCell(x, y, z).Value) > 0 then return true end
			end
		end
	end

	return false
end

local function findSeatsInModel(parent, seatTable)
	if not parent then return end

	if parent.className == "Seat" or parent.className == "VehicleSeat" then
		table.insert(seatTable, parent)
	end
	local myChildren = parent:GetChildren()
	for j = 1, #myChildren do
		findSeatsInModel(myChildren[j], seatTable)
	end
end

local function setSeatEnabledStatus(model, isEnabled)
	local seatList = {}
	findSeatsInModel(model, seatList)

	if isEnabled then
		-- remove any welds called "SeatWeld" in seats
		for i = 1, #seatList do
			local nextSeat = seatList[i]:FindFirstChild("SeatWeld")
			while nextSeat do nextSeat:Remove() nextSeat = seatList[i]:FindFirstChild("SeatWeld") end
		end
	else
		-- put a weld called "SeatWeld" in every seat
		--   this tricks it into thinking there's already someone sitting there, and it won't make you sit XD
		for i = 1, #seatList do
			local fakeWeld = Instance.new("Weld")
			fakeWeld.Name = "SeatWeld"
			fakeWeld.Parent = seatList[i]
		end
	end
end

local function autoAlignToFace(parts)
	local aatf = parts:FindFirstChild("AutoAlignToFace")
	if aatf then return aatf.Value else return false end
end

local function getClosestAlignedWorldDirection(aVector3InWorld)
	local xDir = Vector3.new(1,0,0)
	local yDir = Vector3.new(0,1,0)
	local zDir = Vector3.new(0,0,1)
	local xDot = aVector3InWorld.x * xDir.x + aVector3InWorld.y * xDir.y + aVector3InWorld.z * xDir.z
	local yDot = aVector3InWorld.x * yDir.x + aVector3InWorld.y * yDir.y + aVector3InWorld.z * yDir.z
	local zDot = aVector3InWorld.x * zDir.x + aVector3InWorld.y * zDir.y + aVector3InWorld.z * zDir.z

	if math.abs(xDot) > math.abs(yDot) and math.abs(xDot) > math.abs(zDot) then
		if xDot > 0 then
			return 0
		else
			return 3
		end
	elseif math.abs(yDot) > math.abs(xDot) and math.abs(yDot) > math.abs(zDot) then
		if yDot > 0 then
			return 1
		else
			return 4
		end
	else
		if zDot > 0 then
			return 2
		else
			return 5
		end
	end 
end

local function positionPartsAtCFrame3(aCFrame, currentParts)
	local insertCFrame = nil
	if not currentParts then return currentParts end
	if currentParts and (currentParts:IsA("Model") or currentParts:IsA("Tool")) then
		insertCFrame = currentParts:GetModelCFrame()
		currentParts:TranslateBy(aCFrame.p - insertCFrame.p)
	else
		currentParts.CFrame = aCFrame
	end
	return currentParts
end

local function calcRayHitTime(rayStart, raySlope, intersectionPlane)
	if math.abs(raySlope) < .01 then return 0 end -- 0 slope -->  we just say intersection time is 0, and sidestep this dimension
	return (intersectionPlane - rayStart) / raySlope
end

local function modelTargetSurface(partOrModel, rayStart, rayEnd)
	if not partOrModel then
		return 0
	end

	local modelCFrame = nil
	local modelSize = nil
	if partOrModel:IsA("Model") then
		modelCFrame = partOrModel:GetModelCFrame()
		modelSize = partOrModel:GetModelSize()
	else
		modelCFrame = partOrModel.CFrame
		modelSize = partOrModel.Size
	end

	local mouseRayStart = modelCFrame:pointToObjectSpace(rayStart)
	local mouseRayEnd = modelCFrame:pointToObjectSpace(rayEnd)
	local mouseSlope = mouseRayEnd - mouseRayStart

	local xPositive = 1
	local yPositive = 1
	local zPositive = 1
	if mouseSlope.X > 0 then xPositive = -1 end
	if mouseSlope.Y > 0 then yPositive = -1 end
	if mouseSlope.Z > 0 then zPositive = -1 end

	-- find which surface the transformed mouse ray hits (using modelSize):
	local xHitTime = calcRayHitTime(mouseRayStart.X, mouseSlope.X, modelSize.X/2 * xPositive)
	local yHitTime = calcRayHitTime(mouseRayStart.Y, mouseSlope.Y, modelSize.Y/2 * yPositive)
	local zHitTime = calcRayHitTime(mouseRayStart.Z, mouseSlope.Z, modelSize.Z/2 * zPositive)

	local hitFace = 0

	--if xHitTime >= 0 and yHitTime >= 0 and zHitTime >= 0 then
	if xHitTime > yHitTime then
		if xHitTime > zHitTime then
			-- xFace is hit
			hitFace = 1*xPositive
		else
			-- zFace is hit
			hitFace = 3*zPositive
		end
	else
		if yHitTime > zHitTime then
			-- yFace is hit
			hitFace = 2*yPositive
		else
			-- zFace is hit
			hitFace = 3*zPositive
		end
	end

	return hitFace
end

local function getBoundingBox2(partOrModel)

	-- for models, the bounding box is defined as the minimum and maximum individual part bounding boxes
	-- relative to the first part's coordinate frame.
	local minVec = Vector3.new(math.huge, math.huge, math.huge)
	local maxVec = Vector3.new(-math.huge, -math.huge, -math.huge)

	if partOrModel:IsA("Terrain") then
		minVec = Vector3.new(-2, -2, -2)
		maxVec = Vector3.new(2, 2, 2)
	elseif partOrModel:IsA("BasePart") then
		minVec = -0.5 * partOrModel.Size
		maxVec = -minVec
	else
		maxVec = partOrModel:GetModelSize()*0.5
		minVec = -maxVec
	end

	-- Adjust bounding box to reflect what the model or part author wants in  terms of justification
	local justifyValue = partOrModel:FindFirstChild("Justification")
	if justifyValue ~= nil then
		-- find the multiple of 4 that contains the model
		justify = justifyValue.Value
		two = Vector3.new(2, 2, 2)
		actualBox = maxVec - minVec - Vector3.new(0.01, 0.01, 0.01)
		containingGridBox = Vector3.new(4 * math.ceil(actualBox.x/4), 4 * math.ceil(actualBox.y/4), 4 * math.ceil(actualBox.z/4))
		adjustment = containingGridBox - actualBox
		minVec = minVec - 0.5 * adjustment * justify
		maxVec = maxVec + 0.5 * adjustment * (two - justify)
	end

	return minVec, maxVec
end

local function getBoundingBoxInWorldCoordinates(partOrModel)
	local minVec = Vector3.new(math.huge, math.huge, math.huge)
	local maxVec = Vector3.new(-math.huge, -math.huge, -math.huge)

	if partOrModel:IsA("BasePart") and not partOrModel:IsA("Terrain") then
		vec1 = partOrModel.CFrame:pointToWorldSpace(-0.5 * partOrModel.Size)
		vec2 = partOrModel.CFrame:pointToWorldSpace(0.5 * partOrModel.Size)
		minVec = Vector3.new(math.min(vec1.X, vec2.X), math.min(vec1.Y, vec2.Y), math.min(vec1.Z, vec2.Z))
		maxVec = Vector3.new(math.max(vec1.X, vec2.X), math.max(vec1.Y, vec2.Y), math.max(vec1.Z, vec2.Z))
	elseif partOrModel:IsA("Terrain") then
		-- we shouldn't have to deal with this case
		--minVec = Vector3.new(-2, -2, -2)
		--maxVec = Vector3.new(2, 2, 2)
	else
		vec1 = partOrModel:GetModelCFrame():pointToWorldSpace(-0.5 * partOrModel:GetModelSize())
		vec2 = partOrModel:GetModelCFrame():pointToWorldSpace(0.5 * partOrModel:GetModelSize())
		minVec = Vector3.new(math.min(vec1.X, vec2.X), math.min(vec1.Y, vec2.Y), math.min(vec1.Z, vec2.Z))
		maxVec = Vector3.new(math.max(vec1.X, vec2.X), math.max(vec1.Y, vec2.Y), math.max(vec1.Z, vec2.Z))
	end

	return minVec, maxVec
end

local function getTargetPartBoundingBox(targetPart)
	if targetPart.Parent:FindFirstChild("RobloxModel") ~= nil then
		return getBoundingBox2(targetPart.Parent)
	else
		return getBoundingBox2(targetPart)
	end
end

local function getMouseTargetCFrame(targetPart)
	if targetPart.Parent:FindFirstChild("RobloxModel") ~= nil then
		if targetPart.Parent:IsA("Tool") then return targetPart.Parent.Handle.CFrame
		else return targetPart.Parent:GetModelCFrame() end
	else
		return targetPart.CFrame
	end
end

local function isBlocker(part) -- returns whether or not we want to cancel the stamp because we're blocked by this part
	if not part then return false end
	if not part.Parent then return false end
	if part:FindFirstChild("Humanoid") then return false end
	if part:FindFirstChild("RobloxStamper") or part:FindFirstChild("RobloxModel") then return true end
	if part:IsA("Part") and not part.CanCollide then return false end
	if part == game.Lighting then return false end
	return isBlocker(part.Parent)
end

-- helper function to determine if a character can be pushed upwards by a certain amount
-- character is 5 studs tall, we'll check a 1.5 x 1.5 x 4.5 box around char, with center .5 studs below torsocenter
local function spaceAboveCharacter(charTorso, newTorsoY, stampData)
	local partsAboveChar = game.Workspace:FindPartsInRegion3(
		Region3.new(Vector3.new(charTorso.Position.X, newTorsoY, charTorso.Position.Z) - Vector3.new(.75, 2.75, .75),
		Vector3.new(charTorso.Position.X, newTorsoY, charTorso.Position.Z) + Vector3.new(.75, 1.75, .75)), 
		charTorso.Parent, 
		100)
		
	for j = 1, #partsAboveChar do
		if partsAboveChar[j].CanCollide and not partsAboveChar[j]:IsDescendantOf(stampData.CurrentParts) then return false end
	end

	if clusterPartsInRegion(Vector3.new(charTorso.Position.X, newTorsoY, charTorso.Position.Z) - Vector3.new(.75, 2.75, .75), 
		Vector3.new(charTorso.Position.X, newTorsoY, charTorso.Position.Z) + Vector3.new(.75, 1.75, .75)) then 
			return false
	end

	return true
end


local function findConfigAtMouseTarget(Mouse, stampData)
	-- *Critical Assumption* :
	--				This function assumes the target CF axes are orthogonal with the target bounding box faces
	--				And, it assumes the insert CF axes are orthongonal with the insert bounding box faces
	--				Therefore, insertion will not work with angled faces on wedges or other "non-block" parts, nor
	--				will it work for parts in a model that are not orthogonally aligned with the model's CF.

	if not Mouse then return nil end -- This can happen sometimes, return if so
	if not stampData then error("findConfigAtMouseTarget: stampData is nil") return nil end
	if not stampData["CurrentParts"] then return nil end

	local grid = 4.0
	local admissibleConfig = false
	local targetConfig = CFrame.new(0,0,0)

	local minBB, maxBB = getBoundingBox2(stampData.CurrentParts)
	local diagBB = maxBB - minBB

	local insertCFrame
	if stampData.CurrentParts:IsA("Model") or stampData.CurrentParts:IsA("Tool") then
		insertCFrame = stampData.CurrentParts:GetModelCFrame()
	else
		insertCFrame = stampData.CurrentParts.CFrame
	end

	if Mouse then
		if stampData.CurrentParts:IsA("Tool") then 
			Mouse.TargetFilter = stampData.CurrentParts.Handle
		else
			Mouse.TargetFilter = stampData.CurrentParts
		end
	end

	local hitPlane = false
	local targetPart = nil
	local success = pcall(function() targetPart = Mouse.Target end)

	if not success then-- or targetPart == nil then
		return admissibleConfig, targetConfig
	end
	
	local mouseHitInWorld = Vector3.new(0, 0, 0)
	if Mouse then
		mouseHitInWorld = Vector3.new(Mouse.Hit.x, Mouse.Hit.y, Mouse.Hit.z)
	end
	
	local cellPos = nil
	
	-- Nothing was hit, so check for the default plane.
	if nil == targetPart then
		cellPos = GetTerrainForMouse(Mouse)
		if nil == cellPos then
			hitPlane = false
			return admissibleConfig, targetConfig
		else
			targetPart = game.Workspace.Terrain
			hitPlane = true
			-- Take into account error that will occur.
			cellPos = Vector3.new(cellPos.X - 1, cellPos.Y, cellPos.Z)
			mouseHitInWorld = game.Workspace.Terrain:CellCenterToWorld(cellPos.x, cellPos.y, cellPos.z)
		end
	end

	-- test mouse hit location
	local minBBTarget, maxBBTarget = getTargetPartBoundingBox(targetPart)
	local diagBBTarget = maxBBTarget - minBBTarget
	local targetCFrame = getMouseTargetCFrame(targetPart)

	if targetPart:IsA("Terrain") then
		if not cluster then cluster = game.Workspace:FindFirstChild("Terrain") end
		local cellID = cluster:WorldToCellPreferSolid(mouseHitInWorld)
		if hitPlane then
			cellID = cellPos
		end
		
		targetCFrame = CFrame.new(game.Workspace.Terrain:CellCenterToWorld(cellID.x, cellID.y, cellID.z))
	end
	
	local mouseHitInTarget = targetCFrame:pointToObjectSpace(mouseHitInWorld)
	local targetVectorInWorld = Vector3.new(0,0,0)
	if Mouse then
		-- DON'T WANT THIS IN TERMS OF THE MODEL CFRAME!  (.TargetSurface is in terms of the part CFrame, so this would break, right?  [HotThoth])
		--   (ideally, we would want to make the Mouse.TargetSurface a model-targetsurface instead, but for testing will be using the converse)
		--targetVectorInWorld = targetCFrame:vectorToWorldSpace(Vector3.FromNormalId(Mouse.TargetSurface))
		targetVectorInWorld = targetPart.CFrame:vectorToWorldSpace(Vector3.FromNormalId(Mouse.TargetSurface))   -- better, but model cframe would be best
		--[[if targetPart.Parent:IsA("Model") then
			local hitFace = modelTargetSurface(targetPart.Parent, Mouse.Hit.p, game.Workspace.CurrentCamera.CoordinateFrame.p)  -- best, if you get it right
			local WORLD_AXES = {Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)}
			if hitFace > 0 then
				targetVectorInWorld = targetCFrame:vectorToWorldSpace(WORLD_AXES[hitFace])
			elseif hitFace < 0 then
				targetVectorInWorld = targetCFrame:vectorToWorldSpace(-WORLD_AXES[-hitFace])
			end
		end]]
	end

	local targetRefPointInTarget
	local clampToSurface

	if getClosestAlignedWorldDirection(targetVectorInWorld) == 0 then
		targetRefPointInTarget = targetCFrame:vectorToObjectSpace(Vector3.new(1, -1, 1))
		insertRefPointInInsert = insertCFrame:vectorToObjectSpace(Vector3.new(-1, -1, 1))
		clampToSurface = Vector3.new(0,1,1)
	elseif getClosestAlignedWorldDirection(targetVectorInWorld) == 3 then
		targetRefPointInTarget = targetCFrame:vectorToObjectSpace(Vector3.new(-1, -1, -1))
		insertRefPointInInsert = insertCFrame:vectorToObjectSpace(Vector3.new(1, -1, -1))
		clampToSurface = Vector3.new(0,1,1)
	elseif getClosestAlignedWorldDirection(targetVectorInWorld) == 1 then
		targetRefPointInTarget = targetCFrame:vectorToObjectSpace(Vector3.new(-1, 1, 1))
		insertRefPointInInsert = insertCFrame:vectorToObjectSpace(Vector3.new(-1, -1, 1))
		clampToSurface = Vector3.new(1,0,1)		
	elseif getClosestAlignedWorldDirection(targetVectorInWorld) == 4 then
		targetRefPointInTarget = targetCFrame:vectorToObjectSpace(Vector3.new(-1, -1, 1))
		insertRefPointInInsert = insertCFrame:vectorToObjectSpace(Vector3.new(-1, 1, 1))
		clampToSurface = Vector3.new(1,0,1)
	elseif getClosestAlignedWorldDirection(targetVectorInWorld) == 2 then
		targetRefPointInTarget = targetCFrame:vectorToObjectSpace(Vector3.new(-1, -1, 1))
		insertRefPointInInsert = insertCFrame:vectorToObjectSpace(Vector3.new(-1, -1, -1))
		clampToSurface = Vector3.new(1,1,0)
	else
		targetRefPointInTarget = targetCFrame:vectorToObjectSpace(Vector3.new(1, -1, -1))
		insertRefPointInInsert = insertCFrame:vectorToObjectSpace(Vector3.new(1, -1, 1))
		clampToSurface = Vector3.new(1,1,0)
	end

	targetRefPointInTarget = targetRefPointInTarget * (0.5 * diagBBTarget) + 0.5 * (maxBBTarget + minBBTarget)
	insertRefPointInInsert = insertRefPointInInsert * (0.5 * diagBB) + 0.5 * (maxBB + minBB)
	
	-- To Do: For cases that are not aligned to the world grid, account for the minimal rotation
	-- needed to bring the Insert part(s) into alignment with the Target Part
	-- Apply the rotation here

	local delta = mouseHitInTarget - targetRefPointInTarget
	local deltaClamped = Vector3.new(grid * math.modf(delta.x/grid), grid * math.modf(delta.y/grid), grid * math.modf(delta.z/grid))
	deltaClamped = deltaClamped * clampToSurface
	local targetTouchInTarget = deltaClamped + targetRefPointInTarget

	local TargetTouchRelToWorld = targetCFrame:pointToWorldSpace(targetTouchInTarget)
	local InsertTouchInWorld = insertCFrame:vectorToWorldSpace(insertRefPointInInsert)
	local posInsertOriginInWorld = TargetTouchRelToWorld - InsertTouchInWorld

	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = insertCFrame:components()
	targetConfig = CFrame.new(posInsertOriginInWorld.x, posInsertOriginInWorld.y, posInsertOriginInWorld.z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
	admissibleConfig = true

	return admissibleConfig, targetConfig, getClosestAlignedWorldDirection(targetVectorInWorld)
end

local function truncateToCircleEighth(bigValue, littleValue)
	local big = math.abs(bigValue)
	local little = math.abs(littleValue)
	local hypotenuse = math.sqrt(big*big + little*little)
	local frac = little / hypotenuse

	local bigSign = 1
	local littleSign = 1
	if bigValue < 0 then bigSign = -1 end
	if littleValue < 0 then littleSign = -1 end

	if frac > .382683432 then
		-- between 22.5 and 45 degrees, so truncate to 45-degree tilt
		return .707106781 * hypotenuse * bigSign, .707106781 * hypotenuse * littleSign
	else 
		-- between 0 and 22.5 degrees, so truncate to 0-degree tilt
		return hypotenuse * bigSign, 0
	end
end


local function saveTheWelds(object, manualWeldTable, manualWeldParentTable)
	if object:IsA("ManualWeld") or object:IsA("Rotate") then
		table.insert(manualWeldTable, object)
		table.insert(manualWeldParentTable, object.Parent)
	else
		local children = object:GetChildren()
		for i = 1, #children do
			saveTheWelds(children[i], manualWeldTable, manualWeldParentTable)
		end
	end
end

local function restoreTheWelds(manualWeldTable, manualWeldParentTable)
	for i = 1, #manualWeldTable do
		manualWeldTable[i].Parent = manualWeldParentTable[i]
	end
end

t.CanEditRegion = function(partOrModel, EditRegion) -- todo: use model and stamper metadata
	if not EditRegion then return true, false end

	local minBB, maxBB = getBoundingBoxInWorldCoordinates(partOrModel)
	
	if minBB.X < EditRegion.CFrame.p.X - EditRegion.Size.X/2 or
		minBB.Y < EditRegion.CFrame.p.Y - EditRegion.Size.Y/2 or
		minBB.Z < EditRegion.CFrame.p.Z - EditRegion.Size.Z/2 then
			return false, false
	end
	
	if maxBB.X > EditRegion.CFrame.p.X + EditRegion.Size.X/2 or
		maxBB.Y > EditRegion.CFrame.p.Y + EditRegion.Size.Y/2 or
		maxBB.Z > EditRegion.CFrame.p.Z + EditRegion.Size.Z/2 then
			return false, false
	end
	
	return true, false
end

t.GetStampModel = function(assetId, terrainShape, useAssetVersionId)
	if assetId == 0 then
		return nil, "No Asset"
	end
	if assetId < 0 then
		return nil, "Negative Asset"
	end

	local function UnlockInstances(object)
		if object:IsA("BasePart") then
			object.Locked = false
		end
		for index,child in pairs(object:GetChildren()) do
			UnlockInstances(child)
		end
	end
	
	local function getClosestColorToTerrainMaterial(terrainValue)
		if terrainValue == 1 then
			return BrickColor.new("Bright green")
		elseif terrainValue == 2 then
			return BrickColor.new("Bright yellow")
		elseif terrainValue == 3 then
			return BrickColor.new("Bright red")
		elseif terrainValue == 4 then
			return BrickColor.new("Sand red")
		elseif terrainValue == 5 then
			return BrickColor.new("Black")
		elseif terrainValue == 6 then
			return BrickColor.new("Dark stone grey")
		elseif terrainValue == 7 then
			return BrickColor.new("Sand blue")
		elseif terrainValue == 8 then
			return BrickColor.new("Deep orange")
		elseif terrainValue == 9 then
			return BrickColor.new("Dark orange")
		elseif terrainValue == 10 then
			return BrickColor.new("Reddish brown")
		elseif terrainValue == 11 then
			return BrickColor.new("Light orange")
		elseif terrainValue == 12 then
			return BrickColor.new("Light stone grey")
		elseif terrainValue == 13 then
			return BrickColor.new("Sand green")
		elseif terrainValue == 14 then
			return BrickColor.new("Medium stone grey")
		elseif terrainValue == 15 then
			return BrickColor.new("Really red")
		elseif terrainValue == 16 then
			return BrickColor.new("Really blue")
		elseif terrainValue == 17 then
			return BrickColor.new("Bright blue")
		else
			return BrickColor.new("Bright green")
		end
	end
	
	local function setupFakeTerrainPart(cellMat, cellType, cellOrient)
		local newTerrainPiece = nil
		if (cellType == 1 or cellType == 4) then newTerrainPiece = Instance.new("WedgePart") newTerrainPiece.formFactor = "Custom"
		elseif (cellType == 2) then newTerrainPiece = Instance.new("CornerWedgePart")
		else newTerrainPiece = Instance.new("Part") newTerrainPiece.formFactor = "Custom" end
		newTerrainPiece.Name = "MegaClusterCube"
		newTerrainPiece.Size = Vector3.new(4, 4, 4)
		newTerrainPiece.BottomSurface = "Smooth"
		newTerrainPiece.TopSurface = "Smooth"

		-- can add decals or textures here if feeling particularly adventurous...  for now, can make a table of look-up colors
		newTerrainPiece.BrickColor = getClosestColorToTerrainMaterial(cellMat)

		local sideways = 0
		local flipped = math.pi
		if cellType == 4 then sideways = -math.pi/2 end
		if cellType == 2 or cellType == 3 then flipped = 0 end
		newTerrainPiece.CFrame = CFrame.Angles(0, math.pi/2*cellOrient + flipped, sideways)

		if cellType == 3 then
			local inverseCornerWedgeMesh = Instance.new("SpecialMesh")
			inverseCornerWedgeMesh.MeshType = "FileMesh"
			inverseCornerWedgeMesh.MeshId = "http://www.roblox.com/asset?id=66832495"
			inverseCornerWedgeMesh.Scale = Vector3.new(2, 2, 2)
			inverseCornerWedgeMesh.Parent = newTerrainPiece
		end

		local materialTag = Instance.new("Vector3Value")
		materialTag.Value = Vector3.new(cellMat, cellType, cellOrient)
		materialTag.Name = "ClusterMaterial"
		materialTag.Parent = newTerrainPiece

		return newTerrainPiece
	end
	
	-- This call will cause a "wait" until the data comes back
	-- below we wait a max of 8 seconds before deciding to bail out on loading
	local root
	local loader
	loading = true
	if useAssetVersionId then
		loader = coroutine.create(function()	
			root = game:GetService("InsertService"):LoadAssetVersion(assetId)
			loading = false
		end)
		coroutine.resume(loader)
	else
		loader = coroutine.create(function()	
			root = game:GetService("InsertService"):LoadAsset(assetId)
			loading = false
		end)
		coroutine.resume(loader)
	end

	local lastGameTime = 0
	local totalTime = 0
	local maxWait = 8
	while loading and totalTime < maxWait do
		lastGameTime = tick()
		wait(1)
		totalTime = totalTime + tick() - lastGameTime
	end
	loading = false

	if totalTime >= maxWait then
		return nil, "Load Time Fail"
	end


	if root == nil then
		return nil, "Load Asset Fail"
	end

	if not root:IsA("Model") then
		return nil, "Load Type Fail"
	end

	local instances = root:GetChildren()
	if #instances == 0 then
		return nil, "Empty Model Fail"
	end

	--Unlock all parts that are inserted, to make sure they are editable
	UnlockInstances(root)

	--Continue the insert process
	root = root:GetChildren()[1]

	--Examine the contents and decide what it looks like
	for pos, instance in pairs(instances) do
		if instance:IsA("Team") then
			instance.Parent = game:GetService("Teams")
		elseif instance:IsA("Sky") then
			local lightingService = game:GetService("Lighting")
			for index,child in pairs(lightingService:GetChildren()) do
				if child:IsA("Sky") then
					child:Remove();
				end
			end
			instance.Parent = lightingService
			return
		end
	end
	
	-- ...and tag all inserted models for subsequent origin identification
	-- if no RobloxModel tag already exists, then add it.
	if root:FindFirstChild("RobloxModel") == nil then
		local stringTag = Instance.new("BoolValue", root)
		stringTag.Name = "RobloxModel"

		if root:FindFirstChild("RobloxStamper") == nil then
			local stringTag2 = Instance.new("BoolValue", root)
			stringTag2.Name = "RobloxStamper"
		end
	end
	
	if terrainShape then
		if root.Name == "MegaClusterCube" then
			if (terrainShape == 6) then -- insert an autowedging tag
				local autowedgeTag = Instance.new("BoolValue")
				autowedgeTag.Name = "AutoWedge"
				autowedgeTag.Parent = root
			else
				local clusterTag = root:FindFirstChild("ClusterMaterial")
				if clusterTag then
					if clusterTag:IsA("Vector3Value") then
						root = setupFakeTerrainPart(clusterTag.Value.X, terrainShape, clusterTag.Value.Z)
					else
						root = setupFakeTerrainPart(clusterTag.Value, terrainShape, 0)
					end
				else
					root = setupFakeTerrainPart(1, terrainShape, 0)
				end
			end
		end
	end

	return root
end



t.SetupStamperDragger = function(modelToStamp, Mouse, StampInModel, AllowedStampRegion, StampFailedFunc)
	if not modelToStamp then
		error("SetupStamperDragger: modelToStamp (first arg) is nil!  Should be a stamper model")
		return nil 
	end
	if not modelToStamp:IsA("Model") and not modelToStamp:IsA("BasePart") then
		error("SetupStamperDragger: modelToStamp (first arg) is neither a Model or Part!")
		return nil 
	end
	if not Mouse then
		error("SetupStamperDragger: Mouse (second arg) is nil!  Should be a mouse object")
		return nil 
	end
	if not Mouse:IsA("Mouse") then
		error("SetupStamperDragger: Mouse (second arg) is not of type Mouse!")
		return nil 
	end
	
	local stampInModel = nil
	local allowedStampRegion = nil
	local stampFailedFunc = nil
	if StampInModel then
		if not StampInModel:IsA("Model") then
			error("SetupStamperDragger: StampInModel (optional third arg) is not of type 'Model'")
			return nil
		end
		if not AllowedStampRegion then
			error("SetupStamperDragger: AllowedStampRegion (optional fourth arg) is nil when StampInModel (optional third arg) is defined")
			return nil
		end
		stampFailedFunc = StampFailedFunc
		stampInModel = StampInModel
		allowedStampRegion = AllowedStampRegion
	end
	
	-- Init all state variables
	local gInitial90DegreeRotations = 0
	local stampData = nil
	local mouseTarget = nil
	
	local errorBox = Instance.new("SelectionBox")
	errorBox.Color = BrickColor.new("Bright red")
	errorBox.Transparency = 0
	errorBox.Archivable = false
	
	-- for megacluster MEGA STAMPING
	local adornPart = Instance.new("Part")
	adornPart.Parent = nil
	adornPart.formFactor = "Custom"
	adornPart.Size = Vector3.new(4, 4, 4)
	adornPart.CFrame = CFrame.new()
	adornPart.Archivable = false

	local adorn = Instance.new("SelectionBox")
	adorn.Color = BrickColor.new("Toothpaste")
	adorn.Adornee = adornPart
	adorn.Visible = true
	adorn.Transparency = 0
	adorn.Name = "HighScalabilityStamperLine"
	adorn.Archivable = false

	local HighScalabilityLine = {}
	HighScalabilityLine.Start = nil
	HighScalabilityLine.End = nil
	HighScalabilityLine.Adorn = adorn
	HighScalabilityLine.AdornPart = adornPart
	HighScalabilityLine.InternalLine = nil
	HighScalabilityLine.NewHint = true

	HighScalabilityLine.MorePoints = {nil, nil}
	HighScalabilityLine.MoreLines = {nil, nil}
	HighScalabilityLine.Dimensions = 1
	
	local control = {}
	local movingLock = false
	local stampUpLock = false
	local unstampableSurface = false
	local mouseCons = {}
	local keyCon = nil
	
	local stamped = Instance.new("BoolValue")
	stamped.Archivable = false
	stamped.Value = false
	
	local lastTarget = {}
	lastTarget.TerrainOrientation = 0
	lastTarget.CFrame = 0
	
	local cellInfo = {}
	cellInfo.Material = 1
	cellInfo.clusterType = 0
	cellInfo.clusterOrientation = 0
	
	local function isMegaClusterPart()
		if not stampData then return false end
		if not stampData.CurrentParts then return false end
		
		return ( stampData.CurrentParts:FindFirstChild("ClusterMaterial",true) or (stampData.CurrentParts.Name == "MegaClusterCube") )
	end
	
	local function DoHighScalabilityRegionSelect()
		local megaCube = stampData.CurrentParts:FindFirstChild("MegaClusterCube")
		if not megaCube then 
			if not stampData.CurrentParts.Name == "MegaClusterCube" then
				return
			else
				megaCube = stampData.CurrentParts
			end
		end
		
		HighScalabilityLine.End = megaCube.CFrame.p
		local line = nil
		local line2 = Vector3.new(0, 0, 0)
		local line3 = Vector3.new(0, 0, 0)
			
		if HighScalabilityLine.Dimensions == 1 then
			-- extract the line from these positions and limit to a 2D plane made from 2 of the world axes
			--   then use dominating axis to limit line to be at 45-degree intervals
			--   will use this internal representation of the line for the actual stamping
			line = (HighScalabilityLine.End - HighScalabilityLine.Start)

			if math.abs(line.X) < math.abs(line.Y) then
				if math.abs(line.X) < math.abs(line.Z) then
					-- limit to Y/Z plane, domination unknown
					local newY, newZ
					if (math.abs(line.Y) > math.abs(line.Z)) then 
						newY, newZ = truncateToCircleEighth(line.Y, line.Z)
					else 
						newZ, newY = truncateToCircleEighth(line.Z, line.Y)
					end
					line = Vector3.new(0, newY, newZ)
				else
					-- limit to X/Y plane, with Y dominating
					local newY, newX = truncateToCircleEighth(line.Y, line.X)
					line = Vector3.new(newX, newY, 0)
				end
			else
				if math.abs(line.Y) < math.abs(line.Z) then
					-- limit to X/Z plane, domination unknown
					local newX, newZ
					if math.abs(line.X) > math.abs(line.Z) then
						newX, newZ = truncateToCircleEighth(line.X, line.Z)
					else
						newZ, newX = truncateToCircleEighth(line.Z, line.X)
					end
					line = Vector3.new(newX, 0, newZ)
				else 
					-- limit to X/Y plane, with X dominating
					local newX, newY = truncateToCircleEighth(line.X, line.Y)
					line = Vector3.new(newX, newY, 0)
				end
			end
			HighScalabilityLine.InternalLine = line

		elseif HighScalabilityLine.Dimensions == 2 then
			line = HighScalabilityLine.MoreLines[1]
			line2 = HighScalabilityLine.End - HighScalabilityLine.MorePoints[1]
			
			-- take out any component of line2 along line1, so you get perpendicular to line1 component
			line2 = line2 - line.unit*line.unit:Dot(line2)

			tempCFrame = CFrame.new(HighScalabilityLine.Start, HighScalabilityLine.Start + line)

			-- then zero out whichever is the smaller component
			local yAxis = tempCFrame:vectorToWorldSpace(Vector3.new(0, 1, 0))
			local xAxis = tempCFrame:vectorToWorldSpace(Vector3.new(1, 0, 0))
					
			local xComp = xAxis:Dot(line2)
			local yComp = yAxis:Dot(line2)

			if math.abs(yComp) > math.abs(xComp) then
				line2 = line2 - xAxis * xComp
			else
				line2 = line2 - yAxis * yComp
			end

			HighScalabilityLine.InternalLine = line2
			
		elseif HighScalabilityLine.Dimensions == 3 then
			line  = HighScalabilityLine.MoreLines[1]
			line2 = HighScalabilityLine.MoreLines[2]
			line3 = HighScalabilityLine.End - HighScalabilityLine.MorePoints[2]

			-- zero out all components of previous lines
			line3 = line3 - line.unit * line.unit:Dot(line3)
			line3 = line3 - line2.unit * line2.unit:Dot(line3)

			HighScalabilityLine.InternalLine = line3
		end

		-- resize the "line" graphic to be the correct size and orientation
		tempCFrame = CFrame.new(HighScalabilityLine.Start, HighScalabilityLine.Start + line)
				
		if HighScalabilityLine.Dimensions == 1 then  -- faster calculation for line
			HighScalabilityLine.AdornPart.Size = Vector3.new(4, 4, line.magnitude + 4)
			HighScalabilityLine.AdornPart.CFrame = tempCFrame + tempCFrame:vectorToWorldSpace(Vector3.new(2, 2, 2) - HighScalabilityLine.AdornPart.Size/2)
		else
			local boxSize = tempCFrame:vectorToObjectSpace(line + line2 + line3)
			HighScalabilityLine.AdornPart.Size = Vector3.new(4, 4, 4) + Vector3.new(math.abs(boxSize.X), math.abs(boxSize.Y), math.abs(boxSize.Z))
			HighScalabilityLine.AdornPart.CFrame = tempCFrame + tempCFrame:vectorToWorldSpace(boxSize/2)
		end
		
		-- make player able to see this ish

		local gui = nil
		if game.Players["LocalPlayer"] then 
			gui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
			if gui and gui:IsA("PlayerGui") then
				if HighScalabilityLine.Dimensions == 1 and line.magnitude > 3 then -- don't show if mouse hasn't moved enough
					HighScalabilityLine.Adorn.Parent = gui
				elseif HighScalabilityLine.Dimensions > 1 then
					HighScalabilityLine.Adorn.Parent = gui
				end
			end
		end
		
		if gui == nil then -- we are in studio
			gui = game:GetService("CoreGui")
			if HighScalabilityLine.Dimensions == 1 and line.magnitude > 3 then -- don't show if mouse hasn't moved enough
				HighScalabilityLine.Adorn.Parent = gui
			elseif HighScalabilityLine.Dimensions > 1 then
				HighScalabilityLine.Adorn.Parent = gui
			end
		end
	end
	
	
	local function DoStamperMouseMove(Mouse)
		if not Mouse then
			error("Error: RbxStamper.DoStamperMouseMove: Mouse is nil")
			return
		end
		if not Mouse:IsA("Mouse") then
			error("Error: RbxStamper.DoStamperMouseMove: Mouse is of type", Mouse.className,"should be of type Mouse")
			return
		end
		
		-- There wasn't a target (no part or terrain), so check for plane intersection.
		if not Mouse.Target then 
			local cellPos = GetTerrainForMouse(Mouse)
			if nil == cellPos then
				return
			end
		end
		
		if not stampData then
			return
		end

		-- don't move with dragger - will move in one step on mouse down
		-- draw ghost at acceptable positions
		configFound, targetCFrame, targetSurface = findConfigAtMouseTarget(Mouse, stampData)
		if not configFound then
			error("RbxStamper.DoStamperMouseMove No configFound, returning")
			return
		end	

		local numRotations = 0 -- update this according to how many rotations you need to get it to target surface
		if autoAlignToFace(stampData.CurrentParts) and targetSurface ~= 1 and targetSurface ~= 4 then -- pre-rotate the flag or portrait so it's aligned correctly
			if		targetSurface == 3 then numRotations = 0 - gInitial90DegreeRotations + autoAlignToFace(stampData.CurrentParts)
			elseif	targetSurface == 0 then numRotations = 2 - gInitial90DegreeRotations + autoAlignToFace(stampData.CurrentParts)
			elseif	targetSurface == 5 then numRotations = 3 - gInitial90DegreeRotations + autoAlignToFace(stampData.CurrentParts)
			elseif	targetSurface == 2 then numRotations = 1 - gInitial90DegreeRotations + autoAlignToFace(stampData.CurrentParts)
			end
		end	

		local ry = math.pi/2
		gInitial90DegreeRotations = gInitial90DegreeRotations + numRotations
		if stampData.CurrentParts:IsA("Model") or stampData.CurrentParts:IsA("Tool") then
			--stampData.CurrentParts:Rotate(0, ry*numRotations, 0)
			modelRotate(stampData.CurrentParts, ry*numRotations)
		else
			stampData.CurrentParts.CFrame = CFrame.fromEulerAnglesXYZ(0, ry*numRotations, 0) * stampData.CurrentParts.CFrame
		end

		-- CODE TO CHECK FOR DRAGGING GHOST PART INTO A COLLIDING STATE
		local minBB, maxBB = getBoundingBoxInWorldCoordinates(stampData.CurrentParts)

		-- need to offset by distance to be dragged
		local currModelCFrame = nil
		if stampData.CurrentParts:IsA("Model") then
			currModelCFrame = stampData.CurrentParts:GetModelCFrame()
		else 
			currModelCFrame = stampData.CurrentParts.CFrame
		end
		
		minBB = minBB + targetCFrame.p - currModelCFrame.p
		maxBB = maxBB + targetCFrame.p - currModelCFrame.p

		-- don't drag into terrain
		if clusterPartsInRegion(minBB + insertBoundingBoxOverlapVector, maxBB - insertBoundingBoxOverlapVector) then
			if lastTarget.CFrame then
				if (stampData.CurrentParts:FindFirstChild("ClusterMaterial", true)) then
					local theClusterMaterial = stampData.CurrentParts:FindFirstChild("ClusterMaterial", true)
					if theClusterMaterial:IsA("Vector3Value") then
						local stampClusterMaterial = stampData.CurrentParts:FindFirstChild("ClusterMaterial", true)
						if stampClusterMaterial then
							stampClusterMaterial = clusterMat
						end
					end
				end
			end
			return
		end

		-- if we are stamping a terrain part, make sure it goes on the grid! Otherwise preview block could be placed off grid, but stamped on grid
		if isMegaClusterPart() then
			local cellToStamp = game.Workspace.Terrain:WorldToCell(targetCFrame.p)
			local newCFramePosition = game.Workspace.Terrain:CellCenterToWorld(cellToStamp.X, cellToStamp.Y, cellToStamp.Z)
			local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = targetCFrame:components()
			targetCFrame = CFrame.new(newCFramePosition.X,newCFramePosition.Y,newCFramePosition.Z,R00, R01, R02, R10, R11, R12, R20, R21, R22)
		end

		positionPartsAtCFrame3(targetCFrame, stampData.CurrentParts)
		lastTarget.CFrame = targetCFrame  -- successful positioning, so update 'dat cframe
		if stampData.CurrentParts:FindFirstChild("ClusterMaterial", true) then
			local clusterMat = stampData.CurrentParts:FindFirstChild("ClusterMaterial", true)
			if clusterMat:IsA("Vector3Value") then
				lastTarget.TerrainOrientation = clusterMat.Value.Z
			end
		end


		-- auto break joints code
		if Mouse and Mouse.Target and Mouse.Target.Parent then
			local modelInfo = Mouse.Target:FindFirstChild("RobloxModel")
			if not modelInfo then modelInfo = Mouse.Target.Parent:FindFirstChild("RobloxModel") end
			
			local myModelInfo = stampData.CurrentParts:FindFirstChild("UnstampableFaces")

			--if (modelInfo and modelInfo.Parent:FindFirstChild("UnstampableFaces")) or (modelInfo and myModelInfo) then  -- need better targetSurface calcs
			if (true) then
				local breakingFaces = ""
				local myBreakingFaces = ""
				if modelInfo and modelInfo.Parent:FindFirstChild("UnstampableFaces") then breakingFaces = modelInfo.Parent.UnstampableFaces.Value end
				if myModelInfo then myBreakingFaces = myModelInfo.Value end
				local hitFace = 0

				if modelInfo then hitFace = modelTargetSurface(modelInfo.Parent, game.Workspace.CurrentCamera.CoordinateFrame.p, Mouse.Hit.p) end

				-- are we stamping TO an unstampable surface?
				for bf in string.gmatch(breakingFaces, "[^,]+") do
					if hitFace == tonumber(bf) then
						-- return before we hit the JointsService code below!
						unstampableSurface = true
						game.JointsService:ClearJoinAfterMoveJoints() -- clear the JointsService cache
						return
					end
				end

				-- now we have to cast the ray back in the other direction to find the surface we're stamping FROM
				hitFace = modelTargetSurface(stampData.CurrentParts, Mouse.Hit.p, game.Workspace.CurrentCamera.CoordinateFrame.p)

				-- are we stamping WITH an unstampable surface?
				for bf in string.gmatch(myBreakingFaces, "[^,]+") do
					if hitFace == tonumber(bf) then
						unstampableSurface = true
						game.JointsService:ClearJoinAfterMoveJoints() -- clear the JointsService cache
						return
					end
				end

				-- just need to match breakingFace against targetSurface using rotation supplied by modelCFrame
				-- targetSurface: 1 is top, 4 is bottom, 
			end
		end

		-- to show joints during the mouse move
		unstampableSurface = false
		game.JointsService:SetJoinAfterMoveInstance(stampData.CurrentParts)

		-- most common mouse inactive error occurs here, so check mouse active one more time in a pcall
		if not pcall(function() 
				if Mouse and Mouse.Target and Mouse.Target.Parent:FindFirstChild("RobloxModel") == nil then 
					return
				else
					return
				end
			end) 
		then
			error("Error: RbxStamper.DoStamperMouseMove Mouse is nil on second check")
			game.JointsService:ClearJoinAfterMoveJoints()
			Mouse = nil
			return
		end

		if Mouse and Mouse.Target and Mouse.Target.Parent:FindFirstChild("RobloxModel") == nil then
			game.JointsService:SetJoinAfterMoveTarget(Mouse.Target)
		else
			game.JointsService:SetJoinAfterMoveTarget(nil)
		end
		game.JointsService:ShowPermissibleJoints()

		-- here we allow for a line of high-scalability parts
		if isMegaClusterPart() and HighScalabilityLine and HighScalabilityLine.Start then
				DoHighScalabilityRegionSelect()
		end
	end
	
	local function setupKeyListener(key, Mouse)
		if control and control["Paused"] then return end -- don't do this if we have no stamp
		
		key = string.lower(key)
		if key == 'r' and not autoAlignToFace(stampData.CurrentParts) then -- rotate the model
			gInitial90DegreeRotations = gInitial90DegreeRotations + 1
			
			-- Update orientation value if this is a fake terrain part
			local clusterValues = stampData.CurrentParts:FindFirstChild("ClusterMaterial", true)
			if clusterValues and clusterValues:IsA("Vector3Value") then
				clusterValues.Value = Vector3.new(clusterValues.Value.X, clusterValues.Value.Y, (clusterValues.Value.Z + 1) % 4)
			end
			
			-- Rotate the parts or all the parts in the model
			local ry = math.pi/2
			if stampData.CurrentParts:IsA("Model") or stampData.CurrentParts:IsA("Tool") then
				--stampData.CurrentParts:Rotate(0, ry, 0)
				modelRotate(stampData.CurrentParts, ry)
			else
				stampData.CurrentParts.CFrame = CFrame.fromEulerAnglesXYZ(0, ry, 0) * stampData.CurrentParts.CFrame
			end

			-- After rotating, update the position
			configFound, targetCFrame = findConfigAtMouseTarget(Mouse, stampData)
			if configFound then
				positionPartsAtCFrame3(targetCFrame, stampData.CurrentParts)
				
				-- update everything else in MouseMove
				DoStamperMouseMove(Mouse)
			end
		elseif key == 'c' then -- try to expand our high scalability dragger dimension
			if HighScalabilityLine.InternalLine and HighScalabilityLine.InternalLine.magnitude > 0 and HighScalabilityLine.Dimensions < 3 then
				HighScalabilityLine.MorePoints[HighScalabilityLine.Dimensions] = HighScalabilityLine.End
				HighScalabilityLine.MoreLines[HighScalabilityLine.Dimensions] = HighScalabilityLine.InternalLine
				HighScalabilityLine.Dimensions = HighScalabilityLine.Dimensions + 1
				HighScalabilityLine.NewHint = true
			end
		end
	end
	
	keyCon = Mouse.KeyDown:connect(function(key) -- init key connection (keeping code close to func)
		setupKeyListener(key, Mouse)
	end)
	
	local function resetHighScalabilityLine()
		if HighScalabilityLine then
			HighScalabilityLine.Start = nil
			HighScalabilityLine.End = nil
			HighScalabilityLine.InternalLine = nil
			HighScalabilityLine.NewHint = true
		end
	end

	local function flashRedBox()
		local gui = game.CoreGui
		if game:FindFirstChild("Players") then
			if game.Players["LocalPlayer"] then
				if game.Players.LocalPlayer:FindFirstChild("PlayerGui") then
					gui = game.Players.LocalPlayer.PlayerGui
				end
			end
		end
		if not stampData["ErrorBox"] then return end
		
		stampData.ErrorBox.Parent = gui
		if stampData.CurrentParts:IsA("Tool") then 
			stampData.ErrorBox.Adornee = stampData.CurrentParts.Handle
		else 
			stampData.ErrorBox.Adornee = stampData.CurrentParts
		end

		delay(0,function()
			for i = 1, 3 do
				if stampData["ErrorBox"] then stampData.ErrorBox.Visible = true end
				wait(0.13)
				if stampData["ErrorBox"] then stampData.ErrorBox.Visible = false end
				wait(0.13)
			end
			if stampData["ErrorBox"] then
				stampData.ErrorBox.Adornee = nil
				stampData.ErrorBox.Parent = Tool
			end
		end)
	end
	
	local function DoStamperMouseDown(Mouse)
		if not Mouse then
			error("Error: RbxStamper.DoStamperMouseDown: Mouse is nil")
			return
		end
		if not Mouse:IsA("Mouse") then
			error("Error: RbxStamper.DoStamperMouseDown: Mouse is of type", Mouse.className,"should be of type Mouse")
			return
		end
		if not stampData then 
			return
		end

		if isMegaClusterPart() then
			if Mouse and HighScalabilityLine then
				local megaCube = stampData.CurrentParts:FindFirstChild("MegaClusterCube", true)
				local terrain = game.Workspace.Terrain
				if megaCube then
					HighScalabilityLine.Dimensions = 1
					local tempCell = terrain:WorldToCell(megaCube.CFrame.p)
					HighScalabilityLine.Start = terrain:CellCenterToWorld(tempCell.X, tempCell.Y, tempCell.Z)
					return
				else
					HighScalabilityLine.Dimensions = 1
					local tempCell = terrain:WorldToCell(stampData.CurrentParts.CFrame.p)
					HighScalabilityLine.Start = terrain:CellCenterToWorld(tempCell.X, tempCell.Y, tempCell.Z)
					return
				end
			end
		end
	end
	
	local function loadSurfaceTypes(part, surfaces)
		part.TopSurface = surfaces[1]
		part.BottomSurface = surfaces[2]
		part.LeftSurface = surfaces[3]
		part.RightSurface = surfaces[4]
		part.FrontSurface = surfaces[5]
		part.BackSurface = surfaces[6]
	end

	local function saveSurfaceTypes(part, myTable)
		local tempTable = {}
		tempTable[1] = part.TopSurface
		tempTable[2] = part.BottomSurface
		tempTable[3] = part.LeftSurface
		tempTable[4] = part.RightSurface
		tempTable[5] = part.FrontSurface
		tempTable[6] = part.BackSurface
		
		myTable[part] = tempTable
	end

	local function makeSurfaceUnjoinable(part, surface)
		-- TODO: FILL OUT!
	end

	local function prepareModel(model)
		if not model then return nil end
		
		local gDesiredTrans = 0.7
		local gStaticTrans = 1

		local clone = model:Clone()
		local scripts = {}
		local parts = {}
		local decals = {}
		
		stampData = {}
		stampData.DisabledScripts = {}
		stampData.TransparencyTable = {}
		stampData.MaterialTable = {}
		stampData.CanCollideTable = {}
		stampData.AnchoredTable = {}
		stampData.ArchivableTable = {}
		stampData.DecalTransparencyTable = {}
		stampData.SurfaceTypeTable = {}
		
		collectParts(clone, parts, scripts, decals)

		if #parts <= 0 then return nil, "no parts found in modelToStamp" end

		for index,script in pairs(scripts) do
			if not(script.Disabled) then
				script.Disabled = true
				stampData.DisabledScripts[#stampData.DisabledScripts + 1] = script
			end
		end
		for index, part in pairs(parts) do
			stampData.TransparencyTable[part] = part.Transparency
			part.Transparency = gStaticTrans + (1 - gStaticTrans) * part.Transparency
			stampData.MaterialTable[part] = part.Material
			part.Material = Enum.Material.Plastic
			stampData.CanCollideTable[part] = part.CanCollide
			part.CanCollide = false
			stampData.AnchoredTable[part] = part.Anchored
			part.Anchored = true
			stampData.ArchivableTable[part] = part.Archivable
			part.Archivable = false

			saveSurfaceTypes(part, stampData.SurfaceTypeTable)
			
			local fadeInDelayTime = 0.5
			local transFadeInTime = 0.5
			delay(0,function()
				wait(fadeInDelayTime) -- give it some time to be completely transparent
				
				local begTime = tick()
				local currTime = begTime
				while (currTime - begTime) < transFadeInTime and part and part:IsA("BasePart") and part.Transparency > gDesiredTrans do
					local newTrans = 1 - (((currTime - begTime)/transFadeInTime) * (gStaticTrans - gDesiredTrans))
					if stampData["TransparencyTable"] and stampData.TransparencyTable[part] then
						part.Transparency = newTrans + (1 - newTrans) * stampData.TransparencyTable[part]
					end
					wait(0.03)
					currTime = tick()
				end
				if part and part:IsA("BasePart") then
					if stampData["TransparencyTable"] and stampData.TransparencyTable[part] then
						part.Transparency = gDesiredTrans + (1 - gDesiredTrans) * stampData.TransparencyTable[part]
					end
				end
			end)
		end

		for index, decal in pairs(decals) do
			stampData.DecalTransparencyTable[decal] = decal.Transparency
			decal.Transparency = gDesiredTrans + (1 - gDesiredTrans) * decal.Transparency
		end
		
		-- disable all seats
		setSeatEnabledStatus(clone, true)
		setSeatEnabledStatus(clone, false)

		stampData.CurrentParts = clone

		-- if auto-alignable, we enforce a pre-rotation to the canonical "0-frame"
		if autoAlignToFace(clone) then
			stampData.CurrentParts:ResetOrientationToIdentity()
			gInitial90DegreeRotations = 0
		else -- pre-rotate if necessary
			local ry = gInitial90DegreeRotations * math.pi/2
			if stampData.CurrentParts:IsA("Model") or stampData.CurrentParts:IsA("Tool") then
				--stampData.CurrentParts:Rotate(0, ry, 0)
				modelRotate(stampData.CurrentParts, ry)
			else
				stampData.CurrentParts.CFrame = CFrame.fromEulerAnglesXYZ(0, ry, 0) * stampData.CurrentParts.CFrame
			end
		end

		-- since we're cloning the old model instead of the new one, we will need to update the orientation based on the original value AND how many more
		--  rotations we expect since then [either that or we need to store the just-stamped clusterMaterial.Value.Z somewhere].  This should fix the terrain rotation
		--  issue (fingers crossed) [HotThoth]

		local clusterMaterial = stampData.CurrentParts:FindFirstChild("ClusterMaterial", true)
		if clusterMaterial and clusterMaterial:IsA("Vector3Value") then
			clusterMaterial.Value = Vector3.new(clusterMaterial.Value.X, clusterMaterial.Value.Y, (clusterMaterial.Value.Z + gInitial90DegreeRotations) % 4)
		end

		-- After rotating, update the position
		local configFound, targetCFrame = findConfigAtMouseTarget(Mouse, stampData)
		if configFound then
			stampData.CurrentParts = positionPartsAtCFrame3(targetCFrame, stampData.CurrentParts)
		end
		
		-- to show joints during the mouse move
		game.JointsService:SetJoinAfterMoveInstance(stampData.CurrentParts)
		
		return clone, parts
	end
	
	local function checkTerrainBlockCollisions(cellPos, checkHighScalabilityStamp)
		local cellCenterToWorld = game.Workspace.Terrain.CellCenterToWorld
		local cellCenter = cellCenterToWorld(game.Workspace.Terrain, cellPos.X, cellPos.Y, cellPos.Z)
		local cellBlockingParts = game.Workspace:FindPartsInRegion3(Region3.new(cellCenter - Vector3.new(2, 2, 2) + insertBoundingBoxOverlapVector, cellCenter + Vector3.new(2, 2, 2) - insertBoundingBoxOverlapVector), stampData.CurrentParts,	100)

		local skipThisCell = false
		
		for b = 1, #cellBlockingParts do
			if isBlocker(cellBlockingParts[b]) then skipThisCell = true break end
		end
								
		if not skipThisCell then
			-- pop players up above any set cells
			local alreadyPushedUp = {}
			-- if no blocking model below, then see if stamping on top of a character
			for b = 1, #cellBlockingParts do
				if	cellBlockingParts[b].Parent and 
					not alreadyPushedUp[cellBlockingParts[b].Parent] and 
					cellBlockingParts[b].Parent:FindFirstChild("Humanoid") and 
					cellBlockingParts[b].Parent:FindFirstChild("Humanoid"):IsA("Humanoid") then
				-----------------------------------------------------------------------------------
						local blockingPersonTorso = cellBlockingParts[b].Parent:FindFirstChild("Torso")
						alreadyPushedUp[cellBlockingParts[b].Parent] = true

						if blockingPersonTorso then
							-- if so, let's push the person upwards so they pop on top of the stamped model/part (but only if there's space above them)
							local newY = cellCenter.Y + 5
							if spaceAboveCharacter(blockingPersonTorso, newY, stampData) then
								blockingPersonTorso.CFrame = blockingPersonTorso.CFrame + Vector3.new(0, newY - blockingPersonTorso.CFrame.p.Y, 0)
							else
								-- if no space, we just skip this one
								skipThisCell = true
								break
							end
						end
				-----------------------------------------------------------------------------------
				end
			end
		end
							
		if not skipThisCell then  -- if we STILL aren't skipping...  then we're good to go!
			local canSetCell = true
			
			if checkHighScalabilityStamp then -- check to see if cell is in region, if not we'll skip set
				if allowedStampRegion then
					local cellPos = cellCenterToWorld(game.Workspace.Terrain, cellPos.X, cellPos.Y, cellPos.Z)
					if cellPos.X + 2 > allowedStampRegion.CFrame.p.X + allowedStampRegion.Size.X/2 then
						canSetCell = false
					elseif cellPos.X - 2 < allowedStampRegion.CFrame.p.X - allowedStampRegion.Size.X/2 then
						canSetCell = false
					elseif cellPos.Y + 2 > allowedStampRegion.CFrame.p.Y + allowedStampRegion.Size.Y/2 then
						canSetCell = false
					elseif cellPos.Y - 2 < allowedStampRegion.CFrame.p.Y - allowedStampRegion.Size.Y/2 then
						canSetCell = false
					elseif cellPos.Z + 2 > allowedStampRegion.CFrame.p.Z + allowedStampRegion.Size.Z/2 then
						canSetCell = false
					elseif cellPos.Z - 2 < allowedStampRegion.CFrame.p.Z - allowedStampRegion.Size.Z/2 then
						canSetCell = false
					end
				end
			end
			
			return canSetCell
		end
		return false
	end


	local function ResolveMegaClusterStamp(checkHighScalabilityStamp)
		local cellSet = false

		local cluser = game.Workspace.Terrain
		
		local line = HighScalabilityLine.InternalLine
		local cMax = game.Workspace.Terrain.MaxExtents.Max
		local cMin = game.Workspace.Terrain.MaxExtents.Min

		local clusterMaterial = 1 -- default is grass
		local clusterType = 0 -- default is brick
		local clusterOrientation = 0 -- default is 0 rotation

		local autoWedgeClusterParts = false
		if stampData.CurrentParts:FindFirstChild("AutoWedge") then autoWedgeClusterParts = true end

		if stampData.CurrentParts:FindFirstChild("ClusterMaterial", true) then
			clusterMaterial = stampData.CurrentParts:FindFirstChild("ClusterMaterial", true) 
			if clusterMaterial:IsA("Vector3Value") then
				clusterType = clusterMaterial.Value.Y
				clusterOrientation = clusterMaterial.Value.Z
				clusterMaterial = clusterMaterial.Value.X
			elseif clusterMaterial:IsA("IntValue") then
				clusterMaterial = clusterMaterial.Value
			end
		end
			
		if HighScalabilityLine.Adorn.Parent and HighScalabilityLine.Start and ((HighScalabilityLine.Dimensions > 1) or (line and line.magnitude > 0)) then
			local startCell = game.Workspace.Terrain:WorldToCell(HighScalabilityLine.Start)
			local xInc = {0,0,0}
			local yInc = {0,0,0}
			local zInc = {0,0,0}
			
			local cluster = game.Workspace.Terrain
				
			local incrementVect = {nil, nil, nil}
			local stepVect = {Vector3.new(0, 0, 0), Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)}

			local worldAxes = {Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)}

			local lines = {}
			if HighScalabilityLine.Dimensions > 1 then table.insert(lines, HighScalabilityLine.MoreLines[1]) end
			if line and line.magnitude > 0 then table.insert(lines, line) end
			if HighScalabilityLine.Dimensions > 2 then table.insert(lines, HighScalabilityLine.MoreLines[2]) end

			for i = 1, #lines do
				lines[i] = Vector3.new(math.floor(lines[i].X+.5), math.floor(lines[i].Y+.5), math.floor(lines[i].Z+.5)) -- round to integers

				if lines[i].X > 0 then xInc[i] = 1 elseif lines[i].X < 0 then xInc[i] = -1 end
				if lines[i].Y > 0 then yInc[i] = 1 elseif lines[i].Y < 0 then yInc[i] = -1 end
				if lines[i].Z > 0 then zInc[i] = 1 elseif lines[i].Z < 0 then zInc[i] = -1 end

				incrementVect[i] = Vector3.new(xInc[i], yInc[i], zInc[i])
				if incrementVect[i].magnitude < .9 then incrementVect[i] = nil end
			end


			if not lines[2] then lines[2] = Vector3.new(0, 0, 0) end
			if not lines[3] then lines[3] = Vector3.new(0, 0, 0) end

			local waterForceTag = stampData.CurrentParts:FindFirstChild("WaterForceTag", true)
			local waterForceDirectionTag = stampData.CurrentParts:FindFirstChild("WaterForceDirectionTag", true)
			
			while (stepVect[3].magnitude*4 <= lines[3].magnitude) do
				local outerStepVectIndex = 1
				while outerStepVectIndex < 4 do
					stepVect[2] = Vector3.new(0, 0, 0)
					while (stepVect[2].magnitude*4 <= lines[2].magnitude) do
						local innerStepVectIndex = 1
						while innerStepVectIndex < 4 do
							stepVect[1] = Vector3.new(0, 0, 0)
							while (stepVect[1].magnitude*4 <= lines[1].magnitude) do
								local stepVectSum = stepVect[1] + stepVect[2] + stepVect[3]
								local cellPos = Vector3int16.new(startCell.X + stepVectSum.X, startCell.Y + stepVectSum.Y, startCell.Z + stepVectSum.Z)
								if cellPos.X >= cMin.X and cellPos.Y >= cMin.Y and cellPos.Z >= cMin.Z and cellPos.X < cMax.X and cellPos.Y < cMax.Y and cellPos.Z < cMax.Z then
									-- check if overlaps player or part
									local okToStampTerrainBlock = checkTerrainBlockCollisions(cellPos, checkHighScalabilityStamp)
									
									if okToStampTerrainBlock then
										if waterForceTag then
											cluster:SetWaterCell(cellPos.X, cellPos.Y, cellPos.Z, Enum.WaterForce[waterForceTag.Value], Enum.WaterDirection[waterForceDirectionTag.Value])
										else
											cluster:SetCell(cellPos.X, cellPos.Y, cellPos.Z, clusterMaterial, clusterType, clusterOrientation)
										end
										cellSet = true 
						
										-- auto-wedge it?
										if (autoWedgeClusterParts) then
											game.Workspace.Terrain:AutowedgeCells(Region3int16.new(Vector3int16.new(cellPos.x - 1, cellPos.y - 1, cellPos.z - 1),
												Vector3int16.new(cellPos.x + 1, cellPos.y + 1, cellPos.z + 1)))
										end
									end
								end
								stepVect[1] = stepVect[1] + incrementVect[1]
							end
							if incrementVect[2] then
								while innerStepVectIndex < 4 and worldAxes[innerStepVectIndex]:Dot(incrementVect[2]) == 0 do 
									innerStepVectIndex = innerStepVectIndex + 1
								end
								if innerStepVectIndex < 4 then 
									stepVect[2] = stepVect[2] + worldAxes[innerStepVectIndex] * worldAxes[innerStepVectIndex]:Dot(incrementVect[2])
								end
								innerStepVectIndex = innerStepVectIndex + 1
							else
								stepVect[2] = Vector3.new(1, 0, 0)
								innerStepVectIndex = 4 -- skip all remaining loops
							end 
							if (stepVect[2].magnitude*4 > lines[2].magnitude) then innerStepVectIndex = 4 end
						end
					end
					if incrementVect[3] then 
						while outerStepVectIndex < 4 and worldAxes[outerStepVectIndex]:Dot(incrementVect[3]) == 0 do
							outerStepVectIndex = outerStepVectIndex + 1
						end
						if outerStepVectIndex < 4 then
							stepVect[3] = stepVect[3] + worldAxes[outerStepVectIndex] * worldAxes[outerStepVectIndex]:Dot(incrementVect[3]) 
						end
						outerStepVectIndex = outerStepVectIndex + 1
					else -- skip all remaining loops
						stepVect[3] = Vector3.new(1, 0, 0) outerStepVectIndex = 4 
					end 
					if (stepVect[3].magnitude*4 > lines[3].magnitude) then outerStepVectIndex = 4 end
				end
			end
		end

		-- and also get rid of any HighScalabilityLine stuff if it's there
		HighScalabilityLine.Start = nil
		HighScalabilityLine.Adorn.Parent = nil
		
		-- Mark for undo.
		if cellSet then
			stampData.CurrentParts.Parent = nil
			pcall(function() game:GetService("ChangeHistoryService"): SetWaypoint("StamperMulti") end)
		end
		
		return cellSet
	end
	
	local function DoStamperMouseUp(Mouse)
		if not Mouse then
			error("Error: RbxStamper.DoStamperMouseUp: Mouse is nil")
			return false
		end
		if not Mouse:IsA("Mouse") then
			error("Error: RbxStamper.DoStamperMouseUp: Mouse is of type", Mouse.className,"should be of type Mouse")
			return false
		end

		if not stampData.Dragger then
			error("Error: RbxStamper.DoStamperMouseUp: stampData.Dragger is nil")
			return false
		end
		
		if not HighScalabilityLine then
			return false
		end
		
		local checkHighScalabilityStamp = nil
		if stampInModel then
			local canStamp = nil
			local isHSLPart = isMegaClusterPart()
			
			if isHSLPart and
				HighScalabilityLine and
				HighScalabilityLine.Start and
				HighScalabilityLine.InternalLine and
				HighScalabilityLine.InternalLine.magnitude > 0 then -- we have an HSL line, test later
					canStamp = true
					checkHighScalabilityStamp = true
			else
				canStamp, checkHighScalabilityStamp = t.CanEditRegion(stampData.CurrentParts, allowedStampRegion)
			end
			
			if not canStamp then
				if stampFailedFunc then
					stampFailedFunc()
				end
				return false
			end
		end

		-- if unstampable face, then don't let us stamp there!
		if unstampableSurface then
			flashRedBox()
			return false
		end
		
		-- recheck if we can stamp, as we just moved part
		canStamp, checkHighScalabilityStamp = t.CanEditRegion(stampData.CurrentParts, allowedStampRegion)
		if not canStamp then
			if stampFailedFunc then
				stampFailedFunc()
			end
			return false
		end 

		-- Prevent part from being stamped on top of a player

		local minBB, maxBB = getBoundingBoxInWorldCoordinates(stampData.CurrentParts)

		-- HotThoth's note:  Now that above CurrentParts positioning has been commented out, to be truly correct, we would need to use the 
		--                     value of configFound from the previous onStamperMouseMove call which moved the CurrentParts
		--                     Shouldn't this be true when lastTargetCFrame has been set and false otherwise?
		configFound, targetCFrame = findConfigAtMouseTarget(Mouse, stampData)

		if configFound and not HighScalabilityLine.Adorn.Parent then
			if clusterPartsInRegion(minBB + insertBoundingBoxOverlapVector, maxBB - insertBoundingBoxOverlapVector) then 
				flashRedBox()
				return false
			end

			local blockingParts = game.Workspace:FindPartsInRegion3(Region3.new(minBB + insertBoundingBoxOverlapVector,
																	maxBB - insertBoundingBoxOverlapVector), 
																	stampData.CurrentParts,
																	100)
																	
										
			for b = 1, #blockingParts do
				if isBlocker(blockingParts[b]) then
					flashRedBox()
					return false
				end
			end

			local alreadyPushedUp = {}
				-- if no blocking model below, then see if stamping on top of a character
				for b = 1, #blockingParts do
					if	blockingParts[b].Parent and 
						not alreadyPushedUp[blockingParts[b].Parent] and 
						blockingParts[b].Parent:FindFirstChild("Humanoid") and 
						blockingParts[b].Parent:FindFirstChild("Humanoid"):IsA("Humanoid") then
					---------------------------------------------------------------------------
							local blockingPersonTorso = blockingParts[b].Parent:FindFirstChild("Torso")
							alreadyPushedUp[blockingParts[b].Parent] = true

							if blockingPersonTorso then
								-- if so, let's push the person upwards so they pop on top of the stamped model/part (but only if there's space above them)
								local newY = maxBB.Y + 3
								if spaceAboveCharacter(blockingPersonTorso, newY, stampData) then
									blockingPersonTorso.CFrame = blockingPersonTorso.CFrame + Vector3.new(0, newY - blockingPersonTorso.CFrame.p.Y, 0)
								else
									-- if no space, we just error
									flashRedBox()
									return false
								end
							end
					---------------------------------------------------------------------------
					end
				end
				
		elseif (not configFound) and not (HighScalabilityLine.Start and HighScalabilityLine.Adorn.Parent) then -- if no config then only stamp if it's a real HSL!
			resetHighScalabilityLine()
			return false
		end

		-- something will be stamped!  so set the "StampedSomething" toggle to true
		if game:FindFirstChild("Players") then
			if game.Players["LocalPlayer"] then
				if game.Players.LocalPlayer["Character"] then
					local localChar = game.Players.LocalPlayer.Character
					local stampTracker = localChar:FindFirstChild("StampTracker")
					if stampTracker and not stampTracker.Value then 
						stampTracker.Value = true
					end
				end
			end
		end

		-- if we drew a line of mega parts, stamp them out
		if HighScalabilityLine.Start and HighScalabilityLine.Adorn.Parent and isMegaClusterPart() then
			if ResolveMegaClusterStamp(checkHighScalabilityStamp) or checkHighScalabilityStamp then
				-- kill the ghost part
				stampData.CurrentParts.Parent = nil
				return true
			end
		end

		-- not High-Scalability-Line-Based, so behave normally [and get rid of any HSL stuff]
		HighScalabilityLine.Start = nil
		HighScalabilityLine.Adorn.Parent = nil
		
		local cluster = game.Workspace.Terrain

		-- if target point is in cluster, just use cluster:SetCell
		if isMegaClusterPart() then
			-- if targetCFrame is inside cluster, just set that cell to 1 and return
			--local cellPos = cluster:WorldToCell(targetCFrame.p)

			local cellPos
			if stampData.CurrentParts:IsA("Model") then cellPos = cluster:WorldToCell(stampData.CurrentParts:GetModelCFrame().p)
			else cellPos = cluster:WorldToCell(stampData.CurrentParts.CFrame.p) end

			local cMax = game.Workspace.Terrain.MaxExtents.Max
			local cMin = game.Workspace.Terrain.MaxExtents.Min
				
			if checkTerrainBlockCollisions(cellPos, false) then 

				local clusterValues = stampData.CurrentParts:FindFirstChild("ClusterMaterial", true)
				local waterForceTag = stampData.CurrentParts:FindFirstChild("WaterForceTag", true)
				local waterForceDirectionTag = stampData.CurrentParts:FindFirstChild("WaterForceDirectionTag", true)

				if cellPos.X >= cMin.X and cellPos.Y >= cMin.Y and cellPos.Z >= cMin.Z and cellPos.X < cMax.X and cellPos.Y < cMax.Y and cellPos.Z < cMax.Z then

					if waterForceTag then
						cluster:SetWaterCell(cellPos.X, cellPos.Y, cellPos.Z, Enum.WaterForce[waterForceTag.Value], Enum.WaterDirection[waterForceDirectionTag.Value])
					elseif not clusterValues then
						cluster:SetCell(cellPos.X, cellPos.Y, cellPos.Z, cellInfo.Material, cellInfo.clusterType, gInitial90DegreeRotations % 4)
					elseif clusterValues:IsA("Vector3Value") then
						cluster:SetCell(cellPos.X, cellPos.Y, cellPos.Z, clusterValues.Value.X, clusterValues.Value.Y, clusterValues.Value.Z)
					else
						cluster:SetCell(cellPos.X, cellPos.Y, cellPos.Z, clusterValues.Value, 0, 0)
					end
				
					local autoWedgeClusterParts = false
					if stampData.CurrentParts:FindFirstChild("AutoWedge") then autoWedgeClusterParts = true end
	
					-- auto-wedge it
					if (autoWedgeClusterParts) then
						game.Workspace.Terrain:AutowedgeCells(
							Region3int16.new(
								Vector3int16.new(cellPos.x - 1, cellPos.y - 1, cellPos.z - 1),
								Vector3int16.new(cellPos.x + 1, cellPos.y + 1, cellPos.z + 1)
							)
						)
					end

					-- kill the ghost part
					stampData.CurrentParts.Parent = nil
					
					-- Mark for undo.  It has to happen here or the selection display will come back also.
					pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("StamperSingle") end)						
					return true
				end
			else 
				-- you tried to stamp a HSL-single part where one does not belong!
				flashRedBox()
				return false
			end
		end
		
		local function getPlayer()
			if game:FindFirstChild("Players") then
				if game.Players["LocalPlayer"] then
					return game.Players.LocalPlayer
				end
			end
			return nil
		end
		

		-- Post process: after positioning the part or model, restore transparency, material, anchored and collide states and create joints
		if stampData.CurrentParts:IsA("Model") or stampData.CurrentParts:IsA("Tool") then
			if stampData.CurrentParts:IsA("Model") then
				-- Tyler's magical hack-code for allowing/preserving clones of both Surface and Manual Welds...  just don't ask X<
				local manualWeldTable = {}
				local manualWeldParentTable = {}
				saveTheWelds(stampData.CurrentParts, manualWeldTable, manualWeldParentTable)
				stampData.CurrentParts:BreakJoints()
				stampData.CurrentParts:MakeJoints()
				restoreTheWelds(manualWeldTable, manualWeldParentTable)
			end
					
			-- if it's a model, we also want to fill in the playerID and playerName tags, if it has those (e.g. for the friend-only door)
			playerIdTag = stampData.CurrentParts:FindFirstChild("PlayerIdTag")
			playerNameTag = stampData.CurrentParts:FindFirstChild("PlayerNameTag")
			if playerIdTag ~= nil then
				tempPlayerValue = getPlayer()
				if tempPlayerValue ~= nil then playerIdTag.Value = tempPlayerValue.userId end
			end
			if playerNameTag ~= nil then
				if game:FindFirstChild("Players") and game.Players["LocalPlayer"] then
					tempPlayerValue = game.Players.LocalPlayer
					if tempPlayerValue ~= nil then playerNameTag.Value = tempPlayerValue.Name end
				end
			end
			-- ...and tag all inserted models for subsequent origin identification
			-- if no RobloxModel tag already exists, then add it.
			if stampData.CurrentParts:FindFirstChild("RobloxModel") == nil then
				local stringTag = Instance.new("BoolValue", stampData.CurrentParts)
				stringTag.Name = "RobloxModel"

				if stampData.CurrentParts:FindFirstChild("RobloxStamper") == nil then
					local stringTag2 = Instance.new("BoolValue", stampData.CurrentParts)
					stringTag2.Name = "RobloxStamper"
				end
			end

		else
			stampData.CurrentParts:BreakJoints()
			if stampData.CurrentParts:FindFirstChild("RobloxStamper") == nil then
				local stringTag2 = Instance.new("BoolValue", stampData.CurrentParts)
				stringTag2.Name = "RobloxStamper"
			end
		end
				
		-- make sure all the joints are activated before restoring anchor states
		if not createJoints then game.JointsService:CreateJoinAfterMoveJoints() end

		-- Restore the original properties for all parts being stamped
		for part, transparency in pairs(stampData.TransparencyTable) do
			part.Transparency = transparency
		end
		for part, archivable in pairs(stampData.ArchivableTable) do
			part.Archivable = archivable
		end
		for part, material in pairs(stampData.MaterialTable) do
			part.Material = material
		end
		for part, collide in pairs(stampData.CanCollideTable) do
			part.CanCollide = collide
		end
		for part, anchored in pairs(stampData.AnchoredTable) do
			part.Anchored = anchored
		end
		for decal, transparency in pairs(stampData.DecalTransparencyTable) do
			decal.Transparency = transparency
		end

		for part, surfaces in pairs(stampData.SurfaceTypeTable) do
			loadSurfaceTypes(part, surfaces)
		end

		if isMegaClusterPart() then
			stampData.CurrentParts.Transparency = 0
		end

		-- re-enable all seats
		setSeatEnabledStatus(stampData.CurrentParts, true)

		stampData.TransparencyTable = nil
		stampData.ArchivableTable = nil
		stampData.MaterialTable = nil
		stampData.CanCollideTable = nil
		stampData.AnchoredTable = nil
		stampData.SurfaceTypeTable = nil

		-- ...and tag all inserted models for subsequent origin identification
		-- if no RobloxModel tag already exists, then add it.
		if stampData.CurrentParts:FindFirstChild("RobloxModel") == nil then
			local stringTag = Instance.new("BoolValue", stampData.CurrentParts)
			stringTag.Name = "RobloxModel"
		end

		-- and make sure we don't delete it, now that it's not a ghost part
		if ghostRemovalScript then ghostRemovalScript.Parent = nil end

		--Re-enable the scripts
		for index,script in pairs(stampData.DisabledScripts) do
			script.Disabled = false
		end
		
		--Now that they are all marked enabled, reinsert them into the world so they start running
		for index,script in pairs(stampData.DisabledScripts) do
			local oldParent = script.Parent
			script.Parent = nil
			script:Clone().Parent = oldParent
		end
		
		-- clear out more data
		stampData.DisabledScripts = nil
		stampData.Dragger = nil
		stampData.CurrentParts = nil
	
		pcall(function() game:GetService("ChangeHistoryService"): SetWaypoint("StampedObject") end)
		return true
	end
	
	local function pauseStamper()
		for i = 1, #mouseCons do -- stop the mouse from doing anything
			mouseCons[i]:disconnect()
			mouseCons[i] = nil
		end
		mouseCons = {}
		
		if stampData and stampData.CurrentParts then -- remove our ghost part
			stampData.CurrentParts.Parent = nil
			stampData.CurrentParts:Remove()
		end
		
		resetHighScalabilityLine()
		
		game.JointsService:ClearJoinAfterMoveJoints()
	end
	

	local function prepareUnjoinableSurfaces(modelCFrame, parts, whichSurface)
		local AXIS_VECTORS = {Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)}  -- maybe last one is negative?  TODO: check this!
		local isPositive = 1
		if whichSurface < 0 then isPositive = isPositive * -1 whichSurface = whichSurface*-1 end
		local surfaceNormal = isPositive * modelCFrame:vectorToWorldSpace(AXIS_VECTORS[whichSurface])

		for i = 1, #parts do
			local currPart = parts[i]

			-- now just need to find which surface of currPart most closely match surfaceNormal and then set that to Unjoinable
			local surfaceNormalInLocalCoords = currPart.CFrame:vectorToObjectSpace(surfaceNormal)
			if math.abs(surfaceNormalInLocalCoords.X) > math.abs(surfaceNormalInLocalCoords.Y) then
				if math.abs(surfaceNormalInLocalCoords.X) > math.abs(surfaceNormalInLocalCoords.Z) then
					if surfaceNormalInLocalCoords.X > 0 then currPart.RightSurface = "Unjoinable" else currPart.LeftSurface = "Unjoinable" end
				else
					if surfaceNormalInLocalCoords.Z > 0 then currPart.BackSurface = "Unjoinable" else currPart.FrontSurface = "Unjoinable" end
				end
			else
				if math.abs(surfaceNormalInLocalCoords.Y) > math.abs(surfaceNormalInLocalCoords.Z) then
					if surfaceNormalInLocalCoords.Y > 0 then currPart.TopSurface = "Unjoinable" else currPart.BottomSurface = "Unjoinable" end
				else
					if surfaceNormalInLocalCoords.Z > 0 then currPart.BackSurface = "Unjoinable" else currPart.FrontSurface = "Unjoinable" end
				end
			end
		end
	end

	local function resumeStamper()
		clone, parts = prepareModel(modelToStamp)

		if not clone or not parts then
			return
		end

		-- if we have unjoinable faces, then we want to change those surfaces to be Unjoinable
		local unjoinableTag = clone:FindFirstChild("UnjoinableFaces", true)
		if unjoinableTag then
			for unjoinableSurface in string.gmatch(unjoinableTag.Value, "[^,]*") do
				if tonumber(unjoinableSurface) then
					if clone:IsA("Model") then
						prepareUnjoinableSurfaces(clone:GetModelCFrame(), parts, tonumber(unjoinableSurface))
					else
						prepareUnjoinableSurfaces(clone.CFrame, parts, tonumber(unjoinableSurface))
					end
				end
			end
		end

		stampData.ErrorBox = errorBox
		if stampInModel then
			clone.Parent = stampInModel
		else
			clone.Parent = game.Workspace
		end
		
		if clone:FindFirstChild("ClusterMaterial", true) then -- extract all info from vector
			clusterMaterial = clone:FindFirstChild("ClusterMaterial", true)
			if (clusterMaterial:IsA("Vector3Value")) then
				cellInfo.Material = clusterMaterial.Value.X
				cellInfo.clusterType = clusterMaterial.Value.Y
				cellInfo.clusterOrientation = clusterMaterial.Value.Z
			elseif clusterMaterial:IsA("IntValue") then
				cellInfo.Material = clusterMaterial.Value
			end
		end
		
		pcall(function() mouseTarget = Mouse.Target end)

		if mouseTarget and mouseTarget.Parent:FindFirstChild("RobloxModel") == nil then
			game.JointsService:SetJoinAfterMoveTarget(mouseTarget)
		else
			game.JointsService:SetJoinAfterMoveTarget(nil)
		end
		game.JointsService:ShowPermissibleJoints()
		
		for index, object in pairs(stampData.DisabledScripts) do
			if object.Name == "GhostRemovalScript" then
				object.Parent = stampData.CurrentParts
			end
		end
		
		stampData.Dragger = Instance.new("Dragger")
		
		--Begin a movement by faking a MouseDown signal
		stampData.Dragger:MouseDown(parts[1], Vector3.new(0,0,0), parts)
		stampData.Dragger:MouseUp()
		
		DoStamperMouseMove(Mouse)
		
		table.insert(mouseCons,Mouse.Move:connect(function()
			if movingLock or stampUpLock then return end
			movingLock = true
				DoStamperMouseMove(Mouse)
			movingLock = false
		end))
		
		table.insert(mouseCons,Mouse.Button1Down:connect(function()
			DoStamperMouseDown(Mouse)
		end))
		
		table.insert(mouseCons,Mouse.Button1Up:connect(function()
			stampUpLock = true
				while movingLock do wait() end
				stamped.Value = DoStamperMouseUp(Mouse)
				resetHighScalabilityLine()
			stampUpLock = false
		end))
		
		stamped.Value = false
	end
	
	local function resetStamperState(newModelToStamp)
	
		-- if we have a new model, swap it out
		if newModelToStamp then
			if not newModelToStamp:IsA("Model") and not newModelToStamp:IsA("BasePart") then
				error("resetStamperState: newModelToStamp (first arg) is not nil, but not a model or part!")
			end
			modelToStamp = newModelToStamp
		end
	
		-- first clear our state
		pauseStamper()
		-- now lets load in the new model
		resumeStamper()
		
	end
	
	-- load the model initially
	resetStamperState()
	
	
	-- setup the control table we pass back to the user
	control.Stamped = stamped -- BoolValue that fires when user stamps
	control.Paused = false
	
	control.LoadNewModel = function(newStampModel) -- allows us to specify a new stamper model to be used with this stamper
		if newStampModel and not newStampModel:IsA("Model") and not newStampModel:IsA("BasePart") then
			error("Control.LoadNewModel: newStampModel (first arg) is not a Model or Part!")
			return nil
		end
		resetStamperState(newStampModel)
	end
	
	control.ReloadModel = function() -- will automatically set stamper to get a new model of current model and start stamping with new model
		resetStamperState()
	end
	
	control.Pause = function() -- temporarily stops stamping, use resume to start up again
		if not control.Paused then
			pauseStamper()
			control.Paused = true
		else
			print("RbxStamper Warning: Tried to call Control.Pause() when already paused")
		end
	end
	
	control.Resume = function() -- resumes stamping, if currently paused
		if control.Paused then
			resumeStamper()
			control.Paused = false
		else
			print("RbxStamper Warning: Tried to call Control.Resume() without Pausing First")
		end
	end
	
	control.ResetRotation = function() -- resets the model rotation so new models are at default orientation
		-- gInitial90DegreeRotations = 0
		-- Note:  This function will not always work quite the way we want it to; we will have to build this out further so it works with
		--        High-Scalability and with the new model orientation setting methods (model:ResetOrientationToIdentity())  [HotThoth]
	end
	
	control.Destroy = function() -- Stops current Stamp operation and destroys control construct
		for i = 1, #mouseCons do
			mouseCons[i]:disconnect()
			mouseCons[i] = nil
		end
		
		if keyCon then
			keyCon:disconnect()
		end
		
		game.JointsService:ClearJoinAfterMoveJoints()
		
		if adorn then adorn:Destroy() end
		if adornPart then adornPart:Destroy() end
		if errorBox then errorBox:Destroy() end
		if stampData then
			if stampData["Dragger"] then
				stampData.Dragger:Destroy()
			end
			if stampData.CurrentParts then
				stampData.CurrentParts:Destroy()
			end
		end
		if control and control["Stamped"] then
			control.Stamped:Destroy()
		end
		control = nil
	end

	return control
end

t.Help = 
	function(funcNameOrFunc) 
		--input argument can be a string or a function.  Should return a description (of arguments and expected side effects)
		if funcNameOrFunc == "GetStampModel" or funcNameOrFunc == t.GetStampModel then 
			return "Function GetStampModel.  Arguments: assetId, useAssetVersionId.  assetId is the asset to load in, define useAssetVersionId as true if assetId is a version id instead of a relative assetId.  Side effect: returns a model of the assetId, or a string with error message if something fails" 
		end
		if funcNameOrFunc == "SetupStamperDragger" or funcNameOrFunc == t.SetupStamperDragger then
			return "Function SetupStamperDragger. Side Effect: Creates 4x4 stamping mechanism for building out parts quickly. Arguments: ModelToStamp, Mouse, LegalStampCheckFunction. ModelToStamp should be a Model or Part, preferrably loaded from RbxStamper.GetStampModel and should have extents that are multiples of 4.  Mouse should be a mouse object (obtained from things such as Tool.OnEquipped), used to drag parts around 'stamp' them out. LegalStampCheckFunction is optional, used as a callback with a table argument (table is full of instances about to be stamped). Function should return either true or false, false stopping the stamp action."
		end
	end

-----------------
--DEFAULT VALUES-
-----------------
local on = false
local loaded = false

local partButtonOn = true

local currStampGui = nil
local currStampId = nil
local recentsFrame = nil
local waterTypeChangedEvent = nil
local waterForceAndDirection = {"None","NegX"}

local setPanelVisibility = nil
local getPanelVisibility = nil

local stampControl = nil
local lastStampModel = nil

local keyCon = nil

-- ids of users we want to load sets in from
local userSetIds = {11744447,18881789,18881808,18881829,18881853,18881866}
local recentButtonStack = {}

-- Libraries
local RbxStamper = nil
local RbxGui	 = nil

local BaseUrl = game:GetService("ContentProvider").BaseUrl:lower()

---------------
--PLUGIN SETUP-
---------------
local self	= PluginManager():CreatePlugin()
local mouse	= self:GetMouse()
self.Deactivation:connect(function()
	Off()
end)

local toolbar = self:CreateToolbar("Terrain")
local toolbarbutton = toolbar:CreateButton("", "Part Stamper - Toggle List (F)", "stamp.png")
toolbarbutton.Click:connect(function()
	if on then
		Off()
	elseif loaded then
		On()
	end
end)

-----------------------
--FUNCTION DEFINITIONS-
-----------------------

function showLoadingDialog()
	currStampGui.LoadingFrame.LoadingText:TweenPosition(UDim2.new(0,150,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 2, true)
	currStampGui.LoadingFrame.Visible = true
end

function hideLoadingDialog()
	currStampGui.LoadingFrame.LoadingText:TweenPosition(UDim2.new(0,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
	currStampGui.LoadingFrame.Visible = false
end

local partSelected = function(name, id, terrainShape)
	if not id then
		return
	end
	if not name then
		return
	end
	
	currStampId = id

	if stampControl then
		stampControl.Destroy()
	end
	if stampCon then
		stampCon:disconnect()
		stampCon = nil
	end

	setPanelVisibility(false)
	
	showLoadingDialog()
		lastStampModel = RbxStamper.GetStampModel(id, terrainShape)
		updateRecentParts(name, id, terrainShape)
	hideLoadingDialog()

	if lastStampModel.Name == "MegaClusterCube" then
		local clusterTag = lastStampModel:FindFirstChild("ClusterMaterial")
		-- we are going to stamp water, send info to stamper about this
		if clusterTag and clusterTag.Values == 17 then
			local waterForceTag = Instance.new("StringValue",lastStampModel)
			waterForceTag.Name = "WaterForceTag"
			waterForceTag.Value = waterForceAndDirection[1]

			local waterForceDirectionTag = Instance.new("StringValue",lastStampModel)
			waterForceDirectionTag.Name = "WaterForceDirectionTag"
			waterForceDirectionTag.Value = waterForceAndDirection[2]
		end
	end
	
	setupStamper(lastStampModel, mouse)
end

function updateWaterInfo()
	if stampControl then
		stampControl.Destroy()
	end
	if stampCon then
		stampCon:disconnect()
		stampCon = nil
	end

	showLoadingDialog()
		lastStampModel = RbxStamper.GetStampModel(currStampId)
	hideLoadingDialog()

	if lastStampModel.Name == "MegaClusterCube" then
		local clusterTag = lastStampModel:FindFirstChild("ClusterMaterial")
		-- we are going to stamp water, send info to stamper about this
		if clusterTag and clusterTag.Value.X == 17 then
			local waterForceTag = Instance.new("StringValue",lastStampModel)
			waterForceTag.Name = "WaterForceTag"
			waterForceTag.Value = waterForceAndDirection[1]

			local waterForceDirectionTag = Instance.new("StringValue",lastStampModel)
			waterForceDirectionTag.Name = "WaterForceDirectionTag"
			waterForceDirectionTag.Value = waterForceAndDirection[2]
		end
	end

	setupStamper(lastStampModel, mouse)
end


local dialogClosed = function()
	if lastStampModel then
		if stampControl then
			stampControl.Destroy()
		end
		setupStamper(lastStampModel, mouse)
	end
end

function pickPart()
	if stampControl then
		stampControl.Destroy()
	end
	setPanelVisibility(true)
end

function keyHandler(key)
	key = key:lower()
	if key == 'f' then
		handlePartShow()
	end
end

function partOn()
	pickPart()
	partButtonOn = true
end

function partOff()
	setPanelVisibility(false)
	if lastStampModel then
		if stampControl then
			stampControl.Destroy()
		end
		setupStamper(lastStampModel, mouse)
	end
	partButtonOn = false
end

function handlePartShow()
	if getPanelVisibility() then
		partOff()
	else
		partOn()
	end
end

function On()

	if self and toolbarbutton then
		self:Activate(true)
		toolbarbutton:SetActive(true)
	end
	
	if not RbxStamper then
		RbxStamper = t
	end
	
	if not currStampGui then -- first load, lets make the gui
		createGui()
	end
	
	if setPanelVisibility then
		setPanelVisibility(true)
	end
	
	if recentsFrame then
		recentsFrame.Visible = true
	end
	
	if keyHandler then
		keyCon = mouse.KeyDown:connect(keyHandler)
	end
	
	on = true
end

function Off()

	if toolbarbutton then
		toolbarbutton:SetActive(false)
	end

	if stampControl then
		stampControl.Destroy()
	end
	
	if keyCon then
		keyCon:disconnect()
		keyCon = nil
	end

	if currStampGui and currStampGui:FindFirstChild("WaterFrame") then
		currStampGui.WaterFrame.Visible = false
	end
	
	if lastStampModel then
		lastStampModel:Destroy()
	end
	
	if setPanelVisibility then
		setPanelVisibility(false)
	end
	
	if recentsFrame then
		recentsFrame.Visible = false
	end
	
	on = false
end

function setupStamper(model, mouse)
	if model then
		stampControl = RbxStamper.SetupStamperDragger(model,mouse)
		if stampControl then
			stampCon = stampControl.Stamped.Changed:connect(function()
					if stampControl.Stamped.Value then
						stampControl.ReloadModel()
					end
			end)
		end
	end
end

function updateRecentParts(newName, newId, newTerrainShape)
	if newId then		
		for i = 1, #recentButtonStack do
			if recentButtonStack[i].Id == newId then -- already have item, nothing to do
				return
			end
		end
		for i = #recentButtonStack - 1, 1, -1 do
			recentButtonStack[i + 1].Id = recentButtonStack[i].Id
			recentButtonStack[i + 1].Name = recentButtonStack[i].Name
			recentButtonStack[i + 1].TerrainShape = recentButtonStack[i].TerrainShape
			
			recentButtonStack[i + 1].Button.Image = recentButtonStack[i].Button.Image
		end
		
		recentButtonStack[1].Id = newId
		recentButtonStack[1].Name = newName
		recentButtonStack[1].TerrainShape = newTerrainShape
		recentButtonStack[1].Button.Image = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=75&ht=75&aid=" .. tostring(newId)
	end
end


------
--GUI-
------

function createGui()
	if not RbxGui then
		RbxGui = t
	end
	
	--Insert Panel
	currStampGui, setPanelVisibility, getPanelVisibility, waterTypeChangedEvent = 
		RbxGui.CreateSetPanel(userSetIds, partSelected, dialogClosed, UDim2.new(0.8, 0, 0.9, 0), UDim2.new(0.1,0,0.05,0), true)
	setPanelVisibility(false)
	
	currStampGui.Parent = game:GetService("CoreGui")

	waterTypeChangedEvent.Event:connect(function(waterTable)
		waterForceAndDirection = waterTable
		updateWaterInfo()
	end)

	-- Loading Gui
	local loadingFrame = Instance.new("Frame")
	loadingFrame.Name = "LoadingFrame"
	loadingFrame.Style = Enum.FrameStyle.RobloxRound
	loadingFrame.Size = UDim2.new(0,350,0,60)
	loadingFrame.Visible = false
	loadingFrame.Position = UDim2.new(0.5,-175,0.5,-30)

	local loadingText = Instance.new("TextLabel")
	loadingText.Name = "LoadingText"
	loadingText.BackgroundTransparency = 1
	loadingText.Size = UDim2.new(0,155,1,0)
	loadingText.Font = Enum.Font.ArialBold
	loadingText.FontSize = Enum.FontSize.Size36
	loadingText.Text = "Loading..."
	loadingText.TextColor3 = Color3.new(1,1,1)
	loadingText.TextStrokeTransparency = 0
	loadingText.Parent = loadingFrame

	loadingFrame.Parent = currStampGui

	-- Recents Stack Gui
	recentsFrame = Instance.new("Frame")
	recentsFrame.BackgroundTransparency = 0.5
	recentsFrame.Name = "RecentsFrame"
	recentsFrame.BackgroundColor3 = Color3.new(0,0,0)
	recentsFrame.Size = UDim2.new(0,50,0,150)
	recentsFrame.Visible = false
	recentsFrame.Parent = currStampGui

	local recentButtonOne = Instance.new("ImageButton")
	recentButtonOne.Style = Enum.ButtonStyle.RobloxButton
	recentButtonOne.Name = "RecentButtonOne"
	recentButtonOne.Size = UDim2.new(0,50,0,50)
	recentButtonOne.Parent = recentsFrame

	local recentButtonTwo = recentButtonOne:clone()
	recentButtonTwo.Name = "RecentButtonTwo"
	recentButtonTwo.Position = UDim2.new(0,0,0,50)
	recentButtonTwo.Parent = recentsFrame

	local recentButtonThree = recentButtonOne:clone()
	recentButtonThree.Name = "RecentButtonThree"
	recentButtonThree.Position = UDim2.new(0,0,0,100)
	recentButtonThree.Parent = recentsFrame

	for i = 1, 3 do
		recentButtonStack[i] = {}
		recentButtonStack[i].Name = nil
		recentButtonStack[i].Id = nil
		recentButtonStack[i].TerrainShape = nil
	end

	recentButtonStack[1].Button = recentButtonOne
	recentButtonStack[2].Button = recentButtonTwo
	recentButtonStack[3].Button = recentButtonThree

	local buttonClicked = false

	for i = 1, #recentButtonStack do
		recentButtonStack[i].Button.MouseButton1Click:connect(function()
			if buttonClicked then return end
			buttonClicked = true
			partSelected(recentButtonStack[i].Name, recentButtonStack[i].Id, recentButtonStack[i].TerrainShape)
			buttonClicked = false
		end)
	end
end



--------------------------
--SUCCESSFUL LOAD MESSAGE-
--------------------------
loaded = true