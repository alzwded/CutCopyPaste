#!/usr/bin/perl -w

use CGI::Carp qw/fatalsToBrowser/;
use strict;
use Data::Dumper;
use URI::Escape;

use db;

my $dbh = db::opendb();

# get variables
my $CLEN = $ENV{CONTENT_LENGTH} or die 'no post';
my $s = "";
read STDIN, $s, $CLEN;
my %GETvars = map {
                  my $s = $_;
                  $s =~ s/\+/ /g;
                  my $pos = index $s, "=";
                  my $key = substr $s, 0, $pos;
                  my $value = uri_unescape(substr $s, $pos + 1);
                  $key => $value
              } split /\&/, $s;

my $newId = "";
#print Dumper \%GETvars;

my $id = $GETvars{id} || undef;

my $file = {
    id => $id,
    title => $GETvars{title} || "Untitled " . time() . "" . rand(),
    path => $GETvars{path} || "/",
    keywords => $GETvars{keywords} || "",
    code => $GETvars{code} || "",
    language => $GETvars{language} || "",
};

$file->{code} =~ s///g;

foreach my $key (keys %{$file}) {
    $file->{$key} = uri_unescape($file->{$key});
}

# save it!
if(defined $id) {
    $db::sth->{save}->execute($file->{title}, $file->{path}, $file->{language}, $file->{code}, $file->{id});
    $db::sth->{removeKeywords}->execute($file->{id});
    $newId = $id;
} else {
    $db::sth->{insert}->execute($file->{title}, $file->{path}, $file->{language}, $file->{code});
    $newId = $dbh->func('last_insert_rowid');
    $dbh->do("COMMIT");
}
my %leFiles = map { $_ => 1 } map { process($_) } split /,/, $file->{keywords};
foreach (keys %leFiles)
{
    $db::sth->{insertKeyword}->execute($_, $newId);
}
$dbh->do("COMMIT");

# write redirect
print <<"EOT" ;
Status: 302
Location: view.pl?id=$newId
Content-Type: text/html

<!DOCTYPE html>
<html>
<head><title>Redirecting...</title></head>
<body>
    <p>Click <a href="view.pl?id=$newId">here</a> if your browser does not automatically redirect you</p>
</body>
EOT

# cleanup

db::closedb();
exit 0;

sub process {
    my ($v) = @_;
    $v =~ s/^\s+//;
    $v =~ s/\s+$//;
    $v =~ s/"/\\"/g;
    return $v;
}
