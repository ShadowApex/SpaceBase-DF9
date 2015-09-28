------------------------------------------------------------------------
-- The contents of this file are subject to the Common Public
-- Attribution License Version 1.0. (the "License"); you may not use
-- this file except in compliance with this License.  You may obtain a
-- copy of the License from the COPYING file included in this code
-- base. The License is based on the Mozilla Public License Version 1.1,
-- but Sections 14 and 15 have been added to cover use of software over
-- a computer network and provide for limited attribution for the
-- Original Developer. In addition, Exhibit A has been modified to be
-- consistent with Exhibit B.
--
-- Software distributed under the License is distributed on an "AS IS"
-- basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
-- the License for the specific language governing rights and
-- limitations under the License.
--
-- The Original Code is Spacebase DF-9.
--
-- The Original Developer is not the Initial Developer and is Andrew
-- Hewson of Derelict Games.

-- The Initial Developer of the Original Code is Double Fine
-- Productions, Inc.
--
-- The code in this file is the original work of Derelict Games,
-- authored by Andrew Hewson.
--
-- Copyright (c) 2015  Andrew Hewson <hewson.andy@gmail.com>
-- All Rights Reserved.
------------------------------------------------------------------------


local MOAIImageExt = {}

function MOAIImageExt.new()
	local self = MOAIImage.new()
	
	function self.fillRect(p1, p2, colour)
		local incx = p1.x < p2.x and 1 or -1
		local incy = p1.y < p2.y and 1 or -1
		for y = p1.y, p2.y, incy do
			for x = p1.x, p2.x, incx do
				self:setRGBA(x, y, unpack(colour))
			end
		end
	end
	
	function self.fillTriangle(p1, p2, p3, colour)
		if p1.y > p2.y then
			local temp = p2
			p2 = p1
			p1 = temp
		end
		if p2.y > p3.y then
			local temp = p2
			p2 = p3
			p3 = temp
		end
		if p1.y > p2.y then
			local temp = p2
			p2 = p1
			p1 = temp
		end
		if self.lineSide2D(p2, p1, p3) > 0 then
			for y = p1.y, p3.y do
				if y < p2.y then
					self.scanLine(y, p1, p3, p1, p2, colour)
				else
					self.scanLine(y, p1, p3, p2, p3, colour)
				end
			end
		else
			for y = p1.y, p3.y do
				if y < p2.y then
					self.scanLine(y, p1, p2, p1, p3, colour)
				else
					self.scanLine(y, p2, p3, p1, p3, colour)
				end
			end
		end
	end
	
	function self.lineSide2D(p, lineFrom, lineTo)
		return self.cross2D(p.x - lineFrom.x, p.y - lineFrom.y, lineTo.x - lineFrom.x, lineTo.y - lineFrom.y)
	end

	function self.cross2D(x0, y0, x1, y1)
		return x0 * y1 - x1 * y0
	end

	function self.scanLine(y, pa, pb, pc, pd, colour)
		local grad1 = pa.y ~= pb.y and (y - pa.y) / (pb.y - pa.y) or 1
		local grad2 = pc.y ~= pd.y and (y - pc.y) / (pd.y - pc.y) or 1
		local sx = self.interpolate(pa.x, pb.x, grad1)
		local ex = self.interpolate(pc.x, pd.x, grad2)
		for x = sx, ex do
			self:setRGBA(x, y, unpack(colour))
		end
	end

	function self.interpolate(vmin, vmax, grad)
		return vmin + (vmax - vmin) * self.clamp(grad)
	end

	function self.clamp(value, vmin, vmax)
		vmin = vmin or 0
		vmax = vmax or 1
		return math.max(vmin, math.min(value, vmax))
	end
	
	function self.fillCircle(x0, y0, r, colour)
		for x = -r, r do
			local h = math.sqrt(r * r - x * x)
			for y = -h, h do
				self:setRGBA(x0 + x, y0 + y, unpack(colour))
			end
		end
	end
	
	function self.fillQuartCircle(x0, y0, r, n, colour)
		local startx, endx
		if n == 1 or n == 3 then
			startx, endx = -r, 0
		elseif n == 2 or n == 4 then
			startx, endx = 0, r
		end
		for x = startx, endx do
			local h = math.sqrt(r * r - x * x)
			local starty, endy
			if n == 1 or n == 2 then
				starty, endy = -h, 0
			elseif n == 3 or n == 4 then
				starty, endy = 0, h
			end
			for y = starty, endy do
				self:setRGBA(x0 + x, y0 + y, unpack(colour))
			end
		end
	end
	
	function self.drawLine(x0, y0, x1, y1, w, colour)
		local deltax = math.abs(x1 - x0)
		local deltay = math.abs(y1 - y0)
		local x = x0
		local y = y0
		local xinc0, xinc1, yinc0, yinc1, den, num, numAdd, numPixels
		if x1 >= x0 then
			xinc0 = 1
			xinc1 = 1
		else
			xinc0 = -1
			xinc1 = -1
		end
		if y1 >= y0 then
			yinc0 = 1
			yinc1 = 1
		else
			yinc0 = -1
			yinc1 = -1
		end
		if deltax >= deltay then
			xinc0 = 0
			yinc1 = 0
			den = deltax
			num  = deltax / 2
			numAdd = deltay
			numPixels = deltax
		else
			xinc1 = 0
			yinc0 = 0
			den = deltay
			num = deltay / 2
			numAdd = deltax
			numPixels = deltay
		end
		for curPixel = 0, numPixels do
			self:setRGBA(x, y, unpack(colour))
			for k = 1, w, 1 do
				self:setRGBA(x + k * xinc0, y - k * yinc0, unpack(colour))
				self:setRGBA(x - k * xinc0, y + k * yinc0, unpack(colour))
			end
			num = num + numAdd
			if num >= den then
				num = num - den
				x = x + xinc0
				y = y + yinc0
			end
			x = x + xinc1
			y = y + yinc1
		end
	end
	
	-- if copyTransparent is set to false, will only copy pixels with > 0 alpha
	function self.copyImage(src, srcX, srcY, srcEndX, srcEndY, destStartX, destStartY, copyTransparent)
		copyTransparent = copyTransparent == nil and true or copyTransparent
		local incx, incy = 1, 1
		local startX, startY, endX, endY = 0, 0, srcEndX - srcX, srcEndY - srcY
		if srcX > srcEndX then
			incx = -1
			startX = srcEndX
		end
		if srcY > srcEndY then
			incy = -1
			startY = srcEndY
		end
		for n = startY, endY, incy do
			for m = startX, endX, incx do
				local x, y = startX + m * incx, startY + n * incy
				local r, g, b, a = src:getRGBA(x, y)
				if copyTransparent or a > 0 then
					self:setRGBA(destStartX + m, destStartY + n, r, g, b, a)
				end
			end
		end
	end
	
	return self
end

return MOAIImageExt