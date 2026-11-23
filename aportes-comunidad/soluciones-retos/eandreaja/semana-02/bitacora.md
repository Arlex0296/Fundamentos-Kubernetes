# 📔 Bitácora de Aprendizaje — 🔄 Semana 02: Deployments, Réplicas y Autorreparación

> ⛵ **Tripulante:** [`@eandreaja`](https://github.com/eandreaja)  
> 🗓️ **Fecha de registro:** `2026-11-23`  
> 🎓 **Portafolio Principal:** [⬅️ Volver a mi Portafolio Profesional K8s](../README.md)

---

## 1️⃣ 💡 ¿Qué aprendí esta semana?

Aprendí que un Deployment es una orden permanente ("mantené siempre N Pods") que se apoya en un ReplicaSet, y que Kubernetes la cumple solo: borré un Pod a propósito y en segundos nació otro. También entendí que el archivo YAML y el clúster son cosas separadas, y que `kubectl apply` es el puente entre las dos: el estado que declaro en el archivo manda sobre una orden directa como `kubectl scale`.

---

## 2️⃣ 🧩 ¿Qué fue lo más retador y cómo lo resolví?

En el reto 01 leí mal el archivo: miré solo lo que había a la derecha de los dos puntos y creí que `matchLabels:` y `labels:` estaban vacíos, cuando en YAML lo que va debajo, con más sangría, pertenece a esa línea. Eso me sirvió para el reto 04, que era justamente de sangría y de `apiVersion`. En el reto 03 aprendí que el API Server muestra solo el primer error que encuentra (los campos mal ubicados), pero el archivo tenía otro más (el tipo `Rollingupdates`), así que conviene leer todo el archivo. En el reto 02 vi con `rollout history` que había una sola revisión, la rota, por eso `rollout undo` no podía arreglarlo y había que corregir el YAML y volver a aplicar.

---

## 3️⃣ 💻 Comandos y herramientas que practiqué

```bash
kubectl apply -f <archivo>.yaml
kubectl apply --dry-run=server -f <archivo>.yaml
kubectl get deployments,replicasets,pods -l app=<etiqueta>
kubectl describe pod <nombre>
kubectl scale deployment <nombre> --replicas=6
kubectl set image deployment/<nombre> <contenedor>=<imagen>
kubectl rollout status deployment/<nombre>
kubectl rollout history deployment/<nombre>
kubectl rollout undo deployment/<nombre>
kubectl port-forward deployment/<nombre> 8080:8080
git checkout -b eandreaja/semana-02
```

---

## 4️⃣ 🚀 Aplicación real y próximos pasos

Quiero usar Deployments con `RollingUpdate` (`maxSurge: 1` y `maxUnavailable: 0`) y sondas de preparación cuando despliegue mi proyecto de Python, para actualizar sin que el servicio se caiga y poder volver atrás con un rollback. Me quedó una duda para la semana 03: con `port-forward` el túnel va siempre a un solo Pod, aunque haya varios; entiendo que quien reparte el tráfico entre Pods es un Service.

---

<div align="center">
  <sub>🏔️☕ Bitácora registrada en <b><a href="https://github.com/edwinbermudez91/Fundamentos-Kubernetes">De Cero a Capitán en Kubernetes — Cloud Native Medellín (CNCF)</a></b></sub>
</div>
