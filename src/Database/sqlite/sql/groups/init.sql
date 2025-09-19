CREATE TABLE IF NOT EXISTS groups
(
    id INTEGER PRIMARY KEY,
    description TEXT DEFAULT NULL,
    UNIQUE(description)
);