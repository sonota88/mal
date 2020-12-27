rem -*- mode: basic -*-

Option Explicit

rem --------------------------------

sub register_core_funcs(env)
    dim names
    names = MalList.new_()

    MalList.add(names, "list"  )
    MalList.add(names, "list?" )
    MalList.add(names, "empty?")
    MalList.add(names, "count" )
    MalList.add(names, "="     )
    MalList.add(names, ">"     )
    MalList.add(names, ">="    )
    MalList.add(names, "<"     )
    MalList.add(names, "<="    )
    MalList.add(names, "prn"   )

    ' step4 self host
    MalList.add(names, "dissoc")
    
    ' step 6
    MalList.add(names, "read-string")
    MalList.add(names, "slurp"      )
    MalList.add(names, "str"        )
    MalList.add(names, "atom"       )
    MalList.add(names, "atom?"      )
    MalList.add(names, "deref"      )
    MalList.add(names, "reset!"     )
    MalList.add(names, "swap!"      )
    
    ' step 7
    MalList.add(names, "cons"       )
    MalList.add(names, "concat"     )

    ' step 8 deferrable
    MalList.add(names, "first"      )
    MalList.add(names, "rest"       )

    ' step 9
    MalList.add(names, "throw"      )
    MalList.add(names, "nth"        )
    MalList.add(names, "map"        )
    MalList.add(names, "symbol?"    )
    MalList.add(names, "nil?"       )
    MalList.add(names, "true?"      )
    MalList.add(names, "false?"     )
    MalList.add(names, "apply"      )

    ' step 9 deferrable
    MalList.add(names, "symbol"     )
    MalList.add(names, "keyword?"   )
    MalList.add(names, "keyword"    )
    MalList.add(names, "sequential?")
    MalList.add(names, "vector?"    )
    MalList.add(names, "vector"     )
    MalList.add(names, "map?"       )
    MalList.add(names, "hash-map"   )
    MalList.add(names, "assoc"      )
    MalList.add(names, "get"        )
    MalList.add(names, "contains?"  )
    MalList.add(names, "keys"       )
    MalList.add(names, "vals"       )

    ' step A
    MalList.add(names, "readline"   )

    ' step A deferrable
    MalList.add(names, "time-ms"    )
    MalList.add(names, "string?"    )
    MalList.add(names, "number?"    )
    MalList.add(names, "seq"        )
    MalList.add(names, "conj"       )
    MalList.add(names, "meta"       )
    MalList.add(names, "with-meta"  )
    MalList.add(names, "fn?"        )
    
    ' step A self host
    MalList.add(names, "pr-str"     )
    MalList.add(names, "println"    )
    
    MalList.add(names, "wait"       )

    ' MalEnv.set_(env, MalSymbol.new_("prop-get"), MalNamedFunction.new_("prop-get"))
    ' MalEnv.set_(env, MalSymbol.new_("prop-set"), MalNamedFunction.new_("prop-set"))
    ' MalEnv.set_(env, MalSymbol.new_("uno-get" ), MalNamedFunction.new_("uno-get"))
    ' MalEnv.set_(env, MalSymbol.new_("uno-call"), MalNamedFunction.new_("uno-call"))

    MalList.add(names, "execute-dispatch"  )
    MalList.add(names, "lock-controllers"  )
    MalList.add(names, "unlock-controllers")
    MalList.add(names, "msgbox"            )
    MalList.add(names, "get-ci-max"        )
    MalList.add(names, "get-ri-max"        )
    MalList.add(names, "file-write"        )

    ' Calc
    MalList.add(names, "cell-get")
    MalList.add(names, "cell-set")

    dim i as Integer
    dim name as String
    for i = 0 to MalList.size(names) - 1
        name = MalList.get_(names, i)
        MalEnv.set_(env, MalSymbol.new_(name), MalNamedFunction.new_(name))
    next
end sub

rem --------------------------------

