local ST = {}
ST.frameHeight = 440
ST.frameWidth = 350
ST.headerHeight = 20
ST.borderThickness = 1
ST.frameStrata = 'HIGH'
ST.costHeight = 14
ST.itemHeight = 20 + (ST.borderThickness * 2)

----------

ST.frame = CreateFrame('Frame', 'STMasterFrame', MerchantFrame)
ST.logicFrame = CreateFrame('Frame', 'STLogicFrame', MerchantFrame)
ST.loaded = false
ST.inventory = {}
ST.merchant = {}
ST.getMerchant = false
ST.merchantDelay = 0
ST.merchantAttempts = 0
ST.baseScrollHeight = ST.frameHeight - (ST.headerHeight + (ST.borderThickness * 3))
ST.costGroupFrames = {}
ST.itemFrames = {}
ST.derivedWidth = 0
ST.buybackUiOpen = false
ST.tabsHooked = false

function ST.setupUi()
	ST.frame:EnableMouse(true)
	ST.frame:SetPoint('TOPLEFT', MerchantFrame, 'TOPRIGHT', -30, -12)
	ST.frame:SetFrameStrata(ST.frameStrata)
	ST.frame:SetHeight(ST.frameHeight)
	
	ST.frame.texture = ST.frame:CreateTexture()
	ST.frame.texture:SetAllPoints()
	ST.frame.texture:SetTexture(0, 0, 0, 0.7)
	
	ST.frame:SetFrameLevel(1)
	
	ST.borderFrames = {}
	ST.borderFrames.T = CreateFrame('Frame', 'STBorderFrameT', ST.frame)
	ST.borderFrames.R = CreateFrame('Frame', 'STBorderFrameR', ST.frame)
	ST.borderFrames.B = CreateFrame('Frame', 'STBorderFrameB', ST.frame)
	ST.borderFrames.L = CreateFrame('Frame', 'STBorderFrameL', ST.frame)
	ST.borderFrames.M = CreateFrame('Frame', 'STBorderFrameM', ST.frame)
	
	for _, borderFrame in pairs(ST.borderFrames) do
		borderFrame.texture = borderFrame:CreateTexture()
		borderFrame.texture:SetAllPoints()
		borderFrame.texture:SetTexture(0.5, 0.75, 1, 0.5)
		borderFrame:SetFrameStrata(ST.frameStrata)
		
		borderFrame:SetWidth(ST.borderThickness)
		borderFrame:SetHeight(ST.borderThickness)
	
		borderFrame:SetFrameLevel(2)
	end
	
	ST.borderFrames.T:SetPoint('TOPLEFT', ST.frame, 'TOPLEFT', ST.borderThickness, 0)
	
	ST.borderFrames.M:SetPoint('TOPLEFT', ST.frame, 'TOPLEFT', ST.borderThickness, 0 - (ST.borderThickness + ST.headerHeight))
	
	ST.borderFrames.B:SetPoint('BOTTOMLEFT', ST.frame, 'BOTTOMLEFT', ST.borderThickness, 0)
	
	ST.borderFrames.L:SetHeight(ST.frameHeight)
	ST.borderFrames.L:SetPoint('TOPLEFT', ST.frame, 'TOPLEFT', 0, 0)
	
	ST.borderFrames.R:SetHeight(ST.frameHeight)
	ST.borderFrames.R:SetPoint('TOPRIGHT', ST.frame, 'TOPRIGHT', 0, 0)
	
	ST.headerFrame = CreateFrame('Frame', 'STHeaderFrame', ST.frame)
	ST.headerFrame:SetHeight(ST.headerHeight)
	ST.headerFrame:SetPoint('TOPLEFT', ST.frame, 'TOPLEFT', ST.borderThickness, 0 - ST.borderThickness)
	ST.headerFrame:SetFrameLevel(2)
	
	ST.headerFrame.text = ST.headerFrame:CreateFontString(nil, 'ARTWORK')
	ST.headerFrame.text:SetFont('Fonts\\FRIZQT__.TTF', 12)
	ST.headerFrame.text:SetPoint('TOPLEFT', 6, -3.5)
	ST.headerFrame.text:SetJustifyH('LEFT')
	ST.headerFrame.text:SetTextColor(1, 1, 1)
	ST.headerFrame.text:SetText('ScootsTokens')
	
	ST.closeButton = CreateFrame('Button', 'STHeaderFrame', ST.headerFrame, 'UIPanelCloseButton')
	ST.closeButton:SetWidth(ST.headerHeight + 10)
	ST.closeButton:SetHeight(ST.headerHeight + 10)
	ST.closeButton:SetPoint('TOPRIGHT', ST.headerFrame, 'TOPRIGHT', 5, 5)
	
	ST.closeButton:SetScript('onclick', function()
		ST.frame:Hide()
	end)
	
	-- Make the frame scrollable
	-- https://www.wowinterface.com/forums/showthread.php?t=45982
	ST.scrollframe = ST.scrollframe or CreateFrame('ScrollFrame', 'STScrollFrame', ST.frame, 'UIPanelScrollFrameTemplate')
	ST.scrollframe:SetFrameStrata(ST.frameStrata)
	ST.scrollchild = ST.scrollchild or CreateFrame('Frame', 'STScrollChild', ST.scrollframe)
	ST.scrollchild:SetFrameStrata(ST.frameStrata)

	local scrollbarName = ST.scrollframe:GetName()
	ST.scrollbar = _G[scrollbarName..'ScrollBar']
	ST.scrollupbutton = _G[scrollbarName..'ScrollBarScrollUpButton']
	ST.scrolldownbutton = _G[scrollbarName..'ScrollBarScrollDownButton']

	ST.scrollupbutton:ClearAllPoints()
	ST.scrollupbutton:SetPoint('TOPRIGHT', ST.scrollframe, 'TOPRIGHT', -2, -2)

	ST.scrolldownbutton:ClearAllPoints()
	ST.scrolldownbutton:SetPoint('BOTTOMRIGHT', ST.scrollframe, 'BOTTOMRIGHT', -2, 2)

	ST.scrollbar:ClearAllPoints()
	ST.scrollbar:SetPoint('TOP', ST.scrollupbutton, 'BOTTOM', 0, -2)
	ST.scrollbar:SetPoint('BOTTOM', ST.scrolldownbutton, 'TOP', 0, 2)

	ST.scrollframe:SetScrollChild(ST.scrollchild)
	ST.scrollframe:SetPoint('TOPLEFT', ST.frame, 'TOPLEFT', ST.borderThickness, 0 - (ST.headerHeight + (ST.borderThickness * 2)))
	ST.scrollframe:SetPoint('BOTTOMRIGHT', ST.frame, 'BOTTOMRIGHT', 0 - ST.borderThickness, ST.borderThickness)
	ST.scrollframe:SetFrameLevel(2)
	
	ST.scrollchild:SetHeight(ST.baseScrollHeight)
	ST.scrollchild:SetFrameLevel(3)
	
	-- End scrollable frame

    ST.setWidths()
	
	ST.activeChatFrame = nil
	for i = 1, 10 do
		_G['ChatFrame' .. i .. 'EditBox']:HookScript('OnEditFocusGained', function()
			ST.activeChatFrame = i
		end)

		_G['ChatFrame' .. i .. 'EditBox']:HookScript('OnEditFocusLost', function()
			ST.activeChatFrame = nil
		end)
	end
    
	ST.loaded = true
