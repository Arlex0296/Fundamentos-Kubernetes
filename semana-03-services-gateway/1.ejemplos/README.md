# 🧪 Ejemplos Prácticos de la Semana 03: Services, CoreDNS y Gateway API

¡Bienvenido a los laboratorios de redes de la **Semana 03**! Aquí conectarás tus Deployments de forma interna y externa sin depender nunca de las IPs cambiantes de los Pods.

---

## 📑 Índice de Ejemplos

| Manifiesto | Concepto Clave | Equivalente en ☕ KubeCafé |
| :--- | :--- | :--- |
| [`01-service-clusterip-interno.yaml`](./01-service-clusterip-interno.yaml) | `Service` tipo `ClusterIP` y `Endpoints` | Mesero interno atendiendo pedidos hacia la cocina. |
| [`02-service-nodeport-externo.yaml`](./02-service-nodeport-externo.yaml) | `Service` tipo `NodePort` (`30080`) | Ventanilla directa hacia la calle en un puerto fijo. |
| [`03-dns-interno-coredns.yaml`](./03-dns-interno-coredns.yaml) | Descubrimiento con `CoreDNS` entre namespaces | Llamar por nombre (`cocina-svc.default.svc.cluster.local`). |
| [`04-gateway-api-httproute.yaml`](./04-gateway-api-httproute.yaml) | `Gateway` y `HTTPRoute` (Gateway API) | Puerta principal y recepcionista enrutando `/cocina` y `/menu`. |

---

## 🌐 Laboratorio 1: Service `ClusterIP`, `Endpoints` y `EndpointSlices`

### Paso 1: Despliega la cocina y su Service interno
```bash
kubectl apply -f semana-03-services-gateway/1.ejemplos/01-service-clusterip-interno.yaml
```

### Paso 2: Verifica el Service, sus Endpoints y EndpointSlices
```bash
kubectl get svc cocina-svc
kubectl get endpoints cocina-svc
kubectl get endpointslices -l kubernetes.io/service-name=cocina-svc
kubectl get pods -l app=kubecafe-cocina -o wide
```
> 💡 **Observa:** Las IPs que aparecen en `Endpoints` y en `EndpointSlices` coinciden exactamente con las IPs de los 2 Pods de `kubecafe-cocina`. Si borras un Pod, Kubernetes actualiza la lista automáticamente.
>
> 📌 **¿Por qué existen ambos?** `Endpoints` es el objeto clásico (un único recurso para todas las IPs del Service, lo que se vuelve pesado cuando hay miles de Pods). **`EndpointSlices`** es su sucesor moderno en Kubernetes: divide los destinos en fragmentos más pequeños y eficientes para `kube-proxy` y el plano de control.

---

## 🚪 Laboratorio 2: Exposición Directa con `NodePort`

### Paso 1: Despliega el menú web y el Service NodePort
```bash
kubectl apply -f semana-03-services-gateway/1.ejemplos/02-service-nodeport-externo.yaml
```

### Paso 2: Verifica el puerto asignado y accede
```bash
kubectl get svc menu-nodeport-svc
```
Para probar desde tu máquina:
```bash
kubectl port-forward svc/menu-nodeport-svc 8081:80
```
Abre `http://localhost:8081` en tu navegador (o usa `http://<IP-DEL-NODO>:30080` si tu clúster expone los nodos directamente).

---

## 🧭 Laboratorio 3: Descubrimiento DNS con `CoreDNS` (Cross-Namespace)

### Paso 1: Despliega el Pod cliente en otro Namespace (`kubecafe-salon`)
```bash
kubectl apply -f semana-03-services-gateway/1.ejemplos/03-dns-interno-coredns.yaml
kubectl wait --for=condition=Ready pod/mesero-tester -n kubecafe-salon --timeout=60s
```

### Paso 2: Prueba la resolución DNS entre Namespaces
Desde `kubecafe-salon`, intenta llamar a `cocina-svc` (que vive en `default`):
```bash
# 1. Nombre corto falla porque está en otro namespace:
kubectl exec -n kubecafe-salon mesero-tester -- curl -s --max-time 3 http://cocina-svc || echo "Falla sin namespace"

# 2. Usando <service>.<namespace> funciona:
kubectl exec -n kubecafe-salon mesero-tester -- curl -I http://cocina-svc.default

# 3. Usando el FQDN completo de Kubernetes:
kubectl exec -n kubecafe-salon mesero-tester -- curl -I http://cocina-svc.default.svc.cluster.local
```

---

## 🏛️ Laboratorio 4: Enrutamiento HTTP Moderno con Gateway API (Cilium)

Este laboratorio utiliza **Cilium** (el CNI del clúster) como controlador nativo de **Gateway API** (`gatewayClassName: cilium`).

### Paso 1: Instalar los CRDs de Gateway API y habilitar Gateway API en Cilium
1. Instala los CRDs oficiales de Kubernetes Gateway API:
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
   ```
2. Habilita `gatewayAPI.enabled=true` en tu instalación existente de **Cilium CNI** (elige Helm o Cilium CLI según cómo lo hayas instalado) y reinicia el operador/agente para que detecten los CRDs:
   ```bash
   # Opción A: Con Helm
   helm upgrade cilium cilium/cilium \
     --namespace kube-system \
     --reuse-values \
     --set gatewayAPI.enabled=true

   # Opción B: Con Cilium CLI
   # cilium upgrade --reuse-values --set gatewayAPI.enabled=true

   # Reiniciar Cilium Operator y DaemonSet para activar el controlador Gateway API
   kubectl -n kube-system rollout restart deployment/cilium-operator
   kubectl -n kube-system rollout restart daemonset/cilium
   ```
3. Verifica que Cilium registró el `GatewayClass`:
   ```bash
   kubectl get gatewayclass cilium
   ```
   *(La columna `ACCEPTED` debe mostrar `True`).*

### Paso 2: Aplicar el Gateway y el HTTPRoute
```bash
kubectl apply -f semana-03-services-gateway/1.ejemplos/04-gateway-api-httproute.yaml
kubectl get gateway,httproute
```

### Paso 3: Probar las rutas `/cocina` y `/menu`
Obtén la IP asignada al Gateway (o usa `port-forward` si estás en un entorno local sin LoadBalancer):
```bash
GW_IP=$(kubectl get gateway kubecafe-gateway -o jsonpath='{.status.addresses[0].value}')
curl -I http://$GW_IP/cocina
curl -I http://$GW_IP/menu
```

---

## 🧹 Limpieza de los Ejemplos

```bash
kubectl delete -f semana-03-services-gateway/1.ejemplos/04-gateway-api-httproute.yaml --ignore-not-found
kubectl delete -f semana-03-services-gateway/1.ejemplos/03-dns-interno-coredns.yaml --ignore-not-found
kubectl delete -f semana-03-services-gateway/1.ejemplos/02-service-nodeport-externo.yaml --ignore-not-found
kubectl delete -f semana-03-services-gateway/1.ejemplos/01-service-clusterip-interno.yaml --ignore-not-found
```
