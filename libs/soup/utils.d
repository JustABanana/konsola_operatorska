// Code taken from https://gitlab.com/Gert-dev/grestful/-/blob/master/Generic/Utility.d#L254
// This should be eventually integrated into the upstream gtk-d

/**
 * Simple structure that contains a pointer to a delegate. This is necessary because delegates are not directly
 * convertable to a simple pointer (which is needed to pass as data to a C callback).
 */
struct DelegatePointer(ReturnType, Parameters...)
{
    ReturnType delegate(Parameters) delegateInstance;

    /**
     * Constructor.
     *
     * @param delegateInstance The delegate to invoke.
     */
    public this(ReturnType delegate(Parameters) delegateInstance)
    {
        this.delegateInstance = delegateInstance;
    }
}

/**
 * Callback that will invoke the passed DelegatePointer's delegate when it is called. This very useful method can be
 * used to pass delegates in places where callbacks with C linkage are expected (such as GSourceFunc).
 *
 * The return type is the type that should be returned by this function. The invoked delegate should as a best practice
 * return the same value. If an exception happens and the value from the delegate can't be returned, the '.init' value
 * of the type will be used instead (or nothing in the case of void).
 *
 * @param parameters      Parameters that are passed to the callback function.
 * @param delegatePointer Should contain a pointer to the the DelegatePointer instance.
 *
 * @return Whatever the delegate returns.
 */
extern (C) nothrow static ReturnType invokeDelegatePointerFunc(DataType, ReturnType, Parameters...)(
        Parameters parameters, void* delegatePointer)
{
    try
    {
        // Explicit cast needed for void return types.
        return cast(ReturnType)(cast(DataType) delegatePointer).delegateInstance(parameters);
    }

    catch (Exception e)
    {
        // Just catch it, can't throw D exceptions accross C boundaries.
        static if (__traits(compiles, ReturnType.init))
            return ReturnType.init;
    }

    // Should only end up here for types that don't have an initial value (such as void).
}

/**
 * Takes a delegate and returns a tuple containing a reference to a function with C linkage that can be
 * passed as callback to various methods that require one from GTK. The second element of the tuple is
 * a void pointer that must be passed as the 'user data' along with the callback with C linkage.
 */
auto delegateToCallbackTuple(ReturnType, Parameters...)(ReturnType delegate(Parameters) theDelegate)
{
    import std.typecons : Tuple;

    auto delegatePointer = new DelegatePointer!(ReturnType, Parameters)(theDelegate);

    auto callback = &invokeDelegatePointerFunc!(typeof(delegatePointer), ReturnType, Parameters);
    auto dataForCallback = cast(void*) delegatePointer;

    return Tuple!(typeof(callback), "callback", typeof(dataForCallback), "data")(
            callback, dataForCallback);
}
