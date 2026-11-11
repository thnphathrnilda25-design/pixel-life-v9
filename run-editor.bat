@echo off
rem Open Pixel Life in the Godot editor
setlocal
set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=godot"
"%GODOT%" --editor --path "%~dp0." %*
