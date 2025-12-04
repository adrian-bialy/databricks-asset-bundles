-- This file defines a sample transformation.
-- Edit the sample below or add new transformations
-- using "+ Add" in the file browser.

CREATE OR REFRESH LIVE TABLE sample_trips_demo AS
SELECT
    pickup_zip,
    fare_amount,
    trip_distance
FROM samples.nyctaxi.trips