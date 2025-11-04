local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local carpetaPadre = nil
local minecraftFont = Enum.Font.Arcade

-- Sistema de logging
local logFileName = "DeltaCustom_logs.txt"

local function escribirLog(mensaje, tipoError)
    local success = pcall(function()
        local timestamp = "N/A"
        if os and os.date then
            timestamp = os.date("[%Y-%m-%d %H:%M:%S]")
        end
        
        local tipoStr = tipoError or "INFO"
        local logEntry = timestamp .. " [" .. tipoStr .. "] " .. tostring(mensaje) .. "\n"
        
        local existingLogs = ""
        if isfile and isfile(logFileName) then
            existingLogs = readfile(logFileName)
        end
        
        if writefile then
            writefile(logFileName, existingLogs .. logEntry)
        else
            warn("writefile no disponible - Log: " .. logEntry)
        end
    end)
    
    if not success then
        warn("Error al escribir log: " .. tostring(mensaje))
    end
end

local function logError(funcionNombre, error)
    local mensaje = "Error en " .. funcionNombre .. ": " .. tostring(error)
    escribirLog(mensaje, "ERROR")
    warn(mensaje)
end

local function logInfo(mensaje)
    escribirLog(mensaje, "INFO")
    print("[DeltaCustom] " .. mensaje)
end

local function logWarning(mensaje)
    escribirLog(mensaje, "WARNING")
    warn("[DeltaCustom] " .. mensaje)
end

-- Inicializar log
logInfo("DeltaCustom iniciado - Version HardUI")

local function cambiarFontMinecraft(objeto)
    local success, error = pcall(function()
        for _, descendiente in pairs(objeto:GetDescendants()) do
            if descendiente:IsA("TextLabel") or descendiente:IsA("TextBox") or descendiente:IsA("TextButton") then
                descendiente.Font = minecraftFont
            end
        end
    end)
    
    if not success then
        logError("cambiarFontMinecraft", error)
    else
        logInfo("Font Minecraft aplicado correctamente")
    end
end

local function cambiarFontChat()
    local exito, error = pcall(function()
        local chatGui = LocalPlayer.PlayerGui:FindFirstChild("Chat")
        if chatGui then
            cambiarFontMinecraft(chatGui)
            
            chatGui.DescendantAdded:Connect(function(descendiente)
                if descendiente:IsA("TextLabel") or descendiente:IsA("TextBox") or descendiente:IsA("TextButton") then
                    task.wait(0.05)
                    descendiente.Font = minecraftFont
                end
            end)
        end
        
        cambiarFontMinecraft(CoreGui)
        
        CoreGui.DescendantAdded:Connect(function(descendiente)
            if descendiente:IsA("TextLabel") or descendiente:IsA("TextBox") or descendiente:IsA("TextButton") then
                task.wait(0.05)
                descendiente.Font = minecraftFont
            end
        end)
        
        local textChannels = TextChatService:FindFirstChild("TextChannels")
        if textChannels then
            for _, canal in pairs(textChannels:GetChildren()) do
                if canal:IsA("TextChannel") then
                    canal.MessageReceived:Connect(function(mensaje)
                        task.wait(0.1)
                        for _, ui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                            if ui:IsA("TextLabel") and ui.Text == mensaje.Text then
                                ui.Font = minecraftFont
                            end
                        end
                    end)
                end
            end
        end
        
        for _, canal in pairs(TextChatService:GetDescendants()) do
            if canal:IsA("TextChatMessageProperties") then
                pcall(function()
                    canal.Font = minecraftFont
                end)
            end
        end
        
        LocalPlayer.PlayerGui.DescendantAdded:Connect(function(descendiente)
            if descendiente:IsA("TextLabel") or descendiente:IsA("TextBox") or descendiente:IsA("TextButton") then
                task.wait(0.05)
                descendiente.Font = minecraftFont
            end
        end)
        
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[SISTEMA] Font cambiado a Minecraft (Arcade)",
            Color = Color3.fromRGB(0, 255, 0)
        })
    end)
    
    if not exito then
        logError("cambiarFontChat", error)
    else
        logInfo("Font del chat cambiado correctamente")
    end
end

local function detectarComandoFont(textBox)
    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local texto = textBox.Text
        if texto:lower() == "font>minecraft" then
            cambiarFontMinecraft(game.Players.LocalPlayer.PlayerGui)
            cambiarFontMinecraft(CoreGui)
            cambiarFontChat()
            
            textBox.Text = ""
            
            print("Font cambiado a Minecraft en todo el juego!")
        end
    end)
end

local function aplicarRainbowUIStroke(uiStroke)
    if configuraciones.noOutline then
        uiStroke.Enabled = false
        return
    end
    
    if uiStroke:FindFirstChildOfClass("UIGradient") then
        uiStroke:FindFirstChildOfClass("UIGradient"):Destroy()
    end
    
    if configuraciones.rainbowOutline then
        local gradient = Instance.new("UIGradient")
        gradient.Parent = uiStroke
        
        local colorSequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 127, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
        })
        
        gradient.Color = colorSequence
        
        game:GetService("RunService").RenderStepped:Connect(function()
            gradient.Rotation = (gradient.Rotation + 2) % 360
        end)
    else
        uiStroke.Color = configuraciones.colorOutline
    end
end

local function buscarYModificarScreenGuis()
    for _, descendiente in pairs(CoreGui:GetDescendants()) do
        if descendiente:IsA("ScreenGui") then
            local hijos = descendiente:GetChildren()
            
            if #hijos == 1 then
                local primerHijo = hijos[1]
                
                if primerHijo:IsA("ImageLabel") or primerHijo:IsA("ImageButton") then
                    local hijosImagen = primerHijo:GetChildren()
                    
                    if #hijosImagen == 2 then
                        local tieneUIStroke = false
                        local uiStrokeEncontrado = nil
                        
                        for _, hijo in pairs(hijosImagen) do
                            if hijo:IsA("UIStroke") then
                                tieneUIStroke = true
                                uiStrokeEncontrado = hijo
                                break
                            end
                        end
                        
                        if tieneUIStroke and uiStrokeEncontrado then
                            aplicarRainbowUIStroke(uiStrokeEncontrado)
                            print("UIStroke rainbow aplicado a: " .. descendiente.Name)
                        end
                    end
                end
            end
        end
    end
