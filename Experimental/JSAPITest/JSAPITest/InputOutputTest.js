/*
 
 Supported port types:
 WMPort.Types.Number  = 32-bit float
 WMPort.Types.Index   = 32-bit unsigned int
 WMPort.Types.Vector  = [float, float, float, float] //from 2-4 values
 WMPort.Types.Color   = [float, float, float, float]
 WMPort.Types.Boolean = bool
 WMPort.Types.String  = utf-8 string
 WMPort.Types.Buffer  = WMStructuredBuffer, see documentation
 
 */
var iteration = 0;

//Called when the patch is being set up
function setup(patch) {
	//Have the chance to add/remove ports before deserialization
	patch.addInputPorts([{name:"count", type:WMPort.Types.Index}]);
	patch.addOutputPorts([{name:"t", type:WMPort.Types.Buffer}]);
}

//Read from the inputs and write to the outputs
function main(patch) {
	var count = 1000o;//patch.inputPorts["count"].value;
	
	iteration++;
	
	var def = new WMStructure([{ name : "pos",
								 type : WMBuffer.Type.UnsignedShort,
								count : 4,
							   offset : 0,
						   normalized : true}], 4 * 4);
	
	t = new WMBuffer(def, 4 * 4 * count);
	
	for (var i=0; i<count; i++) {
		t.appendObject({"pos":[count + iteration + 0, count + iteration + 1, count + iteration + 2, count + iteration + 3]});
	}
	
	return {t: t};
}