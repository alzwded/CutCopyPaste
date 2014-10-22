package db;

my %st = (
    getAll => "SELECT * FROM snippets ;",
    getById => "SELECT * FROM snippets WHERE id = ? ;",
    getAllKeywords => "SELECT keyword FROM keywords WHERE snippet_id = ? ;",
    getUnderCurrentPath => "SELECT id,title, path FROM snippets WHERE path LIKE ? ;",
    deleteById => "DELETE FROM snippets WHERE id = ? ;",
    insert => "INSERT INTO snippets (title, path, language, code) VALUES (?, ?, ?, ?);",
    removeKeywords => "DELETE FROM keywords WHERE snippet_id = ? ;",
    save => "UPDATE snippets SET title=?, path=?, language=?, code=? WHERE id = ? ;",
    insertKeyword => "INSERT INTO keywords (keyword, snippet_id) VALUES (?, ?) ;",

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
            { AutoCommit => 0, RaiseError => 1 })
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
