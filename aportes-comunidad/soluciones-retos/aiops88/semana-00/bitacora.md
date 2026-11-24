# 📔 Bitácora de Navegación — Semana 00

## 🧭 Resumen de la Semana
* **Tripulante:** `@aiops88`
* **Módulo:** `Semana 00 — 🐳 Fundamentos de Docker (De Código a Contenedor)`
* **Fecha:** `2026-11-22`
* **Resultado:** 5/5 retos resueltos y validados ([PR #130](https://github.com/edwinbermudez91/Fundamentos-Kubernetes/pull/130)), más dos fallas adicionales detectadas y corregidas fuera del alcance de los enunciados.

---

## 1️⃣ 🧩 Diagnóstico y resolución

Cada reto representa un patrón de falla distinto. El primer paso en todos fue reproducir y clasificar por estado observable antes de tocar código:

| Reto | Estado observado | Causa raíz | Corrección aplicada |
| :---: | :--- | :--- | :--- |
| 01 | `Exited (0)`, sin errores en logs | Nginx se demoniza: el PID 1 hace `fork` y termina, y el runtime detiene el contenedor | `CMD ["nginx", "-g", "daemon off;"]` en forma exec |
| 02 | `Exited (1)`, error explícito | Variable obligatoria ausente; la aplicación aplica *fail-fast* | Inyección en runtime (`-e APP_SECRET_TOKEN`); sin `ENV` para el secreto |
| 03 | `Up`, ejecutando como `uid=0` | Sin `USER`; el UID 0 del contenedor es el UID 0 del kernel del host | Usuario sin privilegios UID 10001, `COPY --chown`, `USER` antes del `CMD` |
| 04 | `Up`, `.env` presente en la imagen | `COPY . .` sin `.dockerignore` incluye el build context completo | `.dockerignore` (denylist) + `COPY` explícito de `app.py` (allowlist) |
| 05 | `Up`, `Connection refused` desde el host | Bind a `127.0.0.1` (loopback del namespace) y puerto 5000 vs. mapeo 8080 | Bind a `0.0.0.0:8080`, `EXPOSE` alineado |

**Reto 01 — falla sin señal de error.** El código de salida `0` descartaba un crash. La evidencia estaba en los identificadores de proceso del log de Nginx: el arranque como `1#1` y los workers lanzados por `30#30`. Ese cambio de PID confirma el `fork` del modo demonio. La corrección va en el `CMD` y no en `nginx.conf`: no demonizarse es un requisito del runtime de contenedores, no de Nginx, y aplicarlo en la configuración afectaría al servicio en cualquier entorno.

**Reto 02 — decisión de diseño sobre secretos.** `ENV` descartado: el valor queda persistido en la configuración de la imagen, es legible con `docker inspect` por cualquiera con permiso de pull, no se puede rotar sin reconstruir y obliga a compartir el mismo secreto entre entornos. Una imagen privada no es un almacén de secretos. `ENV` queda reservado para valores por defecto no sensibles.

**Reto 03 — orden de instrucciones.** Todo lo que requiere privilegios (creación de usuario y grupo) se ejecuta antes de `USER`. Invertir el orden rompe el build (`unable to find user appuser`). El UID 10001 evita colisionar con cuentas reales del host (0–999 sistema, 1000+ usuarios humanos) ante un montaje de volumen o un escape del aislamiento.

**Reto 04 — dos controles independientes.** La allowlist en `COPY` es el control principal, porque no depende de anticipar archivos futuros. El `.dockerignore` reduce el build context y contiene una regresión a `COPY . .`; incluye `.env*`, `**/.env` y `.git/`, porque el historial puede conservar secretos eliminados. `.gitignore` no protege la imagen: Docker no lo lee.

**Reto 05 — aislamiento del problema.** La comparación entre la prueba interna (`docker exec ... wget` contra `127.0.0.1:5000`, exitosa) y la externa (`curl` al puerto mapeado, fallida) descartó la aplicación y aisló la falla en la capa de red. El puerto también puede alinearse sin cambiar código (`-p 8080:5000` o `-e PORT=8080`, ya que la app lee `PORT`), pero se corrigió el valor por defecto para que coincida con el contrato que declara `EXPOSE`.

### Fallas adicionales fuera del alcance de los enunciados
- **Exposición de secretos (Reto 02):** la aplicación devolvía `APP_SECRET_TOKEN` en texto plano en la respuesta HTTP y lo escribía en el log de arranque. Ambos se reemplazaron por un indicador booleano de presencia. La exposición en logs es la de mayor impacto: los logs se retienen, se replican y se envían a plataformas de terceros (SIEM, CloudWatch, Datadog), y no se pueden purgar de forma confiable. También se retiró el puerto interno de la respuesta, por minimización de información.
- **Pérdida de logs por buffering (Reto 05):** `docker logs` no mostraba salida porque Python usa *block buffering* cuando stdout no es una TTY. Se verificó comparando la misma imagen con y sin la variable, y se corrigió con `ENV PYTHONUNBUFFERED=1`. Sin ese ajuste, un crash descarta justamente los logs necesarios para diagnosticarlo.

---

## 2️⃣ 💻 Comandos y herramientas utilizados

```bash
# Ciclo de vida y diagnóstico
docker build -t <imagen> <build-context>
docker run -d -p <host>:<contenedor> --name <nombre> <imagen>
docker ps -a                   # incluye detenidos y su código de salida
docker logs <contenedor>       # stdout/stderr del PID 1
docker rm -f <contenedor>

# Inspección de la imagen sin ejecutar la aplicación (el comando reemplaza el CMD)
docker run --rm <imagen> id
docker run --rm <imagen> ls -la

# Aislamiento de fallas de red: prueba interna vs. externa
docker exec <contenedor> wget -qO- http://127.0.0.1:<puerto>
curl http://localhost:<puerto>

# Auditoría de variables persistidas en la imagen
docker inspect <imagen> --format '{{json .Config.Env}}'

# Flujo de contribución con fork
git remote -v                  # origin = fork propio, upstream = repositorio del curso
git add <ruta-exacta>          # staging explícito por ruta
git diff <archivo>             # revisión previa a operaciones destructivas (restore / reset)
```

---

## 3️⃣ 🚀 Aplicación en Kubernetes y producción

- **Equivalencias en el clúster:** `Exited (0)` y `Exited (1)` se manifiestan como `CrashLoopBackOff`; una imagen que corre como root es rechazada por `securityContext.runAsNonRoot: true` (`CreateContainerConfigError`); el puerto desalineado es un `targetPort` de Service que no coincide con el `containerPort`; y la inyección con `-e` se reemplaza por objetos `Secret` o un gestor externo (Vault, AWS Secrets Manager).
- **Baseline aplicable a cualquier Dockerfile:** `CMD` en forma exec con el proceso en primer plano · `USER` sin privilegios con UID alto · `COPY` por allowlist con `--chown` · `.dockerignore` con `.env*`, `.git/` y logs · ningún secreto en `ENV` · bind a `0.0.0.0` con `EXPOSE` alineado · `PYTHONUNBUFFERED=1` en imágenes de Python.
- **Automatización en CI:** escaneo de imágenes y de secretos en el pipeline (por ejemplo, Trivy y gitleaks), para que estas fallas se detecten en el build y no en revisión manual.

---

<div align="center">
  <sub>☕ Parte de mi Portafolio Profesional de Aprendizaje en <b><a href="https://github.com/edwinbermudez91/Fundamentos-Kubernetes">De Cero a Capitán en Kubernetes — Cloud Native Medellín (CNCF)</a></b></sub>
</div>
