;gui_embedded.au3

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <IE.au3>
#include <String.au3>

#include <SQLite.au3>
#include <SQLite.dll.au3>

_IEErrorHandlerRegister()

;CHANGE IE VERSION
#cs
RegRead ( "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION", @ScriptName )
if @error then
	MsgBox(0,@ScriptName,"Reg key doesn't exist #"& @error)
	RegWrite ( "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION" ,@ScriptName , "REG_DWORD" )
	RegWrite ( "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION" ,@ScriptName , "REG_DWORD", "0x22B8" )
	if @error Then
		MsgBox(0,"REG","Reg couldn't be written #"& @error)
	endif
EndIf
#ce
Local $oIE = _IECreateEmbedded()
local Const $GUIHEIGHT = 580
local Const $GUIWIDTH =  640
GUICreate("Personal Note Tracker", $GUIWIDTH, $GUIHEIGHT, _
      (@DesktopWidth - $GUIWIDTH) / 2,  (@DesktopHeight - $GUIHEIGHT) / 2, _
           $WS_VISIBLE )
; $WS_VISIBLE --> Createa window that is initially visible.
; $WS_OVERLAPPEDWINDOW --> Creates an overlapped window with the WS_OVERLAPPED, WS_CAPTION, WS_SYSMENU, WS_THICKFRAME, WS_MINIMIZEBOX, and WS_MAXIMIZEBOX styles. Same as the WS_TILEDWINDOW style.
; $WS_CLIPSIBLINGS -->
; $WS_CAPTION

GUICtrlCreateObj($oIE, 0, 0, $GUIWIDTH , $GUIHEIGHT)
GUICtrlSetResizing(-1,1)
GUISetState() ;Show GUI

Local $oDictionary = ObjCreate("Scripting.Dictionary")

    ; Add keys with items
    $oDictionary.ADD("main", "list.html")
    $oDictionary.ADD("login", "login.html")
    $oDictionary.ADD("addNote", "addNote.html")



_IENavigate($oIE, @ScriptDir&"\resources\index.html")
;alert(getCurrentPage($oIE))
; PREVENT THE USER FROM SELECTING RIGHT CLICK
;_IEHeadInsertEventScript ($oIE, "document", "oncontextmenu", ";return false")

; Waiting for user to close the window

OnAutoItExitRegister ( "CleanUp" )



local $htmlInit = False
guiEventLoop($oIE)
Func guiEventLoop($oIE)

	__sqliteConnect()
	 _startUp()

	;PASS BY REFERENCE VARIABLES
	local $guiCurrent = "list.html"
	local $noteID = 0

	While 1

		Local $msg = GUIGetMsg()
			Switch $msg
				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch

			Switch $guiCurrent
				Case "login.html"
					HTML_Login($oIE, $guiCurrent)
				Case "addNote.html"
					HTML_addNote($oIE, $guiCurrent )
				Case "list.html"
					HTML_List($oIE, $guiCurrent, $noteID)
				case "viewNote.html"
					HTML_viewNote($oIE, $guiCurrent , $noteID)
			EndSwitch

		;$guiCurrent = getCurrentPage($oIE)

		sleep(1)
	WEnd
	Exit
EndFunc

