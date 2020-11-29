rem -*- mode: basic -*-

Option Explicit

function _pr_str(val, optional print_readably as boolean)
  ' Utils.log2 "-->> _pr_str()"
  dim rv

  dim _r
  if IsMissing(print_readably) then
      _r = true
  else
      _r = print_readably
  end if
  
  ' Utils.logkv2("  9 isnull", IsNull(val))
  ' Utils.logkv2("  10 type name", TypeName(val))
  ' Utils.logkv2("  11 type name ex", Type_Name_ex(val))
    
  if IsNull(val) then
    ' Utils.log2("10 isnull => true")
    rv = "nil"
  elseif TypeName(val) = "String" then
      if 1 <= len(val) and char_at(val, 0) = chr(&H029e) then
          rv = ":" + substring(val, 1)
      else
          if _r then
              rv = inspect_str(val)
          else
              rv = val
          end if
      end if

  elseif TypeName(val) = "Integer" then
    rv = "" & val
  elseif TypeName(val) = "Long" then
    rv = "" & val
  elseif TypeName(val) = "Single" then
    rv = "" & val
  elseif TypeName(val) = "Double" then
    ' Utils.log1 "  21 -->> _pr_str()"
    rv = "" & val
  elseif TypeName(val) = "Boolean" then
      if val then
          rv = "true"
      else
          rv = "false"
      end if
  elseif TypeName(val) = "Object" then
    if obj_typename(val) = MalList.type_name then
      ' Utils.logkv1 "19 list size", val.size
      rv = MalList_pr_str(val, _r)
    elseif obj_typename(val) = MalVector.type_name then
      rv = MalVector_pr_str(val, _r)
    elseif obj_typename(val) = MalSymbol.type_name then
      rv = MalSymbol_inspect(val)
    elseif obj_typename(val) = MalMap.type_name then
      rv = MalMap_pr_str(val, _r)
    elseif obj_typename(val) = MalNamedFunction_type_name then
      rv = MalNamedFunction_inspect(val)
    elseif obj_typename(val) = MalFunction.type_name then
      rv = MalFunction_inspect(val)
    elseif obj_typename(val) = MalAtom.type_name then
      rv = MalAtom_inspect(val)
    elseif obj_typename(val) = "Token" then
      ' TODO Token は渡ってこないはずなので消してよさそう
      rv = Token_inspect(val)
    else
      rv = "<unknown_obj (_pr_str)>" & obj_typename(val)
    end if
  else
    rv = "<UNKNOWN> " & TypeName(val)
  end if

  _pr_str = rv
end function
