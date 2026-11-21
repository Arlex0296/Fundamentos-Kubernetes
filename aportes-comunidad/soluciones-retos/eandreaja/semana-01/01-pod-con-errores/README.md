# Reto 1: el Pod que no encuentra su ropa (puerto e imagen)

Mi solución del reto, semana 01 (@eandreaja).

## Síntoma

Al aplicar el archivo, el clúster lo rechazó:

```bash
kubectl apply -f 01-pod-con-errores.yaml
```

`The Pod "reto-01-imagen" is invalid: spec.containers[0].ports[0].containerPort: Invalid value: 80809: must be between 1 and 65535, inclusive`

## Cómo lo investigué

1. El mensaje trae la ruta exacta del campo (`containerPort`) y la regla (entre 1 y 65535). Con `kubectl get pod reto-01-imagen` comprobé que el Pod ni siquiera se había creado (`NotFound`).
2. Corregí el puerto a `80`, que es el puerto de Nginx dentro del contenedor (el `8080` de `-p 8080:80` es el lado de mi PC y no va en `containerPort`).
3. Al aplicar de nuevo, el Pod se creó pero quedó en `ErrImagePull` / `ImagePullBackOff`. Con `kubectl describe pod reto-01-imagen`, en `Events`: `Failed to pull image "nginx:version-fantasma-999" ... not found`.

## Causa raíz

Dos errores en capas distintas: un puerto fuera de rango (lo rechaza el API antes de crear el Pod) y una etiqueta de imagen inexistente (falla al descargar la imagen).

## Solución

| Línea | Antes | Después |
| :--- | :--- | :--- |
| 14 | `image: nginx:version-fantasma-999` | `image: nginx:alpine` |
| 16 | `containerPort: 80809` | `containerPort: 80` |

Al aplicar el cambio sobre el Pod que ya existía, `kubectl apply` dijo `configured`: la imagen de un contenedor sí se puede cambiar en un Pod existente.

## Cómo lo comprobé

`kubectl get pods` mostró `reto-01-imagen   1/1   Running   0` (cero reinicios), con la imagen `nginx:alpine` y el puerto `80`. Después borré el Pod por su nombre con `kubectl delete pod reto-01-imagen`.

## Qué aprendí

- `ErrImagePull` es el fallo al descargar la imagen; `ImagePullBackOff` es lo mismo, pero el kubelet espera un rato antes de reintentar. En los Events, `(x4 over 2m20s)` significa que lo intentó 4 veces en ese tiempo.
- Un mismo YAML puede tener errores en capas distintas: `apply` muestra el primero y los demás aparecen al corregirlo.
- En `containerPort` va un solo número, el del contenedor; el puerto de mi PC se resuelve después con `port-forward`.
