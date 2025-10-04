INSERT OR IGNORE INTO models
(
    id,
    agent_type,
    population_size,
    game_id,
    graphmodel,
    starting_condition,
    stopping_condition,
    model_bin
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT (model_bin) DO UPDATE
    SET agent_type = models.agent_type
RETURNING id;