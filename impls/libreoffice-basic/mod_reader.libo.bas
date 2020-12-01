rem -*- mode: basic -*-

Option Explicit

dim tokens
dim pos

rem --------------------------------

function get_ident_size(str)
    ' Utils.log3 "-->> get_ident_size()"
    dim rv
    Dim i As Integer

    Dim DQ_ As String
    DQ_ = dq()

    Dim non_ident_chars As String
    non_ident_chars = " []{}('`,;)" & lf()

    Dim c As String
    i = 0
    do while i < len(str)
      c = char_at(str, i)
      if str_include(non_ident_chars, c) then
        exit do
      elseif c = DQ_ then
      end if
      i = i + 1
    loop

    rv = i
    get_ident_size = rv
end function


function _consume_str(rest)
    ' Utils.log3 "-->> _consume_str()"
    dim rv

    if char_at(rest, 0) <> dq() then
      rv = 0
      _consume_str = rv
      exit function
    end if

    dim pos, c, s

    pos = 1
    do while pos < len(rest)
        c = char_at(rest, pos)
        if c = dq() then
            pos = pos + 1
            exit do
        elseif c = bs() then
            pos = pos + 2
        else
            pos = pos + 1
        end if
    loop

    _consume_str = pos
end function


function _consume_comment(rest)
    ' Utils.log3 "-->> _consume_comment()"
    dim rv

    dim pos, c, s

    pos = 1
    do while pos < len(rest)
        c = char_at(rest, pos)
        if c = lf() then
            pos = pos + 1
            exit do
        else
            pos = pos + 1
        end if
    loop

    _consume_comment = pos
end function


function _unescape_str(str)
    ' Utils.logkv3 "-->> _unescape_str()", str
    dim rv
    dim pos, c, s

    s = ""
    pos = 1
    do while pos < len(str)
        c = char_at(str, pos)
        if c = dq() then
            exit do
        elseif c = bs() then
            if pos = len(str) - 2 then rem TODO
                throw "expected '" & dq() & "', got EOF"
                ' CHECK_MAL_ERROR
            end if

            dim next_char
            next_char = char_at(str, pos + 1)
            if next_char = bs() then
                s = s & bs()
            elseif next_char = "n" then
                s = s & lf()
            elseif next_char = dq() then
                s = s & dq()
            else
                s = s & next_char
            end if
            pos = pos + 2
        else
            s = s & c
            pos = pos + 1
        end if
    loop

    rv = s
    _unescape_str = rv
end function


function tokenize(str)
    ' Utils.log2 "-->> tokenize()"

    dim pos, rest_
    dim ts, size
    pos = 0

    ts = MalList.new_()

    do while pos < len(str)
      rest_ = substring(str, pos)
      if left(rest_, 2) = "~@" then
        size = 2
        MalList.add(ts, left(rest_, size))
        pos = pos + size
      elseif str_include(" ," & lf(), left(rest_, 1)) then
        pos = pos + 1
      elseif str_include("[]{}()'`~^@", left(rest_, 1)) then
        size = 1
        MalList.add(ts, left(rest_, size))
        pos = pos + size

      elseif 0 < _consume_str(rest_) then
        size = _consume_str(rest_)
        MalList.add(ts, left(rest_, size))
        pos = pos + size

      elseif left(rest_, 1) = ";" then
        size = _consume_comment(rest_)
        pos = pos + size

      else
        size = get_ident_size(rest_)
        if 0 < size then
          MalList.add(ts, left(rest_, size))
          pos = pos + size
        else
            panic "not yet implemented"
        end if
      end if
    loop

    tokenize = ts
end function

rem --------------------------------

function peek()
    ' Utils.log3 "-->> peek"
    dim rv

    rv = MalList.get_(tokens, pos)

    peek = rv
end function


function next_()
    ' Utils.log3 "-->> next_()"
    dim rv

    pos = pos + 1

    if tokens.size < pos then
      rv = null
    else
      rv = MalList.get_(tokens, pos - 1)
    end if

    next_ = rv
end function

rem --------------------------------

function is_int(str)
    dim rv
    dim i, c

    if str = "-" then
        rv = false
        exit function
    end if

    rv = true
    for i = 0 to len(str) - 1
      c = char_at(str, i)
      if not ( Utils.is_numeric(c) or c = "-" ) then
          rv = false
      end if
    next

    is_int = rv
end function


