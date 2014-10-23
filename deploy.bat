@echo on
@REM I want to see everything

IF #%CCPTARGET%# == ## GOTO :notDefined
IF #%PERLSITEDIR%# == ## GOTO :notDefined

robocopy . "%CCPTARGET%" delete.pl edit.pl index.pl save.pl search.pl view.pl 

@REM yeah, couldn't figure out what the cwd of a script actually is
@REM so just dump that in <perl>/site/lib
robocopy . "%PERLSITEDIR%" db.pm

goto :EOF

:notDefined
echo one of CCPTARGET or PERLISTEDIR are not defined

:EOF
