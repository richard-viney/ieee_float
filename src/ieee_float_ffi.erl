-module(ieee_float_ffi).
-export([rescue_bad_arith/1]).

rescue_bad_arith(Do) ->
    try {ok, Do()}
    catch
        error:badarith -> {error, nil};

        _Class:_Reason -> erlang:error(
            "Unexpected error in ieee_float operation"
        )
    end.
