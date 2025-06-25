import os
import glob
import re

def obtener_perfiles_wifi():
    rutas = glob.glob("/etc/NetworkManager/system-connections/*")
    perfiles = []
    for ruta in rutas:
        nombre_archivo = os.path.basename(ruta)
        perfiles.append(nombre_archivo)
    return perfiles

def obtener_contraseña_wifi(ruta_archivo):
    try:
        with open(ruta_archivo, "r", encoding="utf-8", errors="ignore") as f:
            contenido = f.read()
            ssid_match = re.search(r'ssid=(.+)', contenido)
            psk_match = re.search(r'psk=(.+)', contenido)

            ssid = ssid_match.group(1) if ssid_match else os.path.basename(ruta_archivo)
            psk = psk_match.group(1) if psk_match else "No disponible"

            return ssid, psk
    except PermissionError:
        return os.path.basename(ruta_archivo), "❌ Permiso denegado"

def main():
    print("Contraseñas Wi-Fi guardadas en el sistema:\n")
    rutas = glob.glob("/etc/NetworkManager/system-connections/*")
    if not rutas:
        print("No se encontraron redes guardadas.")
        return

    for ruta in rutas:
        ssid, clave = obtener_contraseña_wifi(ruta)
        print(f"{ssid}: {clave}")

if __name__ == "__main__":
    main()
