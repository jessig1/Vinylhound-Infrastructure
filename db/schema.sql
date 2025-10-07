-- Schema for Vinyhound Postgres backend.
-- Run inside psql or migrate tooling after creating the database.

CREATE TABLE IF NOT EXISTS users (
    id            BIGSERIAL PRIMARY KEY,
    username      TEXT        NOT NULL UNIQUE,
    password_hash BYTEA       NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_content (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    position   INTEGER NOT NULL,
    entry      TEXT    NOT NULL,
    CONSTRAINT user_content_position_unique UNIQUE (user_id, position)
);

CREATE INDEX IF NOT EXISTS idx_user_content_user_id ON user_content(user_id);

CREATE TABLE IF NOT EXISTS sessions (
    token       TEXT        PRIMARY KEY,
    user_id     BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
