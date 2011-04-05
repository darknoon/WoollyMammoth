print "debug rotate ran"

DebugRotate = {}

setmetatable(DebugRotate, WMGameObject)

function DebugRotate:update()
	self.test = "blar"
	for i,v in ipairs(self) do print (i, v) end
end
