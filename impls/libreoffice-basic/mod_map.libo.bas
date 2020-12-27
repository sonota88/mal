rem -*- mode: basic -*-

Option Explicit

type MalMap
    data as Variant ' com.sun.star.container.XMap
    type_ as String
    meta as Variant
end type

function new_
    dim rv as New MalMap

    rv.data = com.sun.star.container.EnumerableMap.create("string", "any")
    rv.type_ = type_name

    new_ = rv
end function


Function type_name As String
    type_name = "MalMap"
End Function


function get_(self, k)
    ' Utils.log1 "-->> MalMap.get_()"
    dim rv

    dim str_key
    str_key = _to_map_key(k)
    
    if self.data.containsKey(str_key) then
        rv = self.data.get(str_key)
    else
        rv = null
    end if
    
    get_ = rv
end function


function has_key(self, k) as Boolean
    'Utils.log1 "-->> MalMap.has_key()"
    has_key = self.data.containsKey(_to_map_key(k))
end function


sub put(self, k, v)
    ' Utils.log2 "-->> MalMap.put()"

    self.data.put(_to_map_key(k), v)
end sub


function get_keys(self)
    ' ON_ERROR_TRY

    Utils.log1 "-->> MalMap.get_keys()"

    dim key_iter, str_key, keys
    keys = MalList.new_()
    key_iter = self.data.createKeyEnumeration(False)
    While key_iter.hasMoreElements()
      str_key = key_iter.nextElement()
      Utils.log1 str_key
      MalList.add(keys, _from_map_key(str_key))
    WEnd

    get_keys = keys

    ' ON_ERROR_CATCH
end function



function get_vals(self)
    ' ON_ERROR_TRY

    Utils.log1 "-->> get_vals()"
    
    dim rv

    dim iter, val, vals
    vals = MalList.new_()
    iter = self.data.createValueEnumeration(False)
    While iter.hasMoreElements()
      val = iter.nextElement()
      MalList.add(vals, val)
    WEnd

    rv = vals
    get_vals = rv

    ' ON_ERROR_CATCH
end function


function MalMap_inspect(self)
    ' ON_ERROR_TRY
    ' Utils.log1 "-->> MalMap.inspect()"

    dim rv

    dim str, keys
    str = "{"

    keys = get_keys(self)

        dim i, key
    for i = 0 to MalList.size(keys) - 1
        key = MalList.get_(keys, i)

        if 1 <= i then
            str = str & ", "
        end if

        str = str & Utils.inspect(key)
        str = str & ": "
        dim val
        val = get_(self, key)
        str = str & Utils.inspect(val)
    next

    str = str & "}"

    rv = str

    MalMap_inspect = rv

    ' ON_ERROR_CATCH
end function


function MalMap_pr_str(self2 as object, print_readably as Boolean)
    ' ON_ERROR_TRY
    ' Utils.log1 "-->> MalMap_pr_str()"

    dim rv

    dim _r
    _r = print_readably
    
    dim str
    str = "{"

    dim keys
    keys = MalMap.get_keys(self2)
    dim i, key
    for i = 0 to MalList.size(keys) - 1
        key = MalList.get_(keys, i)
        
        if 1 <= i then
            str = str & " "
        end if

        str = str & _pr_str(key, _r)
        str = str & " "
        dim val
        val = get_(self2, key)
        str = str & _pr_str(val, _r)
    next
    
    str = str & "}"
    rv = str

    MalMap_pr_str = rv

    ' ON_ERROR_CATCH
end function


function _to_map_key(val) as String
    'Utils.log1 "-->> MalMap._to_map_key()"
    dim rv

    select case type_name_ex(val)
        case MalSymbol.type_name
            rv = MalSymbol_to_map_key(val)
        case "String"
            if Keyword_is_keyword(val) then
                rv = Keyword_to_map_key(val)
            else
                rv = String_to_map_key(val)
            end if
        case MalNamedFunction.type_name
            rv = MalNamedFunction_to_map_key(val)
        case else
            panic "not_yet_impl"
    end select

    _to_map_key = rv
end function


function _from_map_key(key) ' TODO rename => str_key
    ' Utils.log1 "-->> _from_map_key()"
    dim rv
    dim str

    if left(key, 4) = "str:" then
        rv = substring(key, 4)
    elseif left(key, 4) = "sym:" then
        str = substring(key, 4)
        rv = MalSymbol.new_(str)
    elseif left(key, 3) = "kw:" then
        str = substring(key, 3)
        rv = kw_marker() & str
    end if

    _from_map_key = rv

    ' _from_map_key = Reader.read_str(key)
end function


function String_to_map_key(str) as String
    'Utils.log1 "-->> String_to_map_key"
    String_to_map_key = "str:" & str
end function


function MalSymbol_to_map_key(sym) as String
    'Utils.log1 "-->> MalSymbol_to_map_key"
    MalSymbol_to_map_key = "sym:" & sym.str
end function


function Keyword_to_map_key(kw) as String
    'Utils.log1 "-->> Keyword_to_map_key"
    Keyword_to_map_key = "kw:" & substring(kw, 1)
end function


function MalNamedFunction_to_map_key(fname) as String
    'Utils.log1 "-->> MalNamedFunction_to_map_key"
    MalNamedFunction_to_map_key = "fun:" & fname.id
end function


function is_map(val)
    ' Utils.log1 "-->> is_map()"
    dim rv
    
    rv = type_name_ex(val) = MalMap.type_name

    is_map = rv
end function


function delete(self, key)
    self.data.remove(_to_map_key(key))
    delete = null
end function


function clone(self)
    ' Utils.log1 "-->> clone()"
    dim rv
    
    dim newmap
    bewmap = MalMap.new_()
    
    dim keys
    keys = MalMap.get_keys(self)

    dim i as integer
    dim k, v
    for i = 0 to MalList.size(keys) - 1
        k = MalList.get_(keys, i)
        if not _is_deleted(k) then
            v = MalMap.get_(self, k)
            MalMap.put(newmap, k, v)
        end if
    next
    
    rv = map
    clone = rv
end function
