#!/bin/bash
CARPETA_BASE="$HOME/Documentos"
CARPETA_SALIDA="$(dirname "$0")/reportes"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVO_SALIDA="$CARPETA_SALIDA/resumen_$TIMESTAMP.txt"

mkdir -p "$CARPETA_SALIDA"
echo "Analizando $CARPETA_BASE ..."

analizar_carpetas() {
  for d in "$CARPETA_BASE"/*; do
    [ -d "$d" ] || continue
    echo "Carpeta: $(basename "$d")"
  done
}

analizar_carpetas | tee "$ARCHIVO_SALIDA"
echo "Reporte guardado en: $ARCHIVO_SALIDA"
