# Reto 1: el selector que no reconoce a sus propios Pods

Mi solución del reto, semana 02 (@eandreaja).

## Síntoma

Al aplicar el Deployment, Kubernetes lo rechaza de entrada:

```bash
kubectl apply -f 01-deployment-selector-roto.yaml
kubectl get deployments,replicasets,pods
```

El `apply` respondió:

`The Deployment "reto-01-selector" is invalid: spec.template.metadata.labels: Invalid value: {"app":"etiqueta-equivocada-web","reto":"1"}: `selector` does not match template `labels``

Y `get` mostró `No resources found in default namespace`: no se creó ni el Deployment, ni el ReplicaSet, ni los Pods.

## Cómo lo investigué

Como el API Server rechazó el manifiesto antes de crear nada, no había ningún recurso que `kubectl describe` pudiera mirar. La pista estaba en el propio mensaje del `apply`, que hablaba de `selector` y de `labels`.

Al principio leí mal el archivo. Venía de otros lenguajes y miré solo lo que había a la derecha de los dos puntos; como `matchLabels:` y `labels:` no tienen nada al lado, pensé que estaban vacíos. En YAML, lo que va debajo y con más sangría pertenece a esa línea. Cuando miré las líneas de abajo vi los dos valores de `app`:

- `selector.matchLabels` decía `app: cafeteriamovil-api`.
- `template.metadata.labels` decía `app: etiqueta-equivocada-web`.

## Causa raíz

El Deployment crea sus Pods con las etiquetas de `template.metadata.labels` y después los reconoce con `selector.matchLabels`. Si los dos no coinciden, el Deployment crearía Pods que no podría reconocer como suyos, así que Kubernetes rechaza el manifiesto.

## Solución

| Campo | Antes | Después |
| :--- | :--- | :--- |
| `spec.template.metadata.labels.app` | `etiqueta-equivocada-web` | `cafeteriamovil-api` |

Elegí cambiar la etiqueta de la plantilla y no el selector, porque `etiqueta-equivocada-web` no suena a una aplicación real, y `cafeteriamovil-api` sí. Cambié lo mínimo. El nombre del Deployment (`reto-01-selector`) no tiene que ver con esto: las etiquetas solo tienen que coincidir entre sí.

## Cómo lo comprobé

Primero lo validé con `kubectl apply --dry-run=server`, que respondió `created (server dry run)`. Luego lo apliqué: el Deployment llegó a `READY 3/3`, y el ReplicaSet `reto-01-selector-5699b9f4c5` creó 3 Pods que llevan ese mismo hash en el nombre. Con `kubectl get deployment reto-01-selector -o jsonpath` comprobé que el selector y las etiquetas de la plantilla quedaron iguales (`app: cafeteriamovil-api`). Después borré el Deployment por su nombre con `kubectl delete deployment reto-01-selector`.

## Qué aprendí

- `selector.matchLabels` es la regla con la que el Deployment busca sus Pods, y `template.metadata.labels` son las etiquetas con las que los crea. Tienen que coincidir.
- Si el API Server rechaza el manifiesto, no se crea nada: el error del `apply` es la pista, y `describe` no sirve porque no hay recurso.
- En YAML la sangría es parte del significado: una línea que termina en `:` y no tiene valor al lado contiene lo que va debajo, más a la derecha.
- Las etiquetas y el nombre del Deployment son cosas distintas.
