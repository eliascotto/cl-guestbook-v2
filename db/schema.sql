CREATE TABLE message (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    username VARCHAR(50) NOT NULL,
    ts       DATETIME NOT NULL,
    content  TEXT NOT NULL
);
