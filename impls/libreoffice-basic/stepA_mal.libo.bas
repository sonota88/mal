rem -*- mode: basic -*-

Option Explicit

dim ENABLE_LOG
dim log_path as string

dim mal_error

dim input_buf as string
dim input_cont_p as boolean


sub setup(argv, repl_env)
    if environ("ENABLE_LOG") = "1" then
        ENABLE_LOG = true
    elseif environ("ENABLE_LOG") = "0" then
        ENABLE_LOG = False
    else
        ENABLE_LOG = false
    end if
    
    reset_mal_error()
    input_buf = ""
    input_cont_p = False

    MalEnv_setup()
    
    Utils.log2 ""
    Utils.log1  "================================"
    Utils.log1  "start"

    ' step 6
    MalEnv.set_(repl_env, MalSymbol.new_("*ARGV*"), MalList.rest(argv))
    Utils.logkv2 "38 argv", argv
    
    Utils.log2 "-->> prepare eval"
    dim fname_eval
    fname_eval = MalNamedFunction.init("eval")
    fname_eval.env = repl_env
    MalEnv.set_(repl_env, MalSymbol.new_("eval"), fname_eval)
    Utils.log2 "<<-- prepare eval"

    read_eval(repl_env, "(def! *host-language* " & dq() & "libo_bas" & dq() & ")")
    read_eval(repl_env, "(def! not (fn* (a) (if a false true)))")
    
    read_eval(repl_env, _
        "(def! load-file                     " _
      & "  (fn* (f) (eval (read-string (str  " _
      &      dq() & "(do " & dq()              _
      & "     (slurp f)                      " _
      &      dq() & lf() & " nil)" & dq()      _
      & "  ))))                              " _
      & ")                                   " _
    )

    read_eval(repl_env, _
        "(defmacro! cond                                                       " _
      & "  (fn* (& xs)                                                         " _
      & "    (if (> (count xs) 0)                                              " _
      & "      (list                                                           " _
      & "        'if (first xs)                                                " _
      & "        (if (> (count xs) 1)                                          " _
      & "          (nth xs 1)                                                  " _
      & "          (throw " & dq() & "odd number of forms to cond" & dq() & "))" _
      & "        (cons 'cond (rest (rest xs)))))))                             " _
    )
    
    Utils.log0 ""
    Utils.log0 "================================"
    Utils.log0 "<<-- setup done"
    Utils.log0 "================================"
    Utils.log0 ""

    if environ("IS_TEST") = "1" then
        ext_command null, null, "SETUP_DONE"
    else
        ext_command null, "setup done", "SETUP_DONE"
    end if
end sub


Sub Main
    On Local Error GoTo on_error__Main
    
    log_path = environ("FILE_LOG_SETUP")
    Utils.log0 "logging start"
    
    dim repl_env
    repl_env = create_repl_env()

    dim argv
    argv = get_argv()

    setup(argv, repl_env)
    
    log_path = environ("FILE_LOG")
    
    if 0 < MalList.size(argv) then
        Utils.log0 "mode: argv"
        _main_file(repl_env, argv)
        
        if environ("IS_TEST") = "1" then
            ext_command(null, null, "EXIT 0")
        else
            ext_command(null, "bye", "EXIT 0")
        end if
    else
        Utils.log0 "mode: normal"
        _main_repl(repl_env)
        Utils.log2 "<<-- _main_repl()"
    end if
    
    if environ("AUTO_CLOSE") = "1" then
        Utils.log1 "-->> auto close"
        ThisComponent.close(true)
        Utils.log1 "<<-- auto close"
        'wait 1000
        'stardesktop.terminate
    end if

    exit sub

on_error__Main:
  dim msg
  msg = format_err_msg("Main", err, erl, error$)
  
  ext_command(null, msg, "EXIT 1")
  
  if environ("AUTO_CLOSE") = "1" then
      ThisComponent.close(true)
      'wait 1000
      'stardesktop.terminate
    exit sub
  end if
end sub