function dispatch_func(f, args, env)
    ' Utils.log0 "-->> dispatch_func()"
    dim rv
    dim a, b

    if f.id = "+" then
        rv = _builtin_add(args)
    ElseIf f.id = "-" then
        rv = _builtin_sub(args)
    ElseIf f.id = "*" then
        rv = _builtin_mult(args)
    ElseIf f.id = "/" then
        rv = _builtin_div(args)

    ElseIf f.id = "list" then
        rv = Core.list(args)
    ElseIf f.id = "list?" then
        rv = Core.list_p(args)
    ElseIf f.id = "empty?" then
        rv = Core.empty_p(MalList.get_(args, 0))
    ElseIf f.id = "count" then
        rv = Core.count(MalList.get_(args, 0))

    ElseIf f.id = "=" then
        rv = Core.equal(MalList.get_(args, 0), MalList.get_(args, 1))
    ElseIf f.id = ">" then
        rv = Core.greater_than(MalList.get_(args, 0), MalList.get_(args, 1))
    ElseIf f.id = ">=" then
        rv = Core.greater_equal(MalList.get_(args, 0), MalList.get_(args, 1))
    ElseIf f.id = "<" then
        rv = Core.less_than(MalList.get_(args, 0), MalList.get_(args, 1))
    ElseIf f.id = "<=" then
        rv = Core.less_equal(MalList.get_(args, 0), MalList.get_(args, 1))

    ElseIf f.id = "prn" then
        rv = Core.prn(args)
        
    ' step 4 self host
    ElseIf f.id = "dissoc" then
        rv = dissoc(args)

    ' step 6
    ElseIf f.id = "read-string" then
        rv = Core.read_string(args)
    ElseIf f.id = "slurp" then
        rv = Core.slurp(args)
    ElseIf f.id = "str" then
        rv = Core.str_(args)
    ElseIf f.id = "atom" then
        rv = MalAtom.create(MalList.get_(args, 0))
    ElseIf f.id = "atom?" then
        rv = Core.atom_p(MalList.get_(args, 0))
    ElseIf f.id = "deref" then
        rv = Core.deref(MalList.get_(args, 0))
    ElseIf f.id = "reset!" then
        rv = Core.reset(args)
    ElseIf f.id = "swap!" then
        rv = Core.swap(args)

    ' step 7
    ElseIf f.id = "cons" then
        rv = Core.cons(args)

    ElseIf f.id = "concat" then
        rv = Core.concat(args)

    ' step 8 deferrable
    ElseIf f.id = "first" then
        rv = first(args)
    ElseIf f.id = "rest" then
        rv = rest(args)

    ' step 9
    ElseIf f.id = "throw" then
        dim err_obj
        err_obj = MalList.head(args)
        Core.throw(err_obj)
        exit function

    ElseIf f.id = "nth" then
        a = MalList.get_(args, 0)
        b = MalList.get_(args, 1)
        rv = Core.nth(a, b)
        ' CHECK_MAL_ERROR

    ElseIf f.id = "map" then
        a = MalList.get_(args, 0) ' func
        b = MalList.get_(args, 1) ' list
        rv = Core.map(a, b)

    ElseIf f.id = "symbol?" then
        a = MalList.get_(args, 0)
        rv = MalSymbol.is_symbol(a)

    ElseIf f.id = "nil?" then
        a = MalList.get_(args, 0)
        rv = IsNull(a)

    ElseIf f.id = "true?" then
        a = MalList.get_(args, 0)
        if type_name_ex(a) = "Boolean" then
            rv = (a = True)
        else
            rv = False
        end if

    ElseIf f.id = "false?" then
        a = MalList.get_(args, 0)
        rv = (a = False)

    ElseIf f.id = "apply" then
        rv = Core.core_apply(args)
        
    ' step 9 deferrable
    ElseIf f.id = "symbol" then
        rv = make_symbol(args)
        
    ElseIf f.id = "keyword?" then
        rv = is_keyword(args)
        
    ElseIf f.id = "keyword" then
        rv = make_keyword(args)
        
    ElseIf f.id = "sequential?" then
        rv = is_sequential(args)
        
    ElseIf f.id = "vector?" then
        rv = is_vector(args)
        
    ElseIf f.id = "vector" then
        rv = make_vector(args)
        
    ElseIf f.id = "map?" then
        rv = is_map(args)
        
    ElseIf f.id = "hash-map" then
        rv = hash_map(args)
        
    ElseIf f.id = "assoc" then
        rv = assoc(args)
        
    ElseIf f.id = "get" then
        rv = get(args)
        
    ElseIf f.id = "contains?" then
        rv = contains(args)
        
    ElseIf f.id = "keys" then
        rv = keys(args)
        
    ElseIf f.id = "vals" then
        rv = vals(args)
        
    ' step A
    ElseIf f.id = "readline" then
        dim prompt
        prompt = MalList.head(args)
        rv = readline(prompt)

    ' step A deferrable
    ElseIf f.id = "time-ms" then
        rv = time_ms(args)

    ElseIf f.id = "string?" then
        rv = is_string(args)

    ElseIf f.id = "number?" then
        rv = is_number(args)

    ElseIf f.id = "seq" then
        rv = seq(args)

    ElseIf f.id = "conj" then
        rv = conj(args)

    ElseIf f.id = "meta" then
        rv = meta(args)

    ElseIf f.id = "with-meta" then
        rv = with_meta(args)

    ElseIf f.id = "fn?" then
        rv = is_fn(args)

    ' step A self host
    ElseIf f.id = "pr-str" then
        rv = Core.pr_str(args)
    ElseIf f.id = "println" then
        rv = Core.println(args)

    ' libo calc/basic
    ElseIf f.id = "msgbox" then
        rv = Core.msgbox_(args)
    ElseIf f.id = "wait" then
        rv = Core.wait_(args)
        
    ' ElseIf f.id = "prop-get" then
    '     rv = Core.prop_get(args)
    ' ElseIf f.id = "prop-set" then
    '     rv = Core.prop_set(args)
    ' ElseIf f.id = "uno-get" then
    '     rv = uno_get(args)
    ' ElseIf f.id = "uno-call" then
    '     rv = Core.uno_call(args)

    ElseIf f.id = "cell-get" then
        rv = Core.cell_get(args)
    ElseIf f.id = "cell-set" then
        rv = cell_set(args)

    ElseIf f.id = "execute-dispatch" then
        rv = execute_dispatch(args)

    ElseIf f.id = "lock-controllers" then
        rv = lock_controllers(args)
    ElseIf f.id = "unlock-controllers" then
        rv = unlock_controllers(args)

    ElseIf f.id = "msgbox" then
        rv = msgbox_(args)

    ElseIf f.id = "get-ci-max" then
        rv = get_ci_max(args)
    ElseIf f.id = "get-ri-max" then
        rv = get_ri_max(args)
    ElseIf f.id = "file-write" then
        rv = Core__file_write(args)

    ElseIf f.id = "eval" then
        rv = EVAL(MalList.get_(args, 0), f.env)

    else
        panic "unknown function"
    end if

    dispatch_func = rv