end

local function crearBotonRainbow()
    local exito = pcall(function()
        for _, descendiente in pairs(CoreGui:GetDescendants()) do
            if descendiente.Name == "Button" then
                local parent = descendiente.Parent
                if parent and parent.Name == "Holder" then
                    if parent.Parent and parent.Parent.Name == "Settings" then
                        if parent:FindFirstChild("RainbowButton") then
                            return
                        end
                        
                        local clon = descendiente:Clone()
                        clon.Name = "RainbowButton"
                        
                        local titleLabel = clon:FindFirstChild("Title")
                        if titleLabel and titleLabel:IsA("TextLabel") then
                            titleLabel.Text = "Colored button"
                        end
                        
                        local descLabel = clon:FindFirstChild("Desc")
                        if descLabel and descLabel:IsA("TextLabel") then
                            descLabel.Text = "This will change the color of the button to open the Executor, basically rainbow!"
                        end
                        
                        for _, hijo in pairs(clon:GetChildren()) do
                            if hijo:IsA("ImageLabel") or hijo:IsA("ImageButton") then
                                local scriptExistente = hijo:FindFirstChildOfClass("LocalScript")
                                if scriptExistente then
                                    scriptExistente:Destroy()
                                end
                                
                                local localScript = Instance.new("LocalScript")
                                localScript.Name = "RainbowScript"
                                
                                local codigoScript = [[
local boton = script.Parent
local activado = false

boton.MouseButton1Click:Connect(function()
    activado = not activado
    
    if activado then
        local CoreGui = game:GetService("CoreGui")
        
        for _, descendiente in pairs(CoreGui:GetDescendants()) do
            if descendiente:IsA("ScreenGui") then
                local hijos = descendiente:GetChildren()
                
                if #hijos == 1 then
                    local primerHijo = hijos[1]
                    
                    if primerHijo:IsA("ImageLabel") or primerHijo:IsA("ImageButton") then
                        local hijosImagen = primerHijo:GetChildren()
                        
                        if #hijosImagen == 2 then
                            local tieneUIStroke = false
                            local uiStrokeEncontrado = nil
                            
                            for _, hijo in pairs(hijosImagen) do
                                if hijo:IsA("UIStroke") then
                                    tieneUIStroke = true
                                    uiStrokeEncontrado = hijo
                                    break
                                end
                            end
                            
                            if tieneUIStroke and uiStrokeEncontrado then
                                if uiStrokeEncontrado:FindFirstChildOfClass("UIGradient") then
                                    uiStrokeEncontrado:FindFirstChildOfClass("UIGradient"):Destroy()
                                end
                                
                                local gradient = Instance.new("UIGradient")
                                gradient.Parent = uiStrokeEncontrado
                                
                                local colorSequence = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 127, 0)),
                                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
                                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
                                })
                                
                                gradient.Color = colorSequence
                                
                                game:GetService("RunService").RenderStepped:Connect(function()
                                    gradient.Rotation = (gradient.Rotation + 2) % 360
                                end)
                                
                                print("Rainbow activado en: " .. descendiente.Name)
                            end
                        end
                    end
                end
            end
        end
        
        print("Rainbow Button: ACTIVADO")
    else
        print("Rainbow Button: DESACTIVADO")
    end
end)
]]
                                
                                localScript.Source = codigoScript
                                localScript.Parent = hijo
                                
                                print("LocalScript agregado al botón rainbow")
                                break
                            end
                        end
                        
                        clon.Parent = parent
                        print("Botón Rainbow creado exitosamente en Settings!")
                        return
                    end
                end
            end
        end
    end)
    
    if not exito then
        warn("Error al crear el botón Rainbow en Settings")
    end
end

local function aplicarNegroBlanco(textLabel)
    if textLabel:FindFirstChildOfClass("UIGradient") then
        return
    end
    
    local gradient = Instance.new("UIGradient")
    gradient.Parent = textLabel
    
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    
    gradient.Color = colorSequence
    
    game:GetService("RunService").RenderStepped:Connect(function()
        gradient.Offset = Vector2.new(math.sin(tick() * 2) * 0.5, 0)
    end)
end

local function aplicarAzulMarino(textLabel)
    if textLabel:FindFirstChildOfClass("UIGradient") then
        return
    end
    
    local gradient = Instance.new("UIGradient")
    gradient.Parent = textLabel
    
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 191, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 119, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))
    })
    
    gradient.Color = colorSequence
    
    game:GetService("RunService").RenderStepped:Connect(function()
        gradient.Offset = Vector2.new(math.sin(tick() * 1.5) * 0.3, 0)
    end)
end

local function aplicarGradienteLED(textElement)
    if textElement:FindFirstChildOfClass("UIGradient") then
        textElement:FindFirstChildOfClass("UIGradient"):Destroy()
    end
    
    local gradient = Instance.new("UIGradient")
    gradient.Parent = textElement
    
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 127, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
    })
    
    gradient.Color = colorSequence
    
    game:GetService("RunService").RenderStepped:Connect(function()
        gradient.Rotation = (gradient.Rotation + 3) % 360
    end)
end