end

ST.setWidths = function()
    if(ST.headerFrame.text:GetStringWidth() > ST.derivedWidth) then
        ST.derivedWidth = ST.headerFrame.text:GetStringWidth()
    end
    
    for _, frame in pairs(ST.itemFrames) do
        if(frame:IsVisible() and frame.text:GetStringWidth() > ST.derivedWidth) then
            ST.derivedWidth = frame.text:GetStringWidth()
        end
    end

    ST.frameWidth = ST.derivedWidth + ST.scrollbar:GetWidth() + (ST.borderThickness * 2) + 16
    ST.rowWidth = ST.frameWidth - (20 + (ST.borderThickness * 2))

	ST.frame:SetWidth(ST.frameWidth)
	ST.headerFrame:SetWidth(ST.frameWidth - (ST.borderThickness * 2))
	ST.borderFrames.T:SetWidth(ST.frameWidth - (ST.borderThickness * 2))
	ST.borderFrames.M:SetWidth(ST.frameWidth - (ST.borderThickness * 2))
	ST.borderFrames.B:SetWidth(ST.frameWidth - (ST.borderThickness * 2))
    
	ST.scrollchild:SetWidth(ST.rowWidth)
    
    for _, frame in pairs(ST.costGroupFrames) do
		frame.master:SetWidth(ST.rowWidth)
		frame.costs:SetWidth(ST.rowWidth)
		frame.border:SetWidth(ST.rowWidth)
		frame.items:SetWidth(ST.rowWidth)
    end
    
    for _, frame in pairs(ST.itemFrames) do
		frame:SetWidth(ST.rowWidth)
		frame.borderTop:SetWidth(ST.rowWidth)
		frame.borderBottom:SetWidth(ST.rowWidth)
    end
