SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'proposals'
    AND INDEX_NAME = 'idx_proposals_status'
);

SET @drop_idx := IF(
  @idx_exists > 0,
  'ALTER TABLE proposals DROP INDEX idx_proposals_status',
  'SELECT 1'
);
PREPARE stmt FROM @drop_idx;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_type := (
  SELECT DATA_TYPE
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'proposals'
    AND COLUMN_NAME = 'status'
);

SET @widen := IF(
  @col_type = 'varchar',
  'ALTER TABLE proposals MODIFY status TEXT NOT NULL',
  'SELECT 1'
);
PREPARE stmt FROM @widen;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE proposals
SET status = CONCAT('["', status, '"]')
WHERE status NOT LIKE '[%';
