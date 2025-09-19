CREATE TABLE IF NOT EXISTS graphmodel_parameters
(
    id INTEGER PRIMARY KEY,
    graphmodel_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    value TEXT NOT NULL,
    FOREIGN KEY (graphmodel_id)
        REFERENCES graphmodels (id)
        ON DELETE CASCADE,
    UNIQUE(graphmodel_id, name)
    
);