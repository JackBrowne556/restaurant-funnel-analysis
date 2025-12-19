/*
		Standardize timestamp format Query

		Several instances of unstandardized formats that didn't adhere to "YYYY-MM-DD HH:MM"
		were found in events_unique.

*/

/*
	Step 1: Create CASE statement for unstandardized formats

	I created 4 CASE WHEN conditions (1 for standardized, 2 for unstandardized, and 1 for null)
		followed by 4 THEN statements that standardizes incorrect formats, and providing null
		counts for missed values, allowing for auditing.
*/

-- 1) Convert known formats into a real timestamp (data type)
    CASE
      -- Already "YYYY-MM-DD HH:MM", no change
      WHEN e."timestamp" ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$'
        THEN to_timestamp(e."timestamp", 'YYYY-MM-DD HH24:MI')

      -- ISO-format: "2026-01-01T11:34:00" // shows HH:MM:SS
      WHEN e."timestamp" ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$'
        THEN to_timestamp(e."timestamp", 'YYYY-MM-DD"T"HH24:MI:SS')

      -- Human readable: "2:21PM, January 1st 2026"
      WHEN e."timestamp" ~ '^\d{1,2}:\d{2}[AP]M, [A-Za-z]+ \d{1,2}(st|nd|rd|th) \d{4}$'
        THEN to_timestamp(
          -- remove ordinal suffixes (3rd in January 3rd, etc.)
          regexp_replace(e."timestamp", '([0-9]{1,2})(st|nd|rd|th)', '\1', 'g'),
          'HH12:MIAM, Month DD YYYY'
        )
	ELSE NULL

/* 
	Step 2: Save conditions as temporary table 

	the CASE statements were wrapped into a "parsed" temporary view, from
		events_unique.
*/

CREATE OR REPLACE VIEW events_standardized_timestamps AS
WITH parsed AS ( /* Next SELECT statement will use 'parsed' to use these CASE rules to produce
				  	"YYYY-HH-MM HH:MM". */
  SELECT
    e.*,

/* 4 CASE statements in Step 1 */

END AS parsed_timestamp
	FROM events_unique e

/*
	Step 3: Enforce correct timestamp output

	The final unwrapped SELECT statement removes any second parsing that may have been 
		overlooked, and reinforces that the only outputs that exist in timestamp is
		"YYYY-MM-DD HH:MM" strictly.
*/

SELECT
  parsed.*,

			/* removes seconds*/			/* Strictly Outputs */
  to_char(date_trunc('minute', parsed_ts), 'YYYY-MM-DD HH24:MI') AS timestamp_std

FROM parsed;



-- Entire Query Below:


CREATE OR REPLACE VIEW events_standardized_timestamps AS
WITH parsed AS (
  SELECT
    e.*,

    -- 1) Convert known formats into a real timestamp (data type)
    CASE
      -- Already "YYYY-MM-DD HH:MM", no change
      WHEN e."timestamp" ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$'
        THEN to_timestamp(e."timestamp", 'YYYY-MM-DD HH24:MI')

      -- ISO-like: "2026-01-01T11:34:00"
      WHEN e."timestamp" ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$'
        THEN to_timestamp(e."timestamp", 'YYYY-MM-DD"T"HH24:MI:SS')

      -- Human readable: "2:21PM, January 1st 2026"
      WHEN e."timestamp" ~ '^\d{1,2}:\d{2}[AP]M, [A-Za-z]+ \d{1,2}(st|nd|rd|th) \d{4}$'
        THEN to_timestamp(
          -- remove ordinal suffixes (3rd in January 3rd, etc.)
          regexp_replace(e."timestamp", '([0-9]{1,2})(st|nd|rd|th)', '\1', 'g'),
          'HH12:MIAM, Month DD YYYY'
        )
	  -- Two Conditions: event_type = order_complete; timestamp = "2:30pm, January 2nd 2026".
	  WHEN e.event_type = 'order_complete' 
 		 AND e."timestamp" ~ '^\d{1,2}:\d{2}\s*[ap]m,\s*[A-Za-z]+\s+\d{1,2}(st|nd|rd|th)\s+\d{4}$'
		 THEN to_timestamp(
  		regexp_replace(
    	regexp_replace(
      	regexp_replace(e."timestamp", ',\s*', ' ', 'g'), -- Remove Comma
      '([0-9]{1,2})(st|nd|rd|th)', -- remove ordinal suffixes (remove the "nd" in "2nd")
      '\1',
      'g'
    ),
    '(?i)\b(am|pm)\b', -- changes all cases of lowercase am/pm to uppercase.
    upper('\1'),
    'g'
  ),
  'FMHH12:FMMIAM Month FMDD YYYY' --identify root timestamp parsing cause
)

      -- Null Values (Later I found unparsed records)
      ELSE NULL
    END AS parsed_ts
  FROM events_unique e
)

SELECT
  parsed.*,

			/* removes seconds*/			/* Strictly Outputs */
  to_char(date_trunc('minute', parsed_ts), 'YYYY-MM-DD HH24:MI') AS timestamp_std

FROM parsed;


