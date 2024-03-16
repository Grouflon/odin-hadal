@echo off

rem CREATE BIN DIR
@mkdir bin > NUL 2> NUL

rem COMPILE
@echo Building...
odin build ./src -out:bin/hadal.exe -warnings-as-errors -debug
@echo Build done!