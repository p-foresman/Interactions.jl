INSERT OR IGNORE INTO models
(
    id,
    game_id,
    graphmodel_id,
    parameters_id
)
VALUES (?, ?, ?, ?)
ON CONFLICT (game_id, graphmodel_id, parameters_id) DO UPDATE
    SET game_id = models.game_id
RETURNING id;