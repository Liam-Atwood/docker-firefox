#!/bin/sh

set -e
set -u

POSSIBLE_DIRS="/usr/share/novnc /opt/novnc /opt/noVNC /usr/lib/novnc"
SEARCH_DIRS=""
for DIR in $POSSIBLE_DIRS; do
    if [ -d "$DIR" ]; then
        SEARCH_DIRS="$SEARCH_DIRS $DIR"
    fi
done

if [ -z "$SEARCH_DIRS" ]; then
    echo "WARN: Could not find a noVNC directory to patch." >&2
    exit 0
fi

NOVNC_CSS_PATHS="$(
    find $SEARCH_DIRS \
        -maxdepth 3 -type f \
        \( -name 'ui.css' -o -name 'ui.min.css' -o -name 'style.css' -o -name 'noVNC.css' -o -name 'novnc.css' -o -name 'base.css' \)
)"

if [ -z "$NOVNC_CSS_PATHS" ]; then
    echo "WARN: Could not find noVNC CSS to patch." >&2
    exit 0
fi

PATCHED=0
for NOVNC_CSS_PATH in $NOVNC_CSS_PATHS; do
    echo "Using noVNC CSS at $NOVNC_CSS_PATH"

    if grep -q "noVNC Docker customizations: touch-friendly v2" "$NOVNC_CSS_PATH"; then
        echo "Already patched: $NOVNC_CSS_PATH"
        PATCHED=1
        continue
    fi

    if grep -q "noVNC Docker customizations: touch-friendly" "$NOVNC_CSS_PATH"; then
        cat <<'CSS' >> "$NOVNC_CSS_PATH"

/* noVNC Docker customizations: touch-friendly v2 */
html, body, #noVNC_container, #noVNC_screen, #noVNC_canvas, #noVNC_mouse_capture {
    touch-action: pan-x pan-y;
    -ms-touch-action: pan-x pan-y;
    overscroll-behavior: contain;
    user-select: none;
    -webkit-touch-callout: none;
    -webkit-tap-highlight-color: transparent;
}
#noVNC_container img, #noVNC_screen img, #noVNC_canvas img {
    -webkit-user-drag: none;
    user-drag: none;
    user-select: none;
    touch-action: manipulation;
}
CSS
        echo "Updated with touch-friendly v2 CSS: $NOVNC_CSS_PATH"
        PATCHED=1
        continue
    fi

    if grep -q "noVNC Docker customizations: hide control bar" "$NOVNC_CSS_PATH"; then
        cat <<'CSS' >> "$NOVNC_CSS_PATH"

/* noVNC Docker customizations: touch-friendly v2 */
html, body, #noVNC_container, #noVNC_screen, #noVNC_canvas, #noVNC_mouse_capture {
    touch-action: pan-x pan-y;
    -ms-touch-action: pan-x pan-y;
    overscroll-behavior: contain;
    user-select: none;
    -webkit-touch-callout: none;
    -webkit-tap-highlight-color: transparent;
}
#noVNC_container img, #noVNC_screen img, #noVNC_canvas img {
    -webkit-user-drag: none;
    user-drag: none;
    user-select: none;
    touch-action: manipulation;
}
CSS
        echo "Patched with touch-friendly v2 CSS: $NOVNC_CSS_PATH"
    else
        cat <<'CSS' >> "$NOVNC_CSS_PATH"

/* noVNC Docker customizations: hide control bar and cursor */
#noVNC_control_bar, #noVNC_control_bar_handle, #noVNC_control_bar_anchor {
    display: none !important;
}
#noVNC_container, #noVNC_screen, #noVNC_canvas, #noVNC_mouse_capture, html, body {
    cursor: none !important;
}

/* noVNC Docker customizations: touch-friendly v2 */
html, body, #noVNC_container, #noVNC_screen, #noVNC_canvas, #noVNC_mouse_capture {
    touch-action: pan-x pan-y;
    -ms-touch-action: pan-x pan-y;
    overscroll-behavior: contain;
    user-select: none;
    -webkit-touch-callout: none;
    -webkit-tap-highlight-color: transparent;
}
#noVNC_container img, #noVNC_screen img, #noVNC_canvas img {
    -webkit-user-drag: none;
    user-drag: none;
    user-select: none;
    touch-action: manipulation;
}
CSS
        echo "Patched $NOVNC_CSS_PATH"
    fi

    PATCHED=1
done

if [ "$PATCHED" -eq 0 ]; then
    echo "WARN: No CSS files were patched." >&2
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