end function

' --------------------------------

function list(args)
    dim rv

    rv = MalList.new_()

    dim i, it
    do while i < MalList.size(args)
        it = MalList.get_(args, i)
        MalList.add(rv, it)
        i = i + 1
    loop

    list = rv
end function


function list_p(args) as boolean
    dim rv

    dim arg0
    arg0 = MalList.get_(args, 0)
    rv = MalList.is_list(arg0)

    list_p = rv
end function


function empty_p(list) as boolean
    dim rv

    dim size
    size = MalList.size(list)
    rv = (size = 0)

    empty_p = rv
end function


function count(list) as Integer
    dim rv
    
    if IsNull(list) then
        rv = 0
    else
        rv = MalList.size(list)
    end if

    count = rv
end function


function equal(a, b) as Boolean
    dim rv

    ' dim ta, tb
    ' ta = type_name_ex(a)
    ' tb = type_name_ex(b)
    ' if ta <> tb then
    '     Utils.logkv1 "  ta", ta
    '     Utils.logkv1 "  tb", tb
    '     rv = false
    '     equal = rv
    '     exit function
    ' end if
    
    rv = (Utils.inspect(a) = Utils.inspect(b)) rem TODO

    equal = rv
end function


function greater_than(a, b) as Boolean
    greater_than = (a > b)
end function


function greater_equal(a, b) as Boolean
    greater_equal = (a >= b)
end function


function less_than(a, b) as Boolean
    less_than = (a < b)
end function


function less_equal(a, b) as Boolean
    less_equal = (a <= b)
end function


function prn(args)
    ' Utils.log1 "-->> core.prn()"
    dim out as string
    out = ""

    dim i, arg
    i = 0
    do while i < MalList.size(args)
        arg = MalList.get_(args, i)
        if 1 <= i then
            out = out & " "
        end if
        out = out & _pr_str(arg, True)
        i = i + 1
    loop

    ext_command(out, null, "PRINT")

    prn = null
end function


' step A self host
function println(args)
    ' Utils.log1 "-->> core.println()"

    dim out as string
    out = ""

    dim i, arg
    i = 0
    do while i < MalList.size(args)
        arg = MalList.get_(args, i)
        if 1 <= i then
            out = out & " "
        end if
        out = out & _pr_str(arg, False)
        i = i + 1
    loop

    if Utils.is_gui() then
        print_stdout out
    else
        ext_command(out, null, "PRINT")
    end if

    println = null
