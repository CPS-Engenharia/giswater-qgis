/*
 This file is part of Giswater
 The program is free software: you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation, either version 3 of the License,
 or (at your option) any later version.
 */
BEGIN;
SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME",
	public,
	pg_catalog;
-- Regression test for: changing a connec's arc_id (e.g. via the "Get new arc id"
-- form button) did not redraw the link's arc-side point, leaving the link visually
-- connected to the old arc even though connec.arc_id was updated correctly.
-- Fixed in gw_trg_connect_update (base/ftrg and functions/ftrg mirror).
SELECT plan(5);
SELECT has_function(
		'gw_trg_connect_update'::name,
		'Function gw_trg_connect_update should exist'
	);
-- Fixture: a state=1 connec whose link goes from the connec (feature side) to an arc (exit side)
CREATE TEMP TABLE _t_op AS
SELECT l.link_id,
	l.feature_id AS connec_id,
	l.exit_id AS old_arc_id,
	l.the_geom AS link_geom
FROM link l
	JOIN arc a ON a.arc_id = l.exit_id
	JOIN connec c ON c.connec_id = l.feature_id
WHERE l.exit_type = 'ARC'
	AND l.feature_type = 'CONNEC'
	AND l.state = 1
	AND a.state = 1
ORDER BY l.link_id
LIMIT 1;
SELECT is(
		(
			SELECT count(*)::integer
			FROM _t_op
		),
		1,
		'fixture: operative connec-link-arc found'
	);
-- Fixture: a different arc to reassign the connec to (closest one, so the before/after is meaningful)
CREATE TEMP TABLE _t_new_arc AS
SELECT a.arc_id,
	a.the_geom
FROM arc a,
	_t_op t
WHERE a.state = 1
	AND a.arc_id IS DISTINCT
FROM t.old_arc_id
ORDER BY ST_Distance(a.the_geom, t.link_geom)
LIMIT 1;
SELECT is(
		(
			SELECT count(*)::integer
			FROM _t_new_arc
		),
		1,
		'fixture: a different arc exists to reassign to'
	);
-- This is the exact operation the "Get new arc id" button performs: only arc_id changes,
-- the connec's own the_geom does not move.
UPDATE connec
SET arc_id = (
		SELECT arc_id
		FROM _t_new_arc
	)
WHERE connec_id = (
		SELECT connec_id
		FROM _t_op
	);
SELECT ok(
		(
			SELECT ST_DWithin(ST_EndPoint(l.the_geom), n.the_geom, 0.01)
			FROM link l,
				_t_new_arc n
			WHERE l.link_id = (
					SELECT link_id
					FROM _t_op
				)
		),
		'link arc-side point is redrawn onto the new arc after connec.arc_id changes'
	);
SELECT ok(
		(
			SELECT NOT ST_Equals(
					ST_EndPoint(l.the_geom),
					ST_EndPoint(t.link_geom)
				)
			FROM link l,
				_t_op t
			WHERE l.link_id = t.link_id
		),
		'link geometry actually moved (bug: it used to stay pointing at the old arc)'
	);
SELECT finish();
ROLLBACK;