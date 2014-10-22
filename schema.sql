PRAGMA foreign_keys = ON ;

CREATE TABLE IF NOT EXISTS snippets (
    id INT PRIMARY KEY,
    title VARCHAR(256) NOT NULL,
    path VARCHAR(256) NOT NULL,
    language CHAR(40) NULL,
    code TEXT NOT NULL
    );

CREATE TABLE IF NOT EXISTS keywords (
    keyword VARCHAR(256) NOT NULL,
    snippet_id INT NOT NULL,
    PRIMARY KEY (keyword, snippet_id),
    FOREIGN KEY (snippet_id) REFERENCES snippets(id) ON DELETE CASCADE
    );
