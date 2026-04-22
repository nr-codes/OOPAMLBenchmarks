@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "CLOC=.\src\cloc-2.08.exe"
set "EXCL1=__pycache__,examples,external_libs"
set "EXCL2=%EXCL1%,cpp"
set "INCL1=--by-file-by-lang"
set "INCL2=--read-lang-def=src/ampl_definitions.txt %INCL1%"
set "OUT=--out=.\out"

tar -xf .\oop\horizon.zip
"%CLOC%" %INCL1% %OUT%\tol_oop.txt --exclude-dir="%EXCL2%" horizon
rmdir /s /q horizon

"%CLOC%" %INCL1% %OUT%\spot_jump_oop.txt oop\spot_jump.py
"%CLOC%" %INCL1% %OUT%\cart_pole_swing_oop.txt oop\cart_pole_swing.py

"%CLOC%" %INCL2% %OUT%\tol_aml.txt aml\aml-tol.mod

"%CLOC%" %INCL2% %OUT%\spot_jump_aml.txt aml\spot_jump.mod aml\spot_jump.run
"%CLOC%" %INCL2% %OUT%\cart_pole_swing_aml.txt aml\cart_pole_swing.mod aml\cart_pole_swing.run
