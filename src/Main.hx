package;

import sdl.SDL;
import sdl_extend.Mouse.MouseButton;
import sdl.Window;
import sdl.Renderer;
import haxe.Timer.stamp as getTicks;

class Main {
    public static var fps(default, set):Int = 30; // Set in Main!!
    static var usedFps:Int = 0;
    static var _curFPSCnt:Int = 0;
    /* static function get_usedFps():Int {
        return Math.floor(fps / ((lastElapsed / 1000) * fps)); // Check out how to optimize
    }*/
    static var frameDurMS:Float = 0;

    static var lastStamp:Float = 0;
    static var lastElapsed:Float = 0;
    static inline function elapsedTicks():Float {
        final l = lastStamp; // Pass by Value
        lastStamp = getTicks();
        lastElapsed = lastStamp - l;

        return lastElapsed;
    }

    static var state:{ window:Window, renderer:Renderer };

    static function main() {
        fps = 60;

        SDL.init(SDL_INIT_VIDEO | SDL_INIT_EVENTS);
        state = SDL.createWindowAndRenderer(320, 320, SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE);
        SDL.setWindowTitle(state.window, "SDL TEST");
        SDL.stopTextInput();

        while(update(elapsedTicks())) {
            final toWait = frameDurMS - update_timeTaken;
            if(toWait > 0) Sys.sleep(toWait); // todo: sleep is highly inaccurate, use an accumulator!! (https://gafferongames.com/post/fix_your_timestep/)
        }

    }

    static var _fpsSecCnt:Float = 0;
    static var update_timeTaken:Float = 0;
    static var red = 255;
    static var blue = 255;
    static var textInput = "";
    static function update(elapsed:Float) {
        red = Math.floor(255* Math.random());
        blue = Math.floor(255* Math.random());

        while(SDL.hasAnEvent()) {
            var e = SDL.pollEvent();
            switch(e.type) {
                case SDL_QUIT: return false;

                case SDL_MOUSEBUTTONDOWN: // Mouse Click
                switch(e.button.button) {
                    case SDL_BUTTON_LEFT: 
                        trace("Seconds elapsed since last frame: " + elapsed);
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

                case SDL_TEXTINPUT:
                    textInput += e.text.text;
                default:
            }

            SDL.setRenderDrawColor(state.renderer, red, blue, 255, 255);
            SDL.renderClear(state.renderer);
            SDL.renderPresent(state.renderer);
        }

        _curFPSCnt++;
        _fpsSecCnt += elapsed;
        if(_fpsSecCnt >= 1) {
            usedFps = _curFPSCnt;
            _fpsSecCnt = _curFPSCnt = 0; // Reset FPS 
        }
        update_timeTaken = getTicks() - lastStamp;
        // SDL.setHint(SDL_HINT_RENDER_VSYNC, 'true');
        return true;
    }

    static function set_fps(st:Int):Int { 
        // final oldFps = fps;
        frameDurMS = (1 / st); // * 0. + (0.001 * fps); // * (1 + (0.0003 * ((fps * fps) / 30))); // 0.0005
        usedFps = st;
        return fps = st; 
    }

}