/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

-- Regression test for: gw_fct_admin_role_upsertuser only seeded selector_state with
-- state_id = 1 for a newly created user, instead of one row per value_state. Users
-- created this way could not see features in any state other than 1 (e.g. "planned")
-- until someone manually fixed their selector_state rows.
-- Fixed in gw_fct_admin_role_upsertuser (base/fct and functions/fct mirror).

SELECT plan(2);

-- Needs a real role to grant; role_basic exists in every giswater schema
SELECT is(
	(gw_fct_admin_role_upsertuser($${"client":{"device":4, "infoType":1, "lang":"en_US"},
	"form":{}, "data":{"filterFields":{}, "pageInfo":{}, "user_id":"gw_test_upsertuser_state",
	"user_name":"gw_test_upsertuser_state", "password":"pgtap_test_pwd", "role":"role_basic",
	"action":"insert"}}$$)::JSON)->>'status',
	'Accepted',
	'gw_fct_admin_role_upsertuser insert action returns status "Accepted"'
);

-- The actual regression check: one selector_state row per value_state, not just state 1
SELECT is(
	(SELECT count(*)::integer FROM selector_state WHERE cur_user = 'gw_test_upsertuser_state'),
	(SELECT count(*)::integer FROM value_state),
	'new user gets a selector_state row for every value_state (bug: only state_id=1 was seeded)'
);

SELECT finish();
ROLLBACK;
