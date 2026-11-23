# 📔 Bitácora de Aprendizaje — 🌱 Semana 01: Arquitectura de Kubernetes y Pods

> ⛵ **Tripulante:** [`@RAVILA28`](https://github.com/RAVILA28)  
> 🗓️ **Fecha de registro:** `2026-11-23`  
> 🎓 **Portafolio Principal:** [⬅️ Volver a mi Portafolio Profesional K8s](../README.md)

---

## 1️⃣ 💡 ¿Qué aprendí esta semana?

- Recorde de forma general como crear los pods sin deployment
- Lo mas ineteresante esta en saber revisar la documentacion o el diccionario integrado

---

## 2️⃣ 🧩 ¿Qué fue lo más retador y cómo lo resolví?

- Diagnóstico y resolución de manifiestos en el laboratorio.

---

## 3️⃣ 💻 Comandos y herramientas que practiqué

```bash
# Consultar ejemplos reales de sintaxis:
kubectl run --help
kubectl apply --help

# Consultar la documentación y tipos de dato de cualquier campo YAML:
kubectl explain pod
kubectl explain pod.spec.containers
kubectl explain pod.spec.containers.resources
kubectl explain pod.spec.containers.livenessProbe

# Ver el árbol jerárquico completo de propiedades con --recursive:
kubectl explain pod --recursive
kubectl explain pod.spec --recursive | grep -i -C 3 "probe"
```

---

## 4️⃣ 🚀 Aplicación real y próximos pasos

Seguir practicando en los laboratorios del workshop y aplicando buenas prácticas Cloud Native.

---

<div align="center">
  <sub>🏔️☕ Bitácora registrada en <b><a href="https://github.com/edwinbermudez91/Fundamentos-Kubernetes">De Cero a Capitán en Kubernetes — Cloud Native Medellín (CNCF)</a></b></sub>
</div>
