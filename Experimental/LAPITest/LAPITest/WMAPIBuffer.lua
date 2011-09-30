
--WMBuffer = {}

--TODO: create this table in code from the OpenGL api's constants
WMBuffer.Type = {
	Byte          = 0x1400 + 0,
	UnsignedByte  = 0x1400 + 1,
	Short         = 0x1400 + 2,
	UnsignedShort = 0x1400 + 3,
	Int           = 0x1400 + 4,
	UnsignedInt   = 0x1400 + 5,
	Float         = 0x1400 + 6,
	--Same as GL_FIXED
	Fixed         = 0x140C,
}

WMBuffer.TypeSize = {
	[WMBuffer.Type.Byte]          = 1,
	[WMBuffer.Type.UnsignedByte]  = 1,
	[WMBuffer.Type.Short]         = 2,
	[WMBuffer.Type.UnsignedShort] = 2,
	[WMBuffer.Type.Int]           = 4,
	[WMBuffer.Type.UnsignedInt]   = 4,
	[WMBuffer.Type.Float]         = 4,
	[WMBuffer.Type.Fixed]         = 4,
}



WMStructure = {}

function WMStructure:new(fieldList, totalSize)
	self.fieldList = fieldList;
	self.totalSize = totalSize;
	
	--TODO: make sure the fields don't overlap!!
	--TODO: make sure no field extends outside the totalSize
end

function WMStructure:fieldWithName (name)
	for i,field in ipairs(self.fieldList) do
		local field = self.fieldList[i];
		if field.name == name then
			return field
		end
	end
end

vec4Buffer = {
	fields    = {{name="position", type=WMBuffer.Type.Float, count=4}},
	totalSize = 4*4};

--print(vec4Buffer);
--print(buffer); 

--[[ 

To write through the C API into the structured buffer, use this pseudo-method

-- Create a new buffer with a single vertex attribute "position" with 4 floats of 4 bytes each, 16 bytes total

-- This returns a pointer to a userdata whose metatable specifies an __index function and a __newindex function.

-- The __newindex function looks for fields corresponding to the pushed buffer and writes to them
buffer[0] = {position = {0, 1, 2, 3}}

-- The __index function returns an object whose values are tables with names and values corresponding to the fields of the buffer's structure

-- Returns 1
buffer[0].position[2]

-- When we're done modifying the buffer, we can just output it 

patch.outputPorts.buffer.value = buffer;

--]]