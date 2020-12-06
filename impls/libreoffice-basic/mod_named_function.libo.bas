rem -*- mode: basic -*-

Option Explicit

type MalNamedFunction
    type_ as string
    id as string
    env ' TODO as object
    meta as variant
end type


Function type_name
    type_name = "MalNamedfunction"
End Function


Function new_(id, Optional env As Object)
    ' Utils.log2 "-->> MalNamedFunction.new_()"
    dim rv

    dim newfn as MalNamedFunction
    newfn.type_ = type_name
    newfn.id = id
    
    If IsMissing(env) Then
        newfn.env = null
    Else
        newfn.env = env
    End If

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

    rv = (type_name_ex(val) = type_name)

    is_named_function = rv
end function
