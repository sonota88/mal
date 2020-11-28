rem -*- mode: basic -*-

Option Explicit

type MalSymbol
    str
    type_ as String
end type


function new_(str as string)
    ' Utils.log3 "-->> MalSymbol.new_"
    dim sym as New MalSymbol
    sym.str = str
    sym.type_ = type_name
    new_ = sym
end function


Function type_name
    type_name = "MalSymbol"
End Function


function MalSymbol_inspect(sym) as string
    ' MalSymbol_inspect = "'" & sym.str
    MalSymbol_inspect = sym.str
end function


function MalSymbol_to_s(sym) as string
    ' Utils.log3 "-->> MalSymbol_to_s"
    ' MalSymbol_inspect = "'" & sym.str
    MalSymbol_to_s = sym.str
end function


function clone(self)
    dim rv
    rv = new_(self.str)
    clone = rv
end function


function is_symbol(val)
    is_symbol = (type_name_ex(val) = type_name)
end function


function eq_to_str(self, str)
    eq_to_str = (self.str = str)
end function
