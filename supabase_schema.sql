-- Kandel Stadtplan App — Supabase Schema
-- Run this in the Supabase SQL Editor

-- 1. Tables

CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  persona_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  location_id TEXT NOT NULL,
  color TEXT NOT NULL CHECK (color IN ('red', 'yellow', 'green')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, location_id)
);

CREATE TABLE group_interventions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  location_id TEXT NOT NULL,
  intervention_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, location_id, intervention_id)
);

-- 2. Row Level Security (open access — no auth)

ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_interventions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sessions_public" ON sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "groups_public" ON groups FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "votes_public" ON votes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "group_interventions_public" ON group_interventions FOR ALL USING (true) WITH CHECK (true);

-- 3. Realtime — enable for votes and group_interventions
ALTER PUBLICATION supabase_realtime ADD TABLE votes;
ALTER PUBLICATION supabase_realtime ADD TABLE group_interventions;

-- 4. Indexes for common queries
CREATE INDEX idx_groups_session ON groups(session_id);
CREATE INDEX idx_votes_group ON votes(group_id);
CREATE INDEX idx_interventions_group ON group_interventions(group_id);
