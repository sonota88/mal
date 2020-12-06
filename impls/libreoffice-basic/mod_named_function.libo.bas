rem -*- mode: basic -*-

Option Explicit

type MalNamedFunction
    type_ as string
    id as string
    env ' TODO as object
    meta as variant
end type


Function MalNamedFunction_type_name
    MalNamedFunction_type_name = "MalNamedfunction"
End Function


function new_(id)
    ' Utils.log2 "-->> MalNamedFunction.new_()"
    dim rv

    dim newfn as MalNamedFunction
    newfn.type_ = MalNamedFunction_type_name
    newfn.id = id

    rv = newfn

    new_ = rv
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