' print しない
sub _main_file(repl_env, argv)
    read_eval(repl_env, "(load-file " & dq() & MalList.get_(argv, 0) & dq() & ")")

    ' 一番外側の try/catch に相当
    Utils.log0 "-->> check error (argv mode top)"
    if mal_error_exists() then
        print_stderr("Error: " & Printer._pr_str(mal_error, true))
    end if
    Utils.log0 "<<-- check error (argv mode top)"
end sub


sub _main_repl(repl_env)
    do while true
        __LV = 0

        Utils.log0 ""
        Utils.log0 ""
        Utils.log0 "================================"
        Utils.log0 "-->> REPL loop"

        dim text

        text = Core.readline("user> ")

        Utils.logkv2 "text", text

        dim result
        if text = "exit" then
            ext_command(null, "bye", "EXIT 0")
            Utils.log0 "181 exit do"
            exit do
        else
            reset_mal_error()
            
            __inc_lv
            REP(repl_env, text)
            __dec_lv

            ' 一番外側の try/catch に相当
            Utils.log0 "-->> check error (top)"
            if mal_error_exists() then
                dim msg
                msg = "Error: " & Printer._pr_str(mal_error, true)
                Utils.log0 msg
                ' print_stderr(msg)
                ext_command(null, msg, "PRINT")
            end if
            Utils.log0 "<<-- check error (top)"
        end if
        
        Utils.log1 "<<-- REPL loop"
    loop

    Utils.log0 "205 end of _main_repl()"
end sub


function get_argv
    Utils.log2 "-->> get_argv()"

    dim rv
    
    dim path
    path = environ("FILE_ARGS")

    dim argv
    argv = MalList.new_()

    if not FileExists(path) then
        rv = argv
        get_argv = rv
        exit function
    end if

    dim lines
    lines = split(file_read(path), lf())

    dim argc
    argc = CInt(lines(0))
    Utils.logkv2 "argc", argc
    
    dim i
    i = 1
    do while i <= argc
        MalList.add(argv, lines(i))
        i = i + 1
    loop

    Utils.logkv2 "argv", argv
    
    rv = argv
    get_argv = rv    
end function


function create_repl_env()
    dim rv

    dim repl_env
    repl_env = MalEnv.new_()
    MalEnv.set_(repl_env, MalSymbol.new_("+"), MalNamedFunction.init("+"))
    MalEnv.set_(repl_env, MalSymbol.new_("-"), MalNamedFunction.init("-"))
    MalEnv.set_(repl_env, MalSymbol.new_("*"), MalNamedFunction.init("*"))
    MalEnv.set_(repl_env, MalSymbol.new_("/"), MalNamedFunction.init("/"))

    Core.register_core_funcs(repl_env)

    rem special forms
    MalEnv.set_(repl_env, MalSymbol.new_("def!"), MalSymbol.new_("def!"))
    MalEnv.set_(repl_env, MalSymbol.new_("let*"), MalSymbol.new_("let*"))
    MalEnv.set_(repl_env, MalSymbol.new_("fn*" ), MalSymbol.new_("fn*" ))
    MalEnv.set_(repl_env, MalSymbol.new_("if"  ), MalSymbol.new_("if"  ))
    MalEnv.set_(repl_env, MalSymbol.new_("do"  ), MalSymbol.new_("do"  ))
    MalEnv.set_(repl_env, MalSymbol.new_("quote"), MalSymbol.new_("quote"))
    MalEnv.set_(repl_env, MalSymbol.new_("quasiquote"), MalSymbol.new_("quasiquote"))
    MalEnv.set_(repl_env, MalSymbol.new_("defmacro!"), MalSymbol.new_("defmacro!"))
    MalEnv.set_(repl_env, MalSymbol.new_("macroexpand"), MalSymbol.new_("macroexpand"))
    
    rv = repl_env

    create_repl_env = rv
end function

rem --------------------------------

function read_eval(repl_env, line_ As String)
    ' ON_ERROR_TRY

    Utils.log0 "-->> read_eval()"
    dim rv

    dim ast
    ast = READ_(line_)
    
    if input_cont_p then
        Utils.log0 "input continued: skip eval and print"
        read_eval = null
        exit function
    end if
    
    dim eval_result
    eval_result = EVAL(ast, repl_env)

    rv = eval_result
    read_eval = rv

    ' ON_ERROR_CATCH