end function

rem --------------------------------

' function prop_get(args)
'   dim rv
' 
'   dim obj, prop_name
'   obj       = MalList.get_(args, 0)
'   prop_name = MalList.get_(args, 1)
' 
'   rv = "<TODO prop_get_rv>"
' 
'   prop_get = rv
' end function
' 
' 
' function prop_set(args)
'   dim rv
'   
'   dim obj, prop_name, val
'   obj       = MalList.get_(args, 0)
'   prop_name = MalList.get_(args, 1)
'   val       = MalList.get_(args, 2)
'   
'   rv = null
'   prop_set = rv
' end function
' 
' 
' function uno_get(args)
'   dim rv
' 
'   dim fqcn
'   fqcn = MalList.get_(args, 0)
'   
'   rv = CreateUnoService(fqcn)
' 
'   uno_get = rv
' end function
' 
' 
' function uno_call(args)
'   dim rv
'   
'   dim obj, fqcn, method_name, method_args
'   obj         = MalList.get_(args, 0)
'   fqcn        = MalList.get_(args, 1)
'   method_name = MalList.get_(args, 2)
'   method_args = MalList.get_(args, 3)
' 
'   rv = CreateUnoService(fqcn)
'   
'   dim sm
'   sm = GetProcessServiceManager()
' 
'   dim ctx
'   set ctx = sm.getPropertyValue("DefaultContext")
' 
'   set cr = ctx.getValueByName("/singletons/com.sun.star.reflection.theCoreReflection")
' 
'   dim cls
'   cls = cr.forName(fqcn)
' 
'   dim meth
'   meth = cls.getMethod(method_name)
' 
'   rv = meth.invoke(obj, method_args)
' 
'   uno_call = rv
' end function

rem --------------------------------

sub wait_(args)
    dim msec as integer
    msec = MalList.head(args)
    wait msec
end sub


function read_string(args)
    dim rv

    dim str
    str = MalList.get_(args, 0)

    rv = Reader.read_str(str)

    read_string = rv
end function


function _to_fullpath(path)
    dim rv

    ' TODO OS-dependent
    if char_at(path, 0) = "/" then
        rv = path
    else
        rv = environ("PWD") & "/" & path
    end if

    _to_fullpath = rv
end function


function slurp(args)
    ' Utils.log2 "-->> slurp"
    dim rv

    dim path
    path = _to_fullpath(MalList.get_(args, 0))
    
    if not FileExists(path) then
        panic "file not found: " & path
    end if

    rv = file_read(path)

    slurp = rv
end function


function str_(args)
    dim rv

    dim s, i, arg
    s = ""
    for i = 0 to MalList.size(args) - 1
        arg = MalList.get_(args, i)
        s = s & _pr_str(arg, false)
    next
    
    rv = s
    str_ = rv
end function

' --------------------------------

function atom_p(val) As Boolean
    atom_p = MalAtom.is_atom(val)
end function


function deref(atom_)
    deref = atom_.val
end function


function reset(args)
    dim rv

    dim atom_, newval
    atom_  = MalList.get_(args, 0)
    newval = MalList.get_(args, 1)
    
    atom_.val = newval

    rv = atom_.val

    reset = newval
end function


function swap(args)
    ' Utils.log2 "-->> swap()"

    dim rv

    dim atom_, f
    atom_ = MalList.get_(args, 0)
    f     = MalList.get_(args, 1)
    
    dim fn_args
    Dim i As Integer
    fn_args = MalList.new_()
    MalList.add(fn_args, atom_.val)
    if 3 <= MalList.size(args) then
        for i = 2 to MalList.size(args) - 1
            MalList.add(fn_args, MalList.get_(args, i))
        next
    end if
    
    atom_.val = _apply_func(f, fn_args)

    rv = atom_.val

    swap = rv
end function


function cons(args)
    dim rv
    
    dim el, list
    el   = MalList.get_(args, 0)
    list = MalList.get_(args, 1)

    dim newlist
    newlist = MalList.new_()
    MalList.add(newlist, clone(el))

    Dim i As Integer
    dim el2
    for i = 0 to MalList.size(list) - 1
        el2 = MalList.get_(list, i)
        MalList.add(newlist, el2)
    next

    rv = newlist

    cons = rv
end function


