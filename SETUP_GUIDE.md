# Supabase Project Setup Guide

This guide provides step-by-step instructions to set up the database, load initial data, and run processing functions.

## 1. Create Tables

First, connect to your Supabase database using `psql` or the Supabase SQL Editor. Then, execute the following DDL scripts in order to create the necessary tables, indexes, and triggers.

```bash
# Connect to your database first
psql -h YOUR_SUPABASE_HOST -p 5432 -U postgres -d postgres

# Run DDLs
\i DDL/CREATE_unified_company_member.sql
\i DDL/CREATE_new_agents.sql
\i DDL/CREATE_new_unified_agents.sql
```

*Note: The script for `new_unified_agents` also creates necessary extensions like `pg_trgm` and a trigger function `update_last_updated_column()`.*

## 2. Load Initial Data from CSV

Next, use the `\copy` command in `psql` to load data from the CSV files into their corresponding tables. 

*Note: You must provide the absolute path to your CSV files.*

```sql
-- Load raw company information
-- IMPORTANT: We are assuming a 'raw_company_info' table exists for this data.
-- Please verify the table name and columns.
\copy raw_company_info FROM '/path/to/your/project/CSVs/raw_company_info.csv' WITH (FORMAT csv, HEADER true);

-- Load new agents data
\copy new_agents FROM '/path/to/your/project/CSVs/new_agents.csv' WITH (FORMAT csv, HEADER true);
```

## 3. Create and Run Data Processing Functions

Now, create the functions that will process the raw data and populate the unified tables.

1.  **Create Helper Functions**:
    ```sql
    \i FUNCTIONS/helper_functions.sql
    ```

2.  **Create the Main Pipeline Function**:
    ```sql
    \i FUNCTIONS/run_unified_member_pipeline.SQL
    ```

3.  **Execute the Pipeline**:
    After the functions are created, run the main processing function to merge and unify the data.
    ```sql
    SELECT public.run_unified_merge_batch();
    ```

## 4. Verification

After completing the steps above, you can verify the setup:

- Check that the `new_unified_agents` table is populated with data.
- Confirm that the `processed` flag is set to `true` in the `unified_company_member` table for the rows that have been processed.

```sql
-- Check for populated data
SELECT * FROM public.new_unified_agents LIMIT 10;

-- Check row count
SELECT COUNT(*) FROM public.new_unified_agents;
```
