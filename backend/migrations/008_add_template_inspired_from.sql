SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'templates'
    AND COLUMN_NAME = 'inspired_from'
);

SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE templates ADD COLUMN inspired_from MEDIUMTEXT NULL AFTER body',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