end

function ST.getInventory()
	ST.inventory = {}
	for bagId = 0, 4, 1 do
		local containerLength = GetContainerNumSlots(bagId)
		for slotId = 1, containerLength, 1 do
			local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bagId, slotId)
			
			if(itemLink ~= nil) then
				if(ST.inventory[itemLink] == nil) then
					local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
					ST.inventory[itemLink] = {
						['name'] = itemName,
						['quantity'] = 0,
						['icon'] = itemTexture
					}
				end
				
				ST.inventory[itemLink].quantity = ST.inventory[itemLink].quantity + itemCount
			end
		end
	end
end

function ST.getCurrencies()
	ST.currencies = {}
	local numCurrencies = GetCurrencyListSize()
	
	for index = 1, numCurrencies, 1 do
		local name, isHeader, _, _, _, count = GetCurrencyListInfo(index)
		
		if(not isHeader) then
			ST.currencies[name] = count
		end
	end
end

function ST.getMerchantItems()
	ST.merchantAttempts = 0
	ST.getMerchant = true
end

function ST.attemptMerchantCache()
    if(ST.tabsHooked == false) then
        _G['MerchantFrameTab1']:HookScript('OnMouseDown', function()
            ST.buybackUiOpen = false
        end)
        
        _G['MerchantFrameTab2']:HookScript('OnMouseDown', function()
            ST.buybackUiOpen = true
        end)
        
        ST.tabsHooked = true
    end

    if(ST.buybackUiOpen == true) then
        ST.getMerchant = false
        return nil
    end

	if(ST.merchantAttempts == 10) then
		ST.getMerchant = false
		print('|cffff0000ScootsTokens: Unable to retrieve all merchant items|r')
	elseif(ST.merchantDelay > 0) then
		ST.merchantDelay = ST.merchantDelay - 1
	else
		local _, _, _, _, framePoint = MerchantItem9:GetPoint();
		local merchantItemCount = GetMerchantNumItems()
		if(framePoint == -8) then
			local numPages = ceil(merchantItemCount / 10)
			if(ST.merchantAttempts > 0) then
				if(MerchantFrame.page < numPages) then
					MerchantItem9:SetPoint('TOPLEFT', 'MerchantItem7', 'BOTTOMLEFT', 0, -9)
					MerchantFrame.page = MerchantFrame.page + 1
					MerchantFrame_Update()
				else
					MerchantFrame.page = 1
					MerchantFrame_Update()
				end
			end
				
			ST.merchant = {}
			local itemsFound = 0
			local itemId = nil
			local itemLink = nil
			for index = 1, merchantItemCount do
				if(Custom_GetMerchantItem ~= nil) then
					itemID, itemLink = Custom_GetMerchantItem(index)
				else
					itemLink = GetMerchantItemLink(index)
					if(itemLink ~= nil) then
						itemID = itemLink:gsub('^|%x+|Hitem:', ''):gsub(':.+$', '')
					end
				end
				
				if(itemID ~= nil and itemLink ~= nil) then
					itemsFound = itemsFound + 1
				
					local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
					local _, _, _, _, _, _, extendedCost = GetMerchantItemInfo(index)
					
					if(extendedCost == 1) then
						local _, _, itemCount = GetMerchantItemCostInfo(index)
						
						if(itemCount > 0) then
							local item = {
								['index'] = index,
								['link'] = itemLink,
								['name'] = itemName,
								['attune'] = -1,
								['icon'] = itemTexture,
								['costs'] = {}
							}
							
							local hasToken = false
							local canAfford = true
							for currencyIndex = 1, 3 do
								local currencyTexture, currencyCount, currencyItemLink = GetMerchantItemCostItem(index, currencyIndex)
								
								if(currencyItemLink ~= nil) then
									local currencyItemName = GetItemInfo(currencyItemLink)
									
									if(ST.inventory[currencyItemLink] ~= nil) then
										hasToken = true
									end
									
									if(canAfford) then
										if(ST.currencies[currencyItemName] ~= nil) then
											if(ST.currencies[currencyItemName] < currencyCount) then
												canAfford = false
											end
										elseif(ST.inventory[currencyItemLink] == nil or ST.inventory[currencyItemLink].quantity < currencyCount) then
											canAfford = false
										end
										
										if(canAfford) then
											table.insert(item.costs, {
												['link'] = currencyItemLink,
												['name'] = currencyItemName,
												['icon'] = currencyTexture,
												['quantity'] = currencyCount
											})
										end
									end
								end
							end
							
							if(hasToken and canAfford) then					
								if(GetItemAttuneForge ~= nil) then
									item.attune = GetItemAttuneForge(itemID)
								end
							
								table.insert(ST.merchant, item)
							end
						end
					end
				end
			end
			
			if(itemsFound == merchantItemCount) then
				ST.getMerchant = false
				
				if(table.getn(ST.merchant) > 0) then
					ST.renderFrame()
				else
					ST.frame:Hide()
				end
			else
				ST.merchantDelay = 10
				ST.merchantAttempts = ST.merchantAttempts + 1
				ST.attemptMerchantCache()
			end
		else
			ST.attemptMerchantCache()
		end
	end
