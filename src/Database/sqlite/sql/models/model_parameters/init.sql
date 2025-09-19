CREATE TABLE IF NOT EXISTS model_parameters
(
    id INTEGER PRIMARY KEY,
    model_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    value TEXT NOT NULL,
    FOREIGN KEY (model_id)
        REFERENCES models (id)
        ON DELETE CASCADE,
    UNIQUE(name, model_id)
);