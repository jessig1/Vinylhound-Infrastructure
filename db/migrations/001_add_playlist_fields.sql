-- Migration: Add missing fields to playlists table
-- Date: 2025-10-27

-- Add description column
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS description TEXT;

-- Add user_id column (temporarily nullable)
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS user_id BIGINT;

-- Add tags column
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- Add is_public column
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;

-- Update existing playlists to set user_id based on owner username
UPDATE playlists
SET user_id = users.id
FROM users
WHERE playlists.owner = users.username
AND playlists.user_id IS NULL;

-- Make user_id NOT NULL and add foreign key constraint
ALTER TABLE playlists ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE playlists ADD CONSTRAINT fk_playlists_user_id
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Add index for user_id if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON playlists(user_id);
