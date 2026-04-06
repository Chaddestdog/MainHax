local userInputService = cloneref(game:GetService('UserInputService'));
local middle = workspace.CurrentCamera.ViewportSize / 2;

local col3 = Color3.fromRGB;
local vec2 = Vector2.new;

local fonts = {
    ['Inter'] = 2;
    ['Roboto Mono'] = 2;
};

local DrawingImmediate   = DrawingImmediate or loadstring(httpget('https://raw.githubusercontent.com/Chaddestdog/MainHax/refs/heads/main/Assets/DrawingImmediate.luau'), 'DrawingImmediate.luau')();
local drawFilledRect     = DrawingImmediate.FilledRectangle;
local drawOutlinedText   = DrawingImmediate.OutlinedText;

local newClass = function(a)
    local class = a or {};
    class.__index = class;
    return class;
end;

local isHovered = function(position, size, mousePosition)
    local offset = mousePosition - position;
    return (offset.X >= 0 and offset.Y >= 0 and offset.X < size.X and offset.Y < size.Y);
end;

local windowClass  = newClass({ amt = 0 });
local tabClass     = newClass();
local toggleClass  = newClass();

windowClass.new = function(options)
    windowClass.amt += 1;

    local window = setmetatable({
        _type = 'window';
        id = windowClass.amt;
        active = true;
        title = options.title or 'Title';
        size = options.size or vec2(440.0, 520.0);
        position = options.position or middle;
        openBind = options.openBind or Enum.KeyCode.RightShift;
        openFPSCap = options.openFPSCap or 60,
        connections = {};
        isDragging = false;
        isResizing = false;
        resizeStart = nil;
        resizeStartSize = nil;

        theme = options.theme or {
            background = col3(64, 64, 64);
            background2 = col3(56, 56, 56);
            accent = col3(167, 167, 167);
            text = col3(255, 255, 255);
        };

        activeTab = nil;
        amtTabs = 0;
        tabs = {};

        flags = {};
    }, windowClass);

    local mousePosition, mouseHeld, isClicked, keys = userInputService:GetMouseLocation(), false, false, {};
    do
        setfpscap(window.active and window.openFPSCap or 0);

        table.insert(window.connections, userInputService.InputBegan:Connect(function(input)
            keys[input.KeyCode] = true;

            if (input.KeyCode == window.openBind) then
                window.active = not window.active;
                setfpscap(window.active and window.openFPSCap or 0);
            elseif (input.UserInputType ~= Enum.UserInputType.MouseButton1) then
                return;
            end;

            mouseHeld = true;
        end));

        table.insert(window.connections, userInputService.InputEnded:Connect(function(input)
            keys[input.KeyCode] = false;
            if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;
            mouseHeld = false;
        end));
    end;

    local theme = window.theme;

    local lastMouseHeld = false;
    table.insert(window.connections, DrawingImmediate.GetPaint(window.id):Connect(function()
        mousePosition = userInputService:GetMouseLocation();
        local basePos, baseSize = (window.position - window.size / 2), window.size;

        -- base logic
        do

            if (not window.active) then return end;

            if (mouseHeld and not lastMouseHeld) then
                isClicked = true;
            else
                isClicked = false;
            end;

            --[Draging]
            do

                if (mouseHeld and not lastMouseHeld) then
                    isClicked = true;
                else
                    isClicked = false;
                end;

                if (isClicked and isHovered(basePos, vec2(baseSize.X, 18), mousePosition)) then
                    window.isDragging = true;
                end;

                if (not mouseHeld) then
                    window.isDragging  = false;
                    window.dragStart = nil;
                end;

                if (window.isDragging and mouseHeld) then
                    if (not window.dragStart) then
                        window.dragStart = mousePosition - window.position;
                    end;
                    window.position = mousePosition - window.dragStart;
                end;

            end;

            -- [Resizeing]
            do

                if (isClicked and isHovered((basePos + baseSize) - vec2(5, 5), vec2(10, 10), mousePosition)) then
                    window.isResizing = true;
                end;

                if (not mouseHeld) then
                    window.isResizing = false;
                    window.resizeStart = nil;
                    window.resizeStartSize = nil;
                end;

                if (window.isResizing and mouseHeld) then
                    if (not window.resizeStart) then
                        window.resizeStart = mousePosition;
                        window.resizeStartSize = window.size;
                        window.resizeStartPos = window.position;
                    end;
                    local delta = mousePosition - window.resizeStart;
                    local newSize = vec2(math.max(440.0, window.resizeStartSize.X + delta.X), math.max(520.0, window.resizeStartSize.Y + delta.Y));
                    window.position = window.position + (newSize - window.size) / 2;
                    window.size = newSize;
                end;
            end;

        end;

        do -- [Base]

            -- [Background 1]
            drawFilledRect(basePos - vec2(2, 2), baseSize + vec2(4, 4), theme.background, 1.00, 0);

            -- [Background 2]
            drawFilledRect(basePos - vec2(1, 1), baseSize + vec2(2, 2), theme.accent, 1.00, 0);

            -- [Base]
            drawFilledRect(basePos, baseSize, theme.background, 1.00, 0);

        end;

        do -- [Topbar]

            -- [Background]
            drawFilledRect(basePos, vec2(baseSize.X, 18.0), theme.background2, 1.00, 0);

            -- [Title]
            drawOutlinedText(basePos + vec2(baseSize.X / 2, 3), fonts['Inter'], 12, theme.text, 1.00, col3(0, 0, 0), 1, window.title, true);

           -- [Line]
           drawFilledRect(basePos + vec2(0, 19), vec2(baseSize.X, 1.0), theme.accent, 1.00, 0);

        end;

        do -- [TabHolder]

            -- [Rectangle 1]
            drawFilledRect(basePos + vec2(0, 20), vec2(baseSize.X, 22), theme.background2, 1.00, 0);

            -- [Line]
            drawFilledRect(basePos + vec2(0, 42), vec2(baseSize.X, 1.0), theme.accent, 1.00, 0);

        end;

        for i = 1, window.amtTabs do
            local tab = window.tabs[i];
            local tabWidth = baseSize.X / window.amtTabs;
            local tabPos = (basePos + vec2(1, 20)) + vec2(tabWidth * (i - 1), 0);
            local tabSize = vec2(tabWidth - 1, 23);

            if (tab.active) then
                 -- [Rectangle 3]
                drawFilledRect(tabPos, tabSize, theme.background, 1.00, 0);
            end;    

            if (i < window.amtTabs) then
                -- [Rectangle 2]
                drawFilledRect(basePos + vec2(baseSize.X / window.amtTabs * i, 20), vec2(1.0, 22.0), theme.accent, 1.00, 0);
            end;

            -- [Tab_1]
            drawOutlinedText((tabPos + tabSize / 2) - vec2(0, 6), fonts['Inter'], 12, col3(255, 255, 255), 1.00, col3(0, 0, 0), 1, tab.title, true);

            if (isClicked and isHovered(tabPos, tabSize, mousePosition)) then
                window.activeTab.active = false;
                tab.active = true;
                window.activeTab = tab;
            end;
        end;

        local activeTab = window.activeTab;
        if (not activeTab) then return end;
        if (activeTab.amtElements == 0) then return end;
        local elementCursor = basePos + vec2(5, 52);
        for i = 1, activeTab.amtElements do
            local element = activeTab.elements[i];
            local _type = element._type;

            if (_type == 'toggle') then
                -- [Title]
                drawOutlinedText(elementCursor, fonts['Inter'], 12, theme.text, 1.00, col3(0, 0, 0), 1, element.title, false)

                local btn1Pos = vec2((elementCursor.X + baseSize.X) - 176, elementCursor.Y);
                local btn2Pos = vec2((elementCursor.X + baseSize.X) - 38, elementCursor.Y);
                local btnSize = vec2(30, 17);

                do -- [Button 2]

                    -- [Rectangle 6]
                    drawFilledRect(btn2Pos, btnSize, col3(35, 35, 35), 1.00, 0);

                    -- [Rectangle 7]
                    drawFilledRect(btn2Pos + vec2(1, 1), btnSize - vec2(2, 2), col3(56, 56, 56), 1.00, 0);

                    -- [>]
                    drawOutlinedText((btn2Pos + btnSize / 2) - vec2(0, 6), fonts['Inter'], 12, col3(255, 255, 255), 1.00, col3(0, 0, 0), 1, ">", true);

                end;

                do -- [Button 1]

                    -- [Rectangle 6]
                    drawFilledRect(btn1Pos, btnSize, col3(35, 35, 35), 1.00, 0);

                    -- [Rectangle 7]
                    drawFilledRect(btn1Pos + vec2(1, 1), btnSize - vec2(2, 2), col3(56, 56, 56), 1.00, 0);

                    -- [<]
                    drawOutlinedText((btn1Pos + btnSize / 2) - vec2(0, 6), fonts['Inter'], 12, col3(255, 255, 255), 1.00, col3(0, 0, 0), 1, "<", true);

                end;

                -- [Enabled]
                drawOutlinedText(vec2((elementCursor.X + baseSize.X) - 88, elementCursor.Y + 4), fonts['Inter'], 11, col3(212, 212, 212), 1.00, col3(0, 0, 0), 1, element.enabled and "On" or "Off", true);

                if (isClicked) then
                    if (isHovered(btn1Pos, btnSize, mousePosition)) then
                        element.flag:setEnabled();
                    elseif (isHovered(btn2Pos, btnSize, mousePosition)) then
                        element.flag:setEnabled();
                    end;
                end;


                elementCursor += vec2(0, 22);
                continue;
            elseif (_type == 'slider') then
                
                continue;
            else
                continue;
           end;
        end;
        

 
        lastMouseHeld = mouseHeld;
    end));

    return window, window.flags;
