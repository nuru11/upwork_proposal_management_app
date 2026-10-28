SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'proposals'
    AND COLUMN_NAME = 'job_description'
);

SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE proposals ADD COLUMN job_description MEDIUMTEXT NULL AFTER job_url',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
