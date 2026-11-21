# 📔 Bitácora de Aprendizaje — 🌱 Semana 01: Arquitectura de Kubernetes y Pods

> ⛵ **Tripulante:** [`@eandreaja`](https://github.com/eandreaja)  
> 🗓️ **Fecha de registro:** `2026-11-21`  
> 🎓 **Portafolio Principal:** [⬅️ Volver a mi Portafolio Profesional K8s](../README.md)

---

## 1️⃣ 💡 ¿Qué aprendí esta semana?

Aprendí que un error en Kubernetes puede estar en capas distintas y que cada capa se investiga con una herramienta diferente: `kubectl apply` me dice si el YAML es válido, `describe` (sección Events) me dice qué pasó con el scheduler y el kubelet, y `logs` me dice qué pasó dentro del contenedor. También entendí que `created` solo significa que el clúster aceptó el pedido, y que `Running` es otra cosa.

---

## 2️⃣ 🧩 ¿Qué fue lo más retador y cómo lo resolví?

El reto 03 (`Pending`): comparé lo que pedía el Pod (64 CPU y 500Gi) con lo que tiene mi nodo (2 CPU y unos 3,8 Gi, con una parte ya reservada) y entendí que un request es una reserva, no lo que el programa gasta. En el reto 04, kubectl me mostró los errores por capas: primero `apiVersion: v2` y después los campos desconocidos (`imaeg` y `port`) juntos. Y en los retos 02 y 03 `apply` me dio `Forbidden`, porque `command` y `resources` no se pueden cambiar en un Pod que ya existe: tuve que borrarlo y recrearlo.

---

## 3️⃣ 💻 Comandos y herramientas que practiqué

```bash
kubectl apply -f <archivo>.yaml
kubectl get pods
kubectl describe pod <nombre>
kubectl logs <nombre>
kubectl delete pod <nombre>
git checkout -b eandreaja/semana-01
```

---

## 4️⃣ 🚀 Aplicación real y próximos pasos

Cuando dockerice mi proyecto de Python y lo despliegue, quiero leer los errores por capas (apply, Events y logs) en vez de adivinar, y pedir recursos ajustados a lo que la aplicación necesita. Me quedó la duda de cómo se cambia el comando de un Pod sin borrarlo; entiendo que en la práctica lo hace un Deployment (semana 02).

---

<div align="center">
  <sub>🏔️☕ Bitácora registrada en <b><a href="https://github.com/edwinbermudez91/Fundamentos-Kubernetes">De Cero a Capitán en Kubernetes — Cloud Native Medellín (CNCF)</a></b></sub>
</div>
