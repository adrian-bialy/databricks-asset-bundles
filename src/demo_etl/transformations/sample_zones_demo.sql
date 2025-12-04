-- This file defines a sample transformation.
-- Edit the sample below or add new transformations
-- using "+ Add" in the file browser.

CREATE OR REFRESH LIVE TABLE sample_zones_demo AS
SELECT
    pickup_zip,
    SUM(fare_amount) AS total_fare
FROM sample_trips_demo
GROUP BY pickup_zip