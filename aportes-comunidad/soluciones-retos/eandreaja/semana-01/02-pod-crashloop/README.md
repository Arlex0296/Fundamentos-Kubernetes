# Reto 2: el Pod que nace y muere (CrashLoopBackOff)

Mi solución del reto, semana 01 (@eandreaja).

## Síntoma

El Pod se crea, pero no se queda corriendo:

```bash
kubectl apply -f 02-pod-crashloop.yaml
kubectl get pods
```

`apply` dijo `created`, y `get pods` mostró `CrashLoopBackOff` con reinicios cada vez más espaciados (`RESTARTS 1 (5s ago)`).

## Cómo lo investigué

`kubectl describe` no basta, porque Kubernetes sí arrancó el contenedor; lo que falló fue el programa de adentro. Con `kubectl logs reto-02-crash` apareció:

`sh: line 0: echho: not found`

## Causa raíz

El comando es `sh -c "echho ... && sleep 3600"`. Como `echho` no existe, el `&&` impide que corra `sleep`, la shell termina, el contenedor se apaga (vive mientras viva su proceso principal) y Kubernetes lo reinicia una y otra vez.

## Solución

| Línea | Antes | Después |
| :--- | :--- | :--- |
| 16 | `echho '¡Hola Cloud Native Medellín!' && sleep 3600` | `echo '¡Hola Cloud Native Medellín!' && sleep 3600` |

Aplicar el cambio sobre el Pod existente dio `Forbidden: pod updates may not change fields other than ...`: en un Pod que ya existe solo se pueden cambiar `image`, `activeDeadlineSeconds`, `tolerations` y `terminationGracePeriodSeconds`. Tuve que borrar el Pod y crearlo de nuevo.

## Cómo lo comprobé

Con el Pod recreado, `kubectl get pods` mostró `reto-02-crash   1/1   Running   0`, y `kubectl logs reto-02-crash` imprimió `¡Hola Cloud Native Medellín!`. Después borré el Pod por su nombre.

## Qué aprendí

- Cuando el contenedor arranca pero falla por dentro, la causa se lee en `kubectl logs`, no en `describe`.
- `&&` ejecuta el segundo paso solo si el primero sale bien.
- El comando de arranque (`command`) no se puede cambiar en un Pod existente; en la práctica un Deployment crea el Pod nuevo por mí (semana 02).
