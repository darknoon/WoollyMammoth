-- This is an admittedly slow implementation of float[3/4] vectors in lua

Vector = {}

function Vector:new(o)
  local object = o or {0,0,0,0}
  setmetatable(object, { __index = Vector, __tostring = Vector.tostring})
  return object
end

function Vector:magnitude()
  return math.sqrt(self[1]^2 + self[2]^2 + self[3]^2, (self[4] or 0)^2)
end

function Vector:add(b)
  return Vector:new({self[1] + b[1], self[2] + b[2], self[3] + b[3], (self[4] or 0) + (b[4] or 0)})
end

function Vector:dot(a)
  return self[1]*a[1] + self[2]*a[2] + self[3]*a[3] + (self[4] or 0) * (a[4] or 0)
end

function Vector:tostring()
  return "<" .. self[1] .. ", " .. self[2] .. ", " .. self[3] .. ", " .. (self[4] or 0) .. ">"
end

function vec(x,y,z)
  return Vector:new({x,y,z})
end

