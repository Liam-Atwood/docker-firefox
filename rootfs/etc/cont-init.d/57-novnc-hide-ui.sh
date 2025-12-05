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

CUSTOM_CSS='/* noVNC Docker customizations: hide control bar and cursor */
#noVNC_control_bar, #noVNC_control_bar_handle, #noVNC_control_bar_anchor {
    display: none !important;
}
#noVNC_container, #noVNC_screen, #noVNC_canvas, #noVNC_mouse_capture, html, body {
    cursor: none !important;
}

/* noVNC Docker customizations: touch-friendly v3 */
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
'

NOVNC_CSS_PATHS="$(
    find $SEARCH_DIRS \
        -maxdepth 6 -type f \
        \( -name 'ui.css' -o -name 'ui.min.css' -o -name 'style.css' -o -name 'noVNC.css' -o -name 'novnc.css' -o -name 'base.css' -o -name 'app.css' -o -path '*/styles/*.css' \)
        2>/dev/null
)"

PATCHED=0

if [ -z "$NOVNC_CSS_PATHS" ]; then
    echo "WARN: Could not find noVNC CSS to patch." >&2
else
    for NOVNC_CSS_PATH in $NOVNC_CSS_PATHS; do
        echo "Using noVNC CSS at $NOVNC_CSS_PATH"

        if grep -q "noVNC Docker customizations: touch-friendly v3" "$NOVNC_CSS_PATH"; then
            echo "Already patched: $NOVNC_CSS_PATH"
            PATCHED=1
            continue
        fi

        if grep -q "noVNC Docker customizations: touch-friendly" "$NOVNC_CSS_PATH" \
            || grep -q "noVNC Docker customizations: hide control bar" "$NOVNC_CSS_PATH"; then
            printf "\n%s\n" "$CUSTOM_CSS" >> "$NOVNC_CSS_PATH"
            echo "Updated existing patch markers: $NOVNC_CSS_PATH"
        else
            printf "\n%s\n" "$CUSTOM_CSS" >> "$NOVNC_CSS_PATH"
            echo "Patched $NOVNC_CSS_PATH"
        fi

        PATCHED=1
    done
fi

NOVNC_HTML_PATHS="$(
    find $SEARCH_DIRS \
        -maxdepth 4 -type f \
        \( -name 'vnc.html' -o -name 'index.html' -o -name '*vnc*.html' -o -name 'lite.html' \) \
        2>/dev/null
)"

add_inline_style() {
    HTML_PATH="$1"

    if grep -q "noVNC Docker customizations: touch-friendly v3" "$HTML_PATH"; then
        echo "Already patched HTML: $HTML_PATH"
        PATCHED=1
        return
    fi

    TMP_STYLE="$(mktemp)"
    cat > "$TMP_STYLE" <<STYLE
<!-- noVNC Docker customizations: touch-friendly v3 -->
<style>
$CUSTOM_CSS
</style>
STYLE

    if grep -q "</head>" "$HTML_PATH"; then
        # Insert style block before closing head tag.
        sed -i "/<\/head>/{r $TMP_STYLE
}" "$HTML_PATH"
    else
        printf "\n" >> "$HTML_PATH"
        cat "$TMP_STYLE" >> "$HTML_PATH"
    fi

    rm -f "$TMP_STYLE"
    echo "Injected inline styles into $HTML_PATH"
    PATCHED=1
}

for NOVNC_HTML_PATH in $NOVNC_HTML_PATHS; do
    echo "Using noVNC HTML at $NOVNC_HTML_PATH"
    add_inline_style "$NOVNC_HTML_PATH"
done

if [ "$PATCHED" -eq 0 ]; then
    echo "WARN: No CSS or HTML files were patched." >&2
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
