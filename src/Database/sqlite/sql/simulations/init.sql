CREATE TABLE IF NOT EXISTS simulations
(
    uuid TEXT PRIMARY KEY,
    group_id INTEGER DEFAULT NULL,
    prev_simulation_uuid TEXT DEFAULT NULL,
    model_id INTEGER NOT NULL,
    period INTEGER NOT NULL,
    complete BOOLEAN NOT NULL,
    timedout BOOLEAN NOT NULL,
    data TEXT DEFAULT '{}' NOT NULL,
    state_bin BLOB DEFAULT NULL,
    FOREIGN KEY (group_id)
        REFERENCES groups (id)
        ON DELETE CASCADE,
    FOREIGN KEY (prev_simulation_uuid)
        REFERENCES simulations (simulation_uuid),
    FOREIGN KEY (model_id)
        REFERENCES models (id),
    UNIQUE(uuid),
    CHECK (complete in (0, 1)),
    CHECK (timedout in (0, 1))
);