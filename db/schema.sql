-- Vinylhound Database Schema
-- This schema supports the monorepo structure and can be easily split for microservices

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    token VARCHAR(255) PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- User content table
CREATE TABLE IF NOT EXISTS user_content (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    entry TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Albums table
CREATE TABLE IF NOT EXISTS albums (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL,
    release_year INTEGER,
    genre VARCHAR(100),
    cover_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Artists table
CREATE TABLE IF NOT EXISTS artists (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    biography TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Songs table
CREATE TABLE IF NOT EXISTS songs (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL,
    album_id BIGINT REFERENCES albums(id) ON DELETE CASCADE,
    duration INTEGER, -- in seconds
    track_num INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ratings table
CREATE TABLE IF NOT EXISTS ratings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    album_id BIGINT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, album_id)
);

-- Reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    album_id BIGINT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    genre VARCHAR(100) NOT NULL,
    weight DECIMAL(3,2) NOT NULL DEFAULT 1.0 CHECK (weight >= 0.0 AND weight <= 1.0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Playlists table
CREATE TABLE IF NOT EXISTS playlists (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    owner VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Playlist songs table
CREATE TABLE IF NOT EXISTS playlist_songs (
    id BIGSERIAL PRIMARY KEY,
    playlist_id BIGINT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL,
    album VARCHAR(255),
    length_seconds INTEGER DEFAULT 0,
    genre VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(playlist_id, position)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_content_user_id ON user_content(user_id);
CREATE INDEX IF NOT EXISTS idx_albums_artist ON albums(artist);
CREATE INDEX IF NOT EXISTS idx_albums_genre ON albums(genre);
CREATE INDEX IF NOT EXISTS idx_albums_release_year ON albums(release_year);
CREATE INDEX IF NOT EXISTS idx_artists_name ON artists(name);
CREATE INDEX IF NOT EXISTS idx_songs_album_id ON songs(album_id);
CREATE INDEX IF NOT EXISTS idx_songs_artist ON songs(artist);
CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_album_id ON ratings(album_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rating ON ratings(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_album_id ON reviews(album_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_genre ON user_preferences(genre);
CREATE INDEX IF NOT EXISTS idx_playlists_owner ON playlists(owner);
CREATE INDEX IF NOT EXISTS idx_playlist_songs_playlist_id ON playlist_songs(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_songs_artist ON playlist_songs(artist);

-- Sample data for development
-- Seed core artists
INSERT INTO artists (name, biography, image_url) VALUES
  ('The Beatles', 'English rock band formed in Liverpool in 1960.', 'https://example.com/artists/the-beatles.jpg'),
  ('Pink Floyd', 'English progressive rock band formed in London in 1965.', 'https://example.com/artists/pink-floyd.jpg'),
  ('Miles Davis', 'American jazz trumpeter, bandleader, and composer.', 'https://example.com/artists/miles-davis.jpg')
ON CONFLICT (name) DO NOTHING;

-- Seed key albums
INSERT INTO albums (title, artist, release_year, genre, cover_url) VALUES
  ('Abbey Road', 'The Beatles', 1969, 'Rock', 'https://example.com/albums/abbey-road.jpg'),
  ('Sgt. Pepper''s Lonely Hearts Club Band', 'The Beatles', 1967, 'Rock', 'https://example.com/albums/sgt-pepper.jpg'),
  ('Revolver', 'The Beatles', 1966, 'Rock', 'https://example.com/albums/revolver.jpg'),
  ('The Dark Side of the Moon', 'Pink Floyd', 1973, 'Progressive Rock', 'https://example.com/albums/dark-side-of-the-moon.jpg'),
  ('Wish You Were Here', 'Pink Floyd', 1975, 'Progressive Rock', 'https://example.com/albums/wish-you-were-here.jpg'),
  ('Animals', 'Pink Floyd', 1977, 'Progressive Rock', 'https://example.com/albums/animals.jpg'),
  ('Kind of Blue', 'Miles Davis', 1959, 'Jazz', 'https://example.com/albums/kind-of-blue.jpg'),
  ('Bitches Brew', 'Miles Davis', 1970, 'Jazz', 'https://example.com/albums/bitches-brew.jpg'),
  ('Sketches of Spain', 'Miles Davis', 1960, 'Jazz', 'https://example.com/albums/sketches-of-spain.jpg')
ON CONFLICT DO NOTHING;

-- Abbey Road track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'The Beatles', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('Come Together', 259, 1),
  ('Something', 182, 2),
  ('Maxwell''s Silver Hammer', 207, 3),
  ('Oh! Darling', 208, 4),
  ('Octopus''s Garden', 171, 5),
  ('I Want You (She''s So Heavy)', 467, 6),
  ('Here Comes the Sun', 185, 7),
  ('Because', 164, 8),
  ('You Never Give Me Your Money', 243, 9),
  ('Sun King', 153, 10),
  ('Mean Mr. Mustard', 66, 11),
  ('Polythene Pam', 73, 12),
  ('She Came In Through the Bathroom Window', 116, 13),
  ('Golden Slumbers', 91, 14),
  ('Carry That Weight', 100, 15),
  ('The End', 125, 16),
  ('Her Majesty', 23, 17)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'Abbey Road' AND a.artist = 'The Beatles'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );

-- Sgt. Pepper''s Lonely Hearts Club Band track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'The Beatles', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('Sgt. Pepper''s Lonely Hearts Club Band', 122, 1),
  ('With a Little Help from My Friends', 164, 2),
  ('Lucy in the Sky with Diamonds', 206, 3),
  ('Getting Better', 167, 4),
  ('Fixing a Hole', 150, 5),
  ('She''s Leaving Home', 215, 6),
  ('Being for the Benefit of Mr. Kite!', 160, 7),
  ('Within You Without You', 305, 8),
  ('When I''m Sixty-Four', 167, 9),
  ('Lovely Rita', 162, 10),
  ('Good Morning Good Morning', 152, 11),
  ('Sgt. Pepper''s Lonely Hearts Club Band (Reprise)', 78, 12),
  ('A Day in the Life', 335, 13)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'Sgt. Pepper''s Lonely Hearts Club Band' AND a.artist = 'The Beatles'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );

-- Revolver track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'The Beatles', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('Taxman', 156, 1),
  ('Eleanor Rigby', 138, 2),
  ('I''m Only Sleeping', 183, 3),
  ('Love You To', 193, 4),
  ('Here, There and Everywhere', 145, 5),
  ('Yellow Submarine', 164, 6),
  ('She Said She Said', 158, 7),
  ('Good Day Sunshine', 125, 8),
  ('And Your Bird Can Sing', 119, 9),
  ('For No One', 122, 10),
  ('Doctor Robert', 149, 11),
  ('I Want to Tell You', 152, 12),
  ('Got to Get You into My Life', 152, 13),
  ('Tomorrow Never Knows', 180, 14)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'Revolver' AND a.artist = 'The Beatles'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );

-- The Dark Side of the Moon track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'Pink Floyd', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('Speak to Me', 90, 1),
  ('Breathe (In the Air)', 168, 2),
  ('On the Run', 215, 3),
  ('Time', 413, 4),
  ('The Great Gig in the Sky', 276, 5),
  ('Money', 382, 6),
  ('Us and Them', 462, 7),
  ('Any Colour You Like', 201, 8),
  ('Brain Damage', 228, 9),
  ('Eclipse', 123, 10)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'The Dark Side of the Moon' AND a.artist = 'Pink Floyd'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );

-- Wish You Were Here track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'Pink Floyd', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('Shine On You Crazy Diamond (Parts I-V)', 810, 1),
  ('Welcome to the Machine', 441, 2),
  ('Have a Cigar', 311, 3),
  ('Wish You Were Here', 334, 4),
  ('Shine On You Crazy Diamond (Parts VI-IX)', 732, 5)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'Wish You Were Here' AND a.artist = 'Pink Floyd'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );

-- Animals track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'Pink Floyd', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('Pigs on the Wing (Part One)', 95, 1),
  ('Dogs', 1025, 2),
  ('Pigs (Three Different Ones)', 683, 3),
  ('Sheep', 603, 4),
  ('Pigs on the Wing (Part Two)', 92, 5)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'Animals' AND a.artist = 'Pink Floyd'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );

-- Kind of Blue track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'Miles Davis', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('So What', 545, 1),
  ('Freddie Freeloader', 589, 2),
  ('Blue in Green', 329, 3),
  ('All Blues', 693, 4),
  ('Flamenco Sketches', 567, 5)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'Kind of Blue' AND a.artist = 'Miles Davis'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );

-- Bitches Brew track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'Miles Davis', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('Pharaoh''s Dance', 1227, 1),
  ('Bitches Brew', 1665, 2),
  ('Spanish Key', 1050, 3),
  ('John McLaughlin', 270, 4),
  ('Miles Runs the Voodoo Down', 871, 5),
  ('Sanctuary', 285, 6)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'Bitches Brew' AND a.artist = 'Miles Davis'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );

-- Sketches of Spain track list
INSERT INTO songs (title, artist, album_id, duration, track_num)
SELECT v.title, 'Miles Davis', a.id, v.duration, v.track_num
FROM albums a
JOIN (VALUES
  ('Concierto de Aranjuez (Adagio)', 1007, 1),
  ('Will o'' the Wisp', 195, 2),
  ('The Pan Piper', 236, 3),
  ('Saeta', 303, 4),
  ('Solea', 743, 5)
) AS v(title, duration, track_num) ON TRUE
WHERE a.title = 'Sketches of Spain' AND a.artist = 'Miles Davis'
  AND NOT EXISTS (
    SELECT 1 FROM songs s WHERE s.album_id = a.id AND s.title = v.title
  );