local function aplicarEfectosTerminal(textBox)
    local lineNumbers = Instance.new("TextLabel")
    lineNumbers.Name = "LineNumbers"
    lineNumbers.Size = UDim2.new(0, 40, 1, 0)
    lineNumbers.Position = UDim2.new(0, -45, 0, 0)
    lineNumbers.BackgroundTransparency = 1
    lineNumbers.TextColor3 = Color3.fromRGB(100, 100, 100)
    lineNumbers.Font = Enum.Font.Code
    lineNumbers.TextSize = 14
    lineNumbers.TextXAlignment = Enum.TextXAlignment.Right
    lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
    lineNumbers.Parent = textBox
    
    local function actualizarLineas()
        local texto = textBox.Text
        local lineas = 1
        for _ in texto:gmatch("\n") do
            lineas = lineas + 1
        end
        
        local numeracion = ""
        for i = 1, lineas do
            numeracion = numeracion .. i .. "\n"
        end
        lineNumbers.Text = numeracion
    end
    
    textBox:GetPropertyChangedSignal("Text"):Connect(actualizarLineas)
    actualizarLineas()
end



local function modificarTextLabel(textLabel)
    if textLabel:IsA("TextBox") then
        aplicarEfectosTerminal(textLabel)
        
        local placeholderOriginal = "This version was crafted by Hesiz | Discord: .pesopluma :) "
        textLabel.PlaceholderText = placeholderOriginal
        
        spawn(function()
            while textLabel and textLabel.Parent do
                if textLabel.Text == "" then
                    textLabel.PlaceholderText = placeholderOriginal .. "█"
                    wait(0.5)
                    textLabel.PlaceholderText = placeholderOriginal
                    wait(0.5)
                else
                    textLabel.PlaceholderText = placeholderOriginal
                    wait(1)
                end
            end
        end)
    elseif textLabel:IsA("TextLabel") then
        textLabel.PlaceholderText = "This version was crafted by Hesiz | Discord: .pesopluma :)"
    end
end

