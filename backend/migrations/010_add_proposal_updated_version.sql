SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'proposals'
    AND COLUMN_NAME = 'updated_version'
);

SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE proposals ADD COLUMN updated_version MEDIUMTEXT NULL AFTER notes',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
