INSERT OR IGNORE INTO groups
(
    description
)
VALUES (?)
ON CONFLICT (description) DO UPDATE
    SET description = groups.description
RETURNING id;