rem -*- mode: basic -*-

Option Explicit

dim env_id_max as integer

sub MalEnv_setup
    env_id_max = 0
end sub

type MalEnv
    type_ as string
    data as variant
    outer as variant
    id as Integer
end type


function new_(optional outer)
    dim rv as New MalEnv

    rv.type_ = MalEnv.type_name
    rv.data = MalMap.new_()

    rv.id = env_id_max + 1
    env_id_max = env_id_max + 1

    if IsMissing(outer) then
        rv.outer = null
    else
        rv.outer = outer
    end if

    new_ = rv
end function


Function type_name As String
    type_name = "MalEnv"
End Function


function find(self, key)
    ' Utils.log3 "-->> MalEnv.find"
    dim rv
    rv = null

    if MalMap.has_key(self.data, key) then
        rv = self
    end if

    if isNull(rv) then
        if not IsNull(self.outer) then
            rv = find(self.outer, key)
        end if
    elseif isEmpty(rv) then
        if not IsNull(self.outer) then
            rv = find(self.outer, key)
        end if
    end if

    find = rv
end function


function set_(self, key, value)
    ' Utils.log2 "-->> MalEnv.set_()"
    dim rv
    
    Dim tn As String ' type name
    tn = type_name_ex(key)

    if tn = "String" then
        MalMap.put(self.data, key, value)
    elseif tn = MalSymbol.type_name then
        MalMap.put(self.data, key, value)
    elseif tn = MalNamedFunction.type_name then
        MalMap.put(self.data, key, value)
    else
        panic "not yet implemented (MalEnv.set_)"
    end if

    rv = value
    set_ = rv
end function


function get_(self, key)
    ' Utils.log3 "-->> MalEnv.get_()"
    dim rv

    dim env
    env = MalEnv.find(self, key)

    if IsEmpty(env) or IsNull(env) then
        Core.throw "'" & inspect(key) & "' not found"
        ' CHECK_MAL_ERROR
    end if

    rv = MalMap.get_(env.data, key)

    get_ = rv
end function


function has_key(self, k) as boolean
    has_key = MalMap.has_key(self.data, k)
end function


function MalEnv_inspect(self)
    dim rv

    dim outer
    if IsNull(self.outer) then
        outer = ", outer:null"
    else
        outer = ", outer: " & inspect(self.outer)
    end if

    rv = "{ "
    rv = rv & "id: " & int_to_s(self.id)
    rv = rv & ", data: " & MalMap_inspect(self.data)
    rv = rv & outer
    rv = rv & " }"

    MalEnv_inspect = rv
end function
