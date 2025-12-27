# Data Cleaning Notebook

## Introduction

This markdown notebook will detail the cleaning efforts done to the `events.csv` dataset, which contains a 90-day event log, showing multiple sessions and customer funnel progress. Deliverables for this notebook includes a documentation log, SQL cleaning queries, and a finalized `.csv` ready for analysis.

Cleaning is done through SQL Queries (and NOT a spreadsheet software like Excel or Google Sheets) to preserve the original set of data while creating a cleaned view within the company database.

## Cleaning Efforts Summary

The following are cleaning efforts done to `events.csv`:

- **Remove Duplicate Events**
	> Several events were found to be duplicated, leading to data inaccuracy. 
- **Standardizing timestamps**
	>Some timestamps don't follow the format of "YYYY/MM/DD HH:MM", which would cause further issue in analysis.
- **Fixing out-of-order timestamps**
	> Some timestamps appear out-of-order, not following logic of customer funnel.
- **Validate event type sequences**
	> Some events in the latter end of the funnel (e.g. order_complete) aren't accompanied by previous funnel stages (menu_view), leading to inconsistency of event data.

Cleaning Efforts will be organized tackling each of these three issues found within `events.csv` below.

## Cleaning Processes

---

### Removing Duplicate Events

A total of **1044 records** were found to be duplicates, which were removed, then the unique records were kept and created into a new table `events_unique`.

Used `ROWNUMBER()`, and `OVER / PARTITION BY` SQL Window Functions to identify duplicate events and exclude them from the query.

`Removed Duplicates Query`

---

### Standardizing timestamps 

A total of **6867 timestamps** were found to be unstandardized, which means NOT being in the format of "YYYY-MM-DD HH:MM". 

A few examples of unstandardized formats were
- "2026-01-01T11:34:00"
- "2:21PM, January 1st 2026"

Used a total of five (originally four, explanation below) `CASE` statements to identify conditions (e.g. if timestamp is "2:22PM, January 1st, 2026"), and used `Regex SQL` to define these unstandardized timestamps into correct format.

`first standardized timestamp query`

After running the above query, most rows were parsed successfully, showing standardized timestamps in a new column, `timestamps_std`. 

However, I noticed nulls in the standardized timestamps, and after running a simple `COUNT` to check for nulls in `timestamps_std`, I found 205 unparsed rows, all sharing two attributes:
- event_type = order_complete
- timestamp (original) = "2:30pm, January 2nd 2026"

So, I added another case statement which identifies these two conditions, which had an extra comma, ordinal, and upper/lower case problems that weren't covered in the original four `CASE` statements:

`5th case statement`

After adding the 5th case statement which deals with the two unparsed attributes, all records now had standardized timestamps in the form of "YYYY-MM-DD HH:MM". 

---

### Fixing Out-of-order Event Types

Out-of-order event types are customer funnels that do not align with the business funnel:

> **menu_view → item_added → review_cart → payment_attempt → order_complete**

A total of of **639** Session IDs were found to have either regressed funnel order or illogical timestamps. 

Utilized two `CTEs`  with `CASE` statements, and `ROW NUMBER()`, `PARTITION BY` to partition each event and timestamp ordering according to each unique session ID. 

`Whole Out-of-order Query`

---

### Invalid Customer Funnels

Several customer funnels were discovered to be missing previous funnel steps within a sequence, not following business logic. For example, an invalid funnel sequence would start with the customer reviewing the cart (review_cart), hence would be missing the steps in which the customer viewed the menu (menu_view) and added an item (item_added).

Since the point of this project is to analyze funnel and conversion rates, which relies on valid sequences, **I chose to hide all 591 illogical customer funnels**, and create a final table, `events_cleaned`, ready for analysis. 

 I used three `CTEs` for the query, one for assigning numbers to the event types (as seen in 'fixing out-of-order event types), a `session_quality` CTE to identify metrics for a valid session, then finally `valid_sessions` to determine conditions for a valid session, which is when the number of distinct steps taken equals the maximum step in the customer funnel.

`Whole invalid customer funnel query`

---

## Conclusion

A final table within the database, `events_cleaned`, was created from the last cleaning step. All four `.sql` files can be found within the Github Repository `here`.
