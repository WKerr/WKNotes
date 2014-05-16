Global $oDictionary

;_Main()

Func _Main()
    ; Create dictionary object
    $oDictionary = _InitDictionary()

    Local $vKey, $sItem, $sMsg

    ; Add keys with items
    _AddItem("One", "Same")
    _AddItem("Two", "Car")
    _AddItem("Three", "House")
    _AddItem("Four", "Boat")

    If _ItemExists('One') Then
        ; Display item
        MsgBox(0x0, 'Item One', _Item('One'), 2)
        ; Set an item
        _ChangeItem('One', 'Changed')
        ; Display item
        MsgBox(0x20, 'Did Item One Change?', _Item('One'), 3)
        ; Remove key
        _ItemRemove('One')
        ;
    EndIf

    ; Store items into a variable
    For $vKey In $oDictionary
        $sItem &= $vKey & " : " & _Item($vKey) & @CRLF
    Next

    ; Display items
    MsgBox(0x0, 'Items Count: ' & _ItemCount(), $sItem, 3)

    ; Add items into an array
    $aArray = _GetItems()

    ; Display items in the array
    For $i = 0 To _ItemCount() - 1
        MsgBox(0x0, 'Array [ ' & $i & ' ]', $aArray[$i], 2)
    Next

    _ItemRemove("Two")
    _ItemRemove("Three")
    _ItemRemove("Four")

    ; use keys like an array index
    For $x = 1 To 3
        _AddItem($x, "")
    Next
    $sItem = ""
    _ChangeItem(2,"My Custom Item")
    _ChangeItem(1,"This is the 1st item")
    _ChangeItem(3,"This is the last item")
    For $vKey In $oDictionary
        $sItem &= $vKey & " : " & _Item($vKey) & @CRLF
    Next
    ; Display items
    MsgBox(0x0, 'Items Count: ' & _ItemCount(), $sItem, 3)


EndFunc   ;==>_Main

Func _InitDictionary()
    Return ObjCreate("Scripting.Dictionary")
EndFunc   ;==>_InitDictionary

Func _AddItem($v_key, $v_item)
    $oDictionary.ADD ($v_key, $v_item)
EndFunc   ;==>_AddItem

Func _ItemExists($v_key)
    Return $oDictionary.Exists ($v_key)
EndFunc   ;==>_ItemExists

Func _Item($v_key)
    Return $oDictionary.Item ($v_key)
EndFunc   ;==>_Item

Func _ChangeItem($v_key, $v_item)
    $oDictionary.Item ($v_key) = $v_item
EndFunc   ;==>_ChangeItem

Func _ItemRemove($v_key)
    $oDictionary.Remove ($v_key)
EndFunc   ;==>_ItemRemove

Func _ItemCount()
    Return $oDictionary.Count
EndFunc   ;==>_ItemCount

Func _GetItems()
    Return $oDictionary.Items
EndFunc   ;==>_GetItems