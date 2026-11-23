# Giswater QGIS Plugin - Dev Container

Development environment for the Giswater QGIS plugin: QGIS 4.0.3 (Qt6), PostgreSQL 17,
PostGIS 3.5, pgRouting 3.8, plus an Xvfb/TigerVNC + noVNC desktop for the QGIS GUI.

## Quick Start

1. Open the repository root in VS Code (the folder that contains `.devcontainer/`)
2. Install the "Dev Containers" extension
3. `F1` -> "Dev Containers: Reopen in Container"
4. Wait for the build and the `post-create.sh` setup

The configuration lives at `.devcontainer/devcontainer.json`. It is picked up from
there; it must not be nested any deeper.

## Using QGIS GUI (VNC)

```bash
start-vnc
```

Then either open <http://localhost:6080/vnc.html> (noVNC, recommended) or connect a VNC
viewer to `localhost:5901`. Password: `giswater`.

`stop-vnc` shuts both the VNC server and the noVNC proxy down.

## Using PyQGIS

```bash
python3 your_script.py
```

`start-vnc` must be running before you import `qgis.core` / create widgets, because
`QT_QPA_PLATFORM=xcb` and `DISPLAY=:1` are set for the session.

## Database

Inside the dev container (it shares the PostgreSQL network namespace):

```bash
psql -h localhost -p 5432 -U giswater -d giswater
```

From the Windows host, PostgreSQL is published on port 5433:

```bash
psql -h localhost -p 5433 -U giswater -d giswater
```

Credentials in both cases: database `giswater`, user `giswater`, password `giswater`.
Initialisation (PostGIS, PostGIS topology, pgRouting, hstore, uuid-ossp) runs once, from
`.devcontainer/init-db.sh`, when the `postgres-data` volume is first created.

## Help

```bash
bash ~/giswater-help.sh
```