local function modificarShowcase()
    for _, descendant in pairs(CoreGui:GetDescendants()) do
        if descendant.Name == "Showcase" then
            local parent = descendant.Parent
            if parent and parent.Name == "Holder" then
                if parent.Parent and parent.Parent.Name == "Overlay" then
                    if parent.Parent.Parent and parent.Parent.Parent.Name == "Script" then
                        if parent.Parent.Parent.Parent and parent.Parent.Parent.Parent.Name == "Sidemenu" then
                            for _, child in pairs(descendant:GetDescendants()) do
                                if child:IsA("TextLabel") or child:IsA("TextBox") then
                                    child.Text = "hesiz says hello"
                                    aplicarAzulMarino(child)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function modificarNetworkFrame()
    for _, descendant in pairs(CoreGui:GetDescendants()) do
        if descendant.Name == "Frame" then
            local parent = descendant.Parent
            if parent and parent.Name == "Holder" then
                if parent.Parent and parent.Parent.Name == "Overlay" then
                    if parent.Parent.Parent and parent.Parent.Parent.Name == "Network" then
                        if parent.Parent.Parent.Parent and parent.Parent.Parent.Parent.Name == "Sidemenu" then
                            local title = descendant:FindFirstChild("Title")
                            if title and (title:IsA("TextLabel") or title:IsA("TextBox")) then
                                title.Text = "Hesiz Info"
                                aplicarAzulMarino(title)
                                
                                local caraLabel = Instance.new("TextLabel")
                                caraLabel.Name = "CaraAnimada"
                                caraLabel.Size = UDim2.new(0, 30, 0, 30)
                                caraLabel.Position = UDim2.new(1, 5, 0, 0)
                                caraLabel.BackgroundTransparency = 1
                                caraLabel.TextScaled = true
                                caraLabel.Font = Enum.Font.Code
                                caraLabel.Parent = title
                                
                                aplicarAzulMarino(caraLabel)
                                
                                local estados = {":)", "o", "O", "o"}
                                local indice = 1
                                
                                spawn(function()
                                    while caraLabel and caraLabel.Parent do
                                        caraLabel.Text = estados[indice]
                                        indice = indice + 1
                                        if indice > #estados then
                                            indice = 1
                                        end
                                        wait(0.3)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function modificarConsoleTitles()
    for _, descendant in pairs(CoreGui:GetDescendants()) do
        if descendant.Name == "Title" then
            local parent = descendant.Parent
            if parent and parent.Name == "RConsole" then
                if parent.Parent and parent.Parent.Name == "Console" then
                    local titleLabel = descendant:FindFirstChild("Title")
                    if titleLabel and (titleLabel:IsA("TextLabel") or titleLabel:IsA("TextBox")) then
                        titleLabel.Text = "Delta Console"
                        aplicarAzulMarino(titleLabel)
                    end
                    
                    local paragraph = descendant:FindFirstChild("Paragraph")
                    if paragraph and (paragraph:IsA("TextLabel") or paragraph:IsA("TextBox")) then
                        paragraph.Text = "[Does anyone actually use this?]"
                        aplicarAzulMarino(paragraph)
                    end
                end
            end
        end
    end
end

local function modificarExecutor()
    local exito = pcall(function()
        local script1 = nil
        
        for _, descendant in pairs(CoreGui:GetDescendants()) do
            if descendant.Name == "script1.lua" and descendant.Parent and descendant.Parent.Name == "Code" then
                local code = descendant.Parent
                if code.Parent and code.Parent.Name == "Overlay" then
                    local overlay = code.Parent
                    if overlay.Parent and overlay.Parent.Name == "Executor" then
                        local executorInner = overlay.Parent
                        if executorInner.Parent and executorInner.Parent.Name == "Executor" then
                            script1 = descendant
                            carpetaPadre = descendant.Parent
                            break
                        end
                    end
                end
            end
        end
        
        if not script1 then return end
        
        modificarTextLabel(script1)
        detectarComandoFont(script1)
        
        if carpetaPadre then
            carpetaPadre.ChildAdded:Connect(function(child)
                wait(0.1)
                if child:IsA("TextBox") or child:IsA("TextLabel") then
                    modificarTextLabel(child)
                    if child:IsA("TextBox") then
                        detectarComandoFont(child)
                    end
                end
            end)
        end
    end)
end

local function modificarSearchbar()
    local exito = pcall(function()
        for _, descendant in pairs(CoreGui:GetDescendants()) do
            if descendant.Name == "Input" then
                local parent = descendant.Parent
                if parent and parent.Name == "Searchbar" then
                    if parent.Parent and parent.Parent.Name == "Scripthub" then
                        if descendant:IsA("TextBox") then
                            descendant.PlaceholderText = configuraciones.textoSearchbar
                            aplicarGradienteLED(descendant)
                            print("Searchbar modificado con éxito: placeholder y gradiente LED aplicados")
                        end
                    end
                end
            end
        end
    end)
    
    if not exito then
        warn("Error al modificar Searchbar")
    end
end

-- Configuraciones del usuario
local configuraciones = {
    idioma = "es",
    rainbowOutline = true,
    colorOutline = Color3.fromRGB(25, 118, 210),
    noOutline = false,
    textoSearchbar = "Search Scripts!",
    fontMinecraft = false,
    gradienteTipo = "navy"
}

-- Colores del tema azul marino profesional
local colores = {
    fondo = Color3.fromRGB(13, 17, 23),
    contenedor = Color3.fromRGB(22, 27, 34),
    superficie = Color3.fromRGB(32, 39, 49),
    primario = Color3.fromRGB(25, 118, 210),
    secundario = Color3.fromRGB(33, 150, 243),
    acento = Color3.fromRGB(100, 181, 246),
    texto = Color3.fromRGB(255, 255, 255),
    textoSecundario = Color3.fromRGB(189, 200, 240),
    exito = Color3.fromRGB(46, 125, 50),
    error = Color3.fromRGB(211, 47, 47),
    advertencia = Color3.fromRGB(245, 124, 0)
}

-- Textos multiidioma
local textos = {
    es = {
        seleccionarIdioma = "Seleccionar Idioma",
        configurarDelta = "Configurar Delta",
        previewRainbow = "Vista Previa: Borde Arcoiris",
        descRainbow = "Aplica un efecto arcoiris animado al borde del ejecutor con colores que rotan continuamente.",
        previewColor = "Vista Previa: Color Solido",
        descColor = "Borde con color solido seleccionado que mantiene un tono consistente.",
        previewSin = "Vista Previa: Sin Borde",
        descSin = "Remueve completamente el borde para un diseño minimalista y limpio.",
        colorOutline = "Color del Borde",
        noOutline = "SIN\nBORDE",
        textoBusqueda = "Texto de Busqueda",
        fontMinecraft = "Fuente Minecraft",
        rainbow = "Arcoiris",
        aplicar = "Aplicar",
        cancelar = "Cancelar",
        siguiente = "Continuar",
        aplicandoCambio = "Procesando...",
        on = "ACTIVADO",
        off = "DESACTIVADO"
    },
    en = {
        seleccionarIdioma = "Select Language",
        configurarDelta = "Configure Delta",
        previewRainbow = "Preview: Rainbow Border",
        descRainbow = "Applies an animated rainbow effect to the executor border with continuously rotating colors.",
        previewColor = "Preview: Solid Color",
        descColor = "Border with selected solid color that maintains a consistent tone.",
        previewSin = "Preview: No Border",
        descSin = "Completely removes the border for a minimalist and clean design.",
        colorOutline = "Border Color",
        noOutline = "NO\nBORDER",
        textoBusqueda = "Search Text",
        fontMinecraft = "Minecraft Font",
        rainbow = "Rainbow",
        aplicar = "Apply",
        cancelar = "Cancel",
        siguiente = "Continue",
        aplicandoCambio = "Processing...",
        on = "ENABLED",
        off = "DISABLED"
    }
}

local function obtenerTexto(clave)
    return textos[configuraciones.idioma][clave] or textos["es"][clave]
end

local screenGui = nil
local contenedor = nil
local previewFrame = nil
local paletaFrame = nil

local function crearSombra(parent)
    local sombra = Instance.new("Frame")
    sombra.Name = "Sombra"
    sombra.Size = UDim2.new(1, 8, 1, 8)
    sombra.Position = UDim2.new(0, -4, 0, -4)
    sombra.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    sombra.BackgroundTransparency = 0.8
    sombra.BorderSizePixel = 0
    sombra.ZIndex = parent.ZIndex - 1
    sombra.Parent = parent.Parent
    
    local cornerSombra = Instance.new("UICorner")
    cornerSombra.CornerRadius = UDim.new(0, 20)
    cornerSombra.Parent = sombra
    
    return sombra
end

local function animarTransicion(callback)
    local TweenService = game:GetService("TweenService")
    
    local tweenPreview = TweenService:Create(previewFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
        Position = UDim2.new(0.5, -140, 0.5, -75)
    })
    
    local tweenPaleta = TweenService:Create(paletaFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
        Position = UDim2.new(0.5, -130, 0.5, -60)
    })
    
    tweenPreview:Play()
    tweenPaleta:Play()
    
    tweenPreview.Completed:Connect(function()
        local centroCuadro = Instance.new("Frame")
        centroCuadro.Size = UDim2.new(0, 180, 0, 60)
        centroCuadro.Position = UDim2.new(0.5, -90, 0.5, -30)
        centroCuadro.BackgroundColor3 = colores.superficie
        centroCuadro.BorderSizePixel = 0
        centroCuadro.Parent = contenedor
        
        local cornerCentro = Instance.new("UICorner")
        cornerCentro.CornerRadius = UDim.new(0, 12)
        cornerCentro.Parent = centroCuadro
        
        local textoCentro = Instance.new("TextLabel")
        textoCentro.Size = UDim2.new(1, 0, 1, 0)
        textoCentro.BackgroundTransparency = 1
        textoCentro.Text = obtenerTexto("aplicandoCambio")
        textoCentro.TextColor3 = colores.texto
        textoCentro.TextScaled = true
        textoCentro.Font = Enum.Font.GothamSemibold
        textoCentro.Parent = centroCuadro
        
        wait(1.2)
        centroCuadro:Destroy()
        
        local tweenPreviewBack = TweenService:Create(previewFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
            Position = UDim2.new(0, 20, 0, 80)
        })
        
        local tweenPaletaBack = TweenService:Create(paletaFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
            Position = UDim2.new(0, 340, 0, 80)
        })
        
        tweenPreviewBack:Play()
        tweenPaletaBack:Play()
        
        tweenPreviewBack.Completed:Connect(function()
            if callback then callback() end
        end)
    end)