end

function ST.getCostGroup(index)
	if(ST.costGroupFrames[index] == nil) then
		ST.costGroupFrames[index] = {}
		
		ST.costGroupFrames[index].master = CreateFrame('Frame', 'STCostGroup' .. index .. 'Master', ST.scrollchild)
		ST.costGroupFrames[index].master:SetFrameLevel(4)
		
		ST.costGroupFrames[index].costs = CreateFrame('Frame', 'STCostGroup' .. index .. 'Costs', ST.costGroupFrames[index].master)
		ST.costGroupFrames[index].costs:SetFrameLevel(5)
		ST.costGroupFrames[index].costs:SetPoint('TOPLEFT', ST.costGroupFrames[index].master, 'TOPLEFT', 0, 0)
	
		ST.costGroupFrames[index].costs.text = ST.costGroupFrames[index].costs:CreateFontString(nil, 'ARTWORK')
		ST.costGroupFrames[index].costs.text:SetFont('Fonts\\FRIZQT__.TTF', 12)
		ST.costGroupFrames[index].costs.text:SetPoint('TOPLEFT', 3, 0)
		ST.costGroupFrames[index].costs.text:SetJustifyH('LEFT')
		ST.costGroupFrames[index].costs.text:SetTextColor(1, 1, 1)
		
		ST.costGroupFrames[index].border = CreateFrame('Frame', 'STCostGroup' .. index .. 'Border', ST.costGroupFrames[index].master)
		ST.costGroupFrames[index].border:SetFrameLevel(5)
		ST.costGroupFrames[index].border:SetHeight(ST.borderThickness)
		ST.costGroupFrames[index].border:SetPoint('TOPLEFT', ST.costGroupFrames[index].costs, 'BOTTOMLEFT', 0, 0)
		
		ST.costGroupFrames[index].border.texture = ST.costGroupFrames[index].border:CreateTexture()
		ST.costGroupFrames[index].border.texture:SetAllPoints()
		ST.costGroupFrames[index].border.texture:SetTexture(1, 0.55, 0, 1)
		
		ST.costGroupFrames[index].items = CreateFrame('Frame', 'STCostGroup' .. index .. 'Items', ST.costGroupFrames[index].master)
		ST.costGroupFrames[index].items:SetFrameLevel(5)
		ST.costGroupFrames[index].items:SetPoint('TOPLEFT', ST.costGroupFrames[index].border, 'BOTTOMLEFT', 0, 0)
	end
	
	ST.costGroupFrames[index].master:Show()
	
	return ST.costGroupFrames[index]
end

