#!/bin/bash

# ===============================
# SCRIPT DE ANÁLISIS DE CARPETAS
# ===============================

# Configuración
CARPETA_BASE="/ruta/a/tu/carpeta"  # Cambiar a la ruta deseada
CARPETA_SALIDA="$(dirname "$0")/reportes"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVO_SALIDA="$CARPETA_SALIDA/resumen_$TIMESTAMP.txt"

# Colores para output (opcional)
RESET="\e[0m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"

# Crear carpeta de reportes si no existe
mkdir -p "$CARPETA_SALIDA"

# Variables globales
declare -A carpetas_data
declare -a carpetas_orden
total_carpetas=0
total_archivos_global=0
total_peso_global=0

# Función para mostrar spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n "🔍 Analizando carpetas... "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo -e "${GREEN}✓${RESET} Análisis completado."
}

# Función principal de análisis
analizar_carpetas() {
    while IFS= read -r -d '' carpeta; do
        # Contar archivos en esta carpeta (no recursivo)
        num_archivos=$(find "$carpeta" -maxdepth 1 -type f 2>/dev/null | wc -l)
        
        # Si no hay archivos, continuar
        [ "$num_archivos" -eq 0 ] && continue
        
        # Nombre y ruta relativa
        nombre_carpeta=$(basename "$carpeta")
        ruta_relativa="${carpeta#$CARPETA_BASE/}"
        
        # Calcular peso total y tipos de archivo
        peso_total=0
        declare -A tipos_archivo
        
        while IFS= read -r -d '' archivo; do
            # Obtener tamaño
            if [ -f "$archivo" ]; then
                peso=$(stat -c%s "$archivo" 2>/dev/null || stat -f%z "$archivo" 2>/dev/null)
                peso_total=$((peso_total + peso))
                
                # Obtener extensión
                extension="${archivo##*.}"
                if [ "$extension" = "$archivo" ]; then
                    extension="sin_extensión"
                else
                    extension=".${extension,,}"  # Convertir a minúsculas
                fi
                
                tipos_archivo[$extension]=$((${tipos_archivo[$extension]:-0} + 1))
            fi
        done < <(find "$carpeta" -maxdepth 1 -type f -print0 2>/dev/null)
        
        # Convertir bytes a MB
        peso_mb=$(echo "scale=2; $peso_total / 1048576" | bc)
        
        # Guardar datos
        carpetas_orden+=("$carpeta")
        carpetas_data["$carpeta,nombre"]="$nombre_carpeta"
        carpetas_data["$carpeta,ruta"]="$ruta_relativa"
        carpetas_data["$carpeta,archivos"]="$num_archivos"
        carpetas_data["$carpeta,peso"]="$peso_mb"
        
        # Guardar tipos de archivo
        for ext in "${!tipos_archivo[@]}"; do
            carpetas_data["$carpeta,tipo,$ext"]="${tipos_archivo[$ext]}"
        done
        
        # Actualizar totales globales
        total_carpetas=$((total_carpetas + 1))
        total_archivos_global=$((total_archivos_global + num_archivos))
        total_peso_global=$(echo "$total_peso_global + $peso_mb" | bc)
        
    done < <(find "$CARPETA_BASE" -type d -print0 2>/dev/null)
}

# Función para generar y mostrar el reporte
generar_reporte() {
    local duracion=$1
    local separador=$(printf '=%.0s' {1..90})
    
    {
        echo "$separador"
        printf "%*s\n" $(((${#separador}+21)/2)) "RESUMEN DE CARPETAS"
        echo "$separador"
        printf "Duración total del análisis: %.2f segundos\n" "$duracion"
        echo ""
        
        # Detalles por carpeta
        for carpeta in "${carpetas_orden[@]}"; do
            echo "📁 Carpeta: ${carpetas_data[$carpeta,nombre]}"
            echo "   Ruta relativa     : ${carpetas_data[$carpeta,ruta]}"
            echo "   Archivos totales  : ${carpetas_data[$carpeta,archivos]}"
            printf "   Peso total (MB)   : %'.2f\n" "${carpetas_data[$carpeta,peso]}"
            echo "   Tipos de archivo  :"
            
            # Listar tipos de archivo
            for key in "${!carpetas_data[@]}"; do
                if [[ $key == "$carpeta,tipo,"* ]]; then
                    ext="${key#$carpeta,tipo,}"
                    printf "      - %-15s %s archivo(s)\n" "$ext" "${carpetas_data[$key]}"
                fi
            done | sort
            
            echo "$(printf -- '-%.0s' {1..90})"
        done
        
        echo ""
        echo "RESUMEN GLOBAL"
        echo "   Total de carpetas : $total_carpetas"
        echo "   Total de archivos : $total_archivos_global"
        printf "   Peso total (MB)   : %'.2f\n" "$total_peso_global"
        echo "$separador"
        
    } | tee "$ARCHIVO_SALIDA"
    
    echo ""
    echo -e "${CYAN}Resumen guardado en: $ARCHIVO_SALIDA${RESET}"
}

# ===============================
# EJECUCIÓN PRINCIPAL
# ===============================

echo -e "${YELLOW}Iniciando análisis de: $CARPETA_BASE${RESET}"
echo ""

# Verificar que la ruta existe
if [ ! -d "$CARPETA_BASE" ]; then
    echo "Error: La carpeta '$CARPETA_BASE' no existe."
    exit 1
fi

# Iniciar tiempo
inicio=$(date +%s.%N)

# Ejecutar análisis en segundo plano para mostrar spinner
analizar_carpetas &
analizar_pid=$!
spinner $analizar_pid
wait $analizar_pid

# Calcular duración
fin=$(date +%s.%N)    
duracion=$(echo "$fin - $inicio" | bc)

# Generar reporte
if [ "$total_carpetas" -gt 0 ]; then
    generar_reporte "$duracion"
else
    echo "No se encontraron archivos en la carpeta especificada."
fi
