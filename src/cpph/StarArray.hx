package cpph;

import cpp.Star;
import cpp.Native;
import cpp.Native.sizeof;

/**
 * A C++ specific array that internally is handled like a pointer (star).
 * 
 * Provides a regular haxe-like array interface with access to the underlying pointer, and more C++ specific properties.
 */
// ?  @:transitive @:multiType
abstract StarArray<T>(IStarArray) from IStarArray<T> to IStarArray<T> {
    public var data(get, never):Star<T>;
    function get_data():Star<T> return this.data;

    public var length(get, never):Int;
    function get_length():Int return this.length;

    public var size(get, never):Int;
    function get_size():Int return Native.malloc(sizeof(T) * length);

    // function set_data

	/**
		Creates a new StarArray.
	**/
	public function new(expectedElements:Int = 1):Void {
        this = new IStarArray<T>();

        this.data = cast(Native.malloc(sizeof(T) * expectedElements), Star<T>);
        this.currentIndex = 0;
    };

    @:from
    /**
     * Creates a StarArray from a haxe Array.
     * Only guaruanteed to work with basic types, as important information might be lost on conversions for more complex types.
     */
    public static function fromArray<T>(array:Array<T>):StarArray<T> {
        var strarr = new IStarArray<T>();
        strarr.data = untyped __cpp__('({1}*){0}->Pointer()', array, T);
        strarr.currentIndex = 0;

        return strarr;
    }

    /*@:to
    public static function toArray<T>(strarr:StarArray<T>):Array<T> {
        untyped __cpp__('
            int (*c)[{0}] = (int(*)[{0}])new int[{0}];
        ', strarr.length);

        throw 'Die';
        return null;
    }*/



    @:arrayAccess public inline function get(index:Int):Null<T> {
        final changeReq:Int = index - currentIndex;

        untyped __cpp__('{0} = {0} + {1}', this.data, changeReq);
        this.currentIndex = index;
        return untyped __cpp__('*{0}', this.data);
    }

    @:arrayAccess public inline function set(index:Int, value:T):Void {
        final changeReq:Int = index - currentIndex;

        untyped __cpp__('{0} = {0} + {1}', this.data, changeReq);
        this.currentIndex = index;
        untyped __cpp__('*{0} = {1}', this.data, value);
    }
}

// Base implementation to build the abstract on
private class IStarArray<T> {
    public var data:Star<T>;
    public var length:Int;
    public var size:Int;

    public var currentIndex:Int;

    public function new() {};
}