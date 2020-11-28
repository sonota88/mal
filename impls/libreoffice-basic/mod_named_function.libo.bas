rem -*- mode: basic -*-

Option Explicit

type MalNamedFunction
    type_ as string
    id as string
    env ' TODO as object
    meta as variant
end type


function _MalNamedFunction_new_with_id(id)
    ' Utils.log2 "-->> MalNamedFunction_new_with_id()"
    dim rv

    dim newfn as MalNamedFunction
    newfn.type_ = MalNamedFunction_type_name
    newfn.id = id

    rv = newfn
    _MalNamedFunction_new_with_id = rv
end function


Function MalNamedFunction_type_name
    MalNamedFunction_type_name = "MalNamedfunction"
End Function


function init(id)
    ' Utils.log2 "-->> MalNamedFunction.init()"
    dim rv

    rv = _MalNamedFunction_new_with_id(id)

    init = rv
end function


function MalNamedFunction_inspect(self)
    dim rv

    rv = "<MalNamedFunction"
    rv = rv & " " & self.id
    rv = rv & ">"

    MalNamedFunction_inspect = rv
end function


function MalNamedFunction_to_map_key(fname)
    dim rv

    rv = "fun:" & fname.id

    MalNamedFunction_to_map_key = rv
end function


function is_named_function(val)
    ' Utils.log1 "-->> MalNamedFunction.is_named_function()"
    dim rv

    rv = (type_name_ex(val) = MalNamedFunction_type_name)

    is_named_function = rv
end function
