WMGameObject = {}

WMGameObject.__index = WMGameObject

function WMGameObject:new (o)
      o = o or {}   -- create object if user does not provide one
      setmetatable(o, self)
      self.__index = self
      return o
end

function WMGameObject:test()
	print "game object" .. ;
end

print "Imported WMGameObject"