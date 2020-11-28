' -*- mode: basic -*-

Option Explicit

function get_active_sheet
  get_active_sheet = ThisComponent.CurrentController.ActiveSheet
end function


function get_shape_by_name(name)
  dim sh, dp, count, i, shape
  set sh = get_active_sheet()
  dp = sh.Drawpage
  count = dp.Count

  dim target_i
  For i = 0 to count - 1
    shape = dp.getByIndex(i)
    If shape.Name = name then
       target_i = i
    end If
  next i

  get_shape_by_name = dp.getByIndex(target_i)
end function


Function get_ri_max(sheet_name As String)
    Dim rv

    Dim sheet
    sheet = ThisComponent.Sheets.getByName(sheet_name)
    
    Dim range
    range = sheet.getCellRangeByName("A1")

    Dim cursor ' SheetCellCursor
    cursor = sheet.createCursorByRange(range)

    cursor.gotoEndOfUsedArea(True)
    rv = cursor.Rows.Count - 1

    get_ri_max = rv
End Function


Function get_ci_max(sheet_name As String)
    Dim rv

    Dim sheet
    sheet = ThisComponent.Sheets.getByName(sheet_name)
    
    Dim range
    range = sheet.getCellRangeByName("A1")

    Dim cursor ' SheetCellCursor
    cursor = sheet.createCursorByRange(range)

    cursor.gotoEndOfUsedArea(True)
    rv = cursor.Columns.Count - 1

    get_ci_max = rv
End Function


Function cell_get(sheet_name, ci, ri)
    Dim rv

    dim sheet
    sheet = ThisComponent.Sheets.getByName(sheet_name)

    dim cell
    cell = sheet.getCellByPosition(ci, ri)

    select case cell.getType()
        case com.sun.star.table.CellContentType.EMPTY
            rv = null
        case com.sun.star.table.CellContentType.VALUE
            rv = cell.Value
        case com.sun.star.table.CellContentType.TEXT
            rv = cell.String
        case com.sun.star.table.CellContentType.FORMULA
            rv = cell.Formula
        case else
            __ERR__
            'retval = "must not happen"
    end select

    cell_get = rv
End Function


Sub cell_set(sheet_name, ci, ri, value)
    Dim sheet
    sheet = ThisComponent.Sheets.getByName(sheet_name)

    Dim cell
    cell = sheet.getCellByPosition(ci, ri)

    cell.formula = value
End Sub
