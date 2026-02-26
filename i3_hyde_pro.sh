#!/bin/bash

I3_DIR="$HOME/.config/i3"
MOD_DIR="$I3_DIR/config.d"
SRC="$I3_DIR/config"
BACKUP="$I3_DIR/config.bak"

# 1. Crear backup y carpeta
cp "$SRC" "$BACKUP"
mkdir -p "$MOD_DIR"
rm -f "$MOD_DIR"/*.conf

echo "--- Extrayendo contenido de config a módulos ---"

# Función para crear módulo con contenido
extract_to() {
    local label=$1
    local regex=$2
    local file=$3
    echo -e "# =================================================\n# Módulo: $label\n# =================================================\n" > "$MOD_DIR/$file"
    grep -E "$regex" "$BACKUP" >> "$MOD_DIR/$file"
}

# 2. Extraer a los módulos (sin números en el nombre)
extract_to "VARIABLES" "^set\s+\$|^font\s+" "variables.conf"
extract_to "AUTOSTART" "^exec(_always)?\s+" "autostart.conf"
extract_to "KEYBINDINGS" "^bindsym|^bindcode" "keybindings.conf"
extract_to "THEME" "^client\.|^gaps|^smart_|^default_border|^hide_edge_borders" "theme.conf"
extract_to "WINDOW RULES" "^for_window|^assign" "windowrules.conf"

# Extraer bloques 'mode' (como el de resize)
sed -n '/^mode "/,/^}/p' "$BACKUP" >> "$MOD_DIR/keybindings.conf"

# 3. REESCRIBIR EL CONFIG PRINCIPAL
# Ponemos el include arriba y el resto del contenido base abajo
cat << 'EOM' > "$SRC"
# =================================================
# i3 Modular Config Loader
# Laptop profile - Kitty + Brave/Firefox
# =================================================

include ~/.config/i3/config.d/*.conf

# --- Contenido Base/Excepciones ---
EOM

# Añadimos lo que no fue clasificado (comentarios, bar, etc.) para que no se pierda nada
grep -vE "^set\s+\$|^font\s+|^exec|^bindsym|^bindcode|^client\.|^gaps|^smart_|^default_|^hide_edge|^for_window|^assign|^mode\s+\"|^}|^#" "$BACKUP" | sed '/^[[:space:]]*$/d' >> "$SRC"

# Si el bloque 'bar' estaba en el original, lo mantenemos abajo
if grep -q "bar {" "$BACKUP"; then
    sed -n '/bar {/,/}/p' "$BACKUP" >> "$SRC"
fi

echo "--- Proceso completado ---"
i3-msg restart
EOF

chmod +x ~/hyde_modular_extractor.sh
