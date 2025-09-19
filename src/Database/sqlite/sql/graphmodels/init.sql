
CREATE TABLE IF NOT EXISTS graphmodels
(
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    display TEXT NOT NULL,
    graphmodel_bin BLOB NOT NULL,
    UNIQUE(name, graphmodel_bin)
);