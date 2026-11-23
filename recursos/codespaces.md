# ☁️ Guía Opcional: Practicar en GitHub Codespaces (Sin Instalar Nada)

<div align="center">

[![Abrir en GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/edwinbermudez91/Fundamentos-Kubernetes?quickstart=1)

</div>

> [!NOTE]
> **¿Esto es obligatorio?**  
> **No.** GitHub Codespaces es una opción **100% opcional** pensada para quienes tienen un computador con poca RAM, usan Windows sin WSL2 o tienen restricciones para instalar Docker Desktop localmente. También puedes seguir usando tu entorno local o [**iximiuz Labs**](https://labs.iximiuz.com/trainings/fundamentos-de-docker-y-kubernetes-2ae16ea8/).

---

## ⚠️ Disclaimers Importantes (Lee antes de empezar)

> [!IMPORTANT]
> **1. Cuenta y costos (Plan Gratuito de GitHub):**
> * El Codespace corre bajo **tu propia cuenta personal de GitHub** (no en la del instructor).
> * Las cuentas gratuitas (**GitHub Free**) incluyen **120 core-hours/mes gratis** (= **60 horas al mes** en la máquina de **2 cores / 8 GB RAM** configurada en este repo) y **15 GB/mes de almacenamiento** gratis.
> * Si tienes **GitHub Student Developer Pack**, recibes **180 core-hours/mes** (90 horas en 2 cores) y **20 GB** de almacenamiento.
> * Por defecto, GitHub mantiene tu **límite de gasto en `$0 USD`**: si llegaras a agotar las horas gratis del mes, el Codespace simplemente se pausa hasta el mes siguiente (**no te cobra ni te pide tarjeta**).

> [!WARNING]
> **2. Cuida tus horas y tu código:**
> * **Siempre haz `git commit` y `git push` antes de cerrar:** un Codespace es un entorno temporal en la nube.
> * **Detén o elimina el Codespace al terminar la sesión:** aunque se suspende tras 30 minutos de inactividad, mientras exista sigue ocupando parte de tus 15 GB gratis de almacenamiento.
> * **Capacidad recomendada en Codespaces:** la máquina gratuita de 2 vCPU / 8 GB RAM funciona muy bien con un clúster **Kind de 1 o 2 nodos** (evita crear 4+ nodos para no saturar memoria).

---

## 🚀 ¿Qué incluye ya listo el DevContainer?

Gracias al archivo [`.devcontainer/devcontainer.json`](../.devcontainer/devcontainer.json), al abrir el Codespace tendrás preinstalado y configurado:
- 🐳 **Docker** (*Docker-in-Docker*)
- ☸️ **`kubectl`**, **`kind`** y **`helm`**
- 🧭 **`k9s`** (consola visual de clúster en terminal)
- 🟢 **Node.js 20** (para ejecutar `./scripts/verificar-reto.sh` antes de tus PRs)
- 🧩 Extensiones de VS Code para **Kubernetes**, **YAML** y **Docker**

---

## 📋 Paso a Paso Detallado

### Paso 1: Haz Fork (recomendado si vas a enviar retos)
Si planeas guardar tus soluciones y abrir Pull Requests:
1. Entra al repositorio principal: [**Fundamentos-Kubernetes**](https://github.com/edwinbermudez91/Fundamentos-Kubernetes).
2. Haz clic en **Fork** (arriba a la derecha) para tener tu propia copia (`https://github.com/TU-USUARIO/Fundamentos-Kubernetes`).
3. Si ya tenías un Fork de semanas anteriores, haz clic en **Sync fork → Update branch** antes de abrir el Codespace.

*(Si solo quieres probar los ejemplos sin enviar PRs, puedes abrir Codespaces directamente desde el botón superior).*

### Paso 2: Crea tu Codespace
1. Dentro de **tu Fork** en GitHub, haz clic en el botón verde **`<> Code`**.
2. Selecciona la pestaña **`Codespaces`**.
3. Haz clic en **`Create codespace on main`**.
4. Espera **1 a 2 minutos** la primera vez mientras GitHub construye el DevContainer e instala `Docker`, `kind`, `kubectl`, `helm` y `k9s`.

### Paso 3: Verifica que todo esté listo en la terminal
Cuando cargue VS Code en el navegador, abre la terminal integrada (`Ctrl + ñ` o menú `Terminal → New Terminal`) y ejecuta:

```bash
docker --version
kind --version
kubectl version --client
helm version
k9s version
```

Si todos responden una versión sin errores, ¡ya estás listo!

### Paso 4: Levanta tu clúster Kubernetes (Kind + Cilium + Headlamp)
Ejecuta el script del laboratorio:

```bash
bash ./semana-01-arquitectura/0.prepara-tu-laboratorio/setup-lab.sh
```

> 💡 **Tip para Codespaces (2 cores / 8 GB RAM):** cuando `setup-lab.sh` te pregunte cuántos nodos crear, elige **`1` nodo** (control-plane) o **`2` nodos** para mantener un consumo ágil de RAM y CPU.

### Paso 5: Resuelve retos, valida y sube tus cambios
1. Crea tu rama y copia los retos de la semana a tu carpeta:
   ```bash
   git checkout -b TU-USUARIO/semana-01
   mkdir -p aportes-comunidad/soluciones-retos/TU-USUARIO/semana-01
   cp semana-01-arquitectura/2.reto-roto/*.yaml aportes-comunidad/soluciones-retos/TU-USUARIO/semana-01/
   ```
2. Resuelve y prueba tus manifiestos con `kubectl apply -f ...`.
3. Antes de subir tu código, ejecuta el verificador local:
   ```bash
   ./scripts/verificar-reto.sh TU-USUARIO
   ```
4. Guarda y sube a tu Fork:
   ```bash
   git add aportes-comunidad/soluciones-retos/TU-USUARIO/
   git commit -m "Solución retos semana 01"
   git push origin TU-USUARIO/semana-01
   ```
5. Abre tu **Pull Request** desde GitHub.

### Paso 6: Detén o elimina tu Codespace al terminar (¡Muy importante!)
Una vez hayas confirmado que tus cambios quedaron en GitHub (`git push`):
1. Entra a [**github.com/codespaces**](https://github.com/codespaces).
2. Ubica el Codespace del workshop y haz clic en los tres puntos **`...`**.
3. Elige:
   - **`Stop codespace`** si quieres reanudarlo mañana con el clúster ya instalado (consume un poco de tus 15 GB de disco).
   - **`Delete`** si ya terminaste por esta semana y no quieres ocupar nada de almacenamiento gratuito (siempre puedes crear uno nuevo la próxima clase).

---

[⬅️ Volver al README Principal](../README.md) • [🤝 Guía de Contribución (`CONTRIBUTING.md`)](../CONTRIBUTING.md)
