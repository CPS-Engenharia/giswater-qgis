FROM qgis/qgis:4.0.3-questing

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    git-lfs \
    gnupg \
    ca-certificates \
    sudo \
    locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Avoid Git safe.directory warnings for the mounted workspace.
RUN git config --system --add safe.directory /workspace \
    && git config --system --add safe.directory /workspace/libs

RUN apt-get update && apt-get install -y \
    tigervnc-standalone-server \
    tigervnc-common \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    xfce-polkit \
    polkitd \
    pkexec \
    dbus-x11 \
    xfonts-base \
    xfonts-100dpi \
    xfonts-75dpi \
    novnc \
    websockify \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    postgresql-client \
    libqt6sql6-psql \
    vim \
    nano \
    htop \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --ignore-installed --break-system-packages pgadmin4    

RUN pip3 install --no-cache-dir --ignore-installed --break-system-packages \
    black \
    flake8 \
    pylint \
    pre-commit \
    ipython \
    ipdb \
    qgis-plugin-manager

RUN if getent group "$USER_GID" >/dev/null 2>&1; then \
    GROUP_NAME="$(getent group "$USER_GID" | cut -d: -f1)"; \
    elif getent group "$USERNAME" >/dev/null 2>&1; then \
    GROUP_NAME="$USERNAME"; \
    else \
    groupadd --gid "$USER_GID" "$USERNAME"; \
    GROUP_NAME="$USERNAME"; \
    fi \
    && if id -u "$USERNAME" >/dev/null 2>&1; then \
    usermod -g "$GROUP_NAME" "$USERNAME"; \
    if [ "$(id -u "$USERNAME")" != "$USER_UID" ]; then \
    usermod -u "$USER_UID" "$USERNAME"; \
    fi; \
    elif getent passwd "$USER_UID" >/dev/null 2>&1; then \
    EXISTING_USER="$(getent passwd "$USER_UID" | cut -d: -f1)"; \
    usermod -g "$GROUP_NAME" "$EXISTING_USER"; \
    usermod -l "$USERNAME" "$EXISTING_USER"; \
    else \
    useradd --uid "$USER_UID" --gid "$GROUP_NAME" -m "$USERNAME"; \
    fi \
    && USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)" \
    && if [ "$USER_HOME" != "/home/$USERNAME" ]; then \
    usermod -d "/home/$USERNAME" -m "$USERNAME"; \
    fi \
    && echo "$USERNAME" ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN git lfs install --system

# Avoid launching the XFCE PolicyKit agent dialog on desktop startup.
RUN rm -f /etc/xdg/autostart/xfce-polkit.desktop

USER root
WORKDIR /workspace

# Create index.html redirect for noVNC
RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=/vnc.html"/></head></html>' > /usr/share/novnc/index.html

# Pre-create every directory that is later mounted as a named volume. If the
# mountpoint does not exist in the image, Docker creates it as root:root and the
# unprivileged user cannot write into it (QGIS profiles / settings would fail).
RUN USER_HOME="$(getent passwd $USERNAME | cut -d: -f6)" \
    && mkdir -p "$USER_HOME/.config/tigervnc" \
    && mkdir -p "$USER_HOME/.config/QGIS" \
    && mkdir -p "$USER_HOME/.local/share/QGIS" \
    && chown -R $(id -u $USERNAME):$(id -g $USERNAME) "$USER_HOME"

RUN USER_HOME="$(getent passwd $USERNAME | cut -d: -f6)" \
    && printf '#!/bin/bash\nunset WAYLAND_DISPLAY\nexport DISPLAY=:1\nexport XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_TYPE=x11\nexec dbus-launch --exit-with-session startxfce4' > "$USER_HOME/.config/tigervnc/xstartup" \
    && chmod +x "$USER_HOME/.config/tigervnc/xstartup" \
    && chown $(id -u $USERNAME):$(id -g $USERNAME) "$USER_HOME/.config/tigervnc/xstartup"

USER $USERNAME

ENV PYTHONPATH=/usr/share/qgis/python:/usr/share/qgis/python/plugins
ENV QGIS_PREFIX_PATH=/usr