function ST.getAttunementColours(item)
	local colours = {
		['front'] = {
			['r'] = 1,
			['g'] = 1,
			['b'] = 1,
			['a'] = 0.4
		},
		['back'] = {
			['r'] = 0,
			['g'] = 0,
			['b'] = 0,
			['a'] = 0.1
		}
	}
	
	if(item.attune == -1) then
		colours.back.r = 1
		colours.back.g = 1
		colours.back.b = 1
		colours.back.a = 0
	elseif(item.attune == 0) then
		colours.front.r = 0.65
		colours.front.g = 1
		colours.front.b = 0.5
		colours.back.r = 0.5
		colours.back.g = 1
		colours.back.b = 0.5
	elseif(item.attune == 1) then
		colours.front.r = 0.5
		colours.front.g = 0.5
		colours.front.b = 1
		colours.back.r = 0.5
		colours.back.g = 0.5
		colours.back.b = 1
	elseif(item.attune == 2) then
		colours.front.r = 1
		colours.front.g = 0.65
		colours.front.b = 0.5
		colours.back.r = 1
		colours.back.g = 0.5
		colours.back.b = 0.5
	elseif(item.attune == 3) then
		colours.front.r = 1
		colours.front.g = 1
		colours.front.b = 0.65
		colours.back.r = 1
		colours.back.g = 1
		colours.back.b = 0.5
	end
	
	return colours
end