end function

rem --------------------------------

sub REP(repl_env, line_ As String)
    ' ON_ERROR_TRY

    Utils.log0 "-->> REP()"

    dim eval_result
    eval_result = read_eval(repl_env, line_)

    if input_cont_p then
        REP = null
        exit sub
    end if

    PRINT_(eval_result)
    
    ' ON_ERROR_CATCH
end sub

rem --------------------------------

sub PRINT_(exp)
  Utils.log0 "-->> PRINT_"
  dim str As String
  str = Printer._pr_str(exp, True)
  ext_command(str, null, "PRINT")
end sub

rem --------------------------------

function READ_(str)
    ' ON_ERROR_TRY

    Utils.log0 "-->> READ_()"
    dim rv
  
    if environ("IS_TEST") = "1" then
        rv = READ_one_line(str)
    else
        rv = READ_multi_line(str)
    end if
    
    READ_ = rv
    Utils.log0 "<<-- READ_"

    ' ON_ERROR_CATCH
end function


function READ_one_line(str)
    Utils.log1 "-->> READ_one_line()"
    READ_one_line = Reader.read_str(str)
end function


function READ_multi_line(str)
    Utils.log1 "-->> READ_multi_line()"
    dim rv

    rv = Reader.read_str(input_buf & str & lf())

    input_cont_p = false
    if mal_error_exists() then
        ' read で起こった例外を catch

        if type_name_ex(mal_error) = "String" then
            if mal_error = "expected ')', got EOF" then
                ' リストが完了していない => エラーにせず、 input_buf に貯めて継続する
                input_buf = input_buf & str & lf()
                input_cont_p = True
                reset_mal_error() ' エスカレーションしない
            else
                ' 対象外の例外だった場合 => reset
                ' （通常の例外扱い）
                input_buf = ""
                input_cont_p = False
            end if
        else
            ' 対象外の例外だった場合 => reset
            ' （通常の例外扱い）
            input_buf = ""
            input_cont_p = False
        end if
    else
        ' 例外が発生していない => reset
        input_buf = ""
        input_cont_p = False
    end if

    READ_multi_line = rv
end function


rem --------------------------------

function _eval_ast_list(list, env)
  Utils.log2 "-->> _eval_ast_list"
  dim rv
  
  dim newlist
  
  select case type_name_ex(list)
  case MalList.type_name
      newlist = MalList.new_()
  case MalVector.type_name
      newlist = MalVector.new_()
  case else
      throw "unexpected type: " & type_name_ex(list)
  end select

  dim i, ast, eval_result
  for i = 0 to MalList.size(list) - 1
      ast = MalList.get_(list, i)

      eval_result = EVAL(ast, env)
      ' CHECK_MAL_ERROR

      MalList.add(newlist, eval_result)
  next
  rv = newlist
  
  _eval_ast_list = rv
end function


function _eval_ast_map(map, env)
  ' ON_ERROR_TRY

  Utils.log2 "-->> _eval_ast_map()"
  dim rv
  
  dim newmap
  newmap = MalMap.new_()

  dim keys
  keys = MalMap.get_keys(map)

  dim i, ast, k, v, k2, v2
  for i = 0 to MalList.size(keys) - 1
      k = MalList.get_(keys, i)
      v = MalMap.get_(map, k)

      k2 = EVAL(k, env)
      ' CHECK_MAL_ERROR

      v2 = EVAL(v, env)
      ' CHECK_MAL_ERROR

      MalMap.put(newmap, k2, v2)
  next

  rv = newmap

  _eval_ast_map = rv
  
  ' ON_ERROR_CATCH
end function


function _eval_ast(ast, env)
  ' ON_ERROR_TRY

  Utils.log0 "-->> _eval_ast()"
  dim rv

  select case type_name_ex(ast)
    case MalSymbol.type_name
      dim sym
      sym = ast
      rv = MalEnv.get_(env, sym)
      ' CHECK_MAL_ERROR

    case MalList.type_name
      rv = _eval_ast_list(ast, env)
      ' CHECK_MAL_ERROR

    case MalVector.type_name
      rv = _eval_ast_list(ast, env)
      ' CHECK_MAL_ERROR

    case MalMap.type_name
      rv = _eval_ast_map(ast, env)
      ' CHECK_MAL_ERROR

    case else
      rv = ast
  end select

  _eval_ast = rv

  ' ON_ERROR_CATCH
