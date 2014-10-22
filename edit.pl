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

my $id = $GETvars{id};

# write template
my $file = undef;
my $files = {};
my $path = $GETvars{path} || "/";
if(length $path == 0) { $path = "/" }
if(defined $id) {
    $db::sth->{getById}->execute($id);
    my $files = $db::sth->{getById}->fetchall_hashref("id");
    $file = $files->{$id};

    $db::sth->{getAllKeywords}->execute($id);
    my $kws = $db::sth->{getAllKeywords}->fetchall_arrayref([0]);
    my $keywords = join ", ", map { @{$_}[0] } @{$kws};
    $file->{keywords} = $keywords;
}

$file = {
    id => "",
    path => uri_unescape($path),
    title => "",
    keywords => "",
    language => "",
    code => "",
} unless defined $file;

dowrite($file); # TODO parameters

# cleanup

db::closedb();
exit 0;

sub dowrite {
    my ($file) = @_;

    my $qp = uri_escape $file->{path};

    my $id = $file->{id};
    my $title = $file->{title};
    if(length $title < 1) { $title = "<new>" }

    my $titleDrop = "";

    if($id eq "") {
        $titleDrop = <<"EOT" ;
<div title="cancel creation"><h1><a style="color:black;text-decoration:none" href="index.pl?path=$qp">Editing a snippet</a></h1></div>
EOT
    } else {
        $titleDrop = <<"EOT" ;
<div title="cancel edition"><h1><a style="color:black;text-decoration:none" href="view.pl?id=$id">Editing a snippet</a></h1></div>
EOT
    }

    my $template = <<"EOT" ;
Content-Type: text/html; charset=utf-8

<!DOCTYPE html>
<html>
<head>
    <title>Snippet Editor - $title</title>
    <style>
table.formThingy {
    width:100%;
}
    </style>
</head>
<body>
    <form method="POST" name="addNewSnippet" action="save.pl">
        <input name="id" type="hidden" value="$id" />
        <table class="formThingy">
            <colgroup>
                <col style="width:275px" />
                <col style="min-width:800px"/>
            </colgroup>
            <tr>
                <!-- <td><h1>Add a new snippet</h1></td> -->
                <td>$titleDrop</td>
                <td style="text-align:right;min-width:200px"><input type="submit" value="Commit"/></td>
            </tr>
            <tr>
                <td>Title:</td>
                <td><input name="title" style="width:100%" type="text" placeholder="enter a name for your snippet" value="$file->{title}"/></td>
            </tr>
            <tr>
                <td>Keywords:</td>
                <td><input name="keywords" style="width:100%" type="text" placeholder="enter a comma separated list of keywords (optional, but helps searching)" value="$file->{keywords}"/></td>
            </tr>
            <!-- maybe at a later date
            <tr>
                <td>Language:</td>
                <td><select name="language" style="width:100%">
                        <option value="">&lt;autodetect&gt;</option>
                        <option value="C++">C++</option>
                    </select>
                </td>
            </tr> -->
            <tr>
                <td>Path:</td>
                <td><input name="path" style="width:100%" type="text" placeholder="please input a path" value="$file->{path}" /></td>
            </tr>
            <tr>
                <td>Code:</td>
                <td />
            </tr>
            <tr><td colspan="2">
                <textarea name="code" style="width:100%;min-height:200px;font-family:monospace" placeholder="you code here">$file->{code}</textarea>
            </td></tr>
        </table>
    </form>
</body>
EOT

    print $template;
}
