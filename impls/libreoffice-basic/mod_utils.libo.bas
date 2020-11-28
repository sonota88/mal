rem -*- mode: basic -*-

Option Explicit

dim __LV

rem --------------------------------

function dq() as string
  dq = chr(34)
end function


function lf() as string
  lf = chr(10)
end function


function bs() as string
  bs = chr(92)
end function


function kw_marker() as string
  kw_marker = chr(&H029e)
end function

rem --------------------------------

function substring(str, index)
  if (index < 0) then
    substring = "invalid_index"
  else
    substring = right(str, len(str) - index)
  end if
end function


function char_at(str, index)
  dim retval

  if (index < 0 or len(str) <= index) then
    retval = "invalid_index"
  else
    retval = right(left(str, index + 1), 1)
  end if

  char_at = retval
end function


function str_include(str, target) as boolean
  dim rv

  rv = instr(str, target) <> 0 

  str_include = rv
end function


function is_numeric(c)
  is_numeric = str_include("0123456789", c)
end function

rem --------------------------------

function int_to_s(n as integer)
  int_to_s = "" & n
end function

rem --------------------------------

function inspect(val) as string
  ' Utils.log1 "-->> inspect()"
  dim rv

  if IsNull(val) then
    rv = "null"
  elseif IsEmpty(val) then
    rv = "<Empty>"
  Else

    Dim tn As String
    tn = TypeName(val)

    Select Case tn
    Case "Boolean", "Integer", "Long", "Single", "Double"
      rv = CStr(val)
    Case "String"
      rv = inspect_str(val)
    Case "Object"

      Dim otn As String
      otn = obj_typename(val)

      if otn = MalList.type_name then
        rv = List_inspect(val)
      elseif otn = MalVector.type_name then
        rv = MalVector_inspect(val)
      elseif otn = MalSymbol.type_name then
        rv = MalSymbol_inspect(val)
      elseif otn = MalMap.type_name then
        rv = MalMap_inspect(val)
      elseif otn = MalEnv.type_name then
        rv = MalEnv_inspect(val)
      elseif otn = MalNamedFunction_type_name then
        rv = MalNamedFunction_inspect(val)
      elseif otn = "MalFunction" then
        rv = MalFunction_inspect(val)
      elseif otn = "MalAtom" then
        rv = MalAtom_inspect(val)
      elseif otn = "Token" then
        rv = Token_inspect(val)
      else
        rv = "<unknown_obj>"
      end if

    Case Else
      rv = "<UNKNOWN> " & TypeName(val)
    End Select

  End If

  inspect = rv
end function


function inspect_str(str)
  dim rv
  dim s, i, c
  s = ""

  Dim LF_ As String
  Dim DQ_ As String
  Dim BS_ As String
  LF_ = lf()
  DQ_ = dq()
  BS_ = bs()

  for i = 0 to len(str) - 1
    c = char_at(str, i)

    Select Case c
      Case LF_
        s = s & BS_ & "n"
      Case dq()
        s = s & BS_ & DQ_
      Case bs()
        s = s & BS_ & BS_
      Case Else
        s = s & c
    End select
  next

  rv = DQ_ & s & DQ_
  inspect_str = rv
end function


function obj_typename(obj)
  ' Utils.log1 "-->> obj_typename()"
  on local error goto on_error_obj_typename
  
  dim rv
  
  rv = obj.type_
       
  if rv = MalList.type_name then ' TODO use is_list (?)
      ' MalVector の場合がある
      ' Utils.logkv3 "149 MalList.typename(obj)", MalList.typename(obj)
      rv = MalList.typename(obj)
  end if
  
  obj_typename = rv
  exit function

on_error_obj_typename:
  ' typename(err) => "Long"
  if err = 423 then
    rem type_ プロパティが存在しない場合
    obj_typename = null
  else
    msgbox format_err_msg("obj_typename", err, erl, error$)
    __ERROR__
  end if
end function


function type_name_ex(val)
  ' Utils.log1 "-->> type_name_ex()"
  dim rv
  
  if IsNull(val) then
      rv = TypeName(val)
      type_name_ex = rv
      exit function
  end if

  select case TypeName(val)
    case "Integer", "Long", "String", "Boolean", "Single", "Double"
        rv = TypeName(val)
    case else
      rv = obj_typename(val)
  end select

  type_name_ex = rv
end function

rem --------------------------------

sub __inc_lv
    __LV = __LV + 1
end sub

sub __dec_lv
    __LV = __LV - 1
end sub


