local n = 10000
function main ()
	local vec = {0,0,0,0}
	local ps = {position = vec}
	local buffer = WMBuffer.new(vec4Buffer)
	buffer[n] = ps
	for i = 1,n do
		vec[1] = i
		vec[2] = i+1
		vec[3] = i+2
		vec[4] = i+3
		buffer[i] = ps
	end
end