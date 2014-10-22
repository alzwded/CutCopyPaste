#!/usr/bin/perl -w

use CGI::Carp qw/fatalsToBrowser/;
use strict;
use Data::Dumper;
use URI::Escape;

use db;

my $dbh = db::opendb();

# get variables
my %GETvars = map {
                  my $s = $_;
                  my $pos = index $s, "=";
                  my $key = substr $s, 0, $pos;
                  my $value = uri_unescape(substr $s, $pos + 1);
                  $key => $value
              } split /\&/, $ENV{QUERY_STRING};
#print Dumper \%GETvars;

my $path = $GETvars{path} or "/";
$path =~ s#/+#/#g;
if($path ne "/" && $path !~ m#^/..*/$#) {
    if($path !~ m#^.*/$#) {
        $path .= "/";
    }
    if($path !~ m#^/.*$#) {
        $path = "/" . $path;
    }
}

# write template
$db::sth->{getUnderCurrentPath}->execute("$path%");
my $files = $db::sth->{getUnderCurrentPath}->fetchall_hashref("id");

dowrite($path, $files); # TODO parameters

# cleanup

db::closedb();
exit 0;

sub dowrite {
    my ($path, $files) = @_;

    # break path down
    my @pathElements = map { $_."/" } split /\//, $path;
    #print $#pathElements;
    if($#pathElements < 0) { @pathElements = ("/") }
    #print Dumper @pathElements;
    # - generate navigation links
    my $navLinks = "";
    my $rebuiltPath = "";
    foreach (@pathElements) {
        my $p = $_;
        $rebuiltPath .= $p;
        my $qp = uri_escape($rebuiltPath);
        $navLinks .= <<"EOT" ;
<a href="?path=$qp">$p</a>
EOT
    }

    # generate file content
    # - extract subdirectories
    # - filter files to only current directory

    my %subDirs = ();
    my @filteredFiles = ();

    foreach (keys %{$files}) {
        my $file = $files->{$_};
        if($file->{path} =~ m#^${path}([^/]*)/.*$#) {
            $subDirs{$1} = 1;
        } elsif($file->{path} =~ m#^${path}([^/]*)$#) {
            push @filteredFiles, $file;
        }
    }

    my $subDirHTML = "";
    foreach (sort keys %subDirs) {
        my $p = $_;
        my $qp = uri_escape "${path}$p/";
        $subDirHTML .= <<"EOT" ;
<tr><td class="dir"><a href="?path=$qp">[$p]</a></tr></td>
EOT
    }

    my $fileHTML = "";
    foreach (@filteredFiles) {
        my $file = $_;
        $fileHTML .= <<"EOT" ;
<tr><td class="snip"><a href="view.pl?id=$file->{id}">$file->{title}</a></tr></td>
EOT
    }

    my $template = <<"EOT" ;
<!DOCTYPE html>
<html>
<head>
    <title>Snippet directory</title>
    <style>
table.directory {
    width: 100%;
}

table.directory td {
    width: 100%;
    cursor: pointer;
    background-color: #CCC;
}

table.directory td.dir {
}

table.directory td.dir a {
    text-decoration: none;
    color: inherit;
}

table.directory td.snip {
    background-color: #CDC;
}

table.directory td.snip a {
    text-decoration: none;
    color: inherit;
}

#currentPath a {
    padding-left: 3px;
}
    </style>
</head>
<body>
    <table style="width:100%">
        <!-- meta controls -->
        <tr><td>
            <table style="width:100%">
                <tr>
                    <td style="">
                        <a href="edit.pl?path=/General/CommonSnippets/"><input type="button" value="Add new snippet" /></a><span style="padding-left:25px">Current path:</span><span id="currentPath" style="font-family:monospace">$navLinks</span>
                    </td>
                    <td style="text-align:right">
                        <table style="width:100%">
                            <tr><td>
                                <span style="display:block;min-width:200px;width:200px;max-width:200px;float:right"><input type="text" placeholder="search" style="width:100%"/></span>
                            </tr></td>
                            <tr><td>
                                <span style="display:block;min-width:200px;width:200px;max-width:200px;float:right"><input type="checkbox" />search inside code snippets</span>
                            </td></td>
                        </table>
                    </td>
                </tr>
            </table>
        </td></tr>
        <!-- the actual directory -->
        <tr><td>
            <table class="directory">
                $subDirHTML
                $fileHTML
            </table>
        </td</tr>
    </table>
</body>
EOT

    print $template;
}