function concat(args)
    dim rv

    dim newlist
    newlist = MalList.new_()

    Dim arg_i As Integer
    dim arg

    Dim inner_i As Integer
    dim inner_el

    for arg_i = 0 to MalList.size(args) - 1
        arg = MalList.get_(args, arg_i)
        for inner_i = 0 to MalList.size(arg) - 1
            inner_el = MalList.get_(arg, inner_i)
            MalList.add(newlist, inner_el)
        next
    next

    rv = newlist
    
    concat = rv
end function


sub throw(arg)
    Utils.logkv0 "-->> throw", arg
    mal_error = arg
end sub


function nth(list, n)
    dim rv
    
    if MalList.size(list) <= n then
        throw "nth: index out of range"
        ' CHECK_MAL_ERROR
    end if
    
    rv = MalList.get_(list, n)

    nth = rv
end function


function first(args)
    dim rv

    dim xs
    xs = MalList.head(args)
    if IsNull(xs) then
        rv = null
    ElseIf MalList.size(xs) = 0 then
        rv = null
    else
        rv = MalList.head(xs)
    end if

    first = rv
end function


function rest(args)
    dim rv

    dim xs
    xs = MalList.head(args)
    if IsNull(xs) then
        rv = MalList.new_()
    ElseIf MalList.size(xs) = 0 then
        rv = MalList.new_()
    else
        rv = MalList.rest(xs)
    end if

    rest = rv
end function


function map(f, list)
    dim rv
    
    dim newlist
    newlist = MalList.new_()

    Dim i As Integer
    dim el, newval
    for i = 0 to MalList.size(list) - 1
        el = MalList.get_(list, i)
        newval = _apply_func(f, MalList.from_array(Array(el)))
        MalList.add(newlist, newval)
    next
    
    rv = newlist

    map = rv
end function


function make_symbol(args)
    make_symbol = MalSymbol.new_(MalList.head(args))
end function


function is_keyword(args) as boolean
    ' Utils.log1 "-->> is_keyword()"
    dim rv
    dim arg
    arg = MalList.head(args)

    rv = MalMap.Keyword_is_keyword(arg)

    is_keyword = rv
end function


' TODO rename 候補: to_keyword
function make_keyword(args) as string
    ' Utils.log1 "-->> make_keyword()"
    dim rv
    dim arg
    arg = MalList.head(args)
    
    if TypeName(arg) = "String" then
        if MalMap.Keyword_is_keyword(arg) then
            rv = arg
        else
            rv = kw_marker() & arg
        end if
    else
        rv = kw_marker() & arg
    end if

    make_keyword = rv
end function


function is_sequential(args) as boolean
    ' Utils.log1 "-->> is_sequential()"
    dim rv
    dim arg
    arg = MalList.head(args)
    
    Dim tn As String
    tn = type_name_ex(arg)

    rv = ( _
         tn = MalList.type_name _
      or tn = MalVector.type_name _
    )

    is_sequential = rv
end function


function is_vector(args) as boolean
    ' Utils.log1 "-->> is_vector()"
    dim rv
    dim arg
    arg = MalList.head(args)
    
    rv = MalVector.is_vector(arg)

    is_vector = rv
end function


function make_vector(args)
    ' Utils.log1 "-->> make_vector()"
    dim rv
    
    rv = MalVector.new_()

    Dim i As Integer
    for i = 0 to MalList.size(args) - 1
        MalVector.add(rv, MalList.get_(args, i))
    next

    make_vector = rv
end function


function is_map(args) as boolean
    dim arg
    arg = MalList.head(args)
    
    is_map = MalMap.is_map(arg)
end function


function hash_map(args)
    ' Utils.log1 "-->> hash_map()"
    dim rv
    
    rv = MalMap.new_()

    dim i, k, v
    i = 0
    do while i < MalList.size(args)
        k = MalList.get_(args, i)
        v = MalList.get_(args, i + 1)
        MalMap.put(rv, k, v)
        i = i + 2
    loop

    hash_map = rv
end function


function assoc(args)
    ' Utils.log1 "-->> assoc()"
    dim rv

    dim _map
    _map = MalList.get_(args, 0)

    dim newmap
    newmap = MalMap.new_()
    
    dim keys_
    keys_ = MalMap.get_keys(_map)
    
    dim i, k, v
    for i = 0 to MalList.size(keys_) - 1
        k = MalList.get_(keys_, i)
        v = MalMap.get_(_map, k)
        MalMap.put(newmap, k ,v)
    next

    i = 1
    do while i < MalList.size(args)
        k = MalList.get_(args, i)
        v = MalList.get_(args, i + 1)
        MalMap.put(newmap, k, v)
        i = i + 2
    loop
    
    rv = newmap

    assoc = rv
