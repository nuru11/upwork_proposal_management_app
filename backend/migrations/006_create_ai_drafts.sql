CREATE TABLE IF NOT EXISTS ai_drafts (
  id CHAR(36) NOT NULL PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  job_description MEDIUMTEXT NOT NULL,
  notes TEXT NULL,
  domain VARCHAR(32) NOT NULL,
  language VARCHAR(32) NOT NULL,
  issues JSON NOT NULL,
  solutions JSON NOT NULL,
  body MEDIUMTEXT NOT NULL,
  client_name VARCHAR(255) NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  deleted_at DATETIME(3) NULL,
  KEY idx_ai_drafts_user_id (user_id),
  KEY idx_ai_drafts_updated_at (updated_at),
  CONSTRAINT fk_ai_drafts_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