function ST.getItemFrames(index, item)
	if(ST.itemFrames[index] == nil) then
		ST.itemFrames[index] = CreateFrame('Frame', 'STItem' .. index .. 'Master', UIParent)
		ST.itemFrames[index]:SetFrameLevel(6)
		ST.itemFrames[index]:EnableMouse(true)
		ST.itemFrames[index].hover = false
		ST.itemFrames[index]:SetHeight(ST.itemHeight)
		
		ST.headerFrame.text = ST.headerFrame:CreateFontString(nil, 'ARTWORK')
		ST.headerFrame.text:SetFont('Fonts\\FRIZQT__.TTF', 12)
		ST.headerFrame.text:SetPoint('TOPLEFT', 6, -3.5)
		ST.headerFrame.text:SetJustifyH('LEFT')
		ST.headerFrame.text:SetTextColor(1, 1, 1)
		ST.headerFrame.text:SetText('ScootsTokens')
		
		ST.itemFrames[index].text = ST.itemFrames[index]:CreateFontString(nil, 'ARTWORK')
		ST.itemFrames[index].text:SetFont('Fonts\\FRIZQT__.TTF', 12)
		ST.itemFrames[index].text:SetPoint('TOPLEFT', 20, -4)
		ST.itemFrames[index].text:SetWordWrap(true)
		ST.itemFrames[index].text:SetJustifyH('LEFT')
		
		ST.itemFrames[index].texture = ST.itemFrames[index]:CreateTexture()
		ST.itemFrames[index].texture:SetAllPoints()
		
		ST.itemFrames[index].borderTop = CreateFrame('Frame', 'STItem' .. index .. 'BorderTop', ST.itemFrames[index])
		ST.itemFrames[index].borderTop:SetHeight(ST.borderThickness)
		ST.itemFrames[index].borderTop:SetPoint('TOPLEFT', ST.itemFrames[index], 'TOPLEFT', 0, 0)
		ST.itemFrames[index].borderTop.texture = ST.itemFrames[index].borderTop:CreateTexture()
		ST.itemFrames[index].borderTop.texture:SetAllPoints()
		ST.itemFrames[index].borderTop:SetFrameLevel(7)
		
		ST.itemFrames[index].borderBottom = CreateFrame('Frame', 'STItem' .. index .. 'BorderBottom', ST.itemFrames[index])
		ST.itemFrames[index].borderBottom:SetHeight(ST.borderThickness)
		ST.itemFrames[index].borderBottom:SetPoint('BOTTOMLEFT', ST.itemFrames[index], 'BOTTOMLEFT', 0, 0)
		ST.itemFrames[index].borderBottom.texture = ST.itemFrames[index].borderBottom:CreateTexture()
		ST.itemFrames[index].borderBottom.texture:SetAllPoints()
		ST.itemFrames[index].borderBottom:SetFrameLevel(7)
		
		ST.itemFrames[index].iconFrame = CreateFrame('Frame', 'STItem' .. index .. 'Icon', ST.itemFrames[index])
		ST.itemFrames[index].iconFrame:SetSize(ST.itemHeight - (ST.borderThickness * 8), ST.itemHeight - (ST.borderThickness * 8))
		ST.itemFrames[index].iconFrame:SetPoint('TOPLEFT', ST.itemFrames[index], 'TOPLEFT', (ST.borderThickness * 4), (ST.borderThickness * 4) * -1)
		ST.itemFrames[index].iconFrame.texture = ST.itemFrames[index].iconFrame:CreateTexture()
		ST.itemFrames[index].iconFrame.texture:SetAllPoints()
		ST.itemFrames[index].iconFrame:SetFrameLevel(7)
		
		ST.itemFrames[index]:SetScript('OnUpdate', function(self)
			if(self.hover) then
				if(IsControlKeyDown()) then
					ShowInspectCursor()
				else
					ShowMerchantSellCursor(self.merchantIndex)
				end
			end
		end)
		
		ST.itemFrames[index]:SetScript('OnEnter', function(self)
			self.hover = true
			
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
			GameTooltip:SetMerchantItem(self.merchantIndex)
			GameTooltip_ShowCompareItem(GameTooltip)
			
			self.text:SetTextColor(self.colours.front.r, self.colours.front.g, self.colours.front.b)
			self.borderTop.texture:SetTexture(self.colours.front.r, self.colours.front.g, self.colours.front.b, (self.colours.front.a + 0.1))
			self.borderBottom.texture:SetTexture(self.colours.front.r, self.colours.front.g, self.colours.front.b, (self.colours.front.a + 0.1))
			self.texture:SetTexture(self.colours.back.r, self.colours.back.g, self.colours.back.b, (self.colours.back.a + 0.1))
		end)
		
		ST.itemFrames[index]:SetScript('OnLeave', function(self)
			self.hover = false
			SetCursor(nil)
			
			GameTooltip:Hide()			
			
			self.text:SetTextColor(self.colours.front.r, self.colours.front.g, self.colours.front.b)
			self.borderTop.texture:SetTexture(self.colours.front.r, self.colours.front.g, self.colours.front.b, self.colours.front.a)
			self.borderBottom.texture:SetTexture(self.colours.front.r, self.colours.front.g, self.colours.front.b, self.colours.front.a)
			self.texture:SetTexture(self.colours.back.r, self.colours.back.g, self.colours.back.b, self.colours.back.a)
		end)
		
		ST.itemFrames[index]:SetScript('OnMouseDown', function(self, button)
			if(IsShiftKeyDown()) then
				if(ST.activeChatFrame ~= nil) then
					local editBox = DEFAULT_CHAT_FRAME.editBox
					ChatEdit_ActivateChat(editBox)
					editBox:Insert(self.itemLink)
				else
					local maxStack = GetMerchantItemMaxStack(self.merchantIndex)
					OpenStackSplitFrame(maxStack, self, 'BOTTOMLEFT', 'TOPLEFT')
				end
			elseif(IsControlKeyDown()) then
				DressUpItemLink(self.itemLink)
			elseif(button == 'LeftButton') then
				PickupMerchantItem(self.merchantIndex)
			else
				BuyMerchantItem(self.merchantIndex, 1)
			end
		end)
		
		ST.itemFrames[index].SplitStack = function(self, split)
			BuyMerchantItem(self.merchantIndex, split)
		end
	end
	
	ST.itemFrames[index].merchantIndex = item.index
	ST.itemFrames[index].itemLink = item.link
	
	ST.itemFrames[index].colours = ST.getAttunementColours(item)
	
	ST.itemFrames[index].text:SetText(item.name)
	ST.itemFrames[index].text:SetTextColor(ST.itemFrames[index].colours.front.r, ST.itemFrames[index].colours.front.g, ST.itemFrames[index].colours.front.b)
	ST.itemFrames[index].borderTop.texture:SetTexture(ST.itemFrames[index].colours.front.r, ST.itemFrames[index].colours.front.g, ST.itemFrames[index].colours.front.b, ST.itemFrames[index].colours.front.a)
	ST.itemFrames[index].borderBottom.texture:SetTexture(ST.itemFrames[index].colours.front.r, ST.itemFrames[index].colours.front.g, ST.itemFrames[index].colours.front.b, ST.itemFrames[index].colours.front.a)
	ST.itemFrames[index].texture:SetTexture(ST.itemFrames[index].colours.back.r, ST.itemFrames[index].colours.back.g, ST.itemFrames[index].colours.back.b, ST.itemFrames[index].colours.back.a)
	
	ST.itemFrames[index].iconFrame:SetBackdrop({
		bgFile = item.icon
	})
	
	ST.itemFrames[index]:Show()
	
	return ST.itemFrames[index]
