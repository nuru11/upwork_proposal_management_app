SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'templates'
    AND COLUMN_NAME = 'project_type'
);

SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE templates ADD COLUMN project_type VARCHAR(32) NOT NULL DEFAULT ''other'' AFTER language',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'templates'
    AND INDEX_NAME = 'idx_templates_project_type'
);

SET @sql := IF(
  @idx_exists = 0,
  'ALTER TABLE templates ADD KEY idx_templates_project_type (project_type)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
