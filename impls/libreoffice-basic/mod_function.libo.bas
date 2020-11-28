rem -*- mode: basic -*-

Option Explicit

rem --------------------------------

type MalFunction
    type_ as string
    env ' MalEnv
    args ' MalList
    body ' MalList
    is_macro as boolean
    meta as variant
end type


' TODO .new_() にリネーム
function MalFunction_new(env, args, body)
    dim mf as New MalFunction
    mf.type_ = type_name
    mf.env = env
    mf.args = args
    mf.body = body
    MalFunction_new = mf
end function


Function type_name As String
    type_name = "MalFunction"
End Function


function MalFunction_inspect(self)
    dim rv

    rv = "#<function"

    rv = rv & " env: "

    dim iter_env
    iter_env = self.env

    do while True
        rv = rv & iter_env.id

        if IsNull(iter_env.outer) then
            exit do
        else
            rv = rv & "->"
            iter_env = iter_env.outer
        end if
    loop

    rv = rv & ">"

    MalFunction_inspect = rv
end function


function MalFunction_gen_env(self, args)
    ' ON_ERROR_TRY

    ' Utils.log2 "-->> MalFunction_gen_env"

    dim rv
    dim newenv
    
    newenv = MalEnv.new_(self.env)

    dim i, arg_name, arg_val
    i = 0
    do while i < MalList.size(self.args)
        arg_name = MalList.get_(self.args, i)

        if MalSymbol.eq_to_str(arg_name, "&") then
            arg_name = MalList.get_(self.args, i + 1)
            dim opts
            opts = MalList.new_()
            dim i2
            i2 = i
            do while i2 < MalList.size(args)
                arg_val = MalList.get_(args, i2)
                MalList.add(opts, arg_val)
                i2 = i2 + 1
            loop
            MalEnv.set_(newenv, arg_name, opts)
            exit do
        end if
        
        arg_val  = MalList.get_(args, i)

        MalEnv.set_(newenv, arg_name, arg_val)
        i = i + 1
    loop

    rv = newenv
    MalFunction_gen_env = rv
    
    ' ON_ERROR_CATCH
end function


function clone(self)
    ' Utils.log2 "-->> MalFunction.clone()"
    dim rv

    rv = MalFunction_new(self.env, self.args, self.body)
    rv.is_macro = self.is_macro

    clone = rv
end function


function _is_mal_function_obj(val as object) as Boolean
    ' ON_ERROR_TRY

    _is_mal_function_obj = (val.type_ = type_name)

    ' ON_ERROR_CATCH
end function


function is_mal_function(val as variant) as Boolean
    ' ON_ERROR_TRY

    if TypeName(val) <> "Object" then
        is_mal_function = False
        exit function
    end if

    is_mal_function = _is_mal_function_obj(val)

    ' ON_ERROR_CATCH
end function