end;

tabClass.new = function(window, title)
    window.amtTabs += 1;

    local tab = setmetatable({
        _type = 'tab';
        id = window.amtTabs;
        active = window.amtTabs == 1;
        title = title or `Tab_{window.amtTabs}`;
        window = window;
        elements = {};
        amtElements = 0;
    }, tabClass);

    table.insert(window.tabs, tab);

    if (tab.active) then window.activeTab = tab end;

    return tab;
end;

toggleClass.new = function(tab, flag, options)
    tab.amtElements += 1;

    local toggle = setmetatable({
        _type = 'toggle';
        id = tab.amtElements;
        title = options.title or `Toggle_{tab.amtElements}`;
        enabled = options.default or false;
        tab = tab;
        window = tab.window;
        flag = {
            _type = 'toggle';
            value = nil;
            callback = options.callback or function() end;
            setEnabled = function(self, value)
                if (value == nil) then value = not self.value end;
                self.element.enabled = value;
                self.value = value;
                self.callback(value);
            end;
            element = nil;
        };
    }, toggleClass);

    toggle.flag.value = toggle.enabled;
    toggle.flag.element = toggle;

    table.insert(tab.elements, toggle);

    toggle.window.flags[flag or (`flag_{tab.window.id}_{tab.id}_{tab.amtElements}`)] = toggle.flag;

    return toggle, toggle.flag;
end;

-- windowClass methods
do

    function windowClass:Destroy()
        for i = 1, #self.connections do
            self.connections[i]:Disconnect();
        end;
    end;

    function windowClass:addTab(title)
        return tabClass.new(self, title);
    end;

end;

-- tabClass methods
do
    function tabClass:addToggle(flag, options)
        return toggleClass.new(self, flag, options);
    end;

end;


return windowClass;
