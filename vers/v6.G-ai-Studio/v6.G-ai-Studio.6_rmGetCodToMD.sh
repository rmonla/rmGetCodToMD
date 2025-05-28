#!/bin/bash
# Metadata del script
SCRIPT_NAME="rmGetCodToMD.sh"
# ACTUALIZA ESTA LÍNEA MANUALMENTE PARA CADA NUEVA VERSIÓN QUE ME ENVÍES:
SCRIPT_VERSION="v6.G-ai-Studio.6 (250527 1951 ART)"
SCRIPT_AUTHOR="Ricardo MONLA ( rmonla@ )"
GITHUB_REPO_URL="https://raw.githubusercontent.com/rmonla/tools/main/rmGetCodToMD.sh"

# Configuración de colores ANSI
COL_RESET="\033[0m"
COL_BOLD="\033[1m"
COL_RED="\033[31m"
COL_GREEN="\033[32m"
COL_YELLOW="\033[33m"
COL_BLUE="\033[34m"
COL_MAGENTA="\033[35m"
COL_CYAN="\033[36m"
COL_WHITE="\033[37m"

COL_BOLD_RED="\033[1;31m"
COL_BOLD_GREEN="\033[1;32m"
COL_BOLD_YELLOW="\033[1;33m"
COL_BOLD_BLUE="\033[1;34m"
COL_BOLD_MAGENTA="\033[1;35m"
COL_BOLD_CYAN="\033[1;36m"
COL_BOLD_WHITE="\033[1;37m"

# (El resto del script hasta show_help permanece igual que la versión anterior)
# ...

# Variables globales
ROOT_DIR=""
declare -a SELECTED_FILES_ABS # Solo archivos seleccionados
declare -A EXPANDED_DIRS
OUTPUT_FILENAME="project_export.md"
SCRIPT_PATH_REAL=""

declare -a SELECTOR_ITEMS_FULL_DATA=()


# --- Funciones de Utilidad ---
function print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${COL_RESET}"
}

function display_header() {
    clear
    echo -e "${COL_BOLD_CYAN}${SCRIPT_NAME} | ${SCRIPT_VERSION} | ${SCRIPT_AUTHOR}${COL_RESET}"
    echo -e "--------------------------------------------------------------------------------"
    echo -e "Directorio Raíz Actual: ${COL_BOLD_WHITE}${ROOT_DIR}${COL_RESET}"
    echo -e "--------------------------------------------------------------------------------"
}

function map_extension_to_language() {
    local filename="$1"
    local extension="${filename##*.}"
    case "$extension" in
      sh) echo "bash";; py) echo "python";; js) echo "javascript";;
      html) echo "html";; css) echo "css";; c) echo "c";; cpp) echo "cpp";;
      java) echo "java";; rb) echo "ruby";; go) echo "go";; php) echo "php";;
      swift) echo "swift";; kt) echo "kotlin";; rs) echo "rust";;
      md) echo "markdown";; json) echo "json";; yaml|yml) echo "yaml";;
      xml) echo "xml";; sql) echo "sql";; pl) echo "perl";;
      *) echo "text";;
    esac
}

function is_file_selected() {
    local file_path="$1"
    for selected in "${SELECTED_FILES_ABS[@]}"; do
        if [[ "$selected" == "$file_path" ]]; then
            return 0
        fi
    done
    return 1
}

function toggle_file_selection() {
    local file_path_abs="$1"
    local new_selected_files=()
    local found=0

    for selected in "${SELECTED_FILES_ABS[@]}"; do
        if [[ "$selected" == "$file_path_abs" ]]; then
            found=1
        else
            new_selected_files+=("$selected")
        fi
    done

    if [[ $found -eq 1 ]]; then
        SELECTED_FILES_ABS=("${new_selected_files[@]}")
    else
        SELECTED_FILES_ABS+=("$file_path_abs")
    fi
    SELECTED_FILES_ABS=($(printf "%s\n" "${SELECTED_FILES_ABS[@]}" | LC_ALL=C sort -u))
}

# --- Funciones Principales ---