end function


function dissoc(args)
    ' Utils.log1 "-->> dissoc()"
    dim rv

    dim map1, keys
    map1 = MalList.head(args)
    keys = MalList.rest(args)

    dim map2
    map2 = clone(map1)

    dim i as integer
    dim key
    for i = 0 to MalList.size(keys) - 1
        key = MalList.get_(keys, i)
        MalMap.delete(map2, key)
    next

    rv = map2

    dissoc = rv
end function


function get(args)
    ' Utils.log1 "-->> get()"
    dim rv

    dim _map
    _map = MalList.get_(args, 0)
    
    if IsNull(_map) then
        rv = null
        get = rv
        exit function
    end if

    dim k
    k = MalList.get_(args, 1)

    rv = MalMap.get_(_map, k)

    get = rv
end function


function contains(args) as boolean
    ' Utils.log1 "-->> contains()"
    dim rv

    dim _map
    _map = MalList.get_(args, 0)
    
    if IsNull(_map) then
        throw "not_yet_impl" ' TODO
        ' CHECK_MAL_ERROR
    end if
    
    dim k
    k = MalList.get_(args, 1)

    rv = MalMap.has_key(_map, k)

    contains = rv
end function


function keys(args)
    ' Utils.log1 "-->> keys()"
    dim rv

    dim _map
    _map = MalList.get_(args, 0)

    if not MalMap.is_map(_map) then
        rv = MalList.new_()
        keys = rv
        exit function
    end if
    
    rv = MalMap.get_keys(_map)

    keys = rv
end function


function vals(args)
    ' Utils.log1 "-->> vals()"
    dim rv

    dim _map
    _map = MalList.get_(args, 0)

    if not MalMap.is_map(_map) then
        rv = MalList.new_()
        vals = rv
        exit function
    end if
    
    rv = MalMap.get_vals(_map)

    vals = rv
end function


' NOTE Basic の機能ではミリ秒の取得はできなさそう
function time_ms
    time_ms = ((Now() - 25569) * 86400) * 1000
end function


function is_string(args)
    dim arg
    arg = MalList.head(args)

    is_string = (TypeName(arg) = "String")
end function


function is_number(args) as boolean
    ' Utils.log1 "-->> is_number()"
    dim rv

    dim arg
    arg = MalList.head(args)
    
    Dim tn As String
    tn = TypeName(arg)

    rv = ( _
         tn = "Integer" _
      or tn = "Long" _
      or tn = "Single" _
      or tn = "Double" _
    )

    is_number = rv
end function


function seq(args)
    ' Utils.log1 "-->> seq()"
    dim rv
    dim arg
    
    arg = MalList.head(args)
    if IsNull(arg) then
        rv = null
    ElseIf MalList.size(arg) = 0 then
        rv = null
    else
        if MalList.is_list(arg) then
            rv = MalList.seq(arg)
        ElseIf MalVector.is_vector(arg) then
            rv = MalVector.seq(arg)
        else
            throw "unexpected type (" & type_name_ex(arg) & ")"
        end if
    end if
    ' CHECK_MAL_ERROR

    seq = rv
end function


function conj(args)
    ' Utils.log2 "-->> Core.conj()"
    dim rv
    
    dim arg, rest
    arg = MalList.head(args)
    rest = MalList.rest(args)

    dim cloned
    cloned = clone(arg)

    if MalList.is_list(cloned) then
        rv = MalList.conj(cloned, rest)
    ElseIf MalVector.is_vector(cloned) then
        rv = MalVector.conj(cloned, rest)
    else
        throw "unexpected type (" & type_name_ex(arg) & ")"
    end if

    conj = rv
end function


function meta(args)
    ' Utils.log1 "-->> meta()"
    dim rv

    dim arg
    arg = MalList.head(args)
    
    rv = arg.meta

    if IsEmpty(rv) then
        rv = null
    end if
    
    meta = rv
end function


function with_meta(args)
    ' Utils.log1 "-->> with_meta()"
    dim rv
    
    dim a, b, x
    a = MalList.get_(args, 0)
    b = MalList.get_(args, 1)
    
    x = clone(a)
    x.meta = b
    
    rv = x

    with_meta = rv
