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
    dim newfn As MalNamedFunction
    newfn.type_ = type_name
    newfn.id = id
    
    If IsMissing(env) Then
        newfn.env = null
    Else
        newfn.env = env
    End If

    new_ = newfn
end function


function inspect(self As MalNamedFunction) As String
    dim rv As String

    rv = "<MalNamedFunction"
    rv = rv & " " & self.id
    rv = rv & ">"

    inspect = rv
end function


function is_named_function(val) As Boolean
    is_named_function = (type_name_ex(val) = type_name)
end function
