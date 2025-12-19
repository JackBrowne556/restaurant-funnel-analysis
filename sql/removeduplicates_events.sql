/*
		Remove Duplicate Events Query

		Total of 1,044 Duplicates found, removed in-query, and created a new table view.
		From this, a new table is created `events_unique` to be used in the next cleaning
		process.
*/


CREATE TABLE events_unique AS /* Create as separate view */
SELECT *
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER ( /* Window Function to assign each row to # of appearances */
      PARTITION BY		/* Partition by all columns to identify duplicate records */
        session_id, user_id, event_type, item_id, timestamp, platform, device, area, order_value
      ORDER BY session_id
    ) AS rn
  FROM events_table
) x
WHERE rn = 1; 
/* hides any records which appear more than once */






