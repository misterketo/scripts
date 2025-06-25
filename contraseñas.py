import subprocess
import re

def obtener_perfiles_wifi():
    comando = ["netsh", "wlan", "show", "profiles"]
    resultado = subprocess.run(comando, capture_output=True, text=True, encoding="utf-8", errors="ignore")
    perfiles = re.findall(r"Perfil de todos los usuarios\s*:\s*(.+)", resultado.stdout)
    return [p.strip() for p in perfiles]

def obtener_contraseña_wifi(nombre_perfil):
    comando = ["netsh", "wlan", "show", "profile", f'name="{nombre_perfil}"', "key=clear"]
    resultado = subprocess.run(comando, capture_output=True, text=True, encoding="utf-8", errors="ignore")
    contraseña = re.search(r"Contenido de la clave\s*:\s(.+)", resultado.stdout)
    return contraseña.group(1) if contraseña else "No disponible"

def main():
    perfiles = obtener_perfiles_wifi()
    if not perfiles:
        print("No se encontraron perfiles Wi-Fi.")
        return

    print("Contraseñas Wi-Fi guardadas:\n")
    for perfil in perfiles:
        clave = obtener_contraseña_wifi(perfil)
        print(f"{perfil}: {clave}")

if __name__ == "__main__":
    main()
