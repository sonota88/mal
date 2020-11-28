rem -*- mode: basic -*-

Option Explicit


Type MalAtom
  type_ as string
  val as variant
  meta as variant
End Type


Function create(val)
    dim rv as New MalAtom
    
    rv.type_ = "MalAtom"
    rv.val = val

    create = rv
End Function


Function MalAtom_inspect(self)
    dim rv

    rv = "(atom " & inspect(self.val) & ")"

    MalAtom_inspect = rv
End Function
