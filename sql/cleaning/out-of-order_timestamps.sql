/*
		Fix Out-of-order Timestamps Query

		Instances of both non-chronological timestamps AND funnel sequence regressions were
			made to be in-order within the newly created table `events_ordered`

		Note this query uses a previously created table / view from standardized timestamps, 
			'events_standardized_timestamps'. See 'standardized_timestamps.sql` 
			in Github Repository.

*/

/*
	Step 1: Identify Funnel Sequence
	
	We do this by assigning numerical values (1-5) in a CASE statement within a base CTE 
	function. Any unexpected instances are pushed as '999' to push to end.
*/

CREATE OR REPLACE VIEW events_funnel_ordered AS
WITH base AS (
  SELECT
    est.*,

    /* 1) Map each event_type to a funnel step number */
    CASE est.event_type
      WHEN 'menu_view'       THEN 1
      WHEN 'item_added'      THEN 2
      WHEN 'cart_review'     THEN 3
      WHEN 'payment_attempt' THEN 4
      WHEN 'order_complete'  THEN 5
      ELSE 999  -- pushes unexpected instances to end for auditing 
    END AS funnel_step
  FROM events_standardized_timestamp est
),

/* 
	Step 2: create CTE to enforce ordered funnel sequence

	Create an 'ordered' window function using ROW_NUMBER() and PARTITION BY to segregating ordering
	based on each unique session id to ascend order based on identified 'funnel_step' above.
*/

ordered AS (
  SELECT
    b.*, -- b = base CTE, identified later

    ROW_NUMBER() OVER (
      PARTITION BY b.session_id 
	  -- Re-order based on each session_id identified through base cte
      ORDER BY
        b.funnel_step ASC,
        b.timestamp_std ASC,
        b.user_id ASC,
        b.item_id ASC
    ) AS funnel_row_num,

/* 
	Step 3: Enforce strict non-decreasing time series

	Creates a new column that ensures the time stamps follow logic with re-ordered event types.
	I use a MAX() function and PARTITION BY to perform a similar re-ordering as the ordered CTE
	above, but rather do so to ensure timestamps follow logical time sequence based on funnel.
*/

/* ordered CTE...	*/

MAX(b.timestamp_std) OVER (
      PARTITION BY b.session_id
      ORDER BY
        b.funnel_step ASC,
        b.timestamp_std ASC,
        b.user_id ASC,
        b.item_id ASC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS timestamp_funnel_aligned

  FROM base b
)

/* 
	Step 4: Run a filtered SELECT statement for analysis-ready view

	Finally, we run a filtered SELECT statement (instead of using *) from ordered CTE, reinforcing
	order again through an ORDER BY statement
*/

SELECT
  session_id,
  user_id,
  event_type,
  funnel_step,
  timestamp_std,
  timestamp_funnel_aligned,
  item_id,
  platform,
  device,
  area,
  order_value,
  funnel_row_num
FROM ordered
ORDER BY session_id, funnel_row_num;



/* Final Query Below (to run in Database) */

CREATE OR REPLACE VIEW events_funnel_ordered AS
WITH base AS (
  SELECT
    est.*,

    CASE est.event_type
      WHEN 'menu_view'       THEN 1
      WHEN 'item_added'      THEN 2
      WHEN 'cart_review'     THEN 3
      WHEN 'payment_attempt' THEN 4
      WHEN 'order_complete'  THEN 5
      ELSE 999  
    END AS funnel_step
  FROM events_standardized_timestamps est
),

ordered AS (
  SELECT
    b.*,

    ROW_NUMBER() OVER (
      PARTITION BY b.session_id
      ORDER BY
        b.funnel_step ASC,
        b.timestamp_std ASC,
        b.user_id ASC,
        b.item_id ASC
    ) AS funnel_row_num,

    MAX(b.timestamp_std) OVER (
      PARTITION BY b.session_id
      ORDER BY
        b.funnel_step ASC,
        b.timestamp_std ASC,
        b.user_id ASC,
        b.item_id ASC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS timestamp_funnel_aligned

  FROM base b
)

SELECT
  session_id,
  user_id,
  event_type,
  funnel_step,
  timestamp_std,
  timestamp_funnel_aligned,
  item_id,
  platform,
  device,
  area,
  order_value,
  funnel_row_num
FROM ordered
ORDER BY session_id, funnel_row_num;







