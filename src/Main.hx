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
// Custom Message Boxes using untyped __cpp__ with SDL_ShowMessageBox (https://wiki.libsdl.org/SDL2/SDL_ShowMessageBox)
// -> example in rust at (https://github.com/Rust-SDL2/rust-sdl2/blob/master/examples/message-box.rs#L48) (should be easy to copy to cpp)
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
    static var state:{ window:Window, renderer:Renderer };

    static function main() {
        fps = 60;

        SDL.init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC);
        state = SDL.createWindowAndRenderer(320, 320, SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE);
        SDL.setWindowTitle(state.window, "SDL TEST");
        SDL.stopTextInput();

        // Uncomment for MessageBox tests
        /*
        var msgBoxContinue = MessageBoxSys.makeMsgBoxButton('Continue', () -> { trace('Continued!'); });
        var msgBoxQuit = MessageBoxSys.makeMsgBoxButton('Quit', () -> { exit(); });

        MessageBoxSys.showCustomMessageBox(
            'Testing Box',
            'Wuhoh, this is a test, would you like to continue or quit?',
            state.window,
            SDLMessageBoxFlags.SDL_MESSAGEBOX_INFORMATION,
            [msgBoxContinue, msgBoxQuit]
        );
        //*/
        startAppLoop();

        // Exiting our application from here on out, we can clean up everything!!
        SDL.destroyWindow(state.window);
        SDL.destroyRenderer(state.renderer);
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

            // flurry.tick(accumulator / frameDurMS);
        }
    }

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
                        SDL.showSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, 'INFO', 'TOGGLED TEXT INPUT: ${!inputActive}', state.window);
                        textInput = '';
                    default: 
                        final newFps = Std.parseInt(textInput);
                        if(newFps != null && newFps > 0) {
                            SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'INFO', 'FPS set from $fps to $newFps', state.window);
                            fps = newFps;
                        }
                        else SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'WARNING', 'Could not set FPS to input data: $textInput', state.window);
                        
                        textInput = '';
                }
                case SDL_KEYDOWN:
                switch(e.key.keysym.sym) {
                    case Keycodes.backspace: exit();
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
        // trace("RENDERED!");
        SDL.setRenderDrawColor(state.renderer, red, blue, 255, 255);
        SDL.renderClear(state.renderer);
        SDL.renderPresent(state.renderer);
    }

    static var red = 255;
    static var blue = 255;
    /**
     * Update Loop
     * @param dt Time elapsed since last frame in MS
     */
    static function update(dt:Float) {
        red = Math.floor(255* Math.random());
        blue = Math.floor(255* Math.random());

        // SDL.setHint(SDL_HINT_RENDER_VSYNC, 'true');
    }

    static function set_fps(st:Int):Int { 
        // final oldFps = fps;
        frameDurMS = 1 / st;
        usedFps = st;
        return fps = st; 
    }

}