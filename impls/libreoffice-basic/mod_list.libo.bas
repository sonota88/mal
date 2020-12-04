rem -*- mode: basic -*-

Option Explicit

type MalList
    xs as variant
    size as integer
    type_ as string
    klass as string
    meta as variant
end type


function new_
    dim list as New MalList
    dim xs() as variant
    list.xs = xs
    list.size = 0
    list.type_ = type_name
    list.klass = type_name
    new_ = list
end function


Function type_name() As String
    type_name = "MalList"
End Function


function cap(self)
    dim rv

    if ubound(self.xs) = -1 then
        rv = 0
    else
        rv = ubound(self.xs) + 1
    end if

    cap = rv
End function


function from_array(array_)
    dim rv

    rv = MalList.new_()

    dim i
    for i = 0 to ubound(array_)
        MalList.add(rv, array_(i))
    next

    from_array = rv
end function


sub add(self, elem)
    ' ON_ERROR_TRY
    
    dim size_, newsize
    size_ = self.size

    if self.size >= cap(self) then
        if size_ = 0 then
            newsize = 1
        else
            newsize = size_ * 2
        end if

      dim newxs(newsize) as variant

      Dim i As Integer
      i = 0
      do while i < size_
          newxs(i) = self.xs(i)
          i = i + 1
      loop

      self.xs = newxs
    end if

    self.xs(self.size) = elem
    self.size = self.size + 1

    ' ON_ERROR_CATCH
end sub


rem TODO 範囲外の場合: null を返すべき？
function get_(self, i as integer)
    get_ = self.xs(i)
end function


sub set_(self, i as integer, el)
    self.xs(i) = el
end sub


function List_inspect(self)
    dim rv

    dim str
    str = "["

    Dim i As Integer
    for i = 0 to self.size - 1
      if 0 < i then
          str = str & ", "
      end if
      str = str & inspect(MalList.get_(self, i))
    next

    str = str & "]"

    rv = str
    List_inspect = rv
end function


function Seq_pr_str( _
    self As Object, _
    print_readably As Boolean, _
    paren_open As String, _
    paren_close As String _
) As String
    dim rv

    dim str
    str = paren_open

    Dim i As Integer
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
        s2 = Printer._pr_str(el, print_readably)
        str = str & s2
      end if
    next

    str = str & paren_close

    rv = str
    Seq_pr_str = rv
end function


function pr_str(self, print_readably as boolean)
    pr_str = Seq_pr_str(self, print_readably, "(", ")")
end function


function size(self)
    size = self.size
end function


' TODO rename => first
function head(self)
    head = get_(self, 0)
end function


function rest(self)
    Utils.log1 "-->> MalList.rest"
    dim rv

    dim newlist
    newlist = MalList.new_()

    if MalList.size(self) <= 1 then
        rest = newlist
        exit function
    end if

    dim i
    for i = 1 to MalList.size(self) - 1
        dim el
        el = MalList.get_(self, i)
        MalList.add(newlist, el)
    next
    rv = newlist

    rest = rv
end function


function last(self)
    dim rv
    
    dim n
    n = MalList.size(self)
    rv = MalList.get_(self, n - 1)

    last = rv
end function


function reverse(self)
    dim rv

    rv = MalList.new_()

    dim i, el
    i = MalList.size(self) - 1 
    do while 0 <= i
        el = MalList.get_(self, i)
        MalList.add(rv, el)
        i = i - 1
    loop

    reverse = rv
end function


rem TODO sublist とかにした方がよいかも
function newlist_for_do(self)
    dim rv
    rv = MalList.new_()

    dim i
    i = 1
    do while i <= MalList.size(self) - 2
        MalList.add(rv, MalList.get_(self, i))
        i = i + 1
    loop
    
    newlist_for_do = rv
end function


function clone(self)
    dim rv

    rv = MalList.new_()
    dim i
    for i = 0 to MalList.size(self) - 1
        MalList.add(rv, MalList.get_(self, i))
    next
    clone = rv
end function


function is_list(val)
    dim rv
    
    rv = (type_name_ex(val) = type_name)

    is_list = rv
end function


function typename(self)
    ' Utils.log3 "-->> typename()"
    dim rv

    rv = self.klass

    typename = rv
end function


function seq(self)
    ' Utils.log1 "-->> seq()"
    dim rv

    rv = self

    seq = rv
end function


function conj(self, xs)
    ' Utils.log1 "-->> MalList.conj()"
    dim rv

    dim temp
    temp = Core.clone(self)

    ' 先にサイズを確保しておく
    dim newsize as integer
    newsize = MalList.size(self) + MalList.size(xs)
    dim i as integer
    do while MalList.size(self) < newsize
        MalList.add(self, null)
    loop

    dim self_i, el
    self_i = 0
    
    i = MalList.size(xs) - 1
    do while 0 <= i
        el = MalList.get_(xs, i)
        MalList.set_(self, self_i, el)
        i = i - 1
        self_i = self_i + 1
    loop
    
    for i = 0 to MalList.size(temp) - 1
        el = MalList.get_(temp, i)
        MalList.set_(self, self_i, el)
        self_i = self_i + 1
    next
    
    rv = self

    conj = rv
end function
