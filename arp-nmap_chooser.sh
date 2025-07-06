#!/bin/bash

# Requiere privilegios de root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Este script debe ejecutarse como root."
  exit 1
fi

# Interfaz de red (ajústala si usas otra)
IFACE="eth0"

# Carpeta absoluta para guardar resultados (usuario kali)
OUTPUT_DIR="/home/kali/nmap"
mkdir -p "$OUTPUT_DIR"
echo "DEBUG: OUTPUT_DIR='$OUTPUT_DIR', existe carpeta: $( [ -d "$OUTPUT_DIR" ] && echo sí || echo no )"

# Escanear red con arp-scan y filtrar IP + MAC válidas
echo "🔍 Escaneando red con arp-scan..."
hosts=$(arp-scan --interface="$IFACE" --localnet 2>/dev/null | \
  awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\s+([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/ {print $1, $2}')

# Verificar si se encontraron hosts
if [ -z "$hosts" ]; then
  echo "⚠️ No se detectaron hosts. ¿Estás conectado a la red?"
  exit 1
fi

# Crear array desde los hosts detectados
mapfile -t host_array < <(echo "$hosts")

# Mostrar menú con IP y MAC
echo "📋 Dispositivos detectados:"
for i in "${!host_array[@]}"; do
    ip=$(echo "${host_array[$i]}" | awk '{print $1}')
    mac=$(echo "${host_array[$i]}" | awk '{print $2}')
    echo "[$i] $ip - $mac"
done

# Pedir selección al usuario
read -p "Selecciona el número del host a escanear con nmap: " index

# Validar selección
if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 0 ] && [ "$index" -lt "${#host_array[@]}" ]; then
    ip=$(echo "${host_array[$index]}" | awk '{print $1}')
    echo "🚀 Escaneando $ip con nmap (modo rápido -T4)..."

    echo "DEBUG: OUTPUT_DIR='$OUTPUT_DIR'"
    echo "DEBUG: ip='$ip'"

    # Ejecutar escaneo y guardar resultado
    nmap -T4 "$ip" > "${OUTPUT_DIR}/nmap_result_${ip}.txt" 2>&1
    status=$?

    if [ $status -eq 0 ]; then
        echo "✅ Resultado guardado en: ${OUTPUT_DIR}/nmap_result_${ip}.txt"
    else
        echo "❌ Error al ejecutar nmap (código $status)"
    fi
else
    echo "❌ Selección inválida."
fi
