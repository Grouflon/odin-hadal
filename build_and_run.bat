@echo off

@call build.bat
if %errorlevel% neq 0 goto error

:run
@echo:
@echo Running...
@bin\\hadal.exe
exit /b 0

:error
exit /b 1
