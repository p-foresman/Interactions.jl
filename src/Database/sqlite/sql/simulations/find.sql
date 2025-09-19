SELECT
    uuid,
    group_id,
    prev_simulation_uuid,
    model_id,
    period,
    complete,
    timedout,
    data
FROM simulations
WHERE simulations.uuid = ?;