Func HTML_viewNote($oIE, ByRef $guiCurrent, ByRef $noteID)

	; Initiallization
	if (not $htmlInit) Then
		ConsoleWrite("NoteID ==> " & $noteID)

		local $noteJSON = ""
		local $hQuery,$rs
		local $hNoteDb = _SQLite_Open("wknotes.db") ; Creates a database
		_SQLite_Query($hNoteDb, "SELECT * FROM notes WHERE id = "&$noteID&";", $hQuery) ; the query
		While _SQLite_FetchData($hQuery, $rs, False, False) = $SQLITE_OK ; Read Out the next Row
			if $noteJSON <> "" then $noteJSON = $noteJSON & ','
			$noteJSON = $noteJSON & ' {"text":"'&$rs[0]&'","id":'&$rs[1]&', "title": "'&$rs[2]&'", "description": "'&$rs[3]&'", "status":"'&$rs[4]&'","sDateTime":"'&$rs[5]&'","eDateTime":"'&$rs[6]&'"}'
		WEnd
		_SQLite_Close($hNoteDb)

		ConsoleWrite($noteJSON &@CRLF)
		Local $htmlfile = FileOpen(@ScriptDir&"\resources\viewNote.html", 0)
		local $htm=FileRead($htmlfile) ; Read in our main html file
		FileClose($htmlfile)

		; Inject out enhanced script into the html
		$htm=StringReplace($htm,'%noteInfo%',$noteJSON)

		; write the html and js as a unit
		_IEDocWriteHTML($oIE,$htm)
		_IEAction($oIE, "refresh")

		$htmlInit = not $htmlInit
	EndIf

	; Add Note Button
	if ( int(getIdValue($oIE,"onAddNote")) > 0 ) then
		ConsoleWrite("onAddNote ==> Pressed" &@CRLF)

		local $updateID = int(getIdValue($oIE,"noteID"))
		local $ObjText = _IEGetObjById($oIE,"noteText")
		local $updateText = _IEPropertyGet($ObjText,"innertext")
		ConsoleWrite($updateText &@CRLF)

		$hNoteDb = _SQLite_Open("wknotes.db") ; Creates a database
		_SQLite_Exec($hNoteDb, "UPDATE notes SET text='"&$updateText&"' WHERE id = "&$updateID&";") ; the query
		_SQLite_Close($hNoteDb)

		$htmlInit = False
		$guiCurrent = "list.html"
		;_IENavigate($oIE, @ScriptDir&"\resources\index.html")
	endIf

	; On Close
	if getIdValue($oIE,"onClose") = "1" then
		ConsoleWrite("onClose ==> Pressed" &@CRLF)
		_IENavigate($oIE, @ScriptDir&"\resources\index.html")
		$htmlInit = False
		$guiCurrent = "list.html"
	endIf

EndFunc

Func HTML_addNote($oIE, ByRef $guiCurrent)

	if (not $htmlInit) Then
		_IENavigate($oIE, @ScriptDir&"\resources\addNote.html")
		$htmlInit = not $htmlInit
	EndIf

	if getIdValue($oIE,"onAddNote") = "1" then
		ConsoleWrite("onAddNote ==> Pressed" &@CRLF)

		;local $updateID = int(getIdValue($oIE,"noteID"))
		local $valueTitle = getIdValue($oIE,"title")
		local $valueDescription = getIdValue($oIE,"description")
		local $valueStatus = getIdValue($oIE,"status")
		local $valueDateAdded = getIdValue($oIE,"dateAdded")
		local $valueDateCompleted = getIdValue($oIE,"dateCompleted")

		local $hNoteDb = _SQLite_Open("wknotes.db") ; Creates a database
		_SQLite_Exec($hNoteDb, "INSERT INTO notes (title,description,status,sDateTime) VALUES ('"&$valueTitle&"','"&$valueDescription&"','P',datetime('now'));") ; the query
		_SQLite_Close($hNoteDb)

		$htmlInit = False
		$guiCurrent = "list.html"
		;_IENavigate($oIE, @ScriptDir&"\resources\index.html")


		;_IENavigate($oIE, @ScriptDir&"\resources\index.html")
		$htmlInit = False
		$guiCurrent = "list.html"
	endIf

	if getIdValue($oIE,"onClose") = "1" then
		ConsoleWrite("onClose ==> Pressed" &@CRLF)
		_IENavigate($oIE, @ScriptDir&"\resources\index.html")
		$htmlInit = False
		$guiCurrent = "list.html"
	endIf

EndFunc

