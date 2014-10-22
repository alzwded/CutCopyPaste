PRAGMA foreign_keys = ON;

DELETE FROM snippets;
DELETE FROM keywords;

INSERT INTO snippets
    (id, title, path, code)
    VALUES
    (1, "gigi.pl", "/perl/", "exit 0;"),
    (2, "francois.py", "/python/", "exit(0)"),
    (3, "main.c", "/C/", "int main() {
    return 0;
}"),
    (4, "add.c", "/C/", "int main() {
    int x = 2 + 2;
    return x;
}"),
    (5, "stupid.txt", "/", "hello!"),
    (6, "stupid.txt", "/a/b/c/", "hello!");

INSERT INTO keywords
    (keyword, snippet_id)
    VALUES
    ("C", 3),
    ("C", 4),
    ("addition", 4),
    ("int", 4),
    ("perl", 1),
    ("python", 2);
