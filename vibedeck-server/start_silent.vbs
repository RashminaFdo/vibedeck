Set WshShell = CreateObject("WScript.Shell")
scriptPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = scriptPath
pythonwPath = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%\Python\pythoncore-3.14-64\pythonw.exe")
If CreateObject("Scripting.FileSystemObject").FileExists(pythonwPath) Then
    WshShell.Run """" & pythonwPath & """ tray_app.py", 0, False
Else
    WshShell.Run "pythonw tray_app.py", 0, False
End If
Set WshShell = Nothing
