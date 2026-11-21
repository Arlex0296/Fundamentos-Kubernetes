# Reto 3: el Pod demasiado exigente (Pending)

Mi solución del reto, semana 01 (@eandreaja).

## Síntoma

El Pod se crea, pero no arranca:

```bash
kubectl apply -f 03-pod-pendiente-infinito.yaml
kubectl get pods
```

`apply` dijo `created`, y `get pods` mostró `Pending`.

## Cómo lo investigué

`kubectl describe pod reto-03-exigente`, en `Events`:

`FailedScheduling: 0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory`

Comparé lo que pedía el Pod con lo que tiene mi nodo:

| Recurso | Se puede repartir | Ya reservado | Libre | Pedía el reto | Puse yo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| CPU | 2 núcleos (2000m) | 1050m | unos 950m | 64 | 500m |
| Memoria | unos 3,8 Gi | 450 Mi | unos 3,3 Gi | 500 Gi | 500 Mi |

## Causa raíz

Los `requests` (64 CPU y 500Gi) superan por mucho la capacidad del nodo. Un request es una reserva: el despachador (scheduler) no asigna el Pod a un nodo donde no cabe.

## Solución

| Línea | Antes | Después |
| :--- | :--- | :--- |
| 18 | `memory: "500Gi"` | `memory: "500Mi"` |
| 19 | `cpu: "64"` | `cpu: "500m"` |

Los valores caben de sobra y alcanzan para un `nginx:alpine` que solo sirve una página. Igual que en el reto 02, `apply` sobre el Pod existente dio `Forbidden` (`resources` no se puede cambiar), así que lo borré y lo recreé.

## Cómo lo comprobé

Con el Pod recreado, `kubectl get pods` mostró `reto-03-exigente   1/1   Running   0`, con `cpu=500m` y `memoria=500Mi` en sus requests. Después borré el Pod por su nombre.

## Qué aprendí

- Un request es una reserva, no lo que el programa gasta: se compara contra lo que le queda libre al nodo.
- La `m` de CPU son milésimas de núcleo (`500m` es medio núcleo); `Mi` y `Gi` son mebibytes y gibibytes.
- `Pending` lo explica el despachador en los `Events` (`FailedScheduling`), antes de que el kubelet haga nada.
