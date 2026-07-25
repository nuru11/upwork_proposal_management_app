CREATE TABLE IF NOT EXISTS users (
  id CHAR(36) NOT NULL PRIMARY KEY,
  username VARCHAR(64) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  UNIQUE KEY uq_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS templates (
  id CHAR(36) NOT NULL PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  body MEDIUMTEXT NOT NULL,
  language VARCHAR(32) NOT NULL,
  is_favorite TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  deleted_at DATETIME(3) NULL,
  KEY idx_templates_user_id (user_id),
  KEY idx_templates_updated_at (updated_at),
  CONSTRAINT fk_templates_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proposals (
  id CHAR(36) NOT NULL PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  client_name VARCHAR(255) NULL,
  job_url TEXT NULL,
  body MEDIUMTEXT NOT NULL,
  language VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  template_id CHAR(36) NULL,
  notes TEXT NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  submitted_at DATETIME(3) NULL,
  deleted_at DATETIME(3) NULL,
  KEY idx_proposals_user_id (user_id),
  KEY idx_proposals_status (status),
  KEY idx_proposals_language (language),
  KEY idx_proposals_updated_at (updated_at),
  CONSTRAINT fk_proposals_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_proposals_template
    FOREIGN KEY (template_id) REFERENCES templates (id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
