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

CREATE TABLE IF NOT EXISTS albums (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    artist        TEXT        NOT NULL,
    title         TEXT        NOT NULL,
    release_year  INTEGER     NOT NULL CHECK (release_year > 0),
    tracks        JSONB       NOT NULL DEFAULT '[]'::jsonb,
    genres        JSONB       NOT NULL DEFAULT '[]'::jsonb,
    rating        INTEGER     NOT NULL CHECK (rating BETWEEN 1 AND 5),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_albums_user_id ON albums(user_id);

CREATE TABLE IF NOT EXISTS user_album_preferences (
    user_id    BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    album_id   BIGINT      NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    rating     INTEGER     CHECK (rating BETWEEN 1 AND 5),
    favorited  BOOLEAN     NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, album_id)
);
