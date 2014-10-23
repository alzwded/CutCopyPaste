CutCopyPaste
============

cgi app that holds a bunch of code snippets, ready to be cut/copy/paste'd

See [NOTES.md](https://github.com/alzwded/CutCopyPaste/blob/master/NOTES.md)

Example deployment on windows
-----------------------------

There are approximately 3 dependencies:

* an http server with cgi support
* a perl distribution
* the `DBD::SQLite` driver for perl
* `sqlite3` (for setting up the database; you can do this with anything that can create an sqlite3 database)

To fulfill these, here are examples you can use:

* for the server, `lighttpd` found [here](https://code.google.com/p/wlmp-project/downloads/detail?name=LightTPD-1.4.30-4-IPv6-Win32-SSL.zip&can=2&q=)
* for perl, `Strawberry Perl` found [here](http://strawberryperl.com/download/5.20.1.1/strawberry-perl-5.20.1.1-64bit-PDL.zip)
* the SQLite driver can be found on CPAN

### Setting up perl

1. Grab StrawberryPerl
2. Extract it somewhere (e.g. `d:\strawberryperl`)
3. Make it possible to launch perl with the environment set up
   * either launch the server from the portable shell
   * or create a wrapper around `portableshell.bat` that also proceeds to launch perl (you can name it `portableshell-perl.bat` or something like that)
   * or do a full install of strawberry perl to have it injected into your user's default environment
   * or you can set up the server's environment (using `setenv.add-environment`; see below) to achieve the same effect

### Setting up DBD::SQLite

```
$ cpan
cpan> instal DBD::SQLite
```

### Setting up the database

Fire up sqlite3 or some other sqlite3 database creation tool and source `schema.sql`. You can save it somewhere handy (which is also accessible by the web server) like `d:\CutCopyPasteDB.sqlite3`.

### Setting up lighttpd

1. Grab the distribution
2. Extract it somewhere (e.g. `d:\lighttpd`)
3. open up `conf/lighttpd.conf`
   * enable `mod_cgi` and `mod_setenv`
   * set up `mod_cgi` to enable perl (`cgi.assign = (".pl" => "d:\strawberryperl\portableshell-perl.bat")` or `cgi.assign = (".pl" => "perl")` if you have perl set up to work without any launcher)
   * set up the `CCPDATABASE` environment variable (`setenv.add-environment += ( "CCPDATABASE" => "D:\CutCopyPasteDB.sqlite3" )`)
   * set up a port the server will run on (e.g. `server.port = 8081`)
4. deploy the things
    
   ```
   set CCPTARGET=d:\lighttpd\htdocs
   set PERLSITEDIR=d:\strawberryperl\perl\site\lib
   deploy
   ```

5. Launch lighttpd

You can now go to `http://*machinename*:*portnumber*` (e.g. `http://localhost:8081/`) and see if it works. It may or may not work. This was implemented in a hurry and not very tested. If you find bugs either a) create a pull request with the fix b) complain about it [here](http://github.com/alzwded/CutCopyPaste/issues).

Example deployment on linux
---------------------------

TODO not implemented

Well, it's actually very similar to the windows deployment, it's just that you can install everything using your distro's package manager and perl can source modules straight from the /var/www directory; you also need to set some r/w permissions for the database in addition; also, the configuration may or may not be based on `systemd` or using modern `rc.d` scripts. You can figure it out. It's linux, everything's easy if you know vim or emacs personally.