end function

rem --------------------------------

function is_macro_call(ast, env)
    ' ON_ERROR_TRY

    Utils.log1 "-->> is_macro_call()"

    dim rv
    
    if not MalList.is_list(ast) then
        is_macro_call = false
        exit function
    end if

    if MalList.size(ast) = 0 then
        is_macro_call = false
        exit function
    end if
    
    dim head
    head = MalList.head(ast)

    if not MalSymbol.is_symbol(head) then
        is_macro_call = false
        exit function
    end if

    if not Utils.is_truthy(MalEnv.find(env, head)) then
        is_macro_call = false
        exit function
    end if
    
    dim val
    val = MalEnv.get_(env, head)
    
    if not MalFunction.is_mal_function(val) then
        is_macro_call = false
        exit function
    end if

    if not val.is_macro then
        is_macro_call = false
        exit function
    end if
    
    rv = True
    is_macro_call = rv
    
    ' ON_ERROR_CATCH
end function


function _apply_macro(mac, args)
    Utils.log1 "-->> _apply_macro()"
    _apply_macro = Core._apply_func(mac, args) ' TODO core から移動した方がよい？
end function


function macroexpand(ast, env)
    Utils.log1 "-->> macroexpand()"
    dim rv

    ' assert
    if IsEmpty(ast) then
        panic "ast must be non-empty"
    end if
    
    dim mac, args
    do while true
        if not is_macro_call(ast, env) then
            exit do
        end if
        mac = MalEnv.get_(env, MalList.head(ast))
        args = MalList.rest(ast)
        ast = _apply_macro(mac, args)
    loop
    
    rv = ast

    macroexpand = rv
end function

rem --------------------------------

rem mutate env: yes
rem mutate ast: no
rem @return [env, ast, result, do_return]
function _eval_special_form_def(ast, env)
  dim rv

  dim name, val, result
  ' (def! name val)
  name = MalList.get_(ast, 1)
  val  = MalList.get_(ast, 2)

  dim eval_result
  eval_result = EVAL(val, env)
  ' CHECK_MAL_ERROR

  result = MalEnv.set_(env, name, eval_result)

  _eval_special_form_def = Array(env, ast, result, true)
end function


function _eval_special_form_let(ast, env)
    dim rv

    dim kvs, body
    ' (let* kvs body)
    kvs  = MalList.get_(ast, 1)
    body = MalList.get_(ast, 2)

    dim let_env
    let_env = MalEnv.new_(env)

    dim k, v
    dim evaluated_v
    dim i

    i = 0
    do while i < MalList.size(kvs)
      k = MalList.get_(kvs, i)
      v = MalList.get_(kvs, i + 1)
      evaluated_v = EVAL(v, let_env)
      MalEnv.set_(let_env, k, evaluated_v)
      i = i + 2
    loop

    rv = Array(let_env, body, null, false) rem continue
    _eval_special_form_let = rv
end function


function _eval_special_form_quote(ast, env)
    Utils.log2 "-->> _eval_special_form_quote()"
    
    dim rv

    dim val
    val = MalList.get_(ast, 1)
    
  rv = Array(env, ast, val, true)

  _eval_special_form_quote = rv
end function


function _symbol_eq(val, str) As Boolean
    dim rv

    if not MalSymbol.is_symbol(val) then
        rv = false
        _symbol_eq = rv
        exit function
    end if
    
    rv = MalSymbol.eq_to_str(val, str)
    
    _symbol_eq = rv
end function


function _qq_loop_list(acc, list)
    dim rv
    dim head
    
    head = MalList.head(list)
    
    if MalList.size(list) = 2 and _symbol_eq(head, "splice-unquote") then
        acc = MalList.from_array(Array( _
            MalSymbol.new_("concat"), MalList.get_(list, 1), acc _
        ))
    else
        dim qqed
        qqed = quasiquote(list)
        acc = MalList.from_array(Array( _
            MalSymbol.new_("cons"), qqed, acc _
        ))
    end if

    rv = acc
    _qq_loop_list = rv