end function


function is_fn(args) as boolean
    ' Utils.log1 "-->> is_fn()"
    dim rv
    
    dim arg
    arg = MalList.head(args)

    if MalNamedFunction.is_named_function(arg) then
        is_fn = True
        exit function
    end if

    if MalFunction.is_mal_function(arg) then
        is_fn = not arg.is_macro
        exit function
    end if
    
    rv = False
    
    ' rv = ( _
    '   (    MalNamedFunction.is_named_function(arg) _
    '     or  _
    '   ) _
    '   and not arg.is_macro _
    ' )

    ' rv = ( _
    '      MalNamedFunction.is_named_function(arg) _
    '   or (MalFunction.is_mal_function(arg) and not arg.is_macro) _
    ' )

    is_fn = rv
end function


function readline(prompt)
    dim rv

    Dim line As String
    Dim file_done_temp
    
    If Utils.is_gui() Then
        line = InputBox(prompt, "readline")
    Else
        line = ext_command(null, null, "READLINE " & prompt)
    End If
    
    rv = line

    readline = rv
end function


function pr_str(args) as string
    ' Utils.log1 "-->> pr_str()"
    dim rv
    dim s as string
    s = ""

    dim i, arg
    for i = 0 to MalList.size(args) - 1
        arg = MalList.get_(args, i)
        if 1 <= i then
            s = s & " "
        end if
        s = s & _pr_str(arg, true)
    next
    
    rv = s

    pr_str = rv
end function

' --------------------------------

function clone(val)
    ' Utils.log2 "-->> Core.clone()"
    dim rv
    
    if IsNull(val) then
        clone = null
        exit function
    end if
    
    select case type_name_ex(val)
    case "Integer", "Boolean"
        rv = val
    case MalSymbol.type_name
        rv = MalSymbol.clone(val)
    case MalList.type_name
        rv = MalList.clone(val)
    case MalVector.type_name
        rv = MalVector.clone(val)
    case MalMap.type_name
        rv = MalMap.clone(val)
    case MalFunction.type_name
        rv = MalFunction.clone(val)
    case else
        throw "not yet implemented: " & type_name_ex(val)
    end select

    clone = rv
end function


function core_apply(args)
    ' Utils.log2 "-->> core_apply()"
    dim rv

    dim f
    f = MalList.head(args)

    dim i, el

    dim args2
    args2 = MalList.new_()
    for i = 1 to MalList.size(args) - 2
        el = MalList.get_(args, i)
        MalList.add(args2, el)
    next
    
    dim list
    list = MalList.last(args)
    for i = 0 to MalList.size(list) - 1
        el = MalList.get_(list, i)
        MalList.add(args2, el)
    next
    
    rv = _apply_func(f, args2)

    core_apply = rv
end function


function _apply_func(f, args)
    ' Utils.log2 "-->> _apply_func()"

    dim rv
    
    if not MalList.is_list(args) then
        throw "_apply_func: expected MalList, got (" & Utils.inspect(args) & ")"
        ' CHECK_MAL_ERROR
    end if
    
    If MalNamedFunction.is_named_function(f) Then
        rv = apply(f, args, MalEnv.new_())
        
    ElseIf MalFunction.is_mal_function(f) Then
        dim env2
        env2 = MalFunction.gen_env(f, args)

        rv = EVAL(f.body, env2)

    else
        panic "invalid function"
    end if

    _apply_func = rv
end function

rem --------------------------------
rem builtin procedures

function _builtin_add_int(a, b)
    on local error goto on_error___builtin_add_int
    _builtin_add_int = CInt(a + b)

    exit function
on_error___builtin_add_int:
    if Err() = 6 then ' Overflow
       ' step5 のテストを通すための措置
       _builtin_add_int = CLng(a + b)
    else
        throw "_builtin_add " & Erl() & ": ERR" & err & " " & error$
    end if
end function


function _builtin_add(args)
    dim rv
    dim a, b

    a = MalList.get_(args, 0)
    b = MalList.get_(args, 1)
    
    dim ta, tb
    ta = TypeName(a)
    tb = TypeName(b)
    
    ' TODO consider Long
    if (ta = "Integer" and tb = "Integer") then
        rv = _builtin_add_int(a, b)
    else
        rv = a + b
    end if
    
    _builtin_add = rv
end function


function _builtin_sub(args)
    dim rv
    dim a, b

    a = MalList.get_(args, 0)
    b = MalList.get_(args, 1)
    rv = a - b

    _builtin_sub = rv
