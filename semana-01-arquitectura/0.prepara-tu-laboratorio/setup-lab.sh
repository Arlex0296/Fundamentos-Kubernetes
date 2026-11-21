#!/usr/bin/env bash
# 🚀 Script Interactivo de Arranque Rápido para Laboratorio Local KubeCafé
# Crea un clúster Kind multi-nodo con Cilium CNI, Gateway API CRDs, metrics-server y LoadBalancer IPPool.
set -euo pipefail

echo "================================================================="
echo " ☕ KubeCafé — Setup Rápido de Laboratorio Local (Kind + Cilium)"
echo "================================================================="

# 1. Verificar herramientas requeridas
for cmd in docker kind kubectl helm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Falta '$cmd' en tu PATH. Instálalo antes de continuar."
    exit 1
  fi
done

# Helper para preguntas Sí/No tolerante a mayúsculas, espacios y teclas repetidas (ej. SS, si, yes)
ask_yes_no() {
  local prompt="$1"
  local default_val="${2:-S}"
  local ans
  while true; do
    read -r -p "$prompt" ans
    ans="$(echo "$ans" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
    if [[ -z "$ans" ]]; then
      echo "$default_val"
      return 0
    fi
    case "$ans" in
      s|si|sí|ss|y|yes|yy) echo "S"; return 0 ;;
      n|no|nn)             echo "N"; return 0 ;;
      *) echo "   ⚠️  Entrada no válida ('$ans'). Escribe S (sí) o N (no)." >&2 ;;
    esac
  done
}

# 1.5 Detectar clústeres existentes y ofrecer eliminar o recrear
EXISTING_CLUSTERS="$(kind get clusters 2>/dev/null || true)"
if [[ -n "$EXISTING_CLUSTERS" ]]; then
  echo ""
  echo "📋 Clústeres Kind detectados actualmente:"
  while IFS= read -r c; do
    echo "   • $c"
  done <<< "$EXISTING_CLUSTERS"
  echo ""
  echo "¿Qué deseas hacer?"
  echo "  1) Crear un clúster nuevo (por defecto)"
  echo "  2) Eliminar uno o todos los clústeres existentes"
  echo "  3) Recrear un clúster existente (eliminar y volver a crear)"
  while true; do
    read -r -p "👉 Elige una opción [1]: " ACTION_CHOICE
    ACTION_CHOICE="$(echo "${ACTION_CHOICE:-1}" | tr -d '[:space:]')"
    [[ "$ACTION_CHOICE" =~ ^[123]$ ]] && break
    echo "   ⚠️  Opción no válida. Elige 1, 2 o 3."
  done

  if [[ "$ACTION_CHOICE" == "2" ]]; then
    while true; do
      read -r -p "🗑️  Escribe el nombre del clúster a eliminar, o 'todos' para borrar todos: " DEL_TARGET
      DEL_TARGET="$(echo "$DEL_TARGET" | tr -d '[:space:]')"
      DEL_LOWER="$(echo "$DEL_TARGET" | tr '[:upper:]' '[:lower:]')"
      if [[ "$DEL_LOWER" == "todos" || "$DEL_LOWER" == "all" ]]; then
        kind delete clusters --all
        echo "✅ Todos los clústeres Kind fueron eliminados."
        exit 0
      elif [[ -n "$DEL_TARGET" ]] && echo "$EXISTING_CLUSTERS" | grep -Fxq "$DEL_TARGET"; then
        kind delete cluster --name "$DEL_TARGET"
        echo "✅ Clúster '$DEL_TARGET' eliminado."
        exit 0
      else
        echo "   ⚠️  No existe un clúster llamado '$DEL_TARGET'. Intenta de nuevo o escribe 'todos'."
      fi
    done
  elif [[ "$ACTION_CHOICE" == "3" ]]; then
    FIRST_CLUSTER="$(echo "$EXISTING_CLUSTERS" | head -n 1)"
    while true; do
      read -r -p "♻️  Nombre del clúster a recrear [$FIRST_CLUSTER]: " RECREATE_TARGET
      RECREATE_TARGET="$(echo "${RECREATE_TARGET:-$FIRST_CLUSTER}" | tr -d '[:space:]')"
      if echo "$EXISTING_CLUSTERS" | grep -Fxq "$RECREATE_TARGET"; then
        kind delete cluster --name "$RECREATE_TARGET"
        echo "✅ Clúster '$RECREATE_TARGET' eliminado. Continuando con la creación..."
        break
      else
        echo "   ⚠️  No existe un clúster llamado '$RECREATE_TARGET'. Intenta de nuevo."
      fi
    done
  fi
