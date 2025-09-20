SELECT uuid
FROM simulations tabA
WHERE complete = 0
AND NOT EXISTS (
    SELECT *
    FROM simulations tabB
    WHERE tabB.prev_simulation_uuid = tabA.uuid
)