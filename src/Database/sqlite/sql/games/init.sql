CREATE TABLE IF NOT EXISTS games
(
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    payoff_matrix_size TEXT NOT NULL,
    interaction TEXT NOT NULL,
    game_bin BLOB NOT NULL,
    UNIQUE(name, game_bin)
);