package;

import sdl.SDL;
import sdl_extend.Mouse.MouseButton;
import sdl.Window;
import sdl.Renderer;

class Main {
    public static var fps(default, set):Int; // Set in Main!!
    static var usedFps:Int = 0;
    static var _curFPSCnt:Int = 0;
    /* static function get_usedFps():Int {
        return Math.floor(fps / ((lastElapsed / 1000) * fps)); // Check out how to optimize
    }*/
    static var frameDurMS:Int = 0;

    static var lastTickMS:UInt = 0;
    static var lastElapsed:Int = 0;
    static inline function elapsedTicks():Int {
        final l = lastTickMS; // Pass by Value
        lastTickMS = SDL.getTicks();
        lastElapsed = lastTickMS - l;

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
            final toWait = frameDurMS - update_msTaken;
            if(toWait > 0) SDL.delay(toWait);
        }

    }

    static var _fpsSecCnt:Int = 0;
    static var update_msTaken:Int = 0;
    static var red = 255;
    static var blue = 255;
    static var textInput = "";
    static function update(elapsedMs:Int) {
        while(SDL.hasAnEvent()) {
            var e = SDL.pollEvent();
            switch(e.type) {
                case SDL_QUIT: return false;

                case SDL_MOUSEBUTTONDOWN: // Mouse Click
                switch(e.button.button) {
                    case SDL_BUTTON_LEFT: 
                        trace("MS elapsed since last frame: " + elapsedMs);
                        trace("Currently set FPS: " + fps);
                        trace("Currently used FPS: " + usedFps);
                        trace("FPS frame delay MS: " + frameDurMS);
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

            red = Math.floor(255* Math.random());
            blue = Math.floor(255* Math.random());
            
            SDL.setRenderDrawColor(state.renderer, red, blue, 255, 255);
            SDL.renderClear(state.renderer);
            SDL.renderPresent(state.renderer);
        }

        _curFPSCnt++;
        _fpsSecCnt += elapsedMs;
        if(_fpsSecCnt >= 1000) {
            usedFps = _curFPSCnt;
            _curFPSCnt = _fpsSecCnt = 0; // Reset FPS 
        }
        update_msTaken = SDL.getTicks() - lastTickMS;
        return true;
    }

    static function set_fps(st:Int):Int { 
        frameDurMS = Math.floor((1 / st) * 1000) - 1;
        usedFps = st;
        return fps = st; 
    }

}