end function


function qq_loop(ast)
    Utils.log2 "-->> qq_loop()"

    dim rv
    
    dim acc
    acc = MalList.new_()

    dim ast_rev
    ast_rev = MalList.reverse(ast)

    dim i, el
    for i = 0 to MalList.size(ast_rev) - 1
        el = MalList.get_(ast_rev, i)

        if type_name_ex(el) = MalList.type_name then ' TODO Use is_list
            dim acc2
            acc2 = _qq_loop_list(acc, el)
            acc = acc2
        else
            dim _cons, qqed
            _cons = MalSymbol.new_("cons")
            qqed = quasiquote(el)
            dim arr
            arr = Array(_cons, qqed, acc)
            acc = MalList.from_array(arr)
        end if
    next

    rv = acc

    qq_loop = rv
end function


function _is_sym_unquote(sym) as boolean
    Utils.log2 "-->> _is_sym_unquote()"
    dim rv
    
    if not MalSymbol.is_symbol(sym) then
        rv = false
        _is_sym_unquote = rv
        exit function
    end if
    
    rv = MalSymbol.eq_to_str(sym, "unquote")
    
    _is_sym_unquote = rv
end function


function quasiquote(ast)
    Utils.logkv2 "-->> quasiquote()", ast
    dim rv
    dim val

    select case type_name_ex(ast)
    case MalList.type_name
        if MalList.size(ast) = 2 then
            dim head
            head = MalList.head(ast)
            
            if MalSymbol.is_symbol(head) and _is_sym_unquote(head) then
                val = MalList.get_(ast, 1)
            else
                val = qq_loop(ast)
            end if
        else
            val = qq_loop(ast)
        end if
    case MalSymbol.type_name
        val = MalList.from_array(Array(MalSymbol.new_("quote"), ast))
    case else
        val = ast
    end select
    
    rv = val

    quasiquote = rv
end function


function _eval_special_form_quasiquote(args, env)
    Utils.log2 "-->> _eval_special_form_quasiquote()"
    dim rv

    Dim ast
    ast = MalList.get_(args, 1)

    dim val
    val = quasiquote(ast)   
    
    ' val が次のターンの ast になる
    rv = Array(env, val, val, false)

    _eval_special_form_quasiquote = rv
end function


function _eval_special_form_defmacro(ast, env)
    Utils.log1 "-->> _eval_special_form_defmacro()"
    dim rv

    Dim a1, a2
    a1 = MalList.get_(ast, 1)
    a2 = MalList.get_(ast, 2)

    dim eval_result
    eval_result = EVAL(a2, env)
    dim func
    func = Core.clone(eval_result)
    func.is_macro = true
    
    dim val
    val = MalEnv.set_(env, a1, func)

    rv = Array(env, ast, val, true)

    _eval_special_form_defmacro = rv
end function


function _eval_special_form_macroexpand(ast, env)
    Utils.log1 "-->> _eval_special_form_macroexpand()"
    dim rv
    
    Dim a1
    a1 = MalList.get_(ast, 1)
    
    dim val
    val = macroexpand(a1, env)
    rv = Array(env, ast, val, true)

    _eval_special_form_macroexpand = rv
end function


' (try* expr1 (catch* ...))

' @return [env, ast, result, do_return]
function _eval_special_form_try(ast, env)
    Utils.log2 "-->> _eval_special_form_try()"

    dim rv

    dim a1
    a1 = MalList.get_(ast, 1)

    dim result
    __inc_lv
    result = EVAL(a1, env)
    __dec_lv

    if mal_error_exists() then
        if 3 <= MalList.size(ast) then
            ' (catch* err expr)
            dim a2, a2_0
            a2 = MalList.get_(ast, 2)
            a2_0 = MalList.get_(a2, 0)

            if MalSymbol.eq_to_str(a2_0, "catch*") then
                dim ex_name, ast2
                ex_name = MalList.get_(a2, 1)
                ast2 = MalList.get_(a2, 2)
                
                dim env2
                env2 = MalEnv.new_(env)
                MalEnv.set_(env2, ex_name, mal_error) ' 引数をセット

                reset_mal_error()

                result = EVAL(ast2, env2)
            else
                ' TODO エスカレーションする
                ' ここでは何もせず関数を抜け、外側で対応
            end if
        else
            ' TODO エスカレーションする
            ' ここでは何もせず関数を抜け、外側で対応
        end if
    end if

    rv = Array(env, ast, result, true)
    _eval_special_form_try = rv
