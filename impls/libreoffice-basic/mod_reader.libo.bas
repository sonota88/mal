rem -*- mode: basic -*-

Option Explicit

dim tokens
dim pos

rem --------------------------------

function get_ident_size(str)
  Utils.log3 "-->> get_ident_size()"
  dim rv
  dim i
  dim DQ
  DQ = chr(34)
  
  i = 0
  do while i < len(str)
    ' Utils.logkv3 "i", i
    dim c
    c = char_at(str, i)
    ' Utils.logkv3 "c", c
    ' if instr("abcdefghijklmnopqrstuvwxyzABC123-", c) = 0 then
    if str_include(" []{}('`,;)" & lf(), c) then
      exit do
    elseif c = DQ then	
    end if
    i = i + 1
  loop

  rv = i
  get_ident_size = rv
end function


function _consume_str(rest)
  Utils.log3 "-->> _consume_str()"
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
  Utils.log3 "-->> _consume_comment()"
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
  Utils.logkv3 "-->> _unescape_str()", str
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
              ' Utils.panic "expected '" & dq() & "', got EOF"
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

  Utils.logkv3 "  93 unescape result", s
  
  rv = s
  _unescape_str = rv
end function


function tokenize(str)
  Utils.log2 "-->> tokenize()"

  dim pos, rest_
  dim ts, size
  pos = 0

  ts = MalList.new_()

  do while pos < len(str)
    ' Utils.log3 "-->> tokenize() 34"
    rest_ = substring(str, pos)
    ' Utils.logkv3 "139 rest_", rest_
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
      ' Utils.log3 "  match => String"
      size = _consume_str(rest_)
      MalList.add(ts, left(rest_, size))
      pos = pos + size
  
    elseif left(rest_, 1) = ";" then
      ' Utils.log3 "  match => Comment"
      size = _consume_comment(rest_)
      ' MalList.add(ts, left(rest_, size))
      pos = pos + size
  
    else
      'Utils.log3 "-->> tokenize() 44"
      ' Utils.logkv3 "68 rest_", rest_
      size = get_ident_size(rest_)
      ' Utils.logkv3 "69 size", size
      if 0 < size then
        MalList.add(ts, left(rest_, size))
        pos = pos + size
      else
          Utils.panic "not_yet_impl"
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
    ' Utils.log3 "-->> next_() 40"
    rv = null
  else
    ' Utils.log3 "-->> next_() 43 pos=" & pos
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
    Utils.log1 "-->> read_map()"
    dim rv

    dim map, k, v
    map = MalMap.new_()
    
    next_()

    do while True
        ' Utils.logkv0 "237 peek", peek()
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

  Utils.log3 "-->> read_atom()"
  dim rv
  dim token

  ' dim i
  ' for i = 0 to tokens.size - 1
  '     Utils.log1 i
  '     Utils.log1 MalList.get_(tokens, i)
  ' next

  ' Utils.log3 "  t0=" & MalList.get_(tokens, 0)
  ' Utils.log3 "  pos=" & pos
  
  token = next_()
  Utils.logkv3 "-->> read_atom() 245 token", token
  ' Utils.logkv3 "  ---- token", token
  ' Utils.logkv3 "  pos", pos
  ' Utils.logkv3 "  token[0]", char_at(token, 0)
  ' Utils.logkv3 "  len token", len(token)
  ' Utils.logkv3 "  token[-1]", char_at(token, len(token) - 1)

  if token = "nil" then
      rv = null
  elseif is_int(token) then
      Utils.log3 "... int"
      rv = CInt(token)
      Utils.logkv3 "... int done", rv
  elseif token = dq() then
      ' Utils.panic "expected '" & dq() & "', got EOF"
      throw "expected '" & dq() & "', got EOF"
  elseif char_at(token, 0) = dq() then
      if char_at(token, len(token) - 1) = dq() then
          rv = _unescape_str(token)
      else
          ' Utils.panic "expected '" & dq() & "', got EOF"
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

  Utils.log3 "-->> read_atom() 59"
  
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
    Utils.logkv3 "183 read_list", t
    if t = last then
      exit do
    end if
    
    ' TODO switch MalVector
    MalList.add(ast, read_form())
  loop
  next_()

  rv = ast

  'Utils.logkv3 "<<-- read_list()", rv
  read_list = rv
end function


function read_form()
  Utils.log3 "-->> read_form()"
  dim rv
  dim form
  
  ' TODO peek() が何度も呼ばれるので変数にキャッシュするとよいかも
  if peek() = ";" then
    rv = nil

  elseif peek() = "'" then
    ' Utils.log0 "-->> read_form() 317 quasiquote"
    next_()

    form = read_form()
    ' CHECK_MAL_ERROR

    rv = MalList.from_array(Array(MalSymbol.new_("quote"), form))

  elseif peek() = "`" then
    ' Utils.log0 "-->> read_form() 317 quasiquote"
      next_()
      
      form = read_form()
      ' CHECK_MAL_ERROR
      
      rv = MalList.from_array(Array(MalSymbol.new_("quasiquote"), form))

  elseif peek() = "~" then
    ' Utils.log0 "-->> read_form() 322 unquote"
    next_()

    form = read_form()
    ' CHECK_MAL_ERROR

    rv = MalList.from_array(Array(MalSymbol.new_("unquote"), form))

  elseif peek() = "~@" then
    ' Utils.log0 "-->> read_form() 322 unquote"
    next_()

    form = read_form()
    ' CHECK_MAL_ERROR

    rv = MalList.from_array(Array(MalSymbol.new_("splice-unquote"), form))

  elseif peek() = "@" then
    next_()

    form = read_form()
    ' CHECK_MAL_ERROR

    rv = MalList.from_array(Array(MalSymbol.new_("deref"), form))

  elseif peek() = "(" then
    ' Utils.log3 "-->> read_form() 95"
    rv = read_list(MalList.type_name, "(", ")")

  elseif peek() = ")" then
    throw "unexpected ')'"

  elseif peek() = "[" then
    rv = read_list(MalVector.type_name, "[", "]")

  elseif peek() = "]" then
    throw "unexpected ']'"

  elseif peek() = "{" then
      rv = read_map()

  elseif peek() = "}" then
    throw "unexpected '}'"

  else
    ' Utils.log3 "-->> read_form() 99"
    rv = read_atom()
    ' Utils.log3 "-->> read_form() 104"
  end if
  
  ' CHECK_MAL_ERROR

  ' Utils.log3("-->> read_form() 107")
  Utils.logkv3("<<-- read_form()", rv)
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
