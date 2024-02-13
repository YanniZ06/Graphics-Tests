package graphics.oglh;

import opengl.GL;
/**
 * GL Helper class for bindings and the like
 */
@:keep
@:include('linc_opengl.h')
extern class GLH {
    inline static function getString(name:Int):cpp.ConstCharStar { 
        return untyped __cpp__("(const char*)glGetString({0})", name);
    }

    inline static function getStringi(name:Int, index:Int):cpp.ConstCharStar { 
        return untyped __cpp__("(const char*)glGetStringi({0},{1})", name,index);
    }

    /* inline static function glBufferData(target:Int, size:Int, data:BytesData, usage:Int) : Void { 
        untyped __cpp__("glBufferData({0}, {1}, (const void*)&({2}[0]), {3})", target, size, data, usage); 
    }*/
}