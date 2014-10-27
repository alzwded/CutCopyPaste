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
                  $s =~ s/\+//g;
                  my $pos = index $s, "=";
                  my $key = substr $s, 0, $pos;
                  my $value = uri_unescape(substr $s, $pos + 1);
                  $key => $value
              } split /\&/, $ENV{QUERY_STRING};
#print Dumper \%GETvars;

my $id = $GETvars{id} or die 'missing id';

# write template
$db::sth->{getById}->execute($id);
my $files = $db::sth->{getById}->fetchall_hashref("id");
$db::sth->{getAllKeywords}->execute($id);
my $kws = $db::sth->{getAllKeywords}->fetchall_arrayref([0]);
my $keywords = join ", ", map { @{$_}[0] } @{$kws};

my $file = $files->{$id};
$file->{keywords} = $keywords;

dowrite($files->{$id}); # TODO parameters

# cleanup

db::closedb();
exit 0;

sub dowrite {
    my ($file) = @_;

    my $qp = $file->{path}; #uri_escape $file->{path};

    my $template = <<"EOT" ;
Content-Type: text/html; charset=utf-8

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.3/styles/default.min.css">
    <script src="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.3/highlight.min.js"></script>
    <title>Snippet Viewer - $file->{title}</title>
    <style>
table.formThingy {
    width:100%;
}
    </style>
</head>
<body>
        <table class="formThingy">
            <colgroup>
                <col style="width:275px" />
                <col style="min-width:800px"/>
            </colgroup>
            <tr>
                <td><div title="go to $file->{path}"><h1><a href="index.pl?path=$qp" style="color:black;text-decoration:none">$file->{title}</a></h1></div></td>
                <td style="text-align:right;min-width:200px">
                    <input type="button" style="margin-right:25px" value="Delete" onclick="deleteForever()"/>
                    <a href="edit.pl?id=$file->{id}"><input type="button" value="Edit"/></a>
                </td>
            </tr>
            <tr>
                <td>Keywords:</td>
                <td><input name="keywords" style="width:100%" type="text" readonly placeholder="none" value="$file->{keywords}"/></td>
            </tr>
            <tr>
                <td>Path:</td>
                <td><input name="path" style="width:100%" type="text" readonly placeholder="please input a path" value="$file->{path}" /></td>
            </tr>
            <tr>
                <td>Code:</td>
                <td />
            </tr>
            <tr><td colspan="2">
                <pre><code name="code" style="width:auto;left:0px;right:0px;min-height:200px;font-family:monospace">$file->{code}</code></pre>
            </td></tr>
        </table>

    <script>
hljs.initHighlightingOnLoad()

function deleteForever(e) {
    if(window.confirm("Are you sure you want to permanently delete '$file->{title}'?")) {
        // delete.pl should redirect back to index.pl with the current path
        window.location.href = "delete.pl?id=$file->{id}"
    }
}
    </script>
</body>
EOT

    print $template;
}
