# Reto 3: la estrategia de rollout mal escrita

Mi solución del reto, semana 02 (@eandreaja).

## Síntoma

El API Server rechaza el Deployment:

```bash
kubectl apply -f 03-deployment-estrategia-invalida.yaml
kubectl get deployments,pods
```

`apply` respondió:

`Error from server (BadRequest): ... strict decoding error: unknown field "spec.strategy.maxSurge", unknown field "spec.strategy.maxUnavailable"`

Y `get` mostró `No resources found in default namespace`: no se creó nada.

## Cómo lo investigué

El error solo hablaba de la ubicación de `maxSurge` y `maxUnavailable`, pero leyendo el archivo completo vi un segundo problema que el mensaje no mencionaba: el tipo estaba escrito `Rollingupdates`. Para comparar usé el bloque `strategy` del laboratorio 3 (`02-rolling-update-cero-caidas.yaml`), que sí funcionaba, y me fijé en la sangría de cada línea.

## Causa raíz

Había dos errores en `spec.strategy`:

1. El tipo `Rollingupdates` estaba mal escrito. El valor correcto es `RollingUpdate`, con mayúscula en la U y sin la "s" final. Kubernetes distingue mayúsculas y minúsculas.
2. `maxSurge` y `maxUnavailable` estaban directamente debajo de `strategy`. Tienen que ir dentro de la clave `rollingUpdate:` (con la r minúscula).

## Solución

| Línea original | Antes | Después |
| :--- | :--- | :--- |
| `type:` | `Rollingupdates` | `RollingUpdate` |
| `maxSurge` y `maxUnavailable` | un escalón de sangría, debajo de `strategy` | dos escalones, dentro de `rollingUpdate:` |

El bloque quedó así:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

## Cómo lo comprobé

Lo validé con `kubectl apply --dry-run=server` y luego lo apliqué: `apply` respondió `created` y el Deployment llegó a `2/2`. Con `kubectl get deployment reto-03-estrategia -o jsonpath='{.spec.strategy}'` comprobé lo que Kubernetes guardó:

`{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}`

Después borré el Deployment por su nombre con `kubectl delete deployment reto-03-estrategia`.

## Qué aprendí

- `RollingUpdate` (el valor de `type:`) y `rollingUpdate:` (la clave que contiene los parámetros) se parecen pero no son lo mismo, y las mayúsculas importan.
- El API Server muestra el primer error que encuentra: corregir solo ese puede dejar otro escondido, así que conviene leer el archivo completo.
- En YAML la sangría decide a qué bloque pertenece cada línea.
- `maxSurge` es cuántos Pods extra puede haber durante el cambio y `maxUnavailable` cuántos pueden faltar; con `1` y `0` nunca baja el servicio.
