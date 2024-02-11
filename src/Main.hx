package;

import sdl.Keycodes;
import sys.thread.EventLoop;
import sdl.Event;
import sys.thread.Thread;
import haxe.Timer;
import sdl.SDL;
import sdl_extend.Mouse.MouseButton;
import sdl_extend.MessageBox;
import sdl.Window;
import sdl.Renderer;

typedef Pos = {
    var x:Float;
    var y:Float;
}
class Object {
    public var position:Pos;
    public var velocity:Float;

    public function new(pos:Pos, velocity:Float) {
        position = pos;
        this.velocity = velocity;
    }
}

// Interesting todo:
// GL Integration

class Main {
    public static var fps(default, set):Int = 30; // Set in Main!!
    static var usedFps:Int = 0;
    static var _curFPSCnt:Int = 0;
    
    /**
     * Number of seconds between each frame.
     */
    static var frameDurMS:Float = 0;
    static var currentTime:Float;
    static var accumulator:Float;

    static var shouldClose:Bool = false;
    static var window:Window;

    static function main() {
        fps = 60;

        if(SDL.init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC) != 0) {
            throw 'Error initializing SDL subsystems: ${SDL.getError()}';
        }
        //var info = getDesktopDisplayMode()

        // /*
        trace('Displays:');
        var num_displays = SDL.getNumVideoDisplays();
        for(display_index in 0 ... num_displays) {
            var num_modes = SDL.getNumDisplayModes(display_index);
            var name = SDL.getDisplayName(display_index);
            trace('\tDisplay $display_index: $name');
            var desktop_mode = SDL.getDesktopDisplayMode(display_index);
            trace('\t Desktop Mode: ${desktop_mode.w}x${desktop_mode.h} @ ${desktop_mode.refresh_rate}Hz format:${pixel_format_to_string(desktop_mode.format)}');
            var current_mode = SDL.getCurrentDisplayMode(display_index);
            trace('\t Current Mode: ${current_mode.w}x${current_mode.h} @ ${current_mode.refresh_rate}Hz format:${pixel_format_to_string(current_mode.format)}');
            for(display_mode in 0 ... num_modes) {
                var mode = SDL.getDisplayMode(display_index, display_mode);
                trace('\t\t mode:$display_mode ${mode.w}x${mode.h} @ ${mode.refresh_rate}Hz format:${pixel_format_to_string(mode.format)}');
            }
        }
        
        var compiled = SDL.VERSION();
        var linked = SDL.getVersion();
        trace("Versions:");
        trace('    - We compiled against SDL version ${compiled.major}.${compiled.minor}.${compiled.patch} ...');
        trace('    - And linked against SDL version ${linked.major}.${linked.minor}.${linked.patch}');
        // */

        var displayMode = SDL.getCurrentDisplayMode(0);
        window = SDL.createWindow("SDL TEST", 
         cast displayMode.w / 4, cast displayMode.h / 4, // Center of Window should always be half of actual Window dimensions ?? am i tweaking
         cast displayMode.w / 2, cast displayMode.h / 2,
         SDL_WINDOW_OPENGL | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE);

        trace(sdl_extend.Video.getWindowDisplayIndex(window));

        SDL.stopTextInput();

        startAppLoop();

