package db;

my %st = (
    getAll => "SELECT * FROM snippets ;",
    getUnderCurrentPath => "SELECT id,title, path FROM snippets WHERE path LIKE ? ;",
);

my $dbh = undef;

our $sth = {};

use DBI;
use DBD::SQLite;

sub opendb {
    if(defined $dbh) { return $dbh }

    unless(defined $ENV{CCPDATABASE}) {
        use Data::Dumper;
        print Dumper \%ENV;
        die 'CCPDATABASE is not defined';
    }

    # open DB
    $dbh = DBI->connect("dbi:SQLite:dbname=".$ENV{CCPDATABASE}, '', '',
            { AutoCommit => 0 })
    or die 'can'."'".'t open database';
    $dbh->commit(); # get out of transaction
        $dbh->do("PRAGMA foreign_keys = TRUE;");

    # prepare statements
    foreach (keys %st) {
        my $key = $_;
        $sth->{$key} = $dbh->prepare($st{$key});
    }

    return $dbh;
}

sub closedb {
    $dbh->commit();
    
    foreach (keys %{$sth}) {
        my $key = $_;
        $sth->{$key}->finish();
        delete $sth->{$key};
    }
    $dbh->disconnect();
}

1;
