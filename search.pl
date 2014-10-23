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
              } split /\&/, ($ENV{QUERY_STRING} or "");
#print Dumper \%GETvars;

my $path = $GETvars{path} || "/";
$path =~ s#/+#/#g;
if($path ne "/" && $path !~ m#^/..*/$#) {
    if($path !~ m#^.*/$#) {
        $path .= "/";
    }
    if($path !~ m#^/.*$#) {
        $path = "/" . $path;
    }
}

my $q = $GETvars{q};
print Dumper $q;
my @qs = map { split /\s+/, $_ } map { my $nq = $_; $nq =~ s/^\s+//; $nq =~ s/\s+$//; $nq } split /,/, $q;
print Dumper \@qs;
my $everywhere = $GETvars{everywhere};
if(defined($everywhere) && $everywhere eq "on") { $path = "/" }

# execute queries and whatnot
# 1. matching title
my @reses = ();
$db::sth->{searchMatchingTitle}->execute("$path%", "$q");
push @reses, $db::sth->{searchMatchingTitle}->fetchall_hashref("id");
# 2. partial match of title
$db::sth->{searchMatchingTitle}->execute("$path%", "%$q%");
push @reses, $db::sth->{searchMatchingTitle}->fetchall_hashref("id");
# 3. keyword match in title
my $query = "SELECT * FROM snippets WHERE path LIKE ? AND (";
my @queryParams = ("$path%");
my $cnt = $#qs;
print "$cnt\n";
while($cnt >= 0) {
    $query .= "OR " unless $cnt == $#qs;
    $query .= "title LIKE ? ";
    push @queryParams, "$qs[$cnt]";
    $cnt--;
}
$query .= ");";
print Dumper $query;
print Dumper \@queryParams;
my $preppedQuery = $dbh->prepare($query);
$preppedQuery->execute(@queryParams);
push @reses, $preppedQuery->fetchall_hashref("id");
# 4. same, but with wildcards
@queryParams = ("$path%");
$cnt = $#qs;
while($cnt-- >= 0) {
    push @queryParams, "%$qs[$cnt]%";
}
$preppedQuery->execute(@queryParams);
push @reses, $preppedQuery->fetchall_hashref("id");
$preppedQuery->finish();
# 5. keyword hits
push @reses, {};
foreach my $keyword (@qs) {
    $db::sth->{keywordHit}->execute("$path%", "$keyword");
    my $thisHit = $db::sth->{keywordHit}->fetchall_hashref("id");
    @{$reses[$#reses]}{keys %{$thisHit}} = values %{$thisHit};
}
# 6. same, wildcards
push @reses, {};
foreach my $keyword (@qs) {
    $db::sth->{keywordHit}->execute("$path%", "%$keyword%");
    my $thisHit = $db::sth->{keywordHit}->fetchall_hashref("id");
    @{$reses[$#reses]}{keys %{$thisHit}} = values %{$thisHit};
}

my %spentIDs = ();
foreach (@reses) {
    my $href = $_;
    foreach (keys %{$href}) {
        my $key = $_;
        if(defined $spentIDs{$key}) {
            delete $href->{$key};
        } else {
            $spentIDs{$key} = 1;
        }
    }
}


print Dumper \@reses;
exit;

# write template
dowrite($path, \@reses);

# cleanup

db::closedb();
exit 0;

sub dowrite {
    my ($path, $files) = @_;

    my $qp = uri_escape $path;

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
    if($path ne "/") {
        my $qp = uri_escape $path;
        my @newPathElements = @pathElements;
        shift @newPathElements;
        pop @newPathElements;
        my $parent = "/" . join("/", @newPathElements);
        my $qparent = uri_escape $parent;

        $subDirHTML .= <<"EOT" ;
<tr><td class="dir"><a href="?path=$qp"><div>[.]</div></a></td></tr>
EOT
        $subDirHTML .= <<"EOT" ;
<tr><td class="dir"><a href="?path=$parent"><div>[..]</div></a></td></tr>
EOT
    }
    foreach (sort keys %subDirs) {
        my $p = $_;
        my $qp = uri_escape "${path}$p/";
        $subDirHTML .= <<"EOT" ;
<tr><td class="dir"><a href="?path=$qp"><div>[$p]</div></a></td></tr>
EOT
    }

    my $fileHTML = "";
    foreach (sort @filteredFiles) {
        my $file = $_;
        $fileHTML .= <<"EOT" ;
<tr><td class="snip"><a href="view.pl?id=$file->{id}"><div>$file->{title}</div></a></td></tr>
EOT
    }

    my $template = <<"EOT" ;
Content-Type: text/html; charset=utf-8

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="60">
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
                        <a href="edit.pl?path=$qp"><input type="button" value="Add new snippet" /></a><span style="padding-left:25px">Current path:</span><span id="currentPath" style="font-family:monospace">$navLinks</span>
                    </td>
                    <td style="text-align:right">
                        <form action="search.pl" method="GET">
                        <table style="width:100%">
                            <tr><td>
                                <span style="display:block;min-width:200px;width:200px;max-width:200px;float:right"><input name="q" type="text" placeholder="search" style="width:100%"/></span>
                            </tr></td>
                            <tr><td>
                                <span style="display:block;min-width:200px;width:200px;max-width:200px;float:right">
                                    <!-- <input type="checkbox" />search inside code snippets -->
                                    <input name="everywhere" type="checkbox" />search in all directories
                                </span>
                            </td></td>
                        </table>
                        </form>
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
        </td></tr>
    </table>
</body>
EOT

    print $template;
}