end

local function crearSeleccionIdioma()
    local success, error = pcall(function()
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DeltaConfigIntro"
        screenGui.Parent = CoreGui
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local fondo = Instance.new("Frame")
        fondo.Size = UDim2.new(1, 0, 1, 0)
        fondo.BackgroundColor3 = colores.fondo
        fondo.BackgroundTransparency = 0.2
        fondo.Parent = screenGui
        
        contenedor = Instance.new("Frame")
        contenedor.Size = UDim2.new(0, 450, 0, 320)
        contenedor.Position = UDim2.new(0.5, -225, 0.5, -160)
        contenedor.BackgroundColor3 = colores.contenedor
        contenedor.BorderSizePixel = 0
        contenedor.Parent = screenGui
        
        crearSombra(contenedor)
        
        local cornerContenedor = Instance.new("UICorner")
        cornerContenedor.CornerRadius = UDim.new(0, 16)
        cornerContenedor.Parent = contenedor
        
        local titulo = Instance.new("TextLabel")
        titulo.Size = UDim2.new(1, -40, 0, 70)
        titulo.Position = UDim2.new(0, 20, 0, 20)
        titulo.BackgroundTransparency = 1
        titulo.Text = "Select Language / Seleccionar Idioma"
        titulo.TextColor3 = colores.texto
        titulo.TextSize = 24
        titulo.Font = Enum.Font.GothamBold
        titulo.TextWrapped = true
        titulo.Parent = contenedor
        
        local btnEspanol = Instance.new("TextButton")
        btnEspanol.Size = UDim2.new(0, 180, 0, 50)
        btnEspanol.Position = UDim2.new(0.5, -90, 0.5, -40)
        btnEspanol.BackgroundColor3 = colores.primario
        btnEspanol.BorderSizePixel = 0
        btnEspanol.Text = "🇪🇸 Español"
        btnEspanol.TextColor3 = colores.texto
        btnEspanol.TextSize = 18
        btnEspanol.Font = Enum.Font.GothamSemibold
        btnEspanol.Parent = contenedor
        
        local cornerEspanol = Instance.new("UICorner")
        cornerEspanol.CornerRadius = UDim.new(0, 12)
        cornerEspanol.Parent = btnEspanol
        
        local btnIngles = Instance.new("TextButton")
        btnIngles.Size = UDim2.new(0, 180, 0, 50)
        btnIngles.Position = UDim2.new(0.5, -90, 0.5, 20)
        btnIngles.BackgroundColor3 = colores.secundario
        btnIngles.BorderSizePixel = 0
        btnIngles.Text = "🇺🇸 English"
        btnIngles.TextColor3 = colores.texto
        btnIngles.TextSize = 18
        btnIngles.Font = Enum.Font.GothamSemibold
        btnIngles.Parent = contenedor
        
        local cornerIngles = Instance.new("UICorner")
        cornerIngles.CornerRadius = UDim.new(0, 12)
        cornerIngles.Parent = btnIngles
        
        btnEspanol.MouseButton1Click:Connect(function()
            local success, error = pcall(function()
                configuraciones.idioma = "es"
                configuraciones.textoSearchbar = "Buscar Scripts!"
                logInfo("Idioma seleccionado: Español")
                crearConfiguracionOutline()
            end)
            if not success then
                logError("btnEspanol.MouseButton1Click", error)
            end
        end)
        
        btnIngles.MouseButton1Click:Connect(function()
            local success, error = pcall(function()
                configuraciones.idioma = "en"
                configuraciones.textoSearchbar = "Search Scripts!"
                logInfo("Idioma seleccionado: English")
                crearConfiguracionOutline()
            end)
            if not success then
                logError("btnIngles.MouseButton1Click", error)
            end
        end)
    end)
    
    if not success then
        logError("crearSeleccionIdioma", error)
    else
        logInfo("Interfaz de seleccion de idioma creada")
    end
end

