
//Private API
__WM_scripts = [];

function WM_loadScriptNamed(name, mainFunction, setupFunction) {
	//Create a new patch
	var patch = new WMPatch();
	if (setupFunction) {
		setupFunction(patch);
	}
	__WM_scripts[name] = function(){ mainFunction(patch) };
}

function WM_runScriptNamed(name) {
	return __WM_scripts[name]();
}

function WM_clearScriptNamed(name) {
	__WM_scripts[name] = undefined;
}


//Public api

function WMPort(name, type) {
	switch (type) {
		case WMPort.Types.Number:
			this.value = 0.0;
			break;
		case WMPort.Types.Index:
			this.value = 0;
			break;
		case WMPort.Types.Vector:
			this.value = [0.0, 0.0, 0.0, 0.0];
			break;
		case WMPort.Types.Color:
			this.value = [1.0, 1.0, 1.0, 1.0];
			break;
		case WMPort.Types.Boolean:
			this.value = false;
			break;
		case WMPort.Types.String:
			this.value = "";
			break;
	}
	this.name = name;
	this.type = type;
}
WMPort.Types = {
	Number  : 0,
	Index   : 1,
	Vector  : 2,
	Color   : 3,
	Boolean : 4,
	String  : 5,
	Buffer  : 6,
	//TODO: Image
	//TODO: RenderObject
};



function WMPatch() {
	this.inputPorts = [];
	this.outputPorts = [];
}

WMPatch.prototype = {
	addInputPorts : function(portDefinitions) {
		for (var i=0; i<portDefinitions.length; i++) {
			var def = portDefinitions[i];
			var port = WMPort(def.name, def.type);
			inputPorts.push(port);
			inputPorts[def.name] = port;
		}
	}
};