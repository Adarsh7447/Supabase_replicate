CREATE OR REPLACE FUNCTION array_merge_unique(arr1 TEXT[], arr2 TEXT[])
RETURNS TEXT[] AS $$
BEGIN
    RETURN ARRAY(
        SELECT DISTINCT val
        FROM unnest(COALESCE(arr1, '{}') || COALESCE(arr2, '{}')) AS val
        WHERE val IS NOT NULL 
          AND TRIM(val) <> ''
        ORDER BY val
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Auto-update last_updated timestamp
CREATE OR REPLACE FUNCTION update_last_updated_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

