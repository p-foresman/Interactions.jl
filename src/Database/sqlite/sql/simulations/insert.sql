INSERT INTO simulations
(
    uuid,
    group_id,
    prev_simulation_uuid,
    model_id,
    period,
    complete,
    timedout,
    data,
    state_bin
)
VALUES (?,?,?,?,?,?,?,?,?)
RETURNING uuid