# Requirements are handled at image build time above so QGIS can access distro-managed packages.

RUN cat > /tmp/start-vnc <<'EOF'
#!/bin/bash
unset WAYLAND_DISPLAY
export DISPLAY=:1
VNC_DIR="$HOME/.config/tigervnc"
LEGACY_VNC_DIR="$HOME/.vnc"

mkdir -p "$VNC_DIR"
mkdir -p "$LEGACY_VNC_DIR"

if [ -d "$LEGACY_VNC_DIR" ]; then
    [ -f "$LEGACY_VNC_DIR/passwd" ] && cp -f "$LEGACY_VNC_DIR/passwd" "$VNC_DIR/passwd"
    [ -f "$LEGACY_VNC_DIR/xstartup" ] && cp -f "$LEGACY_VNC_DIR/xstartup" "$VNC_DIR/xstartup"
    mv "$LEGACY_VNC_DIR" "$LEGACY_VNC_DIR.bak" 2>/dev/null || rm -rf "$LEGACY_VNC_DIR"
fi

if [ ! -f "$VNC_DIR/passwd" ]; then
    echo "Setting up VNC password..."
    echo "${VNC_PASSWORD:-giswater}" | vncpasswd -f > "$VNC_DIR/passwd"
    chmod 600 "$VNC_DIR/passwd"
fi

cp -f "$VNC_DIR/passwd" "$LEGACY_VNC_DIR/passwd" 2>/dev/null || true
chmod 600 "$LEGACY_VNC_DIR/passwd" 2>/dev/null || true

if [ ! -f "$VNC_DIR/xstartup" ]; then
    cat > "$VNC_DIR/xstartup" <<'XSTARTUP'
#!/bin/bash
unset WAYLAND_DISPLAY
export DISPLAY=:1
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_TYPE=x11
exec dbus-launch --exit-with-session startxfce4
XSTARTUP
    chmod +x "$VNC_DIR/xstartup"
fi

cp -f "$VNC_DIR/xstartup" "$LEGACY_VNC_DIR/xstartup" 2>/dev/null || true
chmod +x "$LEGACY_VNC_DIR/xstartup" 2>/dev/null || true

sudo mkdir -p /tmp/.ICE-unix
sudo chmod 1777 /tmp/.ICE-unix

echo "Starting VNC server on :1..."
vncserver :1 -geometry ${VNC_RESOLUTION:-1920x1080} -depth 24 -localhost no -xstartup "$VNC_DIR/xstartup"

echo "Starting noVNC web server..."
websockify -D --web=/usr/share/novnc/ 6080 localhost:5901

echo ""
echo "VNC server started!"
echo ""
echo "Connect via browser (recommended):"
echo "  URL: http://localhost:6080/vnc.html"
echo "  Password: ${VNC_PASSWORD:-giswater}"
echo ""
echo "Or connect with VNC client:"
echo "  Address: localhost:5901"
echo "  Password: ${VNC_PASSWORD:-giswater}"
echo ""
echo "To stop: stop-vnc"
echo ""
echo "VNC services are running in the background."
EOF

RUN sudo mv /tmp/start-vnc /usr/local/bin/start-vnc \
    && sudo chmod +x /usr/local/bin/start-vnc

RUN printf '#!/bin/bash\npkill -f websockify 2>/dev/null || true\nvncserver -kill :1 2>/dev/null || true\necho "VNC server and noVNC stopped"' > /tmp/stop-vnc \
    && sudo mv /tmp/stop-vnc /usr/local/bin/stop-vnc \
    && sudo chmod +x /usr/local/bin/stop-vnc

RUN cat > /tmp/99-noprompt.rules <<'RULES'
polkit.addRule(function(action, subject) {
    return polkit.Result.YES;
});
RULES

RUN sudo mv /tmp/99-noprompt.rules /etc/polkit-1/rules.d/99-noprompt.rules \
    && sudo chmod 644 /etc/polkit-1/rules.d/99-noprompt.rules

CMD ["/bin/bash"]
