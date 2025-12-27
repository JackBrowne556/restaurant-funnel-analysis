/* 
	Dealing with invalid customer funnels

	Several customer funnels were found to have illogical step sequences, particularly when a later
	step would occur without an earlier one (e.g. customer attempting payment with no evidence of 
	adding an item), not following business logic. 

*/

/* 
	Step 1: First case statements CTE to assign numbers to funnel steps

	created a base CTE that assigns values 1-5 to each funnel step, similar to the last cleaning
	phase.
*/

WITH assigned AS (
  SELECT
    e.*,
    CASE e.event_type
      WHEN 'menu_view'        THEN 1
      WHEN 'item_added'       THEN 2
      WHEN 'cart_review'      THEN 3
      WHEN 'payment_attempt'  THEN 4
      WHEN 'order_complete'   THEN 5
    END AS funnel_step_num
  FROM events_funnel_ordered e
),

/* 
	Step 2: Second CTE to create mini-metrics for final valid CTE

	Creating three mini-metrics: min_step, max_step, and count of distinct steps allows for
	computing what would make a valid session (when step count = max step)
*/

session_quality AS (
  SELECT
    session_id,
    MIN(funnel_step_num)                  AS min_step,
    MAX(funnel_step_num)                  AS max_step,
    COUNT(DISTINCT funnel_step_num)       AS distinct_steps
  FROM tagged
  WHERE funnel_step_num IS NOT NULL
  GROUP BY session_id
),

/* 
	Step 3: Final CTE for valid funnel conditions
	Using session_quality, conditions for a valid session is the following:

	- Starts from step 1 (Cannot be valid if a customer doesn't even view the menu)
	- step count = max steps, as to keep progressive logic
*/

valid_sessions AS (
  SELECT session_id
  FROM session_quality
  WHERE
    -- must start at the beginning of the funnel
    min_step = 1
    -- must contain every step progressively (if max step = 4, then must include each step prior)
    AND distinct_steps = max_step
)


/* Entire Query Below: */

CREATE TABLE events_cleaned AS
WITH assigned AS (
  SELECT
    e.*,
    CASE e.event_type
      WHEN 'menu_view'        THEN 1
      WHEN 'item_added'       THEN 2
      WHEN 'cart_review'      THEN 3
      WHEN 'payment_attempt'  THEN 4
      WHEN 'order_complete'   THEN 5
    END AS funnel_step_num
  FROM events_funnel_ordered e
),

session_quality AS (
  SELECT
    session_id,
    MIN(funnel_step_num)                  AS min_step, 		-- first step in funnel
    MAX(funnel_step_num)                  AS max_step, 		-- last step in funnel
    COUNT(DISTINCT funnel_step_num)       AS distinct_steps -- total funnel stages progressed
  FROM assigned
  WHERE funnel_step_num IS NOT NULL
  GROUP BY session_id
),

valid_sessions AS (
  SELECT session_id
  FROM session_quality
  WHERE
    -- must start at the beginning of the funnel
    min_step = 1
    -- must contain every step from 1..max_step (no gaps)
    AND distinct_steps = max_step
)

-- Final JOIN between first and last CTE
SELECT a.*
FROM assigned a
JOIN valid_sessions v
  ON a.session_id = v.session_id;

