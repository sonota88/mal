rem -*- mode: basic -*-

Option Explicit

type MalNamedFunction
    type_ As String
    id As String
    env As Variant
    meta As Variant
end type


Function type_name As String
    type_name = "MalNamedfunction"
End Function


Function new_(id As String, Optional env As Object) As MalNamedfunction
    ' Utils.log2 "-->> MalNamedFunction.new_()"
    dim rv As MalNamedFunction

    dim newfn As MalNamedFunction
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


function inspect(self As MalNamedFunction) As String
    dim rv As String

    rv = "<MalNamedFunction"
    rv = rv & " " & self.id
    rv = rv & ">"

    inspect = rv
end function


function is_named_function(val) As Boolean
    ' Utils.log1 "-->> MalNamedFunction.is_named_function()"
    dim rv As Boolean

    rv = (type_name_ex(val) = type_name)

    is_named_function = rv
end function
