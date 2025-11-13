#!/bin/bash
CARPETA_BASE="/home/angel/Downloads"
CARPETA_SALIDA="$(dirname "$0")/reportes"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVO_SALIDA="$CARPETA_SALIDA/resumen_$TIMESTAMP.txt"

mkdir -p "$CARPETA_SALIDA"

if [ ! -d "$CARPETA_BASE" ]; then
  echo "❌ Carpeta no existe: $CARPETA_BASE"
  exit 1
fi

echo "🔍 Analizando carpeta: $CARPETA_BASE"
echo ""

total_archivos=0
total_peso=0

# Recorre cada subcarpeta (incluyendo la raíz)
while IFS= read -r -d '' carpeta; do
  archivos=$(find "$carpeta" -maxdepth 1 -type f -print0 2>/dev/null)
  count=$(echo "$archivos" | tr -cd '\0' | wc -c)
  [ "$count" -eq 0 ] && continue

  peso=$(find "$carpeta" -maxdepth 1 -type f -printf "%s\n" 2>/dev/null | awk '{sum+=$1} END {print sum}')
  peso_mb=$(echo "scale=2; $peso / 1048576" | bc)

  echo "📁 $(basename "$carpeta")"
  echo "   Archivos: $count"
  echo "   Peso total (MB): $peso_mb"
  echo "--------------------------------"

  total_archivos=$((total_archivos + count))
  total_peso=$(echo "$total_peso + $peso_mb" | bc)
done < <(find "$CARPETA_BASE" -type d -print0)

echo ""
echo "📊 Total archivos: $total_archivos"
echo "📦 Peso total (MB): $total_peso"

echo ""
echo "✅ Reporte guardado en: $ARCHIVO_SALIDA"

