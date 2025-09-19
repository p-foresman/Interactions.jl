    SELECT
        uuid,
        group_id,
        prev_simulation_uuid,
        model_id,
        period,
        complete,
        timedout,
        data,
        state_bin
    FROM simulations
    WHERE simulations.uuid = ?;