function select_root_directory() {
    local current_nav_dir
    current_nav_dir=$(realpath "$ROOT_DIR")

    while true; do
        display_header
        echo -e "${COL_BOLD_BLUE}Seleccionar Directorio Raíz:${COL_RESET}"
        echo -e "Directorio actual de navegación: ${COL_BOLD_WHITE}${current_nav_dir}${COL_RESET}"
        echo ""
        local subdirs=()
        local i=1
        while IFS= read -r dir_entry; do
            if [[ -d "$current_nav_dir/$dir_entry" && "$dir_entry" != "." && "$dir_entry" != ".." ]]; then
                if [[ "$dir_entry" == ".git" || "$dir_entry" == ".svn" || "$dir_entry" == "node_modules" || "$dir_entry" == "__pycache__" || "$dir_entry" == ".DS_Store" || "$dir_entry" == "target" || "$dir_entry" == "build" || "$dir_entry" == "dist" || "$dir_entry" == ".vscode" || "$dir_entry" == ".idea" ]]; then
                    continue
                fi
                echo -e "  ${COL_CYAN}${i})${COL_RESET} ${dir_entry}/"
                subdirs+=("$dir_entry")
                i=$((i+1))
            fi
        done < <(ls -A1p "$current_nav_dir" | grep '/$' | sed 's/\/$//' | grep -v '^\.' | sort)
        echo ""
        echo -e "  ${COL_CYAN}s)${COL_RESET} Seleccionar este directorio (${COL_BOLD_WHITE}${current_nav_dir}${COL_RESET})"
        if [[ "$current_nav_dir" != "/" ]]; then
            echo -e "  ${COL_CYAN}u)${COL_RESET} Subir un nivel (a: $(realpath "$current_nav_dir/.."))"
        fi
        echo -e "  ${COL_CYAN}q)${COL_RESET} Cancelar y volver al menú principal"
        echo ""
        read -rp "$(echo -e "${COL_BOLD_YELLOW}Opción: ${COL_RESET}")" choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#subdirs[@]}" ]; then
            current_nav_dir=$(realpath "$current_nav_dir/${subdirs[$((choice-1))]}")
        elif [[ "$choice" == "s" ]]; then
            ROOT_DIR="$current_nav_dir"
            SELECTED_FILES_ABS=()
            EXPANDED_DIRS=()
            print_message "${COL_GREEN}" "Directorio raíz cambiado a: ${ROOT_DIR}"
            sleep 1; return
        elif [[ "$choice" == "u" && "$current_nav_dir" != "/" ]]; then
            current_nav_dir=$(realpath "$current_nav_dir/..")
        elif [[ "$choice" == "q" ]]; then
            return
        else
            print_message "${COL_RED}" "Opción inválida."; sleep 1
        fi
    done
}

