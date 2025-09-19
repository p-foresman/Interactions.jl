INSERT OR IGNORE INTO graphmodels
(
    name,
    display,
    graphmodel_bin
)
VALUES (?, ?, ?)
ON CONFLICT (name, graphmodel_bin) DO UPDATE
    SET name = graphmodels.name
RETURNING id;