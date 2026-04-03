-- Schema for diploma verification demo
-- Run automatically by the postgres image on first startup.

CREATE TABLE IF NOT EXISTS universities (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  api_key_hash TEXT NOT NULL,
  UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS diplomas (
  id BIGSERIAL PRIMARY KEY,
  university_id BIGINT NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  student_dob DATE NOT NULL,
  degree TEXT NOT NULL,
  specialization TEXT NOT NULL,
  issue_date DATE NOT NULL,
  diploma_number TEXT NOT NULL,
  data_hash CHAR(64) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (data_hash)
);

CREATE INDEX IF NOT EXISTS diplomas_university_id_idx ON diplomas(university_id);
CREATE INDEX IF NOT EXISTS diplomas_data_hash_idx ON diplomas(data_hash);

CREATE TABLE IF NOT EXISTS certificates (
  id BIGSERIAL PRIMARY KEY,
  diploma_id BIGINT NOT NULL REFERENCES diplomas(id) ON DELETE CASCADE,
  qr_token UUID NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS certificates_qr_token_idx ON certificates(qr_token);
CREATE INDEX IF NOT EXISTS certificates_diploma_active_idx ON certificates(diploma_id, is_active);

