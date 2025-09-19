CREATE TABLE IF NOT EXISTS models
(
    id INTEGER PRIMARY KEY,
    agent_type TEXT NOT NULL,
    population_size INTEGER NOT NULL,
    game_id INTEGER NOT NULL,
    graphmodel_id INTEGER NOT NULL,
    starting_condition TEXT NOT NULL,
    stopping_condition TEXT NOT NULL,
    parameters TEXT NOT NULL,
    variables TEXT NOT NULL,
    arrays TEXT NOT NULL,

    FOREIGN KEY (game_id)
        REFERENCES games (id)
        ON DELETE CASCADE,
    FOREIGN KEY (graphmodel_id)
        REFERENCES graphmodels (id)
        ON DELETE CASCADE,
    UNIQUE(agent_type, population_size, game_id, graphmodel_id, starting_condition, stopping_condition, parameters, variables, arrays)
);