sub debug(x)
  msgbox x    
end sub


sub debug_kv(k, v)
  msgbox "" & k & " (" & inspect(v) & ")"
end sub

' --------------------------------

function _log_indent()
  dim rv
  dim s, i, n
  rv = ""
  s = "|   "
  i = 0
  do while i < __LV
      rv = rv & s
      i = i + 1
  loop
  
  rem Space(4 * __LV)

  _log_indent = rv
end function


sub log0(msg)
    if not ENABLE_LOG then
        exit sub
    end if
    
    if environ("LOG_MODE") = "shape" then
        dim box
        box = Calc.get_shape_by_name("log")
        box.string = box.string & _log_indent() & msg & lf()
    else
        file_append(log_path, "___ " & _log_indent() & msg)
    end if
end sub


sub logkv0(k, v)
    if not ENABLE_LOG then
        exit sub
    end if

    log0 k & " (_" & inspect(v) & "_)"
end sub


sub log1(msg)
    if not ENABLE_LOG then
        exit sub
    end if

    file_append(log_path, "__  " & _log_indent() & msg)
end sub


sub logkv1(k, v)
    if not ENABLE_LOG then
        exit sub
    end if

    log1 k & " (_" & inspect(v) & "_)"
end sub


sub log2(msg)
    if not ENABLE_LOG then
        exit sub
    end if

    file_append(log_path, "_   " & _log_indent() & msg)
end sub


sub logkv2(k, v)
    if not ENABLE_LOG then
        exit sub
    end if

    log2 k & " (_" & inspect(v) & "_)"
end sub


sub log3(msg)
    if not ENABLE_LOG then
        exit sub
    end if

    file_append(log_path, "    " & _log_indent() & msg)
end sub


sub logkv3(k, v)
    if not ENABLE_LOG then
        exit sub
    end if

    log3 k & " (_" & inspect(v) & "_)"
end sub


sub panic(msg)
    Utils.log0   "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    Utils.logkv0 "PANIC", msg
    Utils.log0   "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

    ' TODO ↓ notify_wrapper に置き換え    
    ' dim path
    ' path = environ("FILE_ERR")
    ' file_append(path, "ERR " & msg)
    print_output_stderr msg
    print_status "EXIT 1"

    __ERR__
end sub


sub log_error_clear()
    Utils.log1 "-->> log_error_clear"
    
    dim path
    dim fileno
    fileno = freefile
    path = environ("FILE_ERR")
    open path for output as fileno

    print #fileno, "" ;

    close fileno
end sub

sub log_out_clear()
    Utils.log1 "-->> log_out_clear"
    
    dim path
    dim fileno
    fileno = freefile
    path = environ("FILE_OUT")
    open path for output as fileno

    print #fileno, "" ;

    close fileno
end sub

rem --------------------------------

function is_truthy(val) as boolean
    Utils.log1 "-->> is_truthy()"
    
    dim rv as boolean

    if IsNull(val) then
        rv = False
    elseif TypeName(val) = "Boolean" then
        rv = val
    else
        rv = True
    end if

    is_truthy = rv
end function

rem --------------------------------

rem 完了フラグも兼ねる
sub print_status(st)
  dim file_done as string
  file_done = environ("FILE_DONE")

  file_write(file_done, st)
end sub


