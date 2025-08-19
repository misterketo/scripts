#!/bin/bash

# Comprobar root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Este script debe ejecutarse como root."
  exit 1
fi

OUTPUT_DIR="/home/kali/nmap"
mkdir -p "$OUTPUT_DIR"

# Detectar interfaz activa automáticamente
IFACE=$(ip route | grep '^default' | awk '{print $5}')

# Si no detecta, dejar elegir
if [ -z "$IFACE" ]; then
  echo "⚠️ No se detectó interfaz automáticamente."
  echo "📡 Interfaces disponibles:"
  interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
  for i in "${!interfaces[@]}"; do
    echo "[$i] ${interfaces[$i]}"
  done
  read -p "Selecciona el número de la interfaz a usar: " idx
  IFACE=${interfaces[$idx]}
fi

if [ -z "$IFACE" ]; then
  echo "❌ No se seleccionó interfaz válida."
  exit 1
fi

echo "🌐 Usando interfaz: $IFACE"

echo "🔍 Escaneando red con arp-scan..."
hosts=$(arp-scan --interface="$IFACE" --localnet 2>/dev/null | grep -Eo "^([0-9]{1,3}\.){3}[0-9]{1,3}\s+([0-9A-Fa-f:]{17})")

if [ -z "$hosts" ]; then
  echo "⚠️ No se detectaron hosts. ¿Estás conectado a la red?"
  exit 1
fi

mapfile -t host_array < <(echo "$hosts")

echo "📋 Dispositivos detectados:"
for i in "${!host_array[@]}"; do
  ip=$(echo "${host_array[$i]}" | awk '{print $1}')
  mac=$(echo "${host_array[$i]}" | awk '{print $2}')
  echo "[$i] $ip - $mac"
done

read -p "Selecciona el número del host a escanear con nmap: " index
if ! [[ "$index" =~ ^[0-9]+$ ]] || [ "$index" -lt 0 ] || [ "$index" -ge "${#host_array[@]}" ]; then
  echo "❌ Selección inválida."
  exit 1
fi
ip=$(echo "${host_array[$index]}" | awk '{print $1}')

echo "Elige el tipo de escaneo:"
echo "1) Chihuahua (rápido, escaneo rápido de puertos comunes)"
echo "2) Beagle (medio, escaneo SYN + versión de servicios)"
echo "3) Bloodhound (profundo, escaneo completo de puertos + detección avanzada)"
read -p "Selecciona una opción (1-3): " scan_type

scan_names=("chihuahua" "beagle" "bloodhound")
scan_label=${scan_names[$((scan_type-1))]}

case $scan_type in
  1)
    echo "🚀 Ejecutando Chihuahua (rápido)..."
    nmap -T4 -F "$ip" > "${OUTPUT_DIR}/nmap_result_${ip}_${scan_label}.txt" 2>&1
    ;;
  2)
    echo "🚀 Ejecutando Beagle (medio)..."
    nmap -T4 -sS -sV "$ip" > "${OUTPUT_DIR}/nmap_result_${ip}_${scan_label}.txt" 2>&1
    ;;
  3)
    echo "🚀 Ejecutando Bloodhound (profundo)..."
    nmap -T4 -p- -A --stats-every 20s "$ip" | tee "${OUTPUT_DIR}/nmap_result_${ip}_${scan_label}.txt"
    ;;
  *)
    echo "❌ Opción inválida."
    exit 1
    ;;
esac

echo "✅ Resultado guardado en: ${OUTPUT_DIR}/nmap_result_${ip}_${scan_label}.txt"
