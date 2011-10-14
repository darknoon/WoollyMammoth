local n = 10000
function main ()
	local buffer = WMBuffer.new(vec4Buffer)
	local vec = WMVec4.new(0,0,0,0);
	local ps = {position = vec}

	buffer[n] = ps

	for i = 1,n do
		vec:set(i, i+1, i+2, i+3)
		buffer[i] = ps
	end
end