end

function ST.renderFrame()
	if(ST.loaded ~= true) then
		ST.setupUi()
	end
	
	ST.hideAllSubFrames()
	ST.frame:Show()
	costGroups = {}
	
	for _, item in ipairs(ST.merchant) do
		local costString = ''
	
		for _, cost in ipairs(item.costs) do
			costString = costString .. cost.quantity .. 'x' .. cost.link .. '--'
		end
		
		if(costGroups[costString] == nil) then
			costGroups[costString] = {}
		end
		
		table.insert(costGroups[costString], item)
	end
	
	costGroupIndex = -1
	itemIndex = -1
	cumulativeHeight = 0
    ST.derivedWidth = 0
	for _, items in pairs(costGroups) do
		costGroupIndex = costGroupIndex + 1
		
		local costGroup = ST.getCostGroup(costGroupIndex)
	
		costGroup.master:SetPoint('TOPLEFT', ST.scrollchild, 'TOPLEFT', 0, 0 - (5 + cumulativeHeight + (costGroupIndex * 10)))
		costGroup.master:SetHeight((table.getn(items[1].costs) * ST.costHeight) + ST.borderThickness + (table.getn(items) * ST.itemHeight))
		
		costGroup.costs:SetHeight(table.getn(items[1].costs) * ST.costHeight)
		
		local costTextArray = {}
		for _, cost in ipairs(items[1].costs) do
			local playerHasCurrency = 0
			
			if(ST.inventory[cost.link] ~= nil) then
				playerHasCurrency = ST.inventory[cost.link].quantity
			else
				playerHasCurrency = ST.currencies[cost.name]
			end
            
            local costString = cost.quantity .. ' x ' .. cost.link .. ' (' .. playerHasCurrency .. ')'
            
            costGroup.costs.text:SetText(costString)
            local costStringWidth = costGroup.costs.text:GetStringWidth()
            if(ST.derivedWidth < costStringWidth) then
                ST.derivedWidth = costStringWidth
            end
			
			table.insert(costTextArray, costString)
		end
		
		costGroup.costs.text:SetText(table.concat(costTextArray, '\n'))
		costGroup.items:SetHeight(5 + (table.getn(items) * ST.itemHeight))
		
		cumulativeHeight = cumulativeHeight + costGroup.master:GetHeight()
		
		local itemCount = -1
		for _, item in ipairs(items) do
			itemIndex = itemIndex + 1
			itemCount = itemCount + 1
			
			local itemFrame = ST.getItemFrames(itemIndex, item)
			itemFrame:SetParent(costGroup.items)
			itemFrame:SetPoint('TOPLEFT', costGroup.items, 'TOPLEFT', 0, 0 - (itemCount * ST.itemHeight))
		end
	end
	
    ST.setWidths()
	ST.scrollchild:SetHeight(10 + cumulativeHeight + (costGroupIndex * 10))
end

function ST.hideAllSubFrames()
	for _, frameGroup in pairs(ST.costGroupFrames) do
		frameGroup.master:Hide()
	end
	
	for _, frame in ipairs(ST.itemFrames) do
		frame:Hide()
	end
end

function ST.merchantShow()
	ST.getInventory()
	ST.getCurrencies()
	ST.getMerchantItems()
end

ST.logicFrame:SetScript('OnUpdate', function()
	if(ST.getMerchant == true) then
		ST.attemptMerchantCache()
	end
end)

function ST.eventHandler(self, event)
    if(event == 'MERCHANT_SHOW') then
        ST.buybackUiOpen = false
    end
	ST.merchantShow()
end

ST.logicFrame:SetScript('OnEvent', ST.eventHandler)

ST.logicFrame:RegisterEvent('MERCHANT_SHOW')
ST.logicFrame:RegisterEvent('MERCHANT_UPDATE')