function read_map
    ' ON_ERROR_TRY
    ' Utils.log1 "-->> read_map()"
    dim rv

    dim map, k, v
    map = MalMap.new_()
    
    next_()

    do while True
        if peek() = "}" then
            next_()
            exit do
        end if
        k = read_atom()
        ' CHECK_MAL_ERROR
        v = read_form()
        ' CHECK_MAL_ERROR
        MalMap.put(map, k, v)
    loop
    
    rv = map
    read_map = rv
    
    ' ON_ERROR_CATCH
end function


function read_atom()
    ' ON_ERROR_TRY

    ' Utils.log3 "-->> read_atom()"
    dim rv
    dim token

    token = next_()

    if token = "nil" then
        rv = null
    elseif is_int(token) then
        rv = CInt(token)
    elseif token = dq() then
        throw "expected '" & dq() & "', got EOF"
    elseif char_at(token, 0) = dq() then
        if char_at(token, len(token) - 1) = dq() then
            rv = _unescape_str(token)
        else
            throw "expected '" & dq() & "', got EOF"
        end if
    elseif char_at(token, 0) = ":" then
        rv = kw_marker() & substring(token, 1)
    elseif token = "true" then
        rv = True
    elseif token = "false" then
        rv = False
    else
        rv = MalSymbol.new_(token)
    end if
    ' CHECK_MAL_ERROR

    read_atom = rv

    ' ON_ERROR_CATCH
end function


function read_list(klass, start, last)
    ' Utils.log3("-->> read_list()")
    dim rv
    dim ast, t

    select case klass
    case MalList.type_name
        ast = MalList.new_()
    case MalVector.type_name
        ast = MalVector.new_()
    case else
        throw "unexpected klass (" & klass & ")"
    end select

    t = next_()
    if t <> start then
      __ERR_unexpected_start__
    end if

    do while true
        if tokens.size <= pos then
            throw "expected '" & last & "', got EOF"
            ' CHECK_MAL_ERROR
        end if

      t = peek()
      if t = last then
        exit do
      end if

      ' TODO switch MalVector
      MalList.add(ast, read_form())
    loop
    next_()

    rv = ast

    read_list = rv
end function


function read_form()
    Utils.log3 "-->> read_form()"
    dim rv
    dim form

    Dim c As String
    c = peek()

    if c = ";" then
      rv = nil

    elseif c = "'" then
      next_()

      form = read_form()
      ' CHECK_MAL_ERROR

      rv = MalList.from_array(Array(MalSymbol.new_("quote"), form))

    elseif c = "`" then
        next_()

        form = read_form()
        ' CHECK_MAL_ERROR

        rv = MalList.from_array(Array(MalSymbol.new_("quasiquote"), form))

    elseif c = "~" then
      next_()

      form = read_form()
      ' CHECK_MAL_ERROR

      rv = MalList.from_array(Array(MalSymbol.new_("unquote"), form))

    elseif c = "~@" then
      next_()

      form = read_form()
      ' CHECK_MAL_ERROR

      rv = MalList.from_array(Array(MalSymbol.new_("splice-unquote"), form))

    elseif c = "@" then
      next_()

      form = read_form()
      ' CHECK_MAL_ERROR

      rv = MalList.from_array(Array(MalSymbol.new_("deref"), form))

    elseif c = "(" then
      rv = read_list(MalList.type_name, "(", ")")

    elseif c = ")" then
      throw "unexpected ')'"

    elseif c = "[" then
      rv = read_list(MalVector.type_name, "[", "]")

    elseif c = "]" then
      throw "unexpected ']'"

    elseif c = "{" then
        rv = read_map()

    elseif c = "}" then
      throw "unexpected '}'"

    else
      rv = read_atom()
    end if

    ' CHECK_MAL_ERROR

    read_form = rv
end function


function read_str(str)
    Utils.logkv2 "-->> read_str()", str
    dim rv

    tokens = tokenize(str)
    Utils.log3 "--------------------------------"
    Utils.logkv3 "tokens.size", tokens.size
    Utils.logkv3 "tokens", tokens
    Utils.log3 "--------------------------------"
    pos = 0

    if tokens.size = 0 then
      rv = null
    else
      rv = read_form()
    end if

    Utils.log3 "--------------------------------"
    Utils.logkv3 "read result", rv
    Utils.log3 "--------------------------------"

    ' CHECK_MAL_ERROR

    read_str = rv
end function
