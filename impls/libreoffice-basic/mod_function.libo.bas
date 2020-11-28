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
  mf.type_ = "MalFunction"
  mf.env = env
  mf.args = args
  mf.body = body
  Utils.logkv3 "23 new", mf
  MalFunction_new = mf
end function


function MalFunction_inspect(self)
  dim rv

  rv = "#<function"

  ' ↓これでも問題ないが
  ' rv = "<MalFunction"
  ' rv = rv & " " & inspect(self.args)
  ' rv = rv & " " & inspect(self.body)
  ' ' rv = rv & " " & inspect(self.env) ' 無限再帰する？
  
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
  
  ' rv = rv & " " & _pr_str(self.body)

  rv = rv & ">"
  
  MalFunction_inspect = rv
end function


function MalFunction_gen_env(self, args)
    ' ON_ERROR_TRY

    Utils.log2 "-->> MalFunction_gen_env"
    Utils.logkv2 "self.args", self.args
    Utils.logkv2 "args", args

    dim rv
    dim newenv
    
    newenv = MalEnv.new_(self.env)

    dim i, arg_name, arg_val
    i = 0
    do while i < MalList.size(self.args)
        ' Utils.logkv3 "gen_env i", i
        arg_name = MalList.get_(self.args, i)

        ' Utils.logkv3 "gen_env 88 arg_name", arg_name
        ' Utils.logkv3 "gen_env 88 arg_name type", type_name_ex(arg_name)

        if MalSymbol.eq_to_str(arg_name, "&") then
            ' Utils.log3 "90 gen_env"
            arg_name = MalList.get_(self.args, i + 1)
            ' Utils.logkv3 "gen_env 93 arg_name", arg_name
            dim opts
            opts = MalList.new_()
            dim i2
            i2 = i
            do while i2 < MalList.size(args)
                ' Utils.logkv3 "gen_env i2", i2
                arg_val = MalList.get_(args, i2)
                MalList.add(opts, arg_val)
                i2 = i2 + 1
            loop
            MalEnv.set_(newenv, arg_name, opts)
            exit do
        end if
        
        arg_val  = MalList.get_(args, i)
        ' Utils.logkv3 "gen_env 89 arg_val", arg_val

        MalEnv.set_(newenv, arg_name, arg_val)
        i = i + 1
    loop

    Utils.logkv3 "103 newenv", newenv
    
    rv = newenv
    MalFunction_gen_env = rv
    
    ' ON_ERROR_CATCH
end function


function clone(self)
    Utils.log2 "-->> MalFunction.clone()"
    Utils.logkv3 "self", self
    ' Utils.logkv3 "self.env", self.env
    ' Utils.logkv3 "self.args", self.args
    ' Utils.logkv3 "self.body", self.body
    dim rv

    rv = MalFunction_new(self.env, self.args, self.body)
    Utils.logkv3 "  95 func clone", rv
    rv.is_macro = self.is_macro

    clone = rv
    Utils.logkv2 "<<-- MalFunction.clone()", rv
end function


function _is_mal_function_obj(val as object) as Boolean
    ' ON_ERROR_TRY
    Utils.log2 "-->> MalFunction.is_mal_function_sub()"
    dim rv

    rv = (val.type_ = "MalFunction")

    _is_mal_function_obj = rv

    ' ON_ERROR_CATCH
end function


function is_mal_function(val as variant) as Boolean
    ' ON_ERROR_TRY
    Utils.log2 "-->> MalFunction.is_mal_function()"
    dim rv
    
    if TypeName(val) <> "Object" then
        is_mal_function = False
        exit function
    end if

    rv = _is_mal_function_obj(val)

    is_mal_function = rv

    ' ON_ERROR_CATCH
end function