function build_file_tree_for_selector() {
    local current_path_abs="$1"
    local current_path_rel="$2"
    local depth="$3"
    local -n target_array_ref="$4"
    local current_prefix_str="$5"
    local -n full_data_array_ref="$6"

    local entries_raw=()
    while IFS= read -r entry; do entries_raw+=("d:$entry"); done < <(find "$current_path_abs" -maxdepth 1 -mindepth 1 -type d -not -path '*/\.*' -printf "%P\n" | LC_ALL=C sort)
    while IFS= read -r entry; do entries_raw+=("f:$entry"); done < <(find "$current_path_abs" -maxdepth 1 -mindepth 1 -type f -not -path '*/\.*' -printf "%P\n" | LC_ALL=C sort)

    local num_entries=${#entries_raw[@]}
    local count=0

    for typed_item_name in "${entries_raw[@]}"; do
        count=$((count + 1))
        local item_type_char="${typed_item_name%%:*}"
        local item_name="${typed_item_name#*:}"
        local item_path_abs="$current_path_abs/$item_name"
        local item_path_rel; [[ -z "$current_path_rel" ]] && item_path_rel="$item_name" || item_path_rel="$current_path_rel/$item_name"
        local type="file"; [[ "$item_type_char" == "d" ]] && type="dir"
        local connector="├── "; [[ $count -eq $num_entries ]] && connector="└── "
        local display_prefix="${current_prefix_str}${connector}"
        local display_item_string=""
        local full_data_string="($item_path_abs;$type;$item_path_rel)"

        if [[ "$type" == "dir" ]]; then
            local expanded_char="+"; [[ -n "${EXPANDED_DIRS[$item_path_rel]}" ]] && expanded_char="-"
            display_item_string="   ${display_prefix}[$expanded_char] $item_name/"
            target_array_ref+=("$display_item_string")
            full_data_array_ref+=("$full_data_string")

            if [[ -n "${EXPANDED_DIRS[$item_path_rel]}" ]]; then
                local next_prefix_str_for_children="${current_prefix_str}"
                [[ $count -eq $num_entries ]] && next_prefix_str_for_children+="    " || next_prefix_str_for_children+="│   "
                build_file_tree_for_selector "$item_path_abs" "$item_path_rel" $((depth+1)) "$4" "$next_prefix_str_for_children" "$6"
            fi
        else
            local selected_char=" "; is_file_selected "$item_path_abs" && selected_char="x"
            display_item_string="[$selected_char] ${display_prefix}   $item_name"
            target_array_ref+=("$display_item_string")
            full_data_array_ref+=("$full_data_string")
        fi
    done
}

function parse_selection_input() {
    local input_str="$1"
    local max_val="$2"
    local -n _parsed_numbers_ref="$3"

    _parsed_numbers_ref=()
    local clean_input=$(echo "$input_str" | tr ',' ' ' | tr -s ' ')

    for part in $clean_input; do
        if [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
            local start_range=${part%-*}; local end_range=${part#*-}
            if (( start_range <= end_range && start_range >= 1 && end_range <= max_val )); then
                for (( i=start_range; i<=end_range; i++ )); do _parsed_numbers_ref+=("$i"); done
            else print_message "${COL_RED}" "Rango inválido: $part (max: $max_val)"; _parsed_numbers_ref=(); return 1; fi
        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            if (( part >= 1 && part <= max_val )); then _parsed_numbers_ref+=("$part");
            else print_message "${COL_RED}" "Número fuera de rango: $part (max: $max_val)"; _parsed_numbers_ref=(); return 1; fi
        elif [[ -n "$part" ]]; then
            print_message "${COL_RED}" "Entrada inválida: $part"; _parsed_numbers_ref=(); return 1
        fi
    done
    _parsed_numbers_ref=($(printf "%s\n" "${_parsed_numbers_ref[@]}" | LC_ALL=C sort -un)); return 0
}


function interactive_selector() {
    if [[ -z "$ROOT_DIR" ]]; then
        print_message "${COL_RED}" "Primero debe seleccionar un directorio raíz."; sleep 2; return
    fi

    while true; do
        display_header
        echo -e "${COL_BOLD_BLUE}Selector de Archivos/Carpetas:${COL_RESET}"
        echo -e "Navegando en: ${COL_BOLD_WHITE}${ROOT_DIR}${COL_RESET}"
        echo -e "Archivos seleccionados: ${COL_YELLOW}${#SELECTED_FILES_ABS[@]}${COL_RESET}"
        echo ""

        local displayable_items_for_ui=()
        SELECTOR_ITEMS_FULL_DATA=()

        build_file_tree_for_selector "$ROOT_DIR" "" 0 "displayable_items_for_ui" "" "SELECTOR_ITEMS_FULL_DATA"

        if [[ ${#displayable_items_for_ui[@]} -eq 0 ]]; then
            echo -e "${COL_YELLOW}No hay archivos o directorios visibles en ${ROOT_DIR}.${COL_RESET}"
        fi

        for i in "${!displayable_items_for_ui[@]}"; do
            echo -e "  ${COL_CYAN}$((i+1)))${COL_RESET} ${displayable_items_for_ui[$i]}"
        done

        echo ""
        echo -e "${COL_BOLD_MAGENTA}Comandos:${COL_RESET}"
        echo -e "  ${COL_CYAN}[nums]${COL_RESET} (Des)Seleccionar Archivo(s) / Expandir/Colapsar Dir(s) (ej: 1, 3-5, 8)"
        echo -e "  ${COL_CYAN}a${COL_RESET} Seleccionar todos los archivos | ${COL_CYAN}n${COL_RESET} Deseleccionar todo"
        echo -e "  ${COL_CYAN}e${COL_RESET} Expandir todo | ${COL_CYAN}c${COL_RESET} Colapsar todo | ${COL_CYAN}f${COL_RESET} Finalizar selección | ${COL_CYAN}q${COL_RESET} Cancelar"
        echo ""
        read -rp "$(echo -e "${COL_BOLD_YELLOW}Opción: ${COL_RESET}")" choice

        local item_indices_to_process=()
        if parse_selection_input "$choice" "${#displayable_items_for_ui[@]}" item_indices_to_process; then
            if [[ ${#item_indices_to_process[@]} -gt 0 ]]; then
                for item_idx_one_based in "${item_indices_to_process[@]}"; do
                    local item_idx_zero_based=$((item_idx_one_based - 1))
                    local item_data_str="${SELECTOR_ITEMS_FULL_DATA[$item_idx_zero_based]}"
                    item_data_str="${item_data_str//[()]/}"
                    IFS=';' read -r item_path_abs item_type item_path_rel <<< "$item_data_str"

                    if [[ -z "$item_path_abs" || -z "$item_type" ]]; then
                        print_message "${COL_RED}" "Error interno procesando ítem $item_idx_one_based."; continue
                    fi

                    if [[ "$item_type" == "dir" ]]; then
                        if [[ -n "${EXPANDED_DIRS[$item_path_rel]}" ]]; then unset EXPANDED_DIRS["$item_path_rel"];
                        else EXPANDED_DIRS["$item_path_rel"]="expanded"; fi
                    else
                        toggle_file_selection "$item_path_abs"
                    fi
                done; continue
            fi
        elif [[ "$choice" =~ [0-9] ]]; then
            sleep 1; continue
        fi

        case "$choice" in
            a) SELECTED_FILES_ABS=()
                for item_data_str_raw in "${SELECTOR_ITEMS_FULL_DATA[@]}"; do
                    local item_data_parsed="${item_data_str_raw//[()]/}"
                    IFS=';' read -r item_path_abs_loop item_type_loop item_path_rel_loop <<< "$item_data_parsed"
                    if [[ "$item_type_loop" == "file" ]]; then SELECTED_FILES_ABS+=("$item_path_abs_loop"); fi
                done
                SELECTED_FILES_ABS=($(printf "%s\n" "${SELECTED_FILES_ABS[@]}" | LC_ALL=C sort -u))
                print_message "${COL_GREEN}" "Todos los archivos visibles seleccionados."; sleep 0.5 ;;
            n) SELECTED_FILES_ABS=(); print_message "${COL_GREEN}" "Ningún archivo seleccionado."; sleep 0.5 ;;
            e) EXPANDED_DIRS=()
                while IFS= read -r -d $'\0' dir_item; do
                    local rel_path="${dir_item#"$ROOT_DIR"/}"
                    if [[ "$dir_item" == "$ROOT_DIR" ]]; then :
                    elif [[ -n "$rel_path" ]]; then EXPANDED_DIRS["$rel_path"]="expanded"; fi
                done < <(find "$ROOT_DIR" -type d -not -path '*/\.*' -print0)
                print_message "${COL_GREEN}" "Todos los directorios expandidos."; sleep 0.5 ;;
            c) EXPANDED_DIRS=(); print_message "${COL_GREEN}" "Todos los directorios colapsados."; sleep 0.5 ;;
            f) print_message "${COL_GREEN}" "Selección finalizada."; sleep 1; return ;;
            q) print_message "${COL_YELLOW}" "Selección cancelada."; sleep 1; return ;;
            *) if ! [[ ${#item_indices_to_process[@]} -gt 0 && $? -eq 0 ]]; then
                    if [[ "$choice" != "" ]]; then
                         print_message "${COL_RED}" "Opción inválida: $choice"; sleep 1
                    fi
                fi ;;
        esac
    done
}


function generate_markdown_tree() {
    local output_file="$1"
    local tree_items_rel=()
    local collected_paths=()

    for item_abs in "${SELECTED_FILES_ABS[@]}"; do
        local item_rel="${item_abs#"$ROOT_DIR"/}"
        [[ "$item_abs" == "$ROOT_DIR" && "$item_rel" == "$ROOT_DIR" ]] && item_rel="."
        collected_paths+=("$item_rel")
        local parent_dir_rel=$(dirname "$item_rel")
        while [[ "$parent_dir_rel" != "." && "$parent_dir_rel" != "/" && ! -z "$parent_dir_rel" ]]; do
            if ! printf '%s\n' "${collected_paths[@]}" | grep -q -x -F "$parent_dir_rel"; then
                collected_paths+=("$parent_dir_rel")
            fi
            parent_dir_rel=$(dirname "$parent_dir_rel")
        done
    done
    
    local valid_paths=()
    for p in "${collected_paths[@]}"; do
        if [[ "$p" == "." || -e "$ROOT_DIR/$p" ]]; then valid_paths+=("$p"); fi
    done
    
    if [[ ${#SELECTED_FILES_ABS[@]} -eq 0 ]]; then
        echo "\`\`\`text" >> "$output_file"; echo "." >> "$output_file"
        echo "(No se seleccionaron archivos para detallar la estructura)" >> "$output_file"
        echo "\`\`\`" >> "$output_file"; return
    fi
    if [[ ${#valid_paths[@]} -eq 0 && ! " ${collected_paths[*]} " =~ " . " ]]; then
        echo "\`\`\`text" >> "$output_file"
        echo "(No hay estructura para mostrar basada en la selección)" >> "$output_file"
        echo "\`\`\`" >> "$output_file"; return
    fi

    IFS=$'\n' tree_items_rel=($(LC_ALL=C sort -u <<<"${valid_paths[*]}"))
    unset IFS

    echo "\`\`\`text" >> "$output_file"
    local root_printed=0
    if [[ "${tree_items_rel[0]}" == "." || ${#tree_items_rel[@]} -eq 0 ]]; then
        echo "." >> "$output_file"; root_printed=1
    elif ! printf '%s\n' "${tree_items_rel[@]}" | grep -q -x -F "."; then
        if [[ ${#tree_items_rel[@]} -gt 0 || ${#SELECTED_FILES_ABS[@]} -gt 0 ]]; then
            echo "." >> "$output_file"; root_printed=1
        fi
    fi

    local last_entry_at_depth=()
    for ((i=0; i<${#tree_items_rel[@]}; i++)); do
        local current_rel_path="${tree_items_rel[i]}"
        if [[ "$current_rel_path" == "." ]]; then
            [[ $root_printed -eq 1 ]] && continue
            if [[ $root_printed -eq 0 && ${#tree_items_rel[@]} -eq 1 ]]; then echo "." >> "$output_file"; root_printed=1; continue; fi
        fi
        local base_name=$(basename "$current_rel_path")
        local current_depth=$(echo "$current_rel_path" | tr -dc '/' | wc -c)
        local is_dir_type=0; [[ -d "$ROOT_DIR/$current_rel_path" ]] && is_dir_type=1
        local is_last_in_parent_group=1
        local current_parent_path=$(dirname "$current_rel_path")
        for ((j=i+1; j<${#tree_items_rel[@]}; j++)); do
            local next_rel_path="${tree_items_rel[j]}"
            [[ "$next_rel_path" == "." ]] && continue
            local next_parent_path=$(dirname "$next_rel_path")
            if [[ "$next_parent_path" == "$current_parent_path" ]]; then is_last_in_parent_group=0; break; fi
            if ! [[ "$next_rel_path" == "$current_parent_path"* ]]; then break; fi
        done
        last_entry_at_depth[$current_depth]=$is_last_in_parent_group
        local indent_prefix_parts=""
        for ((d=0; d<current_depth; d++)); do
            if [[ "${last_entry_at_depth[$d]}" -eq 1 ]]; then indent_prefix_parts+="    "; else indent_prefix_parts+="│   "; fi
        done
        local connector_branch=""; if [[ "$is_last_in_parent_group" -eq 1 ]]; then connector_branch="└── "; else connector_branch="├── "; fi
        if [[ "$is_dir_type" -eq 1 ]]; then echo "${indent_prefix_parts}${connector_branch}${base_name}/" >> "$output_file";
        else echo "${indent_prefix_parts}${connector_branch}${base_name}" >> "$output_file"; fi
    done
    echo "\`\`\`" >> "$output_file"
}


function export_content_to_markdown() {
    if [[ ${#SELECTED_FILES_ABS[@]} -eq 0 ]]; then
        print_message "${COL_YELLOW}" "No hay archivos seleccionados para exportar."; sleep 2; return
    fi
    display_header
    echo -e "${COL_BOLD_BLUE}Exportar a Markdown:${COL_RESET}"
    local date_from_version=$(echo "$SCRIPT_VERSION" | grep -oP '\(\K[0-9]+') # YYMMDD
    local default_output_filename="project_$(basename "$ROOT_DIR")_${date_from_version}.md"

    read -rp "$(echo -e "Nombre del archivo de salida [${COL_YELLOW}${default_output_filename}${COL_RESET}]: ")" user_filename
    local chosen_output_filename; [[ -n "$user_filename" ]] && chosen_output_filename="$user_filename" || chosen_output_filename="$default_output_filename"
    local absolute_output_path
    if [[ "$chosen_output_filename" == /* ]]; then absolute_output_path="$chosen_output_filename";
    else absolute_output_path="$(pwd)/$chosen_output_filename"; fi
    absolute_output_path=$(realpath -m "$absolute_output_path")
    local output_dir=$(dirname "$absolute_output_path")

    if [[ ! -d "$output_dir" ]]; then
        if mkdir -p "$output_dir"; then print_message "${COL_BLUE}" "Directorio de salida '$output_dir' creado.";
        else print_message "${COL_RED}" "Error: No se pudo crear directorio '$output_dir'."; sleep 3; return; fi
    fi
    if ! [[ -w "$output_dir" ]]; then
        print_message "${COL_RED}" "Error: Sin permisos de escritura en '$output_dir'."; sleep 3; return
    fi
    if [[ -e "$absolute_output_path" ]]; then
        read -rp "$(echo -e "${COL_BOLD_YELLOW}El archivo '$absolute_output_path' ya existe. ¿Sobrescribir? (s/N): ${COL_RESET}")" confirm_overwrite
        if [[ "${confirm_overwrite,,}" != "s" ]]; then print_message "${COL_YELLOW}" "Exportación cancelada."; sleep 1; return; fi
    fi
    echo -e "${COL_BLUE}Generando archivo Markdown en: ${absolute_output_path}${COL_RESET}"
    {
        echo "# Exportación de Código: $(basename "$ROOT_DIR")"; echo ""
        echo "**Ruta raíz del proyecto:** \`$ROOT_DIR\`"
        echo "**Versión del script de exportación:** \`${SCRIPT_VERSION}\`"
        echo "**Fecha de exportación (actual):** $(TZ="America/Argentina/La_Rioja" date '+%Y-%m-%d %H:%M:%S %Z')"; echo ""
    } > "$absolute_output_path"
    echo "## Estructura de Archivos Seleccionados" >> "$absolute_output_path"
    generate_markdown_tree "$absolute_output_path"; echo "" >> "$absolute_output_path"

    local files_to_list_rel=()
    for item_abs in "${SELECTED_FILES_ABS[@]}"; do files_to_list_rel+=("${item_abs#"$ROOT_DIR"/}"); done
    files_to_list_rel=($(printf "%s\n" "${files_to_list_rel[@]}" | LC_ALL=C sort -u))

    if [[ ${#files_to_list_rel[@]} -gt 0 ]]; then
        echo "## Archivos Incluidos (${#files_to_list_rel[@]})" >> "$absolute_output_path"
        for item_rel in "${files_to_list_rel[@]}"; do echo "- \`$item_rel\`" >> "$absolute_output_path"; done
        echo "" >> "$absolute_output_path"
        echo "## Contenido de Archivos" >> "$absolute_output_path"
        for item_rel in "${files_to_list_rel[@]}"; do
            local item_abs="$ROOT_DIR/$item_rel"; local language=$(map_extension_to_language "$item_rel")
            echo "" >> "$absolute_output_path"; echo "### \`$item_rel\`" >> "$absolute_output_path"
            echo "\`\`\`$language" >> "$absolute_output_path"
            if [[ -r "$item_abs" ]]; then
                if file -b --mime-encoding "$item_abs" | grep -q "binary"; then echo "[Contenido binario omitido]" >> "$absolute_output_path";
                else LC_ALL=C cat "$item_abs" >> "$absolute_output_path"; fi
            else echo "[Error: No se pudo leer el archivo $item_rel]" >> "$absolute_output_path"; fi
            echo "\`\`\`" >> "$absolute_output_path"
        done
    else
        echo "## Archivos Incluidos (0)" >> "$absolute_output_path"
        echo "(No se seleccionaron archivos para incluir su contenido)" >> "$absolute_output_path"; echo "" >> "$absolute_output_path"
    fi
    print_message "${COL_BOLD_GREEN}" "Exportación completada: $absolute_output_path"; sleep 2
}


function update_script() {
    print_message "${COL_BLUE}" "Buscando actualizaciones para $(basename "$SCRIPT_PATH_REAL")..."
    if ! command -v curl &> /dev/null; then print_message "${COL_RED}" "Error: 'curl' no está instalado."; sleep 3; return; fi
    local checksum_cmd=""; if command -v sha256sum &> /dev/null; then checksum_cmd="sha256sum"; elif command -v shasum &> /dev/null; then checksum_cmd="shasum -a 256"; fi
    local temp_script_file=$(mktemp -t "$(basename "$SCRIPT_PATH_REAL").XXXXXX")
    if curl -fsSL "$GITHUB_REPO_URL" -o "$temp_script_file"; then
        if [[ -s "$temp_script_file" ]] && head -n 1 "$temp_script_file" | grep -q -e "^#!.*bash"; then
            local remote_is_different=1
            if [[ -n "$checksum_cmd" ]]; then
                local current_checksum=$($checksum_cmd "$SCRIPT_PATH_REAL" | awk '{print $1}')
                local new_checksum=$($checksum_cmd "$temp_script_file" | awk '{print $1}')
                [[ "$current_checksum" == "$new_checksum" ]] && remote_is_different=0
            else if diff -q "$SCRIPT_PATH_REAL" "$temp_script_file" &>/dev/null; then remote_is_different=0; fi; fi
            if [[ "$remote_is_different" -eq 0 ]]; then print_message "${COL_GREEN}" "El script ya está actualizado."; rm "$temp_script_file"; sleep 2; return; fi
            read -rp "$(echo -e "${COL_BOLD_YELLOW}Nueva versión disponible. ¿Actualizar? (s/N): ${COL_RESET}")" confirm_update
            if [[ "${confirm_update,,}" == "s" ]]; then
                local backup_path="${SCRIPT_PATH_REAL}.bak.$(date +%Y%m%d%H%M%S)"
                print_message "${COL_BLUE}" "Creando backup en: ${backup_path}"
                if cp "$SCRIPT_PATH_REAL" "$backup_path"; then
                    if mv -f "$temp_script_file" "$SCRIPT_PATH_REAL"; then
                        chmod +x "$SCRIPT_PATH_REAL"
                        print_message "${COL_BOLD_GREEN}" "Script actualizado exitosamente. Por favor, reinicie el script."; exit 0
                    else print_message "${COL_RED}" "Error al reemplazar el script (código: $?)."; print_message "${COL_YELLOW}" "Backup: ${backup_path}"; sleep 5; fi
                else print_message "${COL_RED}" "Error al crear backup (código: $?)."; rm "$temp_script_file"; sleep 3; fi
            else print_message "${COL_YELLOW}" "Actualización cancelada."; rm "$temp_script_file"; sleep 1; fi
        else print_message "${COL_RED}" "Error: El archivo descargado no es válido."; rm "$temp_script_file"; sleep 3; fi
    else print_message "${COL_RED}" "Error al descargar actualización (código: $?)."; rm -f "$temp_script_file"; sleep 3; fi
}

function show_help() {
    # La variable SCRIPT_VERSION es estática y se usa directamente.
    # La variable SCRIPT_NAME también es estática.
    # Usar tabulaciones para alinear descripciones, y `printf` para formatear si es necesario.

    # Para un mejor control del espaciado, podrías usar printf para cada línea.
    # Pero un `cat << EOF` bien formateado suele ser suficiente.

    local help_info
    help_info=$(cat << HEREDOC
${COL_BOLD_CYAN}${SCRIPT_NAME} | ${SCRIPT_VERSION}${COL_RESET}
Herramienta interactiva para exportar código fuente a un archivo Markdown.

${COL_BOLD_MAGENTA}USO:${COL_RESET}
  ./${SCRIPT_NAME} [OPCIONES]

${COL_BOLD_MAGENTA}OPCIONES DE LÍNEA DE COMANDOS:${COL_RESET}
  ${COL_CYAN}-h, --help${COL_RESET}      Muestra esta ayuda.
  ${COL_CYAN}-r, --update${COL_RESET}    Intenta actualizar el script automáticamente desde GitHub y sale.

${COL_BOLD_MAGENTA}FLUJO PRINCIPAL (INTERACTIVO):${COL_RESET}
  ${COL_GREEN}1) Seleccionar archivos/carpetas:${COL_RESET}
     Navegador interactivo para marcar archivos a incluir y expandir/colapsar directorios.
     ${COL_BOLD_YELLOW}Comandos del selector:${COL_RESET}
       ${COL_YELLOW}[números]${COL_RESET}   (Des)Selecciona Archivo(s) / Expande/Colapsa Directorio(s).
                   Ejemplos: ${COL_WHITE}1${COL_RESET} (ítem 1)
                             ${COL_WHITE}2,4${COL_RESET} (ítems 2 y 4)
                             ${COL_WHITE}3-5, 8${COL_RESET} (ítems 3,4,5 y 8)
       ${COL_YELLOW}a${COL_RESET}           Seleccionar todos los ${COL_BOLD_WHITE}archivos${COL_RESET} visibles.
       ${COL_YELLOW}n${COL_RESET}           Deseleccionar todos los ${COL_BOLD_WHITE}archivos${COL_RESET}.
       ${COL_YELLOW}e${COL_RESET}           Expandir todos los directorios.
       ${COL_YELLOW}c${COL_RESET}           Colapsar todos los directorios.
       ${COL_YELLOW}f${COL_RESET}           Finalizar selección y volver al menú principal.
       ${COL_YELLOW}q${COL_RESET}           Cancelar y volver al menú principal.

  ${COL_GREEN}2) Cambiar directorio raíz:${COL_RESET}
     Permite navegar y seleccionar el directorio base para la selección de archivos.

  ${COL_GREEN}3) Exportar a Markdown:${COL_RESET}
     Genera el archivo .md con la estructura, listado y contenido de los
     archivos seleccionados. El archivo se guarda por defecto en el directorio actual.

  ${COL_GREEN}4) Actualizar script:${COL_RESET}
     Busca y aplica la última versión del script desde GitHub.
     (${COL_BLUE}${GITHUB_REPO_URL}${COL_RESET})

  ${COL_GREEN}5) Salir:${COL_RESET}
     Termina la ejecución del script.

${COL_BOLD_MAGENTA}NOTAS:${COL_RESET}
  - Los directorios no se exportan, solo se usan para navegación y estructura.
  - Se excluyen archivos/directorios ocultos y carpetas comunes de build/vcs.
  - Requiere: ${COL_WHITE}Bash 4+, realpath, curl${COL_RESET} (para update), ${COL_WHITE}file${COL_RESET}.
             ${COL_WHITE}sha256sum/shasum${COL_RESET} (recomendado para update).
HEREDOC
)
    echo -e "$help_info"
}


# --- Flujo Principal ---
function main() {
    local actual_script_path="${BASH_SOURCE[0]}"
    while [[ -L "$actual_script_path" ]]; do
        actual_script_path=$(readlink "$actual_script_path")
        [[ "$actual_script_path" != /* ]] && actual_script_path="$(dirname "${BASH_SOURCE[0]}")/$actual_script_path"
    done
    SCRIPT_PATH_REAL=$(realpath "$actual_script_path")
    ROOT_DIR=$(realpath "$(pwd)")

    # Expandir opciones largas para getopts
    # Esto requiere un bucle de pre-procesamiento o usar una función de getopts más avanzada
    # Por simplicidad aquí, solo manejaremos las cortas directamente con getopts
    # pero en show_help mostramos las largas como sugerencia de formato.

    while getopts ":hr" opt; do
        case ${opt} in
            h ) show_help; exit 0 ;;
            r ) update_script; exit $? ;;
            \? ) print_message "${COL_RED}" "Opción inválida: -$OPTARG"; show_help; exit 1 ;;
        esac
    done
    shift $((OPTIND -1))

    if ! command -v realpath &> /dev/null; then print_message "${COL_RED}" "Error: 'realpath' no está instalado."; exit 1; fi
    if ! TZ="America/Argentina/La_Rioja" date &>/dev/null ; then
        if [[ "$(echo "$SCRIPT_VERSION" | grep -o "ART")" ]]; then
          print_message "${COL_YELLOW}" "Advertencia: Zona horaria 'America/Argentina/La_Rioja' no reconocida por 'date'. Usando UTC/GMT para fechas en el script."
          local current_x=$(echo "$SCRIPT_VERSION" | grep -oP 'Studio\.\K[0-9]+')
          local current_date_time_part=$(date -u +'%y%m%d %H%M') # Fecha y hora actual en UTC
          SCRIPT_VERSION="v6.G-ai-Studio.${current_x} (${current_date_time_part} UTC)" # Sobreescribir versión para mostrar UTC
        fi
    fi

    while true; do
        display_header
        echo -e "${COL_BOLD_BLUE}Menú Principal:${COL_RESET}"
        echo -e "  ${COL_CYAN}1)${COL_RESET} Seleccionar archivos/carpetas"
        echo -e "  ${COL_CYAN}2)${COL_RESET} Cambiar directorio raíz"
        echo -e "  ${COL_CYAN}3)${COL_RESET} Exportar a Markdown (${COL_YELLOW}${#SELECTED_FILES_ABS[@]} archivos${COL_RESET})"
        echo -e "  ${COL_CYAN}4)${COL_RESET} Actualizar script"
        echo -e "  ${COL_CYAN}5)${COL_RESET} Salir"
        echo ""
        read -rp "$(echo -e "${COL_BOLD_YELLOW}Opción: ${COL_RESET}")" choice

        case "$choice" in
            1) interactive_selector ;;
            2) select_root_directory ;;
            3) export_content_to_markdown ;;
            4) update_script ;;
            5) print_message "${COL_GREEN}" "Saliendo..."; break ;;
            *) print_message "${COL_RED}" "Opción inválida."; sleep 1 ;;
        esac
    done
    exit 0
}

if ((BASH_VERSINFO[0] < 4)); then
    echo "Error: Este script requiere Bash versión 4 o superior." >&2
    bash_version_info=$(bash --version | head -n1); echo "Versión actual de Bash: $bash_version_info" >&2; exit 1
fi

main "$@"