end function


rem mutate ast
rem @return [env, ast, result, do_return]
function _eval_special_form_do(ast, env)
    Utils.log2 "-->> _eval_special_form_do()"
    dim rv
    
    dim exps, results
    exps = MalList.newlist_for_do(ast) rem 先頭と最後以外 / ast[1..-2]
    ast  = MalList.last(ast)

    rem 最後を除いて / 最後以外を / eval する
    __inc_lv
    results = _eval_ast(exps, env)
    __dec_lv
    ' TODO check error

    rv = Array(env, ast, results, false)
    _eval_special_form_do = rv
end function


function _eval_special_form_if(ast, env)
    Utils.log2 "-->> _eval_special_form_if()"

    dim rv
    dim result, do_return
    result = null
    do_return = false
    
    ' (if cond_expr then_expr else_expr)
    dim cond_expr, then_expr, else_expr
    cond_expr = MalList.get_(ast, 1)
    then_expr = MalList.get_(ast, 2)
    dim cond
    cond = EVAL(cond_expr, env)
    
    if is_truthy(cond) then
        ast = then_expr rem Continue loop (TCO)
    else
        rem if IsNull(else_expr) or IsEmpty(else_expr) then
        if MalList.size(ast) <= 3 then
            rem else が省略されている場合
            do_return = true
        else
            else_expr = MalList.get_(ast, 3)
            ast = else_expr rem Continue loop (TCO)
        end if
    end if

    rv = Array(env, ast, result, do_return)
    _eval_special_form_if = rv
end function


rem (fn* ...) => (lambda ...)
function _eval_special_form_fn(ast, env)
    Utils.log2 "-->> _eval_special_form_fn()"
    
    dim rv
    dim arg_names, body

  ' (fn* (x) x)
  '          body ... body
  '      arg_names     ... args

  arg_names = MalList.get_(ast, 1)
  body      = MalList.get_(ast, 2)

  dim newfunc
  newfunc = MalFunction_new(env, arg_names, body)

  rv = Array(env, ast, newfunc, true)

  _eval_special_form_fn = rv
end function


rem @return [env, ast, eval_result, do_return]
function eval_special_form(ast, env)
  Utils.log2 "-->> eval_special_form"

  dim iter_rv

  Dim a0
  a0 = MalList.get_(ast, 0)

  select case a0.str
    case "def!"
      iter_rv = _eval_special_form_def(ast, env)
    case "let*"
      iter_rv = _eval_special_form_let(ast, env)
    case "quote"
      iter_rv = _eval_special_form_quote(ast, env)
    case "quasiquote"
      iter_rv = _eval_special_form_quasiquote(ast, env)
    case "defmacro!"
      iter_rv = _eval_special_form_defmacro(ast, env)
    case "macroexpand"
      iter_rv = _eval_special_form_macroexpand(ast, env)
    case "try*"
      iter_rv = _eval_special_form_try(ast, env)
    case "do"
      iter_rv = _eval_special_form_do(ast, env)
    case "if"
      iter_rv = _eval_special_form_if(ast, env)
    case "fn*"
      iter_rv = _eval_special_form_fn(ast, env)
    case else
      panic "invalid special form"
  end select

  eval_special_form = iter_rv
end function

rem --------------------------------

