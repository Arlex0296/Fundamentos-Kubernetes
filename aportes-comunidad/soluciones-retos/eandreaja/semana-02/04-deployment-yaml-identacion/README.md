# Reto 4: el manifiesto con indentación rota y apiVersion incompatible

Mi solución del reto, semana 02 (@eandreaja).

## Síntoma

El API Server rechaza el Deployment desde el primer intento:

```bash
kubectl apply -f 04-deployment-yaml-identacion.yaml
```

`apply` respondió:

`error: resource mapping not found for name: "reto-04-estructura" ... no matches for kind "Deployment" in version "v1"`

Y `get` mostró `No resources found in default namespace`: no se creó nada.

## Cómo lo investigué

El error solo hablaba del `apiVersion`, pero como en los retos anteriores sabía que el API Server muestra el primer error que encuentra, leí el archivo completo y lo comparé con los Deployments de los otros retos y del laboratorio de la semana 02, donde el `apiVersion` es `apps/v1` y `template` y `containers` están con sangría. Así encontré tres problemas:

1. `apiVersion: v1`.
2. `template:` pegado al borde izquierdo, al mismo nivel que `spec:`.
3. `containers:` pegado al borde izquierdo, en vez de estar dentro del `spec:` de `template`.

## Causa raíz

- Los Deployments pertenecen al grupo `apps/v1`, no a `v1`: Kubernetes buscó "Deployment" en `v1` y no lo encontró.
- En YAML la sangría decide a qué bloque pertenece cada línea. `template` y `containers` estaban en el borde, así que no pertenecían a `spec:` ni a `template.spec:`, y todo su contenido quedaba fuera de lugar.

## Solución

| Línea | Antes | Después |
| :--- | :--- | :--- |
| `apiVersion` | `v1` | `apps/v1` |
| `template:` | 0 espacios | 2 espacios, dentro de `spec:` |
| `containers:` | 0 espacios | 6 espacios, dentro del `spec:` de `template` |

Al mover `template:` y `containers:` moví también todas las líneas que van debajo de cada uno, porque forman parte de su bloque. La escalera quedó así:

```yaml
spec:                      # 0 espacios
  template:                # 2 espacios
    metadata:              # 4 espacios
      labels:              # 6 espacios
        app: pagos         # 8 espacios
    spec:                  # 4 espacios
      containers:          # 6 espacios
        - name: servicio-pagos   # 8 espacios
```

## Cómo lo comprobé

Lo validé con `kubectl apply --dry-run=server` y luego lo apliqué: `apply` respondió `created` y el Deployment llegó a `2/2`, con un ReplicaSet (`reto-04-estructura-fd88bc579`) y 2 Pods con ese mismo hash. Con `kubectl get deployment reto-04-estructura -o jsonpath` comprobé que el clúster guardó `apiVersion: apps/v1` y el contenedor `servicio-pagos` con la imagen `nginx:alpine`. Después borré el Deployment por su nombre con `kubectl delete deployment reto-04-estructura`.

## Qué aprendí

- Cada recurso pertenece a un grupo de API: un Deployment va en `apps/v1`, no en `v1`.
- Cuando muevo una línea que termina en `:`, tengo que mover también todo lo que va debajo, porque pertenece a ella.
- Al contar sangrías hay que decir desde qué línea cuento: el mismo `containers:` está a 3 escalones desde el `spec:` principal y a 1 desde el `spec:` de `template`.
- El API Server muestra el primer error que encuentra; leer el archivo completo evita que los otros queden escondidos.
