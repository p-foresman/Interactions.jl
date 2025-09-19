INSERT OR IGNORE INTO games
(
    name,
    payoff_matrix_size,
    interaction,
    game_bin
)
VALUES (?, ?, ?, ?)
ON CONFLICT (name, game_bin) DO UPDATE
    SET name = games.name
RETURNING id;