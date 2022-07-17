-- Copyright (c) 2019-2022 David Vogel
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

CAPTURE_PIXEL_SIZE = 1 -- Screen to virtual pixel ratio.
CAPTURE_GRID_SIZE = 512 -- in virtual (world) pixels. There will always be exactly 4 images overlapping if the virtual resolution is 1024x1024.
CAPTURE_FORCE_HP = 4 -- * 25HP

-- "Base layout" (Base layout. Every part outside this is based on a similar layout, but uses different materials/seeds)
CAPTURE_AREA_BASE_LAYOUT = {
	Left = -17920, -- in virtual (world) pixels.
	Top = -7168, -- in virtual (world) pixels.
	Right = 17920, -- in virtual (world) pixels. (Coordinate is not included in the rectangle)
	Bottom = 17408 -- in virtual (world) pixels. (Coordinate is not included in the rectangle)
}

-- "Main world" (The main world with 3 parts: sky, normal and hell)
CAPTURE_AREA_MAIN_WORLD = {
	Left = -17920, -- in virtual (world) pixels.
	Top = -31744, -- in virtual (world) pixels.
	Right = 17920, -- in virtual (world) pixels. (Coordinate is not included in the rectangle)
	Bottom = 41984 -- in virtual (world) pixels. (Coordinate is not included in the rectangle)
}

-- "Extended" (Main world + a fraction of the parallel worlds to the left and right)
CAPTURE_AREA_EXTENDED = {
	Left = -25600, -- in virtual (world) pixels.
	Top = -31744, -- in virtual (world) pixels.
	Right = 25600, -- in virtual (world) pixels. (Coordinate is not included in the rectangle)
	Bottom = 41984 -- in virtual (world) pixels. (Coordinate is not included in the rectangle)
}

-- Set of already captured entities.
local capturedEntities = {}

local function preparePlayer()
	local playerEntity = getPlayer()
	addEffectToEntity(playerEntity, "PROTECTION_ALL")

	--addPerkToPlayer("BREATH_UNDERWATER")
	--addPerkToPlayer("INVISIBILITY")
	--addPerkToPlayer("REMOVE_FOG_OF_WAR")
	--addPerkToPlayer("REPELLING_CAPE")
	--addPerkToPlayer("WORM_DETRACTOR")
	setPlayerHP(CAPTURE_FORCE_HP)
end

--- Captures a screenshot at the given coordinates.
--- This will block until all chunks in the given area are loaded.
---
--- @param x number -- Virtual x coordinate (World pixels) of the screen center.
--- @param y number -- Virtual y coordinate (World pixels) of the screen center.
--- @param rx number -- Screen x coordinate of the top left corner of the screenshot rectangle.
--- @param ry number -- Screen y coordinate of the top left corner of the screenshot rectangle.
--- @param entityFile file*
local function captureScreenshot(x, y, rx, ry, entityFile)
	local virtualWidth, virtualHeight =
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")),
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))

	local virtualHalfWidth, virtualHalfHeight = math.floor(virtualWidth / 2), math.floor(virtualHeight / 2)
	local xMin, yMin = x - virtualHalfWidth, y - virtualHalfHeight
	local xMax, yMax = xMin + virtualWidth, yMin + virtualHeight

	UiCaptureDelay = 0
	GameSetCameraPos(x, y)
	repeat
		if UiCaptureDelay > 100 then
			-- Wiggle the screen a bit, as chunks sometimes don't want to load.
			GameSetCameraPos(x + math.random(-100, 100), y + math.random(-100, 100))
			DrawUI()
			wait(0)
			UiCaptureDelay = UiCaptureDelay + 1
			GameSetCameraPos(x, y)
		end

		DrawUI()
		wait(0)
		UiCaptureDelay = UiCaptureDelay + 1
	until DoesWorldExistAt(xMin, yMin, xMax, yMax) -- Chunks will be drawn on the *next* frame.

	wait(0) -- Without this line empty chunks may still appear, also it's needed for the UI to disappear.
	if not TriggerCapture(rx, ry) then
		UiCaptureProblem = "Screen capture failed. Please restart Noita."
	end

	-- Capture entities right after capturing the screenshot.
	if entityFile then
		local radius = math.sqrt(virtualHalfWidth^2 + virtualHalfHeight^2) + 1
		local entities = EntityGetInRadius(x, y, radius)
		for _, entityID in ipairs(entities) do
			-- Make sure to only export entities when they are encountered the first time.
			if not capturedEntities[entityID] then
				capturedEntities[entityID] = true
				local x, y, rotation, scaleX, scaleY = EntityGetTransform(entityID)
				local entityName = EntityGetName(entityID)
				local entityTags = EntityGetTags(entityID)
				entityFile:write(string.format("%d, %s, %f, %f, %f, %f, %f, %q\n", entityID, entityName, x, y, rotation, scaleX, scaleY, entityTags))
				-- TODO: Correctly escape CSV data
			end
		end
		entityFile:flush() -- Ensure everything is written to disk before noita decides to crash.
	end

	-- Reset monitor and PC standby each screenshot.
	ResetStandbyTimer()
end

