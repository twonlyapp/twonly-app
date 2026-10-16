-- Bookkeeping for Signal session resets.
--
-- A reset asks the peer to open a fresh session. If their side cannot honour
-- that -- a mismatched identity key, a peer stuck on a state we reject -- both
-- clients would keep answering each other's reset requests forever. These rows
-- bound that: one reset per peer per cooldown, and a capped number per window.
CREATE TABLE IF NOT EXISTS signal_session_resets (
    name TEXT NOT NULL,
    device_id INTEGER NOT NULL,
    last_reset_at INTEGER NOT NULL,
    window_started_at INTEGER NOT NULL,
    resets_in_window INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (name, device_id)
);
