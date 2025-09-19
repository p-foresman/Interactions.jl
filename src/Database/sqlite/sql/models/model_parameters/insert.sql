INSERT OR IGNORE INTO model_parameters
(
    model_id,
    name,
    type,
    value
)
VALUES (?, ?, ?, ?)
ON CONFLICT (model_id, name) DO UPDATE
    SET name = model_parameters.name
RETURNING id;