local function createOrOpenEntityCaptureFile()
	local file = io.open("mods/noita-mapcap/output/entities.csv", "r")
	if file then
		local _ = file:read() -- Skip first line.
		for line in file:lines() do
			for field in string.gmatch(line, "([^,]+)") do
				local entityID = tonumber(field)
				if entityID then
					capturedEntities[entityID] = true
				end
				break
			end
		end
		file:close()
	end

	-- Create or reopen entities CSV file.
	local file = io.open("mods/noita-mapcap/output/entities.csv", "a+")
	if file == nil then return nil end

	if file:seek("end") == 0 then
		-- Empty file: Create header.
		file:write("entityID, entityName, x, y, rotation, scaleX, scaleY, tags\n")
		file:flush()
	end

	return file
end

function startCapturingSpiral()
	local entityFile = createOrOpenEntityCaptureFile()

	local ox, oy = GameGetCameraPos() -- Returns the virtual coordinates of the screen center.
	ox, oy = math.floor(ox / CAPTURE_GRID_SIZE) * CAPTURE_GRID_SIZE, math.floor(oy / CAPTURE_GRID_SIZE) * CAPTURE_GRID_SIZE
	ox, oy = ox + 256, oy + 256 -- Align screen with ingame chunk grid that is 512x512.
	local x, y = ox, oy

	local virtualWidth, virtualHeight =
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")),
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))

	local virtualHalfWidth, virtualHalfHeight = math.floor(virtualWidth / 2), math.floor(virtualHeight / 2)

	preparePlayer()

	GameSetCameraFree(true)

	-- Coroutine to calculate next coordinate, and trigger screenshots.
	local i = 1
	async_loop(
		function()
			-- +x
			for i = 1, i, 1 do
				local rx, ry = (x - virtualHalfWidth) * CAPTURE_PIXEL_SIZE, (y - virtualHalfHeight) * CAPTURE_PIXEL_SIZE
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					captureScreenshot(x, y, rx, ry, entityFile)
				end
				x, y = x + CAPTURE_GRID_SIZE, y
			end
			-- +y
			for i = 1, i, 1 do
				local rx, ry = (x - virtualHalfWidth) * CAPTURE_PIXEL_SIZE, (y - virtualHalfHeight) * CAPTURE_PIXEL_SIZE
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					captureScreenshot(x, y, rx, ry, entityFile)
				end
				x, y = x, y + CAPTURE_GRID_SIZE
			end
			i = i + 1
			-- -x
			for i = 1, i, 1 do
				local rx, ry = (x - virtualHalfWidth) * CAPTURE_PIXEL_SIZE, (y - virtualHalfHeight) * CAPTURE_PIXEL_SIZE
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					captureScreenshot(x, y, rx, ry, entityFile)
				end
				x, y = x - CAPTURE_GRID_SIZE, y
			end
			-- -y
			for i = 1, i, 1 do
				local rx, ry = (x - virtualHalfWidth) * CAPTURE_PIXEL_SIZE, (y - virtualHalfHeight) * CAPTURE_PIXEL_SIZE
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					captureScreenshot(x, y, rx, ry, entityFile)
				end
				x, y = x, y - CAPTURE_GRID_SIZE
			end
			i = i + 1
		end
	)
end

function startCapturingHilbert(area)
	local entityFile = createOrOpenEntityCaptureFile()

	local ox, oy = GameGetCameraPos()

	local virtualWidth, virtualHeight =
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")),
		tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))

	local virtualHalfWidth, virtualHalfHeight = math.floor(virtualWidth / 2), math.floor(virtualHeight / 2)

	-- Get size of the rectangle in grid/chunk coordinates.
	local gridLeft = math.floor(area.Left / CAPTURE_GRID_SIZE)
	local gridTop = math.floor(area.Top / CAPTURE_GRID_SIZE)
	local gridRight = math.ceil(area.Right / CAPTURE_GRID_SIZE) -- This grid coordinate is not included.
	local gridBottom = math.ceil(area.Bottom / CAPTURE_GRID_SIZE) -- This grid coordinate is not included.

	-- Edge case
	if area.Left == area.Right then
		gridRight = gridLeft
	end
	if area.Top == area.Bottom then
		gridBottom = gridTop
	end

	-- Size of the grid in chunks.
	local gridWidth = gridRight - gridLeft
	local gridHeight = gridBottom - gridTop

	-- Hilbert curve can only fit into a square, so get the longest side.
	local gridPOTSize = math.ceil(math.log(math.max(gridWidth, gridHeight)) / math.log(2))
	-- Max size (Already rounded up to the next power of two).
	local gridMaxSize = math.pow(2, gridPOTSize)

	local t, tLimit = 0, gridMaxSize * gridMaxSize

	UiProgress = {Progress = 0, Max = gridWidth * gridHeight}

	preparePlayer()

	GameSetCameraFree(true)

	-- Coroutine to calculate next coordinate, and trigger screenshots.
	async(
		function()
			while t < tLimit do
				local hx, hy = mapHilbert(t, gridPOTSize)
				if hx < gridWidth and hy < gridHeight then
					local x, y = (hx + gridLeft) * CAPTURE_GRID_SIZE, (hy + gridTop) * CAPTURE_GRID_SIZE
					x, y = x + 256, y + 256 -- Align screen with ingame chunk grid that is 512x512.
					local rx, ry = (x - virtualHalfWidth) * CAPTURE_PIXEL_SIZE, (y - virtualHalfHeight) * CAPTURE_PIXEL_SIZE
					if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
						captureScreenshot(x, y, rx, ry, entityFile)
					end
					UiProgress.Progress = UiProgress.Progress + 1
				end

				t = t + 1
			end

			UiProgress.Done = true
		end
	)
end
