#!/usr/bin/env bash
set -euo pipefail

# Verificador local de retos antes de abrir un Pull Request
# Uso: ./scripts/verificar-reto.sh <tu-usuario-github> [semana-XX]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -lt 1 ]]; then
  echo "Uso: ./scripts/verificar-reto.sh <tu-usuario-github> [semana-XX]"
  echo "Ejemplo: ./scripts/verificar-reto.sh Arlex0296"
  echo "Ejemplo: ./scripts/verificar-reto.sh Arlex0296 semana-02"
  exit 1
fi

GH_USER="$1"
FILTER_WEEK="${2:-}"
USER_DIR="aportes-comunidad/soluciones-retos/${GH_USER}"

echo "============================================================"
echo "🧪 Verificador Local de Retos — @${GH_USER}"
echo "============================================================"

# 1. Verificar archivos modificados fuera de la carpeta del estudiante
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  LOWER_PREFIX="aportes-comunidad/soluciones-retos/$(echo "$GH_USER" | tr '[:upper:]' '[:lower:]')/"
  PROTECTED_CHANGES=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    file="${line:3}"
    file_lower="$(echo "$file" | tr '[:upper:]' '[:lower:]')"
    if [[ "$file_lower" != "$LOWER_PREFIX"* ]]; then
      PROTECTED_CHANGES+=("$file")
    fi
  done < <(git status --porcelain)

  if [[ ${#PROTECTED_CHANGES[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Archivos modificados fuera de tu carpeta (${USER_DIR}/):"
    for f in "${PROTECTED_CHANGES[@]}"; do
      echo "   ❌ $f"
    done
    echo "   💡 Antes de hacer PR, asegúrate de no incluir cambios en archivos protegidos."
  else
    echo "✅ Archivos locales: sin cambios fuera de ${USER_DIR}/"
  fi
fi

# 2. Verificar que exista la carpeta del estudiante
if [[ ! -d "$USER_DIR" ]]; then
  echo ""
  echo "❌ No existe la carpeta '${USER_DIR}'."
  echo "   Crea tus soluciones dentro de '${USER_DIR}/semana-XX/' antes de verificar."
  exit 1
fi

# 3. Validar sintaxis YAML en la carpeta del estudiante
echo ""
echo "🔍 Validando sintaxis YAML en ${USER_DIR}..."
YAML_ERRORS=0
while IFS= read -r -d '' yml; do
  if command -v yamllint >/dev/null 2>&1; then
    if ! yamllint -d "{extends: relaxed, rules: {line-length: disable}}" "$yml" >/dev/null 2>&1; then
      echo "   ❌ Error YAML (yamllint): $yml"
      yamllint -d "{extends: relaxed, rules: {line-length: disable}}" "$yml" || true
      YAML_ERRORS=$((YAML_ERRORS + 1))
    fi
  elif command -v ruby >/dev/null 2>&1; then
    if ! ruby -ryaml -e "YAML.load_stream(File.read('$yml'))" >/dev/null 2>&1; then
      echo "   ❌ Error de sintaxis YAML: $yml"
      YAML_ERRORS=$((YAML_ERRORS + 1))
    fi
  elif command -v python3 >/dev/null 2>&1; then
    if ! python3 -c "import yaml, sys; list(yaml.safe_load_all(open(sys.argv[1])))" "$yml" >/dev/null 2>&1; then
      echo "   ❌ Error de sintaxis YAML: $yml"
      YAML_ERRORS=$((YAML_ERRORS + 1))
    fi
  fi
done < <(find "$USER_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0)

if [[ $YAML_ERRORS -eq 0 ]]; then
  echo "✅ Sintaxis YAML válida en todos tus manifiestos."
else
  echo "❌ Se encontraron ${YAML_ERRORS} archivo(s) YAML con errores."
fi

# 4. Evaluar retos con el validador oficial de scripts/generar-asistentes.js
if ! command -v node >/dev/null 2>&1; then
  echo ""
  echo "⚠️  Node.js no está instalado; se omitió la evaluación automática de retos."
  exit $YAML_ERRORS
fi

echo ""
echo "📊 Evaluando soluciones con el validador oficial del repositorio..."
NODE_EXIT=0
node - "$GH_USER" "$FILTER_WEEK" <<'EOF' || NODE_EXIT=$?
const {
  CHALLENGE_VALIDATORS,
  discoverOfficialChallenges,
  evaluateUserProgress
} = require('./scripts/generar-asistentes.js');

const user = process.argv[2];
const filterWeek = (process.argv[3] || '').toLowerCase();
const official = discoverOfficialChallenges();
const result = evaluateUserProgress(user, official);

const weeks = (result.detailedReport || []).filter(r =>
  filterWeek ? r.weekKey === filterWeek : (r.solvedCount > 0 || r.hasBitacora || r.totalExpected > 0)
);

let hasFailure = false;
for (const r of weeks) {
  const validators = CHALLENGE_VALIDATORS[r.weekKey];
  if (!validators && !r.hasBitacora && r.solvedCount === 0) continue;
  const icon = r.isComplete ? '✅' : '⏳';
  const bitacoraTxt = r.hasBitacora ? ' • 📔 Bitácora OK' : '';
  console.log(`\n📂 ${r.weekKey} (${r.solvedCount}/${r.totalExpected} ${icon}${bitacoraTxt})`);
  if (validators) {
    for (const v of validators) {
      const ok = r.solvedNums.includes(v.id);
      if (!ok && r.solvedCount > 0) hasFailure = true;
      console.log(`   ${ok ? '✅ OK  ' : '❌ FAIL'}  ${v.name}`);
    }
  }
}

console.log(`\n🏆 Resumen estimado: ${result.points} XP (${result.rango})`);
if (hasFailure) {
  process.exitCode = 2;
}
EOF

echo ""
if [[ $YAML_ERRORS -eq 0 && $NODE_EXIT -eq 0 ]]; then
  echo "🎉 ¡Todo listo! Ya puedes hacer commit y abrir tu Pull Request."
else
  echo "💡 Revisa los puntos marcados con ❌ antes de abrir tu Pull Request."
  exit 1
fi
