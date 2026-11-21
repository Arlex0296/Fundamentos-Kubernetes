# Reto 4: el YAML que el API Server no deja entrar

Mi solución del reto, semana 01 (@eandreaja).

## Síntoma

`kubectl apply` rechaza el archivo, y los errores aparecen por capas:

```bash
kubectl apply -f 04-pod-yaml-molesto.yaml
```

## Cómo lo investigué

1. Primero: `no matches for kind "Pod" in version "v2"`. kubectl tiene que saber qué recurso es antes de revisar los campos de adentro. Corregí `apiVersion: v1`.
2. Después: `strict decoding error: unknown field "spec.containers[0].imaeg", unknown field "spec.containers[0].ports[0].port"`. La revisión estricta junta todos los campos desconocidos en un solo mensaje.

## Causa raíz

Tres errores de escritura: `apiVersion: v2`, `imaeg` y `port`.

## Solución

| Línea | Antes | Después |
| :--- | :--- | :--- |
| 5 | `apiVersion: v2` | `apiVersion: v1` |
| 12 | `imaeg: nginx:alpine` | `image: nginx:alpine` |
| 14 | `- port: 80` | `- containerPort: 80` |

## Cómo lo comprobé

Con los tres cambios, `kubectl apply` dijo `pod/reto-04-sintaxis created` y `kubectl get pods` mostró `reto-04-sintaxis   1/1   Running   0`, con la imagen `nginx:alpine` y el puerto `80`. Después borré el Pod por su nombre.

## Qué aprendí

Los errores vienen en capas, y cada capa se investiga con una herramienta distinta:

| Quién revisa | Qué revisa | Dónde se ve el error |
| :--- | :--- | :--- |
| kubectl y el API Server | Que el YAML sea válido (versión, tipo, campos, rangos) | En la salida de `apply` |
| El scheduler | Que haya un nodo con capacidad | `describe`, sección `Events` (`FailedScheduling`) |
| El kubelet | Que se pueda descargar la imagen y arrancar | `describe`, sección `Events` (`ErrImagePull`) |
| El contenedor | Que el programa de adentro funcione | `logs` |

Además: `created` solo significa que el clúster aceptó el pedido; `Running` significa que el contenedor ya funciona.
