package sdl_extend;

import sdl.SDL;
import sdl.Window;

@:unreflective @:keep @:include('SDL_messagebox.h')
@:structAccess @:native('SDL_MessageBoxData')
extern class SDL_MessageBoxData {
    var flags:cpp.UInt32;
    var window:Window;

    var title:cpp.ConstCharStar;
    var message:cpp.ConstCharStar;
    
    var numbuttons:Int;
    var buttons:cpp.ConstStar<SDL_MessageBoxButtonData>;
    var colorScheme:cpp.ConstStar<SDL_MessageBoxColorScheme>;
}

@:unreflective @:keep @:include('SDL_messagebox.h')
@:structAccess @:native('SDL_MessageBoxColor')
extern class SDL_MessageBoxColor {
    var r:cpp.UInt8;
    var g:cpp.UInt8;
    var b:cpp.UInt8;
}

@:unreflective @:keep @:include('SDL_messagebox.h')
@:structAccess @:native('SDL_MessageBoxColorScheme')
extern class SDL_MessageBoxColorScheme {
    var colors:cpp.RawPointer<SDL_MessageBoxColor>; // This is a c++ array. Yeah. Thats right
}

@:unreflective @:keep @:include('SDL_messagebox.h')
@:structAccess @:native('SDL_MessageBoxButtonData')
extern private class SDL_MessageBoxButtonData {
    var flags:cpp.UInt32;
    var buttonid:Int;
    var text:cpp.ConstCharStar;
}

typedef MsgBoxButton = {
    var rawData:SDL_MessageBoxButtonData;
    var callerFunc:Void->Void; 
};

class MessageBoxSys {
    static var msgBoxButtonCount:Int = 0;

    public static function makeMsgBoxButton(name:cpp.ConstCharStar, onPress:Void->Void):MsgBoxButton {
        var rawdata:SDL_MessageBoxButtonData = untyped __cpp__('{0, ::sdl_extend::MessageBoxSys_obj::msgBoxButtonCount++, name}');
        return {
            rawData: rawdata,
            callerFunc: onPress
        };
    }

    public static function showCustomMessageBox(title:cpp.ConstCharStar, message:cpp.ConstCharStar, window:Window, flags:SDLMessageBoxFlags, buttons:Array<MsgBoxButton>):Int {
        var boxData:SDL_MessageBoxData = untyped __cpp__('{0, NULL, "", "", 0, NULL, NULL}');
        boxData.title = title;
        boxData.message = message;
        boxData.window = window;
        boxData.flags = flags;

        var rawBtnArray:Array<SDL_MessageBoxButtonData> = [];
        for(button in buttons) { rawBtnArray.push(button.rawData); }

        // ! Problem most definetly lies within the const data pointer
        var btnArrayPtr:cpp.ConstStar<SDL_MessageBoxButtonData> = untyped __cpp__ ('const_cast<const SDL_MessageBoxButtonData*>({0})', cpp.Pointer.ofArray(rawBtnArray).ptr);
        trace(buttons[1].rawData.buttonid); // ? Gives 1
        trace(btnArrayPtr.buttonid); // ?! Gives Pseudorandom number "A"

        boxData.buttons = btnArrayPtr;
        boxData.numbuttons = buttons.length;
        boxData.colorScheme = untyped __cpp__('NULL');

        var btn:Int = 0;
        var btnpressed:cpp.RawPointer<Int> = untyped __cpp__('&btn');

        var boxResult:Int = 0;
        untyped __cpp__('
            const SDL_MessageBoxData* data = &{0};

            boxResult = SDL_ShowMessageBox(
                data,
                btnpressed
            );
        ', boxData, btnpressed);
        trace(btnpressed[0]); // ?! When second button with supposed id '1' is pressed, gives same Pseudorandom number "A" as on earlier trace

        buttons[btnpressed[0]].callerFunc();
        msgBoxButtonCount = 0;
        return boxResult;
    }
}