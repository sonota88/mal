rem -*- mode: basic -*-

Option Explicit


Type MalAtom
  type_ as string
  val as variant
  meta as variant
End Type


Function create(val)
    dim rv as New MalAtom
    
    rv.type_ = type_name
    rv.val = val

    create = rv
End Function


Function type_name As String
    type_name = "MalAtom"
End Function


Function MalAtom_inspect(self)
    dim rv

    rv = "(atom " & inspect(self.val) & ")"

    MalAtom_inspect = rv
End Function


Function is_atom(val) As Boolean
    is_atom = (type_name_ex(val) = type_name)
End Function
