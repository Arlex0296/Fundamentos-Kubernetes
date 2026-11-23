# ❓ Preguntas Frecuentes de la Comunidad (FAQ)

Respuestas a dudas reales surgidas en las **bitácoras semanales** y sesiones en vivo del workshop **De Cero a Capitán en Kubernetes — Cloud Native Medellín (CNCF)**.

> 💡 ¿Tienes una duda nueva? Regístrala en el campo **7️⃣ ¿Te quedó alguna duda?** del [**Formulario de Bitácora Semanal**](https://github.com/edwinbermudez91/Fundamentos-Kubernetes/issues/new?template=bitacora-semanal.yml) o abre un [**Issue de Duda en Laboratorio**](https://github.com/edwinbermudez91/Fundamentos-Kubernetes/issues/new?template=01-duda-laboratorio.md).

---

## 🌱 Semana 01 — Pods y Arquitectura

### 1. ¿Cómo cambio el `command`, `args` o `resources` de un Pod sin borrarlo?
**No se puede** modificar directamente en un Pod que ya existe (`kubectl apply` responde `Forbidden`). La mayoría de los campos de `spec` en un Pod son **inmutables** por diseño (solo se permiten cambios puntuales como `image` o `activeDeadlineSeconds`).

- **En laboratorio (Pod suelto):** Debes eliminar el Pod y volver a aplicarlo:
  ```bash
  kubectl delete pod <nombre-pod>
  kubectl apply -f <archivo>.yaml
  ```
  *(O en un solo paso durante pruebas: `kubectl replace --force -f <archivo>.yaml`).*
- **En producción:** Nunca se despliegan Pods sueltos, sino un **Deployment** (Semana 02). Cuando cambias el `command` o `resources` en el Deployment, Kubernetes crea Pods nuevos con la nueva especificación y elimina los anteriores gradualmente sin caída del servicio.

### 2. ¿Por qué mi Pod se queda en estado `Pending`?
`Pending` significa que el **Scheduler** no encontró un nodo donde ubicar el Pod. La causa más común en laboratorio es pedir más `resources.requests` (CPU o RAM) de los que tiene disponibles el nodo.
- Revisa los eventos con `kubectl describe pod <nombre-pod>` (sección `Events` al final).
- Compara lo que pide el Pod con la capacidad disponible del nodo (`kubectl describe nodes`). Recuerda que `requests` es una **reserva garantizada**, no el consumo instantáneo de la app.

---

## 🔄 Semana 02 — Deployments, Réplicas y Rollouts

### 3. ¿Por qué `kubectl rollout undo` no arregló mi Deployment roto?
Si el Deployment falló en su **primera revisión** (Revisión 1), no existe una revisión anterior sana a la cual volver (`kubectl rollout history` muestra solo 1 revisión). En ese caso, debes corregir el YAML y volver a ejecutar `kubectl apply -f <archivo>.yaml`.

### 4. ¿Por qué `kubectl apply` dice que hay un campo desconocido o error de sintaxis aunque "se vea bien"?
En YAML la **indentación (espacios)** define la jerarquía y el API Server valida los errores por capas:
- Primero valida `apiVersion` y `kind` (por ejemplo, `Deployment` usa `apps/v1`, no `v1`).
- Luego valida los nombres exactos de campos en `camelCase` (`RollingUpdate`, `matchLabels`, `containerPort`).
- Si hay varios errores en el archivo, `kubectl` a veces reporta primero el error estructural antes de validar los campos internos.

---

## 🌐 Semana 03 — Services y Port-Forward

### 5. Con `kubectl port-forward`, ¿se reparte el tráfico entre todos los Pods del Deployment?
**No.** `kubectl port-forward` abre un túnel TCP directo hacia **un único Pod**. Incluso si ejecutas `kubectl port-forward svc/mi-servicio 8080:80` o `deploy/mi-app`, `kubectl` elige internamente **un solo Pod** detrás de ese recurso y envía todas tus peticiones ahí.
- Quien realmente agrupa los Pods por `labels` y **balancea el tráfico** entre todas las réplicas disponibles es el **Service** dentro del clúster (mediante `kube-proxy`) o el **Gateway / HTTPRoute** desde el exterior.

---

## 🐙 Git y Flujo del Workshop

### 6. ¿Cómo actualizo mi Fork cada semana sin perder mis soluciones?
Sigue nuestra guía visual paso a paso: [**🔄 Cómo Sincronizar tu Fork sin Conflictos**](./como-sincronizar-tu-fork.md).
