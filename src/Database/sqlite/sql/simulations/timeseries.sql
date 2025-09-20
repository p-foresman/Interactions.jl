WITH RECURSIVE
    timeseries(i, uuid, prev_simulation_uuid, period, complete, data) AS (
        SELECT ?, simulations.uuid, simulations.prev_simulation_uuid, simulations.period, simulations.complete, simulations.data -- question mark here is limit (anchor member)
        FROM simulations
        WHERE simulations.uuid = ?
        UNION ALL
        SELECT i - 1, simulations.uuid, simulations.prev_simulation_uuid, simulations.period, simulations.complete, simulations.data
        FROM simulations, timeseries
        WHERE simulations.uuid = timeseries.prev_simulation_uuid
        AND i - 1 > 0
    )
SELECT *
FROM timeseries
ORDER BY i ASC