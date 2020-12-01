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

    if IsNull(val) then
      rv = "nil"
      _pr_str = rv
      Exit Function
    End If

    Dim tn As String
    tn = TypeName(val)

    If tn = "String" then
        If Keyword_is_keyword(val) Then
            rv = ":" + substring(val, 1)
        else
            if _r then
                rv = inspect_str(val)
            else
                rv = val
            end if
        end if

    elseif tn = "Integer" then
      rv = "" & val
    elseif tn = "Long" then
      rv = "" & val
    elseif tn = "Single" then
      rv = "" & val
    elseif tn = "Double" then
      rv = "" & val
    elseif tn = "Boolean" then
        if val then
            rv = "true"
        else
            rv = "false"
        end if
    elseif tn = "Object" then
      Dim otn As String
      otn = obj_typename(val)

      if otn = MalList.type_name then
        rv = MalList_pr_str(val, _r)
      elseif otn = MalVector.type_name then
        rv = MalVector_pr_str(val, _r)
      elseif otn = MalSymbol.type_name then
        rv = MalSymbol_inspect(val)
      elseif otn = MalMap.type_name then
        rv = MalMap_pr_str(val, _r)
      elseif otn = MalNamedFunction_type_name then
        rv = MalNamedFunction_inspect(val)
      elseif otn = MalFunction.type_name then
        rv = MalFunction_inspect(val)
      elseif otn = MalAtom.type_name then
        rv = MalAtom_inspect(val)
      else
        rv = "<unknown_obj> " & otn
      end if
    else
      rv = "<unknown> " & tn
    end if

    _pr_str = rv
end function