function file_read(path)
  ' ON_ERROR_TRY
  dim icount as integer
  dim text2 as string
  iCount = Freefile
  open path for binary access Read as #iCount

  seek(#icount, 1)
  get(#icount, , text2)

  close #iCount

  file_read = text2

  ' ON_ERROR_CATCH
end function


sub file_write(path, str as string)
  ' ON_ERROR_TRY
  dim iCount3 as integer
  iCount3 = Freefile
  ' open path for OutPut as iCount3
  open path for binary access write as #iCount3

  put(#iCount3, 1, str)

  close #iCount3

  ' ON_ERROR_CATCH
end sub


' TODO rename: clean の方がよいかも
sub file_touch(path)
    file_write(path, "")
end sub


sub file_clear(path)
    if FileExists(path) then
        file_rm(path)
    end if
    file_write(path, "")
end sub


sub file_append(path, msg)
  ' ON_ERROR_TRY

  dim iCount3 as integer
  iCount3 = Freefile
  ' open path for OutPut as iCount3
  open path for append as #iCount3

  print #iCount3, msg

  close #iCount3

  ' ON_ERROR_CATCH
end sub


function file_read_v2(path as string)
  'Utils.log2 "-->> file_read_v2()"
  'Utils.log2 path
  dim rv

  dim sfa as object
  sfa = CreateUnoService("com.sun.star.ucb.SimpleFileAccess")

  dim is_ as object
  is_ = sfa.openFileRead(path)

  Dim tis As Object
  tis = CreateUnoService("com.sun.star.io.TextInputStream")
  tis.setInputStream(is_)
  tis.setEncoding("UTF-8")
  

  rv = tis.readString(Array(), false)
  'Utils.log1 "(_" & s & "_)"
  'Utils.log1 "(_" & len(s) & "_)"

  tis.closeInput()

  file_read_v2 = rv
  'Utils.log2 "<<-- file_read_v2()"
end function


sub file_rm(path)
    Kill(ConvertToUrl(path))
end sub


sub file_rm_if_exists(path)
    if FileExists(path) then
        Kill(ConvertToUrl(path))
    end if
end sub


' TODO rename => file_wait
sub wait_file(path)
    Utils.logkv0 "-->> wait_file", path

    dim interval_sec
    interval_sec = 0.1
    
    do while not FileExists(path)
        Utils.log3("wait_file: exist ... no => wait " & str(interval_sec))
        wait interval_sec * 1000
        interval_sec = interval_sec + 0.1
        if 5 <= interval_sec then
            interval_sec = 5
        end if
    loop

    Utils.log1 "wait_file: exist ... yes"
end sub


sub box_clear(box_name)
    dim box
    box = Calc.get_shape_by_name(box_name)
    box.string = ""
end sub


sub box_append(box_name, text)
    dim box
    box = Calc.get_shape_by_name(box_name)
    box.string = box.string & text

    Utils.logkv1 "603 text", text
end sub


sub print_output_stdout(msg)
    dim msg2 as string
    msg2 = ""
        
    if msg = "" then
        msg2 = "OUT "
    else
        dim lines
        lines = split(msg, lf())
        dim i
        for i = 0 to ubound(lines)
          msg2 = msg2 & "OUT " & lines(i) & lf()
        next
    end if
    
    if environ("RUN_MODE") = "gui" then
        box_append("output", msg2)
    else
        dim path
        path = environ("FILE_OUT")
        file_append(path, msg2)
    end if
end sub


sub print_output_stderr(msg)
    if environ("RUN_MODE") = "gui" then
        box_append("output", msg)
    else
        dim path
        path = environ("FILE_OUT")
        file_append(path, "ERR " & msg)
    end if
end sub


sub clear_output
    dim path
    path = environ("FILE_OUT")
    file_write(path, "")
end sub


function mal_error_exists() as boolean
    dim rv

    if TypeName(mal_error) = "Integer" then
        if mal_error = 0 then
            rv = False
        else
            rv = True
        end if
    else
        rv = True
    end if

    mal_error_exists = rv
end function


sub reset_mal_error()
    mal_error = 0
end sub


function notify_wrapper(stdout, stderr, command) as string
    Utils.log0 "-->> notify_wrapper: cmd from libo: " & command
    Utils.logkv0 "668 stdout", stdout
    Utils.logkv0 "669 stderr", stderr

    dim rv

    dim resp as string

    Utils.logkv0 "613", environ("FILE_OUT")
    file_clear(environ("FILE_OUT"))
    Utils.log0 "615"

    if not IsNull(stdout) then
        print_output_stdout(stdout)
    end if

    if not IsNull(stderr) then
        print_output_stderr(stderr)
    end if
    
    if environ("RUN_MODE") = "gui" then
        exit function
    end if
    
    ' Utils.logkv0 "file_out content", file_read_v2(environ("FILE_OUT"))

    dim file_done as string
    dim file_done_temp as string
    file_done = environ("FILE_DONE")
    file_done_temp = file_done & ".temp"

    file_write(file_done_temp, command)
    ' Utils.logkv0 "file_done content", file_read_v2(file_done_temp)
    ' file_rm file_done
    name file_done_temp as file_done

    wait_file environ("FILE_IN")
    resp = file_read_v2(environ("FILE_IN"))
    file_rm(environ("FILE_IN")) ' 読んだら消す
    
    rv = resp
    notify_wrapper = rv

    Utils.log0 "<<-- notify_wrapper: cmd from libo"
end function


function format_err_msg(text, err_, erl_, error_) as String
    ' Utils.log2 "-->> format_err_msg()"
    dim rv as String
    
    rv = text & " (line " & erl_ & ") " & err_ & " " & error_

    format_err_msg = rv
end function
