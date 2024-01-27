package;

import sdl.SDL;
import sdl_extend.Mouse.MouseButton;
import sdl.Window;
import sdl.Renderer;

class Main {
    public static var fps(default, set):Int; // Set in Main!!
    static var usedFps(get, default):Int;
    static function get_usedFps():Int {
        return Math.floor(fps / ((lastElapsed / 1000) * fps)); // Check out how to optimize
    }
    static var frameDurMS:Int = 33;

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

        while(update(elapsedTicks())) {
            SDL.delay(frameDurMS);
        }

    }

    static var red = 255;
    static var blue = 255;
    static var textInput = "";
    static function update(elapsedMs:Int) {
        red = Math.floor(255* Math.random());
        blue = Math.floor(255* Math.random());

        while(SDL.hasAnEvent()) {
            var e = SDL.pollEvent();
            switch(e.type) {
                case SDL_QUIT: return false;

                case SDL_MOUSEBUTTONDOWN: // Mouse Click
                switch(e.button.button) {
                    case SDL_BUTTON_LEFT: 
                        trace(elapsedMs);
                        trace(usedFps);

                    case SDL_BUTTON_RIGHT:
                        final inputActive = SDL.isTextInputActive();

                        if(!inputActive) SDL.startTextInput();
                        else SDL.stopTextInput();
                        SDL.showSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, 'INFO', 'TOGGLED TEXT INPUT ${!inputActive}', state.window);
                    default: 
                        final newFps = Std.parseInt(textInput);
                        if(newFps != null) {
                            SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'INFO', 'FPS set from $fps to $newFps', state.window);
                            fps = newFps;
                        }
                        else SDL.showSimpleMessageBox(SDL_MESSAGEBOX_WARNING, 'WARNING', 'FPS set from $fps to $newFps', state.window);
                }

                case SDL_TEXTINPUT:
                    textInput = e.text.text;
                default:
            }

            SDL.setRenderDrawColor(state.renderer, red, blue, 255, 255);
            SDL.renderClear(state.renderer);
            SDL.renderPresent(state.renderer);
        }

        return true;

    } 

    static function set_fps(st:Int):Int { 
        frameDurMS = Math.floor((1 / st) * 1000); 
        return fps = st; 
    }

}