local function crearConfiguracionOutline()
    for _, child in pairs(contenedor:GetChildren()) do
        if child.Name ~= "UICorner" then
            child:Destroy()
        end
    end
    
    contenedor.Size = UDim2.new(0, 650, 0, 480)
    contenedor.Position = UDim2.new(0.5, -325, 0.5, -240)
    
    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, -40, 0, 50)
    titulo.Position = UDim2.new(0, 20, 0, 15)
    titulo.BackgroundTransparency = 1
    titulo.Text = obtenerTexto("configurarDelta") .. " - " .. obtenerTexto("colorOutline")
    titulo.TextColor3 = colores.texto
    titulo.TextSize = 22
    titulo.Font = Enum.Font.GothamBold
    titulo.Parent = contenedor
    
    previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(0, 300, 0, 160)
    previewFrame.Position = UDim2.new(0, 20, 0, 80)
    previewFrame.BackgroundColor3 = colores.superficie
    previewFrame.BorderSizePixel = 0
    previewFrame.Parent = contenedor
    
    local cornerPreview = Instance.new("UICorner")
    cornerPreview.CornerRadius = UDim.new(0, 12)
    cornerPreview.Parent = previewFrame
    
    local previewTitle = Instance.new("TextLabel")
    previewTitle.Name = "PreviewTitle"
    previewTitle.Size = UDim2.new(1, -20, 0, 35)
    previewTitle.Position = UDim2.new(0, 10, 0, 10)
    previewTitle.BackgroundTransparency = 1
    previewTitle.Text = obtenerTexto("previewRainbow")
    previewTitle.TextColor3 = colores.acento
    previewTitle.TextSize = 16
    previewTitle.Font = Enum.Font.GothamSemibold
    previewTitle.Parent = previewFrame
    
    local previewDesc = Instance.new("TextLabel")
    previewDesc.Name = "PreviewDesc"
    previewDesc.Size = UDim2.new(1, -20, 1, -55)
    previewDesc.Position = UDim2.new(0, 10, 0, 45)
    previewDesc.BackgroundTransparency = 1
    previewDesc.Text = obtenerTexto("descRainbow")
    previewDesc.TextColor3 = colores.textoSecundario
    previewDesc.TextSize = 14
    previewDesc.TextWrapped = true
    previewDesc.Font = Enum.Font.Gotham
    previewDesc.Parent = previewFrame
    
    paletaFrame = Instance.new("Frame")
    paletaFrame.Size = UDim2.new(0, 290, 0, 160)
    paletaFrame.Position = UDim2.new(0, 340, 0, 80)
    paletaFrame.BackgroundColor3 = colores.superficie
    paletaFrame.BorderSizePixel = 0
    paletaFrame.Parent = contenedor
    
    local cornerPaleta = Instance.new("UICorner")
    cornerPaleta.CornerRadius = UDim.new(0, 12)
    cornerPaleta.Parent = paletaFrame
    
    local paletaTitle = Instance.new("TextLabel")
    paletaTitle.Size = UDim2.new(1, -20, 0, 30)
    paletaTitle.Position = UDim2.new(0, 10, 0, 10)
    paletaTitle.BackgroundTransparency = 1
    paletaTitle.Text = obtenerTexto("colorOutline")
    paletaTitle.TextColor3 = colores.acento
    paletaTitle.TextSize = 16
    paletaTitle.Font = Enum.Font.GothamSemibold
    paletaTitle.Parent = paletaFrame
    
    local coloresPaleta = {
        Color3.fromRGB(244, 67, 54),
        Color3.fromRGB(76, 175, 80),
        Color3.fromRGB(33, 150, 243),
        Color3.fromRGB(255, 193, 7),
        Color3.fromRGB(156, 39, 176),
        Color3.fromRGB(0, 188, 212),
        Color3.fromRGB(255, 87, 34),
        Color3.fromRGB(121, 85, 72)
    }
    
    for i, color in ipairs(coloresPaleta) do
        local colorBtn = Instance.new("TextButton")
        colorBtn.Size = UDim2.new(0, 28, 0, 28)
        local x = ((i - 1) % 4) * 40 + 30
        local y = math.floor((i - 1) / 4) * 40 + 50
        colorBtn.Position = UDim2.new(0, x, 0, y)
        colorBtn.BackgroundColor3 = color
        colorBtn.BorderSizePixel = 0
        colorBtn.Text = ""
        colorBtn.Parent = paletaFrame
        
        local cornerColor = Instance.new("UICorner")
        cornerColor.CornerRadius = UDim.new(1, 0)
        cornerColor.Parent = colorBtn
        
        colorBtn.MouseButton1Click:Connect(function()
            configuraciones.colorOutline = color
            configuraciones.rainbowOutline = false
            configuraciones.noOutline = false
            previewTitle.Text = obtenerTexto("previewColor")
            previewDesc.Text = obtenerTexto("descColor")
            
            animarTransicion(function()
                crearConfiguracionTexto()
            end)
        end)
    end
    
    local noOutlineBtn = Instance.new("TextButton")
    noOutlineBtn.Size = UDim2.new(0, 70, 0, 70)
    noOutlineBtn.Position = UDim2.new(0, 200, 0, 50)
    noOutlineBtn.BackgroundColor3 = colores.contenedor
    noOutlineBtn.BorderSizePixel = 2
    noOutlineBtn.BorderColor3 = colores.textoSecundario
    noOutlineBtn.Text = obtenerTexto("noOutline")
    noOutlineBtn.TextColor3 = colores.textoSecundario
    noOutlineBtn.TextSize = 12
    noOutlineBtn.Font = Enum.Font.GothamBold
    noOutlineBtn.Parent = paletaFrame
    
    local cornerNoOutline = Instance.new("UICorner")
    cornerNoOutline.CornerRadius = UDim.new(1, 0)
    cornerNoOutline.Parent = noOutlineBtn
    
    noOutlineBtn.MouseButton1Click:Connect(function()
        configuraciones.noOutline = true
        configuraciones.rainbowOutline = false
        previewTitle.Text = obtenerTexto("previewSin")
        previewDesc.Text = obtenerTexto("descSin")
        
        animarTransicion(function()
            crearConfiguracionTexto()
        end)
    end)
    
    local rainbowBtn = Instance.new("TextButton")
    rainbowBtn.Size = UDim2.new(0, 220, 0, 45)
    rainbowBtn.Position = UDim2.new(0.5, -110, 1, -90)
    rainbowBtn.BackgroundColor3 = colores.primario
    rainbowBtn.BorderSizePixel = 0
    rainbowBtn.Text = obtenerTexto("rainbow") .. " " .. obtenerTexto("on")
    rainbowBtn.TextColor3 = colores.texto
    rainbowBtn.TextSize = 16
    rainbowBtn.Font = Enum.Font.GothamSemibold
    rainbowBtn.Parent = contenedor
    
    local cornerRainbow = Instance.new("UICorner")
    cornerRainbow.CornerRadius = UDim.new(0, 12)
    cornerRainbow.Parent = rainbowBtn
    
    rainbowBtn.MouseButton1Click:Connect(function()
        configuraciones.rainbowOutline = true
        configuraciones.noOutline = false
        previewTitle.Text = obtenerTexto("previewRainbow")
        previewDesc.Text = obtenerTexto("descRainbow")
        
        animarTransicion(function()
            crearConfiguracionTexto()
        end)
    end)