function _eval_inner(ast, env)
    ' ON_ERROR_TRY
    Utils.log0 "-->> _eval_inner()"
    dim rv

  ast = macroexpand(ast, env)

  if type_name_ex(ast) <> MalList.type_name then ' TODO Use is_list()
      rv = _eval_ast(ast, env)
      ' CHECK_MAL_ERROR

      _eval_inner = Array(env, ast, rv, true)
      exit function
  end if
  
  if MalList.size(ast) = 0 then
      rv = ast
      _eval_inner = Array(env, ast, rv, true)
      exit function
  end if
  
  dim iter_rv
  Dim result
  Dim do_return As Boolean

  if is_special_form(ast) then
      iter_rv = eval_special_form(ast, env)
      ' CHECK_MAL_ERROR

      env       = iter_rv(0)
      ast       = iter_rv(1)
      result    = iter_rv(2)
      do_return = iter_rv(3)
  else
      dim el, f, args

      el = _eval_ast(ast, env)
      ' CHECK_MAL_ERROR

      f = MalList.head(el)
      args = MalList.rest(el)

      if MalFunction.is_mal_function(f) then
          ast = f.body
          env = MalFunction_gen_env(f, args) rem TODO
      else
          result = apply(f, args, env)
          ' CHECK_MAL_ERROR
          do_return = true
      end if
  end if

  _eval_inner = Array(env, ast, result, do_return)

  ' ON_ERROR_CATCH
end function


function EVAL(ByVal ast, ByVal env)
    Utils.log0 "-->> EVAL()"

  dim rv
  dim iter_rv

  dim eval_result
  Dim do_return As Boolean
  
  dim i
  i = 0
  do while true
      i = i + 1

      iter_rv = _eval_inner(ast, env)
      ' CHECK_MAL_ERROR

      env         = iter_rv(0)
      ast         = iter_rv(1)
      eval_result = iter_rv(2)
      do_return   = iter_rv(3)

      if do_return then
          rv = eval_result
          exit do
      end if
  loop
  
    EVAL = rv
end function

rem --------------------------------

rem ここに渡ってきた時点で args は評価済み
rem 評価済みの args に手続きを適用するだけ
function apply(f, args, env)
    Utils.log0 "-->> apply()"
    dim rv

    if type_name_ex(f) <> MalNamedFunction_type_name then
        throw "apply: expected MalNamedFunction, got (" & inspect(f) & ")"
    end if

    rv = dispatch_func(f, args, env)
    
    apply = rv
end function

rem --------------------------------

function _is_special_form_symbol(sym)
  Utils.log2 "-->> _is_special_form_symbol()"
  dim rv

  select case sym.str
      case "def!", "let*", "fn*", "if", "do", "quote", _
           "quasiquote", "defmacro!", "macroexpand", "try*"
    rv = true
  case else
    rv = false
  end select

_is_special_form_symbol = rv
end function


Function is_special_form(list) As Boolean
  Utils.log2 "-->> is_special_form()"
  dim rv
  dim el0
  el0 = MalList.get_(list, 0)

  If Not MalSymbol.is_symbol(el0) Then
      rv = false
      is_special_form = rv
      exit function
  end if

  rv = _is_special_form_symbol(el0)

  is_special_form = rv
End Function

' --------------------------------

sub _run
  ' ON_ERROR_TRY
    ' ThisComponent.LockControllers()
    
    dim box_src, box_output
    box_src    = Calc.get_shape_by_name("src")
    box_output = Calc.get_shape_by_name("output")

    dim src
    src = box_src.string
    
    log_path = environ("FILE_LOG_SETUP")

    dim argv
    argv = MalList.new_()

    dim repl_env
    repl_env = create_repl_env()

    setup(argv, repl_env)
    
    ' clear log
    ' dim logbox
    ' logbox = Calc.get_shape_by_name("log")
    ' logbox.string = " "

    log_path = environ("FILE_LOG")
    ' file_clear log_path
    
    box_clear "output"
    
    dim result
    result = read_eval(repl_env, src)
    
    ' 一番外側の try/catch に相当
    Utils.log0 "-->> check error (gui mode top)"
    if mal_error_exists() then
        ' print_stderr("Error: " & Printer._pr_str(mal_error, true))
        result = mal_error
    end if
    Utils.log0 "<<-- check error (gui mode top)"

    ' box_output.string = Printer._pr_str(result, false)
    dim out_str
    out_str = Printer._pr_str(result, false)
    Utils.box_append("output", "=> " & out_str)

    ' ThisComponent.UnlockControllers()
    
    ' ON_ERROR_CATCH
end sub
