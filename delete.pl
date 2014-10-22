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

my $id = $GETvars{id} or die 'missing id';

# delete it
$db::sth->{getById}->execute($id);
my $files = $db::sth->{getById}->fetchall_hashref("id");
$db::sth->{deleteById}->execute($id);
$dbh->do("COMMIT");

my $qp = $files->{$id}->{path};

# write redirect
print <<"EOT" ;
Status: 302
Location: index.pl?path=$qp
Content-Type: text/html

<!DOCTYPE html>
<html>
<head><title>Redirecting...</title></head>
<body>
    <p>Click <a href="index.pl?path=$qp">here</a> if your browser does not automatically redirect you</p>
</body>
EOT

# cleanup

db::closedb();
exit 0;
