#!/bin/csh

if($gid != 0) then
    echo not root, will probably fail
endif

if($CCPTARGET:q == "") then
    echo no deployment target
    exit 2
endif

install -g www-data -o www-data -m 644 index.pl edit.pl view.pl search.pl save.pl delete.pl $CCPTARGET:q
