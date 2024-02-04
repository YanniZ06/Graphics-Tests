package;

import sys.thread.EventLoop;
import sdl.Event;
import sys.thread.Thread;
import haxe.Timer;
import sdl.SDL;
import sdl_extend.Mouse.MouseButton;
import sdl.Window;
import sdl.Renderer;
import UInt as Ticks;
// import haxe.Timer.stamp as getTicks;

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

class Main {
    public static var fps(default, set):Int = 30; // Set in Main!!
    static var usedFps:Int = 0;
    static var _curFPSCnt:Int = 0;
    /* static function get_usedFps():Int {
        return Math.floor(fps / ((lastElapsed / 1000) * fps)); // Check out how to optimize
    }*/
    static var frameDurMS:Ticks = 0;
    // static var updateTimerID:Int;
    static var updateTimer:Timer;

    static var lastStamp:Ticks = 0;
    static var lastElapsed:Ticks = 0;
    static inline function elapsedTicks():Ticks {
        final l = lastStamp; // Pass by Value
        lastStamp = SDL.getTicks();
        lastElapsed = lastStamp - l;

        return lastElapsed;
    }

    static var shouldClose:Bool = false;
    static var state:{ window:Window, renderer:Renderer };
    
    /*static function tmr_callback(interval:Int, data:{someint:Int}):Int { // TODO: figure out why this crashes, and why haxe.Timer isnt working?? one of them needs to!!
        trace('timer fired from $interval with data:'+data);
        globalUpdate();
        return 0;

    }*/

    static var updateLoopThread:Thread;
    static var mainThread:Thread;
    static function main() {
        fps = 60;

        SDL.init(SDL_INIT_VIDEO | SDL_INIT_EVENTS);
        state = SDL.createWindowAndRenderer(320, 320, SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE);
        SDL.setWindowTitle(state.window, "SDL TEST");
        SDL.stopTextInput();

        mainThread = Thread.current();
        updateLoopThread = Thread.createWithEventLoop(() -> {
            //Thread.runWithEventLoop(() -> {
            updateTimer = new Timer(frameDurMS);
            updateTimer.run = () -> {
                fireSDLUserEvent();
                // SDL.registerEvents(1);

                // globalUpdate();
            };
            //});
        });
        // Thread.runWithEventLoop();
        /* updateLoopThread = Thread.create(() -> {

        }); */ 
        startAppLoop();

        // updateTimerID = SDL.addTimer(frameDurMS, tmr_callback, {someint:frameDurMS});
        //final toWait = frameDurMS - update_timeTaken;

    }

    @:functionCode('
        SDL_Event event;
        event.type = SDL_USEREVENT;

        SDL_PushEvent (&event);
        return event;
    ')
    static function fireSDLUserEvent():Event {
        throw 'SDLUSEREVENT CREATION FAILED';
    }

    
    static var textInput = "";
    static var numRendersRequested:Int = 0;
    static function startAppLoop():Void {
        while(!shouldClose) { 
            // We constantly poll events. Our update timer runs on the defined FPS on its own!
            var continueEventSearch = SDL.hasAnEvent();
            var renderRequested:Bool = false; 

            while(continueEventSearch) {
                var e = SDL.pollEvent();
                switch(e.type) {
                    case SDL_USEREVENT: // Our UserEvent requests a Render, so we do that!We call update here so its all in the same Thread!!
                        renderRequested = true;
                        numRendersRequested++;

                        updateLoopThread.events.run(() -> {
                            updateTimer.stop();
                            updateTimer = new Timer(100000); // Block the updating Timer until we need to setup the next updateLoopThread. 
                        });

                    case SDL_QUIT: 
                        continueEventSearch = !(shouldClose = onQuit()) && SDL.hasAnEvent(); // If onQuit returns true we are actually quitting, otherwise we're not!! Useful for "Save / Cancel" operations
                        renderRequested = (!shouldClose && renderRequested);
                        trace("QUIT REQUEST! DID ACCEPT QUIT?? - " + shouldClose);

                    case SDL_MOUSEBUTTONDOWN: // Mouse Click
                    switch(e.button.button) { // Lets find out what Mouse Part clicked!!
                        case SDL_BUTTON_LEFT: 
                            trace("Seconds elapsed since last frame: " + lastElapsed);
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

                continueEventSearch = SDL.hasAnEvent();
            }

            if(renderRequested) {
                if(numRendersRequested > 1) logWarning('Requested a total of $numRendersRequested renders before actually rendering!');
                numRendersRequested = 0;

                globalUpdate();
                update_timeTaken = SDL.getTicks() - lastStamp;

                var nextFrameMS = frameDurMS - update_timeTaken;
                if(nextFrameMS <= 0) {
                    fireSDLUserEvent();
                    // SDL.registerEvents(1);

                    continue;
                }
        
                /*updateTimerID = SDL.addTimer(nextFrameMS, (timeSet, dynamicObj) -> {
                    globalUpdate();
                    return 0;
                }, 0);*/
        
                updateLoopThread.events.run(() -> {
                    updateTimer.stop();
        
                    updateTimer = new Timer(nextFrameMS);
                    updateTimer.run = () -> {
                        fireSDLUserEvent();
                        // SDL.registerEvents(1);
                    };
                });
            }
        }

        // Exiting our application from here on out, we can stop the update timer and clean up everything!!
        // SDL.removeTimer(updateTimerID);
        updateTimer.stop();
    }

    inline static function logWarning(warning:Dynamic) {
        trace('Warning: $warning (Registered at: ${Date.now()})');
    } 

    static var _fpsSecCnt:Ticks = 0;
    static var update_timeTaken:Int = 0;
    #if !debug inline #end static function globalUpdate():Void { // TODO: accumulator?
        // SDL.removeTimer(updateTimerID);

        update(elapsedTicks());
        render();

        _curFPSCnt++;
        _fpsSecCnt += lastElapsed;
        if(_fpsSecCnt >= 1000) {
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
    static var dtAccumulator = 0;
    /**
     * Update Loop
     * @param dt Time elapsed since last frame in MS
     */
    static function update(dt:Ticks) {
        dtAccumulator += dt;
        if(dtAccumulator < 50) return;

        red = Math.floor(255* Math.random());
        blue = Math.floor(255* Math.random());

        // SDL.setHint(SDL_HINT_RENDER_VSYNC, 'true');
    }

    static function set_fps(st:Int):Int { 
        // final oldFps = fps;
        frameDurMS = Math.floor((1 / st) * 1000);
        usedFps = st;
        return fps = st; 
    }

}