end

local function crearConfiguracionTexto()
    for _, child in pairs(contenedor:GetChildren()) do
        if child.Name ~= "UICorner" then
            child:Destroy()
        end
    end
    
    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, -40, 0, 50)
    titulo.Position = UDim2.new(0, 20, 0, 15)
    titulo.BackgroundTransparency = 1
    titulo.Text = obtenerTexto("configurarDelta") .. " - " .. obtenerTexto("textoBusqueda")
    titulo.TextColor3 = colores.texto
    titulo.TextSize = 22
    titulo.Font = Enum.Font.GothamBold
    titulo.Parent = contenedor
    
    previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(0, 300, 0, 160)
    previewFrame.Position = UDim2.new(0, 20, 0, 80)
    previewFrame.BackgroundColor3 = colores.superficie
    previewFrame.BorderSizePixel = 0
    previewFrame.Parent = contenedor
    
    local cornerPreview = Instance.new("UICorner")
    cornerPreview.CornerRadius = UDim.new(0, 12)
    cornerPreview.Parent = previewFrame
    
    local previewTitle = Instance.new("TextLabel")
    previewTitle.Size = UDim2.new(1, -20, 0, 30)
    previewTitle.Position = UDim2.new(0, 10, 0, 10)
    previewTitle.BackgroundTransparency = 1
    previewTitle.Text = "Vista Previa: " .. obtenerTexto("textoBusqueda")
    previewTitle.TextColor3 = colores.acento
    previewTitle.TextSize = 16
    previewTitle.Font = Enum.Font.GothamSemibold
    previewTitle.Parent = previewFrame
    
    local previewSearchbar = Instance.new("TextBox")
    previewSearchbar.Size = UDim2.new(1, -40, 0, 40)
    previewSearchbar.Position = UDim2.new(0, 20, 0, 60)
    previewSearchbar.BackgroundColor3 = colores.contenedor
    previewSearchbar.BorderSizePixel = 0
    previewSearchbar.PlaceholderText = configuraciones.textoSearchbar
    previewSearchbar.Text = ""
    previewSearchbar.TextColor3 = colores.texto
    previewSearchbar.TextSize = 14
    previewSearchbar.Font = Enum.Font.Gotham
    previewSearchbar.Parent = previewFrame
    
    local cornerSearchbar = Instance.new("UICorner")
    cornerSearchbar.CornerRadius = UDim.new(0, 8)
    cornerSearchbar.Parent = previewSearchbar
    
    paletaFrame = Instance.new("Frame")
    paletaFrame.Size = UDim2.new(0, 290, 0, 160)
    paletaFrame.Position = UDim2.new(0, 340, 0, 80)
    paletaFrame.BackgroundColor3 = colores.superficie
    paletaFrame.BorderSizePixel = 0
    paletaFrame.Parent = contenedor
    
    local cornerPaleta = Instance.new("UICorner")
    cornerPaleta.CornerRadius = UDim.new(0, 12)
    cornerPaleta.Parent = paletaFrame
    
    local inputTitle = Instance.new("TextLabel")
    inputTitle.Size = UDim2.new(1, -20, 0, 30)
    inputTitle.Position = UDim2.new(0, 10, 0, 10)
    inputTitle.BackgroundTransparency = 1
    inputTitle.Text = "Personalizar Texto"
    inputTitle.TextColor3 = colores.acento
    inputTitle.TextSize = 16
    inputTitle.Font = Enum.Font.GothamSemibold
    inputTitle.Parent = paletaFrame
    
    local textoInput = Instance.new("TextBox")
    textoInput.Size = UDim2.new(1, -20, 0, 40)
    textoInput.Position = UDim2.new(0, 10, 0, 50)
    textoInput.BackgroundColor3 = colores.contenedor
    textoInput.BorderSizePixel = 0
    textoInput.Text = configuraciones.textoSearchbar
    textoInput.TextColor3 = colores.texto
    textoInput.TextSize = 14
    textoInput.Font = Enum.Font.Gotham
    textoInput.Parent = paletaFrame
    
    local cornerInput = Instance.new("UICorner")
    cornerInput.CornerRadius = UDim.new(0, 8)
    cornerInput.Parent = textoInput
    
    textoInput:GetPropertyChangedSignal("Text"):Connect(function()
        configuraciones.textoSearchbar = textoInput.Text
        previewSearchbar.PlaceholderText = textoInput.Text
    end)
    
    local siguienteBtn = Instance.new("TextButton")
    siguienteBtn.Size = UDim2.new(0, 180, 0, 45)
    siguienteBtn.Position = UDim2.new(0.5, -90, 1, -90)
    siguienteBtn.BackgroundColor3 = colores.exito
    siguienteBtn.BorderSizePixel = 0
    siguienteBtn.Text = obtenerTexto("siguiente")
    siguienteBtn.TextColor3 = colores.texto
    siguienteBtn.TextSize = 16
    siguienteBtn.Font = Enum.Font.GothamSemibold
    siguienteBtn.Parent = contenedor
    
    local cornerSiguiente = Instance.new("UICorner")
    cornerSiguiente.CornerRadius = UDim.new(0, 12)
    cornerSiguiente.Parent = siguienteBtn
    
    siguienteBtn.MouseButton1Click:Connect(function()
        animarTransicion(function()
            crearConfiguracionFinal()
        end)
    end)
