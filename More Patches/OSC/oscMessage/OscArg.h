/*
 OscMessage -- Open Sound Control message wrapper for oscpack
 http://www.muse.com/tr3
 
 Copyright (c) 2010 Warren Stringer <warren@muse.com>
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files
 (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 Any person wishing to distribute modifications to the Software is
 requested to send the modifications to the original developer so that
 they can be incorporated into the canonical version.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef OscArg_H
#define OscArg_H

#include <string>
#include "OscArgType.h"

struct OscArg {
    
    OscArg(OscArg&arg)     {
        
        _oscArgType = arg._oscArgType;
        
        switch (_oscArgType) {
        
            case kOscArgType_Int32   : _ivalue = arg._ivalue; break;
            case kOscArgType_Float   : _fvalue = arg._fvalue; break;
            case kOscArgType_String  : _svalue = new std::string(arg._svalue->c_str()); break;
            default: break;
        }
    }
    OscArg(){_oscArgType = kOscArgType_Undfined;}
	OscArg(float value)      { set(value); }
	OscArg(int32_t value)    { set(value); }
	OscArg(const char*value) { set(value); }
	OscArg(std::string value){ set(value.c_str()); }    
    
    ~OscArg() {if (_oscArgType==kOscArgType_String) delete _svalue;}

    void set(float   value )   {_oscArgType = kOscArgType_Float;  _fvalue = value; }
    void set(int32_t value )   {_oscArgType = kOscArgType_Int32;  _ivalue = value; }
    void set(const char*value) {_oscArgType = kOscArgType_String; _svalue = new std::string(value); }

    operator float()        const {return _fvalue;}
    operator std::string()  const {return*_svalue;}
    operator int32_t()      const {return _ivalue;}
    
    OscArgType getType() { return _oscArgType; }
    
    std::string getTypeName() {
        
        switch (_oscArgType) {
        
            case kOscArgType_Int32   : return "int";
            case kOscArgType_Float   : return "float";
            case kOscArgType_String  : return "string";
                /*
            case kOscArgType_True    : return "true";
            case kOscArgType_False   : return "false";
            case kOscArgType_None    : return "none";                
            case kOscArgType_Blob    : return "blob";  
                 */
            default              : return "undefined";
        }
    }
    
    OscArgType _oscArgType;
    
    union {	
        int32_t      _ivalue;
        float        _fvalue;
        std::string *_svalue;
    };
};

#endif