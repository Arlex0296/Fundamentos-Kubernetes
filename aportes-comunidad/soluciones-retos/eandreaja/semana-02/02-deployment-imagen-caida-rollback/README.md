# Reto 2: el despliegue fallido y el bloqueo de réplicas

Mi solución del reto, semana 02 (@eandreaja).

## Síntoma

El Deployment se crea, pero nunca queda listo:

```bash
kubectl apply -f 02-deployment-imagen-caida-rollback.yaml
kubectl get deployments,replicasets,pods
```

`apply` respondió `deployment.apps/reto-02-imagen created`, y `get` mostró `READY 0/3` y los Pods en `ImagePullBackOff`.

## Cómo lo investigué

`get pods` me dijo **qué** pasaba (`ImagePullBackOff`), pero no **por qué**. Con `kubectl describe pod` leí la sección `Events`, que decía:

`Failed to pull image "nginx:version-fantasma-prod-999": ... not found`

`Pull` es traer la imagen y `BackOff` es que Kubernetes espera cada vez más entre un intento y el siguiente. Además miré `kubectl rollout history deployment/reto-02-imagen` y solo había 1 revisión, la rota: no había una versión buena anterior, así que `rollout undo` no servía.

## Causa raíz

El nombre de la imagen (`nginx`) era correcto, pero la etiqueta (la versión) `version-fantasma-prod-999` no existe en el registro. Sin imagen, el contenedor no arranca y el Deployment se queda en `0/3`.

## Solución

| Campo | Antes | Después |
| :--- | :--- | :--- |
| `spec.template.spec.containers[0].image` | `nginx:version-fantasma-prod-999` | `nginx:alpine` |

Cambié solo la etiqueta y no el nombre `nginx`, porque lo mínimo que estaba mal era la versión.

## Cómo lo comprobé

Lo validé con `kubectl apply --dry-run=server` y luego lo apliqué: `apply` respondió `configured` y el Deployment llegó a `READY 3/3`. Kubernetes hizo un rolling update: creó un ReplicaSet nuevo (`reto-02-imagen-6d4dbc8546`) con 3 Pods sanos y dejó el ReplicaSet roto en `DESIRED 0`. `rollout history` mostró 2 revisiones: la 1 con la imagen rota y la 2 con `nginx:alpine`. Después borré el Deployment por su nombre con `kubectl delete deployment reto-02-imagen`.

## Qué aprendí

- `get pods` dice qué estado tiene un Pod; para saber por qué, hay que leer `Events` con `describe`.
- `ImagePullBackOff` significa que no se pudo traer la imagen y que Kubernetes espera más tiempo entre cada reintento.
- `rollout undo` solo sirve si hubo antes una versión buena; si la única revisión es la rota, hay que corregir el YAML y aplicar.
- Arreglar el archivo no cambia el clúster hasta hacer `apply`.
