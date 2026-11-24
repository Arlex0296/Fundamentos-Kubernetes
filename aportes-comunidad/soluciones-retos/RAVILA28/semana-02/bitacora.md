# 📔 Bitácora de Aprendizaje — 🔄 Semana 02: Deployments, Réplicas y Autorreparación

> ⛵ **Tripulante:** [`@RAVILA28`](https://github.com/RAVILA28)  
> 🗓️ **Fecha de registro:** `2026-11-24`  
> 🎓 **Portafolio Principal:** [⬅️ Volver a mi Portafolio Profesional K8s](../README.md)

---

## 1️⃣ 💡 ¿Qué aprendí esta semana?

- Despliegue de deploymente, usos de probes y estategia de despligue

---

## 2️⃣ 🧩 ¿Qué fue lo más retador y cómo lo resolví?

- Diagnóstico y resolución de manifiestos en el laboratorio.

---

## 3️⃣ 💻 Comandos y herramientas que practiqué

```bash
kubectl get deployments: Lista los deployments y sus réplicas deseadas/actuales
kubectl describe deployment <nombre> _}: Muestra eventos, estrategia, selector y réplicas
kubectl scale deployment <nombre> --replicas=5 : Escala horizontalmente el número de Pods
kubectl rollout status deployment <nombre> : Monitorea en tiempo real el progreso de actualización
kubectl rollout history deployment <nombre> : Muestra las revisiones del historial de despliegue
kubectl rollout undo deployment <nombre> : Vuelve a la versión anterior inmediatamente
kubectl rollout undo deployment <nombre> --to-revision=1 : Vuelve a una revisión específica
kubectl rollout restart deployment <nombre> : Reinicia todos los Pods en secuencia ordenada
kubectl get deployments,replicasets,pods -l app=<label> : Observar jerraquía


# Cambiar la variable VERSION en el Deployment
kubectl set env deployment/<nombre> VERSION=v2.0

# Observar cómo Kubernetes reemplaza los Pods uno a uno sin apagar el servicio
kubectl rollout status deployment/<nombre>

# Consultar el historial de revisiones
kubectl rollout history deployment/<nombre>

# Comprobar que el contenedor NO corre como root (uid=10001)
kubectl exec deployment/<nombre> -- id
```

---

## 4️⃣ 🚀 Aplicación real y próximos pasos

Seguir practicando en los laboratorios del workshop y aplicando buenas prácticas Cloud Native.

---

<div align="center">
  <sub>🏔️☕ Bitácora registrada en <b><a href="https://github.com/edwinbermudez91/Fundamentos-Kubernetes">De Cero a Capitán en Kubernetes — Cloud Native Medellín (CNCF)</a></b></sub>
</div>