end

local function crearConfiguracionFinal()
    for _, child in pairs(contenedor:GetChildren()) do
        if child.Name ~= "UICorner" then
            child:Destroy()
        end
    end
    
    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, -40, 0, 50)
    titulo.Position = UDim2.new(0, 20, 0, 15)
    titulo.BackgroundTransparency = 1
    titulo.Text = obtenerTexto("configurarDelta") .. " - Configuracion Final"
    titulo.TextColor3 = colores.texto
    titulo.TextSize = 22
    titulo.Font = Enum.Font.GothamBold
    titulo.Parent = contenedor
    
    local fontBtn = Instance.new("TextButton")
    fontBtn.Size = UDim2.new(0, 250, 0, 60)
    fontBtn.Position = UDim2.new(0.5, -125, 0.5, -80)
    fontBtn.BackgroundColor3 = colores.superficie
    fontBtn.BorderSizePixel = 0
    fontBtn.Text = obtenerTexto("fontMinecraft") .. ": " .. obtenerTexto("off")
    fontBtn.TextColor3 = colores.textoSecundario
    fontBtn.TextSize = 16
    fontBtn.Font = Enum.Font.GothamSemibold
    fontBtn.Parent = contenedor
    
    local cornerFont = Instance.new("UICorner")
    cornerFont.CornerRadius = UDim.new(0, 12)
    cornerFont.Parent = fontBtn
    
    fontBtn.MouseButton1Click:Connect(function()
        configuraciones.fontMinecraft = not configuraciones.fontMinecraft
        fontBtn.Text = obtenerTexto("fontMinecraft") .. ": " .. (configuraciones.fontMinecraft and obtenerTexto("on") or obtenerTexto("off"))
        fontBtn.BackgroundColor3 = configuraciones.fontMinecraft and colores.exito or colores.superficie
        fontBtn.TextColor3 = configuraciones.fontMinecraft and colores.texto or colores.textoSecundario
    end)
    
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, -40, 0, 50)
    btnFrame.Position = UDim2.new(0, 20, 1, -70)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = contenedor
    
    local aplicarBtn = Instance.new("TextButton")
    aplicarBtn.Size = UDim2.new(0, 140, 1, 0)
    aplicarBtn.Position = UDim2.new(1, -290, 0, 0)
    aplicarBtn.BackgroundColor3 = colores.exito
    aplicarBtn.BorderSizePixel = 0
    aplicarBtn.Text = obtenerTexto("aplicar")
    aplicarBtn.TextColor3 = colores.texto
    aplicarBtn.TextSize = 16
    aplicarBtn.Font = Enum.Font.GothamSemibold
    aplicarBtn.Parent = btnFrame
    
    local cornerAplicar = Instance.new("UICorner")
    cornerAplicar.CornerRadius = UDim.new(0, 12)
    cornerAplicar.Parent = aplicarBtn
    
    local cancelarBtn = Instance.new("TextButton")
    cancelarBtn.Size = UDim2.new(0, 140, 1, 0)
    cancelarBtn.Position = UDim2.new(1, -140, 0, 0)
    cancelarBtn.BackgroundColor3 = colores.error
    cancelarBtn.BorderSizePixel = 0
    cancelarBtn.Text = obtenerTexto("cancelar")
    cancelarBtn.TextColor3 = colores.texto
    cancelarBtn.TextSize = 16
    cancelarBtn.Font = Enum.Font.GothamSemibold
    cancelarBtn.Parent = btnFrame
    
    local cornerCancelar = Instance.new("UICorner")
    cornerCancelar.CornerRadius = UDim.new(0, 12)
    cornerCancelar.Parent = cancelarBtn
    
    aplicarBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        aplicarConfiguraciones()
    end)
    
    cancelarBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
end

local function aplicarConfiguraciones()
    local success, error = pcall(function()
        logInfo("Iniciando aplicacion de configuraciones...")
        
        if configuraciones.fontMinecraft then
            logInfo("Aplicando font Minecraft...")
            cambiarFontMinecraft(game.Players.LocalPlayer.PlayerGui)
            cambiarFontMinecraft(CoreGui)
            cambiarFontChat()
        end
        
        logInfo("Modificando componentes de Delta...")
        modificarExecutor()
        modificarShowcase()
        modificarNetworkFrame()
        modificarConsoleTitles()
        modificarSearchbar()
        
        if not configuraciones.noOutline then
            logInfo("Aplicando efectos de outline...")
            buscarYModificarScreenGuis()
        end
        
        crearBotonRainbow()
        logInfo("Configuraciones aplicadas exitosamente")
    end)
    
    if not success then
        logError("aplicarConfiguraciones", error)
    end
end

-- Iniciar con seleccion de idioma
local success, error = pcall(function()
    logInfo("Iniciando DeltaCustom...")
    crearSeleccionIdioma()
end)

if not success then
    logError("Inicio del script", error)
end

CoreGui.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "script1.lua" then
        wait(0.1)
        modificarExecutor()
    elseif descendant.Name == "Showcase" then
        wait(0.1)
        modificarShowcase()
    elseif descendant.Name == "Frame" then
        wait(0.1)
        modificarNetworkFrame()
    elseif descendant.Name == "Title" then
        wait(0.1)
        modificarConsoleTitles()
    elseif descendant.Name == "Input" or descendant.Name == "Searchbar" or descendant.Name == "Scripthub" then
        wait(0.1)
        modificarSearchbar()
    elseif descendant:IsA("ScreenGui") then
        wait(0.1)
        buscarYModificarScreenGuis()
    elseif descendant.Name == "Settings" then
        wait(0.5)
        crearBotonRainbow()
    elseif descendant.Name == "Holder" and descendant.Parent and descendant.Parent.Name == "Settings" then
        wait(0.5)
        crearBotonRainbow()
    end
end)