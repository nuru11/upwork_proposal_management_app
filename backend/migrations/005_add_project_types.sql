SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'projects'
    AND COLUMN_NAME = 'types'
);

SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE projects ADD COLUMN types JSON NOT NULL DEFAULT (JSON_ARRAY(''other'')) AFTER web_url',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