        // Exiting our application from here on out, we can clean up everything!!
        SDL.destroyWindow(window);
        // SDL.destroyRenderer(state.renderer);
        SDL.quit();
    }

    /**
     * Fires an SDL Event of the given type.
     * @param type Type of SDL Event.
     */
    @:functionCode('
        SDL_Event event;
        event.type = eType;

        SDL_PushEvent (&event);
    ')
    static function fireSDLEvent(eType:SDLEventType):Void {
    }

    
    static var textInput = "";
    static function startAppLoop():Void {
        while(!shouldClose) { 
            final newTime = Timer.stamp();
            final frameTime = newTime - currentTime;

            currentTime = newTime;
            accumulator = if (frameTime > 0.25) accumulator + 0.25 else accumulator + frameTime;

            while (accumulator >= frameDurMS) {
                handleSDLEvents();

                globalUpdate(frameDurMS);

                accumulator -= frameDurMS;
            }
            
            SDL.delay(1);
            // flurry.tick(accumulator / frameDurMS);
        }
    }

    static final msgBoxContinue = MessageBoxSys.makeMsgBoxButton('Continue', () -> {});
    static final msgBoxQuit = MessageBoxSys.makeMsgBoxButton('Quit', () -> { exit(); });
    inline static function handleSDLEvents():Void {
        var continueEventSearch = SDL.hasAnEvent();
        while(continueEventSearch) {
            var e = SDL.pollEvent();
            
            switch(e.type) {
                case SDL_QUIT: 
                    // If onQuit returns true we are actually quitting, otherwise we're not!! Useful for "Save / Cancel" operations
                    continueEventSearch = !(shouldClose = onQuit()) && SDL.hasAnEvent();

                case SDL_MOUSEBUTTONDOWN: // Mouse Click
                switch(e.button.button) { // Lets find out what Mouse Part clicked!!
                    case SDL_BUTTON_LEFT: 
                        trace("Currently set FPS: " + fps);
                        trace("Currently used FPS: " + usedFps);
                        trace("FPS frame delay Seconds: " + frameDurMS);
                        trace("---------------------------------\n");

                    case SDL_BUTTON_RIGHT:
                        final inputActive = SDL.isTextInputActive();

                        if(!inputActive) SDL.startTextInput();
                        else SDL.stopTextInput();
                        SDL.showSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, 'INFO', 'TOGGLED TEXT INPUT: ${!inputActive}', window);
                        textInput = '';
                    default: 
                        final newFps = Std.parseInt(textInput);
                        if(newFps != null && newFps > 0) {
                            SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'INFO', 'FPS set from $fps to $newFps', window);
                            fps = newFps;
                        }
                        else SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'WARNING', 'Could not set FPS to input data: $textInput', window);
                        
                        textInput = '';
                }
                case SDL_KEYDOWN:
                switch(e.key.keysym.sym) {
                    case Keycodes.backspace:         
                        MessageBoxSys.showCustomMessageBox(
                            'Quit requested',
                            'Would you like to continue or quit?',
                            window,
                            SDLMessageBoxFlags.SDL_MESSAGEBOX_WARNING,
                            [msgBoxContinue, msgBoxQuit]
                        );
                    default:
                }

                case SDL_TEXTINPUT:
                    textInput += e.text.text;
                default:
            }

            continueEventSearch = SDL.hasAnEvent();
        }
    }

    inline static function exit() fireSDLEvent(SDL_QUIT);

    inline static function logWarning(warning:Dynamic) {
        trace('Warning: $warning (Registered at: ${Date.now()})');
    } 

    static var _fpsSecCnt:Float = 0;
    #if !debug inline #end static function globalUpdate(dt:Float):Void { 
        update(dt);
        render();

        _curFPSCnt++;
        _fpsSecCnt += dt;
        if(_fpsSecCnt >= 1) {
            usedFps = _curFPSCnt;
            _fpsSecCnt = _curFPSCnt = 0; // Reset FPS 
        }
    }

    dynamic static function onQuit():Bool return true;

    static function render():Void {
        // SDL.setRenderDrawColor(state.renderer, red, blue, 255, 255);
        // SDL.renderClear(state.renderer);
        // SDL.renderPresent(state.renderer);
    }

    static var red = 255;
    static var blue = 255;
    /**
     * Update Loop
     * @param dt Time elapsed since last frame in MS
     */
    static function update(dt:Float) {
        // red = Math.floor(255* Math.random());
        // blue = Math.floor(255* Math.random());

        // SDL.setHint(SDL_HINT_RENDER_VSYNC, 'true');
    }

    static function set_fps(st:Int):Int { 
        // final oldFps = fps;
        frameDurMS = 1 / st;
        usedFps = st;
        return fps = st; 
    }


    static function pixel_format_to_string(format:SDLPixelFormat) {
        return switch(format) {
            case SDL_PIXELFORMAT_UNKNOWN     :'UNKNOWN';
            case SDL_PIXELFORMAT_INDEX1LSB   :'INDEX1LSB';
            case SDL_PIXELFORMAT_INDEX1MSB   :'INDEX1MSB';
            case SDL_PIXELFORMAT_INDEX4LSB   :'INDEX4LSB';
            case SDL_PIXELFORMAT_INDEX4MSB   :'INDEX4MSB';
            case SDL_PIXELFORMAT_INDEX8      :'INDEX8';
            case SDL_PIXELFORMAT_RGB332      :'RGB332';
            case SDL_PIXELFORMAT_RGB444      :'RGB444';
            case SDL_PIXELFORMAT_RGB555      :'RGB555';
            case SDL_PIXELFORMAT_BGR555      :'BGR555';
            case SDL_PIXELFORMAT_ARGB4444    :'ARGB4444';
            case SDL_PIXELFORMAT_RGBA4444    :'RGBA4444';
            case SDL_PIXELFORMAT_ABGR4444    :'ABGR4444';
            case SDL_PIXELFORMAT_BGRA4444    :'BGRA4444';
            case SDL_PIXELFORMAT_ARGB1555    :'ARGB1555';
            case SDL_PIXELFORMAT_RGBA5551    :'RGBA5551';
            case SDL_PIXELFORMAT_ABGR1555    :'ABGR1555';
            case SDL_PIXELFORMAT_BGRA5551    :'BGRA5551';
            case SDL_PIXELFORMAT_RGB565      :'RGB565';
            case SDL_PIXELFORMAT_BGR565      :'BGR565';
            case SDL_PIXELFORMAT_RGB24       :'RGB24';
            case SDL_PIXELFORMAT_BGR24       :'BGR24';
            case SDL_PIXELFORMAT_RGB888      :'RGB888';
            case SDL_PIXELFORMAT_RGBX8888    :'RGBX8888';
            case SDL_PIXELFORMAT_BGR888      :'BGR888';
            case SDL_PIXELFORMAT_BGRX8888    :'BGRX8888';
            case SDL_PIXELFORMAT_ARGB8888    :'ARGB8888';
            case SDL_PIXELFORMAT_RGBA8888    :'RGBA8888';
            case SDL_PIXELFORMAT_ABGR8888    :'ABGR8888';
            case SDL_PIXELFORMAT_BGRA8888    :'BGRA8888';
            case SDL_PIXELFORMAT_ARGB2101010 :'ARGB2101010';
            case SDL_PIXELFORMAT_YV12        :'YV12';
            case SDL_PIXELFORMAT_IYUV        :'IYUV';
            case SDL_PIXELFORMAT_YUY2        :'YUY2';
            case SDL_PIXELFORMAT_UYVY        :'UYVY';
            case SDL_PIXELFORMAT_YVYU        :'YVYU';
            case SDL_PIXELFORMAT_NV12        :'NV12';
            case SDL_PIXELFORMAT_NV21        :'NV21';
        }
    }

}