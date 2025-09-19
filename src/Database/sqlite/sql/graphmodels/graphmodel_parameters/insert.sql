INSERT OR IGNORE INTO graphmodel_parameters
(
    graphmodel_id,
    name,
    type,
    value
)
VALUES (?, ?, ?, ?)
ON CONFLICT (graphmodel_id, name) DO UPDATE
    SET name = graphmodel_parameters.name
RETURNING id;