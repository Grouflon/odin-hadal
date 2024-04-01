@echo off

rem CREATE BIN DIR
@mkdir bin > NUL 2> NUL

rem COMPILE
@echo on
odin build ./src -out:bin/hadal.exe -collection:hadal=src -warnings-as-errors -debug
@echo off
if %errorlevel% neq 0 goto error

:end
@echo:
@echo Build done!
exit /b 0

:error
@echo Build failed!
exit /b 1