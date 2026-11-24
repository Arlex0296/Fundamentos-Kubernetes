# 📔 Bitácora de Aprendizaje — 🌐 Semana 03: Redes en Kubernetes (Services y Gateway API)

> ⛵ **Tripulante:** [`@RAVILA28`](https://github.com/RAVILA28)  
> 🗓️ **Fecha de registro:** `2026-11-24`  
> 🎓 **Portafolio Principal:** [⬅️ Volver a mi Portafolio Profesional K8s](../README.md)

---

## 1️⃣ 💡 ¿Qué aprendí esta semana?

Services (ClusterIP y NodePort): IP virtual y puerto estables frente a Pods efímeros.
EndpointSlices: La lista dinámica de IPs de Pods sanos detrás de un Service.
CoreDNS: Cómo los Pods se encuentran por nombre (cocina-svc) sin memorizar IPs.
Cilium Gateway API (Gateway + HTTPRoute): El estándar moderno de enrutamiento HTTP/HTTPS que reemplaza al antiguo Ingress.

---

## 2️⃣ 🧩 ¿Qué fue lo más retador y cómo lo resolví?

- Diagnóstico y resolución de manifiestos en el laboratorio.

---

## 3️⃣ 💻 Comandos y herramientas que practiqué

```bash
kubectl get svc  <nombre>
kubectl get endpoints <nombre>
kubectl get endpointslices -l kubernetes.io/service-name=<nombre>
kubectl get pods -l app=<label> -o wide

# 0. Inspecciona la configuración DNS inyectada por CoreDNS:
kubectl exec -n kubecafe-salon mesero-tester -- cat /etc/resolv.conf

# 1. Nombre corto falla porque está en otro namespace:
kubectl exec -n kubecafe-salon mesero-tester -- nslookup cocina-svc || echo "Falla sin namespace"

# 2. Con <service>.<namespace>:
kubectl exec -n kubecafe-salon mesero-tester -- curl -i http://cocina-svc.default

# 3. Con <service>.<namespace>.svc:
kubectl exec -n kubecafe-salon mesero-tester -- curl -i http://cocina-svc.default.svc

# 4. Con el FQDN completo:
kubectl exec -n kubecafe-salon mesero-tester -- curl -i http://cocina-svc.default.svc.cluster.local
```

---

## 4️⃣ 🚀 Aplicación real y próximos pasos

Seguir practicando en los laboratorios del workshop y aplicando buenas prácticas Cloud Native.

---

<div align="center">
  <sub>🏔️☕ Bitácora registrada en <b><a href="https://github.com/edwinbermudez91/Fundamentos-Kubernetes">De Cero a Capitán en Kubernetes — Cloud Native Medellín (CNCF)</a></b></sub>
</div>