Func HTML_List($oIE, ByRef $guiCurrent ,ByRef $noteID)

	if (not $htmlInit) Then

		local $noteJSON = ""
		local $hQuery,$rs
		local $hNoteDb = _SQLite_Open("wknotes.db") ; Creates a database
		_SQLite_Query($hNoteDb, "SELECT * FROM notes ORDER BY id;", $hQuery) ; the query
		While _SQLite_FetchData($hQuery, $rs, False, False) = $SQLITE_OK ; Read Out the next Row
			if $noteJSON <> "" then $noteJSON = $noteJSON & ','
			$noteJSON = $noteJSON & ' {"text":"'&$rs[0]&'","id":'&$rs[1]&', "title": "'&$rs[2]&'", "description": "'&$rs[3]&'", "status":"'&$rs[4]&'","sDateTime":"'&$rs[5]&'","eDateTime":"'&$rs[6]&'"}'
		WEnd
		_SQLite_Close($hNoteDb)

		Local $htmlfile = FileOpen(@ScriptDir&"\resources\list.html", 0)
		local $htm=FileRead($htmlfile) ; Read in our main html file
		FileClose($htmlfile)

		; Inject out enhanced script into the html
		$htm = StringReplace($htm,'%noteList%',$noteJSON)

		; write the html and js as a unit
		_IEDocWriteHTML($oIE,$htm)
		_IEAction($oIE, "refresh")

		$htmlInit = not $htmlInit
	EndIf

	if getIdValue($oIE,"onClose") = "1" then
		ConsoleWrite("onClose ==> Pressed" &@CRLF)
		Exit
	endIf

	if getIdValue($oIE,"onAddNote") = "1" then
		ConsoleWrite("onAddNote ==> Pressed" &@CRLF)
		$htmlInit = False
		$guiCurrent = "addNote.html"
	endIf

	if int(getIdValue($oIE,"onEditNote")) > 0 Then
		ConsoleWrite("onEditNote ==> Pressed #"& getIdValue($oIE,"onEditNote") &@CRLF)
		$htmlInit = False
		$guiCurrent = "viewNote.html"
		$noteID = getIdValue($oIE,"onEditNote")
	EndIf

EndFunc

Func HTML_Login($oIE, ByRef $guiCurrent)

	; EVENT HANDLER FOR THE LOGIN SCREEN
	if getIdValue($oIE,"onClose") = "1" then
		ConsoleWrite("onClose ==> Pressed" &@CRLF)
		Exit
	endIf

	if getIdValue($oIE,"onLogin") <> "1" then
		ConsoleWrite("Login button pressed" &@CRLF)
		Return False
	EndIf

	; GET THE NAME VALUE AND CHECK IF NOT EMPTY
	if getIdValue($oIE,"name") = "" then
		setIdValue($oIE,"onLogin","0")
		Return
	EndIf

	if getIdValue($oIE,"password") = "" then
		setIdValue($oIE,"onLogin","0")
		Return
	EndIf

	Alert("Candidate passes")
	_IENavigate($oIE, @ScriptDir&"\main.html")

EndFunc

;Simplified message alert box
Func alert($msg)
	MsgBox(48,"Alert",$msg)
EndFunc

;Internal functions to get the current html page.
Func getCurrentPage($oIE)
	return StringRegExpReplace(_IEPropertyGet($oIE, "locationurl"),"^.*\/","")
EndFunc

Func getCurrentPageFull($oIE)
	return _IEPropertyGet($oIE, "locationurl")
EndFunc

Func getIdValue($oIE,$s_Id)
	local $objForm = _IEGetObjById($oIE, $s_Id)
	return _IEFormElementGetValue($objForm)
EndFunc

Func setIdValue($oIE,$s_Id,$s_newvalue)
	local $objForm = _IEGetObjById($oIE, $s_Id)
	_IEFormElementSetValue($objForm,$s_newvalue)
EndFunc

Func __sqliteConnect()
	_SQLite_Startup("sqlite3.dll")
	If @error Then
			MsgBox(16, "SQLite Error", "SQLite.dll Can't be Loaded!")
			Exit -1
	EndIf
	ConsoleWrite("_SQLite_LibVersion=" & _SQLite_LibVersion() & @CRLF)
EndFunc

Func __sqliteOpen()
	$hNoteDb = _SQLite_Open("wknotes.db") ; Open a database
	If @error Then
		MsgBox(16, "SQLite Error", "Can't link to database!")
		Exit -1
	EndIf
	return $hNoteDb
EndFunc

Func _startUp()

	;check if db exists... if not create a new one.
	if not FileExists("wknotes.db") then
		local $hNoteDb = __sqliteOpen()
		_SQLite_Exec($hNoteDb, "CREATE TABLE notes IF NOT EXISTS (text TEXT, id INTEGER PRIMARY KEY, title CHAR(50), description CHAR(50), status CHAR(5), sDateTime datetime, eDateTime datetime);")
		_SQLite_Close($hNoteDb)
	EndIf

EndFunc

Func CleanUp()
	GUIDelete()
	_SQLite_Shutdown()
EndFunc





