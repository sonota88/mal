rem -*- mode: basic -*-

Option Explicit

function new_
    ' Utils.log3 "-->> MalVector.new_()"

    dim list ' TODO rename
    list = MalList.new_()

    dim xs() as variant
    list.xs = xs
    list.size = 0
    list.type_ = MalList.type_name
    list.klass = MalVector.type_name

    new_ = list
end function


Function type_name
    type_name = "MalVector"
End Function


function clone(self)
    ' Utils.log0 "-->> MalVector.clone()"
    dim rv

    rv = MalList.clone(self)
    rv.klass = MalVector.type_name

    clone = rv
end function


function MalVector_inspect(self)
    dim rv
    dim str, i

    str = "["

    for i = 0 to self.size - 1
      if 0 < i then
        str = str & ", "
      end if
      str = str & inspect(MalList.get_(self, i))
    next

    str = str & "]"

    rv = str
    MalVector_inspect = rv
end function


' TODO List_pr_str と共通化
function MalVector_pr_str(self, print_readably as boolean)
    ' Utils.log2 "-->> MalVector_pr_str"

    dim rv
    dim str, i, _r
    _r = print_readably

    str = "["

    for i = 0 to self.size - 1
      if 0 < i then
        str = str & " "
      end if

      dim el
      el = MalList.get_(self, i)

      if IsNull(el) then
        rem 本当は _pr_str に渡したいが渡せないためここで分岐している
        str = str & "nil"
      else
        dim s2 as string
        s2 = Printer._pr_str(el, _r)
        str = str & s2
      end if
    next

    str = str & "]"

    rv = str
    MalVector_pr_str = rv
end function


sub add(self, elem)
    MalList.add(self, elem)    
end sub


function seq(self)
    ' Utils.log1 "-->> seq()"
    dim rv

    rv = MalVector.new_()
    dim i, el
    for i = 0 to size(self) - 1
        el = MalList.get_(self, i)
        MalVector.add(rv, el)
    next

    seq = rv
end function


function conj(self, xs)
    ' Utils.log1 "-->> MalVector.conj()"
    dim rv

    dim i, el
    
    for i = 0 to MalList.size(xs) - 1
        el = MalList.get_(xs, i)
        MalVector.add(self, el)
    next
    
    rv = self

    conj = rv
end function


function is_vector(val) as Boolean
    is_vector = (type_name_ex(val) = MalVector.type_name)
end function
