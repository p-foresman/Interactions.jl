INSERT OR IGNORE INTO simulations
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
) SELECT 
    uuid,
    group_id,
    prev_simulation_uuid,
    model_id,
    period,
    complete,
    timedout,
    data
FROM merge_db.simulations;