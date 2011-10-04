
/*

 An example of a field:
 field = { name  : "pos",
   type  : WMBuffer.Type.Float,
   count : 4,
   offset: 0,
   normalized: true}
 
 How to create a buffer:
 buffer = new WMBuffer([field, otherfield])
 
 Then append some data
 buffer.appendObject({pos: [0.0, 0.2, 0.5]})
 
 */

function WMStructure(fieldList, totalSize) {
	this.fieldList = fieldList;
	this.totalSize = totalSize;
	
	//TODO: make sure the fields don't overlap!!
}

WMStructure.prototype = {
	fieldWithName : function(name) {
		for (var i=0; i<this.fieldList.length; ++i) {
			var field = this.fieldList[i];
			if (field.name == name) {
				return field;
			}
		}
	}
};



WMBuffer.Type = {
	Byte          : 0x1400 + 0,
	UnsignedByte  : 0x1400 + 1,
	Short         : 0x1400 + 2,
	UnsignedShort : 0x1400 + 3,
	Int           : 0x1400 + 4,
	UnsignedInt   : 0x1400 + 5,
	Float         : 0x1400 + 6,
	//Same as GL_FIXED
	Fixed         : 0x140C,
};

function WMBuffer (structure, size) {
	this.structure = structure;
	this.buffer = new ArrayBuffer(size);
	this.count = 0;
	return this;
}

WMBuffer.prototype = {
	//Same as gl types
	
//	setSize : function(size) {
//		function nextPowerOf2(i){
//			v = i<<0;
//			v--;
//			v |= v >> 1;
//			v |= v >> 2;
//			v |= v >> 4;
//			v |= v >> 8;
//			v |= v >> 16;
//			return ++v;
//		}
//		if (this.buffer.length != nextPowerOf2(size)) {
//			this.buffer = new ArrayBuffer(
//		}
//	}
	
	currentOffset : function() {
		return this.structure.totalSize * this.count;
	},
		
	appendObject : function(object) {
		function constructor (type) {
			switch (type) {
				case WMBuffer.Type.Byte:
					return Int8Array;
				case WMBuffer.Type.UnsignedByte:
					return Uint8Array;
				case WMBuffer.Type.Short:
					return Int16Array;
				case WMBuffer.Type.UnsignedShort:
					return Uint16Array;
				case WMBuffer.Type.Int:
					return Int32Array;
				case WMBuffer.Type.UnsignedInt:
					return Uint32Array;
				case WMBuffer.Type.Float:
					return Float32Array;
			}
		};
		
		for (var key in object) {
			//Find corresponding field in definition
			var field = this.structure.fieldWithName(key);
			//Make a new reference into our buffer of the correct type
			var pointer = new (constructor(field.type))(this.buffer, this.currentOffset() + field.offset, field.count);
			//If the value is an array, use that, otherwise make an array with just the one value
			var arr = object[key].length ? object[key] : [1 * object[key]];
			pointer.set(arr);
		}
		
		this.count++;
	},
	
	dataString : function() {
		var rawBuf = new Uint8Array(this.buffer);
		var data = ""
		for (var i=0; i<rawBuf.length; i++) {
			data += String.fromCharCode(rawBuf[i]);
		}
		return data;
	},
	
	toJSON : function() {
		return {
			"_wmtype": "wmsbuf",
			"data": this.dataString()};
	}
};