fi

# 2. Configuración interactiva
while true; do
  read -r -p "📛 Nombre del clúster Kind [kubecafe]: " CLUSTER_NAME
  CLUSTER_NAME="$(echo "${CLUSTER_NAME:-kubecafe}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  if [[ "$CLUSTER_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
    break
  fi
  echo "   ⚠️  Nombre inválido. Usa solo letras minúsculas, números y guiones (ej. kubecafe)."
done

while true; do
  read -r -p "🖥️  Número de nodos Worker (0 = solo control-plane) [2]: " WORKER_COUNT
  WORKER_COUNT="$(echo "${WORKER_COUNT:-2}" | tr -d '[:space:]')"
  if [[ "$WORKER_COUNT" =~ ^[0-9]+$ ]]; then
    break
  fi
  echo "   ⚠️  Ingresa un número entero válido (>= 0)."
done

INSTALL_CILIUM="$(ask_yes_no "🐝 ¿Instalar Cilium CNI + Gateway API? [S/n]: " "S")"
if [[ "$INSTALL_CILIUM" == "S" ]]; then
  INSTALL_LB="$(ask_yes_no "⚖️  ¿Configurar Cilium LoadBalancer (IPPool + L2 basado en Docker)? [S/n]: " "S")"
else
  INSTALL_LB="N"
fi
INSTALL_METRICS="$(ask_yes_no "📊 ¿Instalar metrics-server (para kubectl top)? [S/n]: " "S")"
INSTALL_HEADLAMP="$(ask_yes_no "🖥️  ¿Instalar consola visual Headlamp? [S/n]: " "S")"

# 3. Generar configuración Kind temporal
KIND_CFG="$(mktemp /tmp/kind-kubecafe-XXXXXX.yaml)"
trap 'rm -f "$KIND_CFG"' EXIT

cat > "$KIND_CFG" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
EOF

if [[ "$INSTALL_CILIUM" == "S" ]]; then
  cat >> "$KIND_CFG" <<EOF
networking:
  disableDefaultCNI: true
  kubeProxyMode: "none"
EOF
fi

cat >> "$KIND_CFG" <<EOF
nodes:
  - role: control-plane
EOF

for ((i = 1; i <= WORKER_COUNT; i++)); do
  echo "  - role: worker" >> "$KIND_CFG"
done

echo ""
echo "🔨 Creando clúster Kind '$CLUSTER_NAME' (1 control-plane + $WORKER_COUNT worker(s))..."
kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CFG"

# 4. Instalar Gateway API CRDs + Cilium
if [[ "$INSTALL_CILIUM" == "S" ]]; then
  echo ""
  echo "📦 Instalando CRDs de Kubernetes Gateway API (v1.6.3)..."
  GW_BASE="https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.6.3/config/crd/standard"
  for crd in gatewayclasses gateways httproutes referencegrants grpcroutes backendtlspolicies tlsroutes; do
    kubectl apply --server-side -f "${GW_BASE}/gateway.networking.k8s.io_${crd}.yaml"
  done

  echo ""
  echo "🐝 Instalando Cilium CNI via Helm..."
  helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true
  helm repo update >/dev/null

  API_SERVER_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"
  CILIUM_ARGS=(
    --namespace kube-system
    --set ipam.mode=kubernetes
    --set kubeProxyReplacement=true
    --set k8sServiceHost="$API_SERVER_IP"
    --set k8sServicePort=6443
    --set gatewayAPI.enabled=true
  )
  if [[ "$INSTALL_LB" == "S" ]]; then
    CILIUM_ARGS+=(--set l2announcements.enabled=true --set externalIPs.enabled=true)
  fi

  helm upgrade --install cilium cilium/cilium "${CILIUM_ARGS[@]}"

  echo "⏳ Esperando a que los nodos y Cilium estén Ready..."
  kubectl -n kube-system rollout status daemonset/cilium --timeout=180s
  kubectl -n kube-system rollout status deployment/cilium-operator --timeout=180s
fi

kubectl wait --for=condition=Ready nodes --all --timeout=120s

# 5. Configurar LoadBalancer IPPool basado en la red Docker 'kind'
if [[ "$INSTALL_CILIUM" == "S" && "$INSTALL_LB" == "S" ]]; then
  DOCKER_SUBNET="$(docker network inspect kind -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}' 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\./){print $i; exit}}')"
  PREFIX="$(echo "$DOCKER_SUBNET" | awk -F'.' '{print $1"."$2}')"
  DEFAULT_START="${PREFIX:-172.18}.255.200"
  DEFAULT_STOP="${PREFIX:-172.18}.255.240"

  echo ""
  echo "🌐 Subred Docker 'kind' detectada: ${DOCKER_SUBNET:-desconocida}"
  read -r -p "   IP inicial del Pool LoadBalancer [$DEFAULT_START]: " LB_START
  LB_START="${LB_START:-$DEFAULT_START}"
  read -r -p "   IP final del Pool LoadBalancer [$DEFAULT_STOP]: " LB_STOP
  LB_STOP="${LB_STOP:-$DEFAULT_STOP}"

  kubectl apply -f - <<EOF
apiVersion: cilium.io/v2
kind: CiliumLoadBalancerIPPool
metadata:
  name: kubecafe-docker-pool
spec:
  blocks:
    - start: "${LB_START}"
      stop: "${LB_STOP}"
---
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: kubecafe-l2-policy
spec:
  interfaces:
    - ^eth[0-9]+
  externalIPs: true
  loadBalancerIPs: true
EOF
  echo "✅ Pool LoadBalancer configurado: ${LB_START} - ${LB_STOP}"
fi

# 6. Instalar metrics-server (con --kubelet-insecure-tls para Kind)
if [[ "$INSTALL_METRICS" == "S" ]]; then
  echo ""
  echo "📊 Instalando metrics-server para Kind..."
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  kubectl -n kube-system patch deployment metrics-server --type='json' \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi

# 7. Instalar Headlamp (LoadBalancer si Cilium LB está activo, o NodePort)
if [[ "$INSTALL_HEADLAMP" == "S" ]]; then
  echo ""
  echo "🖥️  Instalando consola visual Headlamp..."
  helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/ >/dev/null 2>&1 || true
  helm repo update >/dev/null

  if [[ "$INSTALL_CILIUM" == "S" && "$INSTALL_LB" == "S" ]]; then
    HL_SVC_TYPE="LoadBalancer"
  else
    HL_SVC_TYPE="NodePort"
  fi

  helm upgrade --install headlamp headlamp/headlamp \
    --namespace kube-system \
    --set service.type="$HL_SVC_TYPE"

  if [[ "$HL_SVC_TYPE" == "LoadBalancer" ]]; then
    kubectl patch svc headlamp -n kube-system --type=json \
      -p='[{"op":"replace","path":"/spec/allocateLoadBalancerNodePorts","value":false},{"op":"remove","path":"/spec/ports/0/nodePort"}]' >/dev/null 2>&1 || true
  fi

  kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: headlamp-admin
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: headlamp
type: kubernetes.io/service-account-token
EOF

  kubectl -n kube-system rollout status deployment/headlamp --timeout=120s
fi

echo ""
echo "================================================================="
echo " 🎉 ¡Clúster '$CLUSTER_NAME' listo para KubeCafé!"
echo "================================================================="
kubectl get nodes -o wide

if [[ "$INSTALL_HEADLAMP" == "S" ]]; then
  echo ""
  echo "🖥️  Servicio de Headlamp en kube-system ($HL_SVC_TYPE):"
  if [[ "$HL_SVC_TYPE" == "LoadBalancer" ]]; then
    sleep 3
    kubectl get svc headlamp -n kube-system
    HL_IP="$(kubectl get svc headlamp -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
    echo "   🌐 URL LoadBalancer: http://${HL_IP:-<pendiente>}"
    if [[ "$(uname -s)" == "Darwin" ]]; then
      echo "   🍏 Tip macOS (Docker Desktop): para abrir http://${HL_IP:-172.18.255.200} directo en tu navegador:"
      echo "      brew install chipmk/tap/docker-mac-net-connect && sudo brew services restart chipmk/tap/docker-mac-net-connect"
    fi
  else
    kubectl get svc headlamp -n kube-system
    HL_PORT="$(kubectl get svc headlamp -n kube-system -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || true)"
    NODE_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || true)"
    echo "   🌐 URL NodePort (Linux): http://${NODE_IP:-<IP_NODO>}:${HL_PORT:-<PUERTO>}"
  fi
  echo "   📋 Comando para ver el servicio: kubectl get svc headlamp -n kube-system"
  echo "   🔌 Túnel universal (macOS/Windows/Linux): kubectl -n kube-system port-forward svc/headlamp 8080:80"
  echo "   🔑 Token de conexión:"
  echo ""
  kubectl get secret headlamp-admin -n kube-system -o jsonpath='{.data.token}' | base64 -d
  echo ""
fi
