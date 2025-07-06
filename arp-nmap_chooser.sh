#!/bin/bash

# Requiere privilegios de root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Este script debe ejecutarse como root."
  exit 1
fi

# Interfaz de red (puedes ajustar esto)
IFACE="eth0"

# Detectar red automáticamente
echo "🔍 Escaneando red con arp-scan..."
hosts=$(arp-scan --interface="$IFACE" --localnet 2>/dev/null | \
  grep -Eo "^([0-9]{1,3}\.){3}[0-9]{1,3}\s+([0-9A-Fa-f:]{17})")

if [ -z "$hosts" ]; then
  echo "⚠️ No se detectaron hosts. ¿Estás conectado a la red?. Me cago en la peluca de su abuela"
  exit 1
fi

# Crear lista en array
mapfile -t host_array < <(echo "$hosts")

# Mostrar menú
echo "📋 Dispositivos detectados:"
for i in "${!host_array[@]}"; do
    ip=$(echo "${host_array[$i]}" | awk '{print $1}')
    mac=$(echo "${host_array[$i]}" | awk '{print $2}')
    echo "[$i] $ip - $mac"
done

# Selección del usuario
read -p "Selecciona el número del host a escanear con nmap: " index

if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 0 ] && [ "$index" -lt "${#host_array[@]}" ]; then
    ip=$(echo "${host_array[$index]}" | awk '{print $1}')
    echo "🚀 Escaneando $ip con nmap (modo rápido -T4)..."
    nmap -T4 "$target_ip" > "$HOME/nmaps/nmap_result_${target_ip}.txt"
    echo "✅ Resultado guardado en: nmap_result_$ip.txt"
else
    echo "❌ Selección inválida."
fi
