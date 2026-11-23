#!/bin/bash

echo "=========================================="
echo "Giswater Development Environment Setup"
echo "=========================================="
echo ""

echo "Initializing Git submodules..."
git config --global --add safe.directory /workspace
if git -C /workspace rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C /workspace submodule update --init --recursive
    git -C /workspace config submodule.recurse true
    echo "  Submodules initialized"
else
    echo "  Skipped (not a Git repository)"
fi
echo ""

if [ -f /workspace/.pre-commit-config.yaml ]; then
    echo "Setting up pre-commit hooks..."
    if git -C /workspace rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        pre-commit install
        echo "  Pre-commit hooks installed"
    else
        echo "  Skipped (not a Git repository)"
    fi
    echo ""
fi

echo "Setting up QGIS plugin directory..."
# Named volumes created by an older run may be owned by root; take them back.
sudo chown -R "$(id -u):$(id -g)" "$HOME/.local/share/QGIS" "$HOME/.config/QGIS" 2>/dev/null || true
mkdir -p ~/.local/share/QGIS/QGIS4/profiles/default/python/plugins
ln -sf /workspace ~/.local/share/QGIS/QGIS4/profiles/default/python/plugins/giswater 2>/dev/null || true
echo "  Plugin directory configured"
echo ""

install_qpip() {
    if ! command -v qgis-plugin-manager >/dev/null 2>&1; then
        echo "  qgis-plugin-manager not found, skipping plugin installation"
        echo ""
        return
    fi

    echo "Installing QGIS plugins via qgis-plugin-manager..."
    export QGIS_PLUGINPATH="$HOME/.local/share/QGIS/QGIS4/profiles/default/python/plugins"
    qgis-plugin-manager init
    qgis-plugin-manager update
    qgis-plugin-manager install qpip
    echo "  QGIS plugins installed"
    echo ""
}

install_qpip

seed_qgis_ini() {
    local qgis_ini="$HOME/.local/share/QGIS/QGIS4/profiles/default/QGIS/QGIS4.ini"

    mkdir -p "$(dirname "$qgis_ini")"

    cat >> "$qgis_ini" <<'EOF'

[PostgreSQL/connections]
selected=dev

[PostgreSQL/connections/dev]
host=localhost
port=5432
database=giswater
username=giswater
password=giswater
saveUsername=true
savePassword=true

[PythonPlugins]
a00_qpip=true
giswater=true

[QPIP]
check_on_startup=yes
EOF

    echo "  QGIS configuration seeded"
    echo ""
}

seed_qgis_ini

# setup_gui_shortcuts() {
#     local desktop_dir="$HOME/Desktop"
#     local helper_dir="$HOME/.local/bin"

#     mkdir -p "$desktop_dir"

#     cp /usr/share/applications/org.qgis.qgis.desktop "$desktop_dir/qgis.desktop"
#     cp /usr/share/applications/designer-qt5.desktop "$desktop_dir/designer-qt5.desktop"
#     chmod +x "$desktop_dir/qgis.desktop" "$desktop_dir/designer-qt5.desktop"

    
#     echo "  Desktop shortcuts configured"
#     echo ""
# }

# setup_gui_shortcuts


if [ "${GISWATER_SKIP_DB_WAIT:-0}" = "1" ]; then
    echo "Skipping PostgreSQL wait because GISWATER_SKIP_DB_WAIT=1"
    echo ""
else
    echo "Waiting for PostgreSQL..."
    until pg_isready -h localhost -p 5432 -U giswater > /dev/null 2>&1; do
        sleep 1
    done
    echo "  PostgreSQL is ready"
    echo ""
fi

cat > ~/giswater-help.sh << 'EOF'
#!/bin/bash
echo ""
echo "============================================================"
echo "           Giswater Development Environment"
echo "============================================================"
echo ""
echo "QGIS GUI (VNC):"
echo "   start-vnc          Start VNC server for QGIS GUI"
echo "   stop-vnc           Stop VNC server"
echo "   Browser: http://localhost:6080/vnc.html (password: giswater)"
echo "   VNC client: localhost:5901 (password: giswater)"
echo ""
echo "PyQGIS (Scripting):"
echo "   python3 script.py  Run Python scripts with QGIS API"
echo ""
echo "Database:"
echo "   psql -h localhost -U giswater -d giswater   (inside container: port 5432)"
echo "   From the host: localhost:5433 | DB: giswater | User: giswater | Pass: giswater"
echo ""
echo "Development:"
echo "   black .            Format Python code"
echo "   flake8 .           Lint Python code"
echo "   pytest             Run tests"
echo ""
echo "Repository Layout:"
echo "   dbmodel/           PostgreSQL data model (tracked in this repo)"
echo "   libs/              tools_* libraries (git submodule, pulled automatically)"
echo ""
echo "Versions:"
echo "   QGIS: 4.0.3"
echo "   PostgreSQL: 17"
echo "   PostGIS: 3.5"
echo "   pgRouting: 3.8"
echo ""
EOF
chmod +x ~/giswater-help.sh

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
bash ~/giswater-help.sh