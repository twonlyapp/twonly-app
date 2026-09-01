-- Where the editor's cutter placed the two ends of a recorded video.
--
-- Only the bounds are stored, never a cut copy of the clip: the send already
-- transcodes every video once, so the trim is applied by that pass and the
-- original recording stays intact until the media is retired. That also keeps
-- the cut reversible while the editor is open.
--
-- NULL on either side means "not cut there", which is what an untouched clip
-- and every non-video media file carries.
ALTER TABLE media_files ADD COLUMN trim_start_ms INTEGER;
ALTER TABLE media_files ADD COLUMN trim_end_ms INTEGER;
