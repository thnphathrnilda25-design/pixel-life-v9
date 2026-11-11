@echo off
rem Launch Pixel Life (Godot game)
setlocal
set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=godot"
"%GODOT%" --path "%~dp0." %*