end function


function _builtin_mult(args)
    dim rv
    dim a, b

    a = MalList.get_(args, 0)
    b = MalList.get_(args, 1)
    rv = a * b

    _builtin_mult = rv
end function


function _builtin_div(args)
    dim rv
    dim a, b

    a = MalList.get_(args, 0)
    b = MalList.get_(args, 1)
    rv = a / b

    _builtin_div = rv
end function

' --------------------------------

function _make_uno_args(uno_kvs)
    dim rv
    
    if MalList.size(uno_kvs) = 0 then
        rv = Array()
    else
        dim i
        dim num_uno_args
        num_uno_args = MalList.size(uno_kvs) / 2

        dim uno_args(num_uno_args - 1) as new com.sun.star.beans.PropertyValue
        for i = 0 to num_uno_args - 1
            uno_args(i).Name  = MalList.get_(uno_kvs, i * 2)
            uno_args(i).Value = MalList.get_(uno_kvs, i * 2 + 1)
        next
        rv = uno_args
    end if

    _make_uno_args = rv
end function


function execute_dispatch(args)
    dim rv : rv = null
    
    dim document   as object
    dim dispatcher as object
    rem ----------------------------------------------------------------------
    rem get access to the document
    document   = ThisComponent.CurrentController.Frame
    dispatcher = createUnoService("com.sun.star.frame.DispatchHelper")

    rem ----------------------------------------------------------------------
    dim uno_command
    uno_command = MalList.head(args)

    dim uno_kvs
    uno_kvs = MalList.rest(args)

    dim uno_args
    uno_args = _make_uno_args(uno_kvs)

    dispatcher.executeDispatch(document, ".uno:" & uno_command, "", 0, uno_args)

    execute_dispatch = rv
end function


function lock_controllers(args)
    ' Utils.log1 "-->> lock_controllers()"

    ThisComponent.LockControllers()

    lock_controllers = null
end function


function unlock_controllers(args)
    ' Utils.log1 "-->> unlock_controllers()"

    if ThisComponent.hasControllersLocked() then
        ThisComponent.LockControllers()
    end if

    unlock_controllers = null
end function


Function msgbox_(args)
    Dim rv As Integer
    Dim arg0, arg1, arg2
    arg0 = MalList.head(args)

    If MalList.size(args) = 1 Then
        rv = MsgBox(arg0)
    ElseIf MalList.size(args) = 2 Then
        arg1 = MalList.get_(args, 1)
        rv = MsgBox(arg0, arg1)
    ElseIf MalList.size(args) = 3 Then
        arg1 = MalList.get_(args, 1)
        arg2 = MalList.get_(args, 2)
        rv = MsgBox(arg0, arg1, arg2)
    End If

    msgbox_ = rv
End Function

' --------------------------------
' Calc

Function cell_get(args)
    Dim sname, ci, ri
    sname = MalList.get_(args, 0)
    ci    = MalList.get_(args, 1)
    ri    = MalList.get_(args, 2)

    cell_get = Calc.cell_get(sname, ci, ri)
End Function


Function cell_set(args)
    ' ON_ERROR_TRY

    Dim sname, ci, ri, val
    sname = MalList.get_(args, 0)
    ci    = MalList.get_(args, 1)
    ri    = MalList.get_(args, 2)
    val   = MalList.get_(args, 3)

    Calc.cell_set(sname, ci, ri, val)
    cell_set = null

    ' ON_ERROR_CATCH
End Function


Function get_ri_max(args)
    ' Utils.log2 "-->> get_ri_max()"
    Dim rv

    Dim sh_name As String
    sh_name = MalList.get_(args, 0)

    rv = Calc.get_ri_max(sh_name)
    
    get_ri_max = rv
End Function


Function get_ci_max(args)
    ' Utils.log2 "-->> get_ci_max()"
    Dim rv

    Dim sh_name As String
    sh_name = MalList.get_(args, 0)

    rv = Calc.get_ci_max(sh_name)

    get_ci_max = rv
End Function

' --------------------------------

Function Core__file_write(args) ' TODO rename
    ' Utils.log2 "-->> Core__file_write()"
    Dim rv
    rv = null
    
    Dim path As String
    Dim text As String
    path = MalList.get_(args, 0)
    text = MalList.get_(args, 1)
    
    Utils.file_clear(path)
    Utils.file_write(path, text)

    Core__file_write = rv
End Function
