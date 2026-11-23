# 🛡️ Política de Seguridad (`SECURITY.md`)

## Alcance del Repositorio

Este repositorio contiene material educativo, manifiestos de laboratorio, scripts de aprovisionamiento (`setup-lab.sh`), automatizaciones de GitHub Actions y aportes de estudiantes para el workshop **De Cero a Capitán en Kubernetes — Cloud Native Medellín (CNCF)**.

> ⚠️ **Importante para estudiantes:** Nunca subas credenciales reales, tokens, llaves SSH, archivos `.env` con secretos productivos ni datos personales sensibles en tus Pull Requests dentro de `aportes-comunidad/`. Los ejemplos de `Secrets` y `.env` del workshop son estrictamente ficticios para entornos locales de aprendizaje.

---

## Versiones Soportadas

| Rama / Entorno | Estado |
| :--- | :--- |
| `main` | ✅ Mantenida activamente |
| Forks desactualizados | ⚠️ Sincronizar con `upstream/main` |

---

## 🚨 ¿Cómo reportar una vulnerabilidad o exposición de secretos?

**Por favor, NO abras un Issue público** si detectas:
- Un secreto, token o credencial expuesta accidentalmente en el repositorio o en un historial de commits.
- Una vulnerabilidad en alguno de los workflows de GitHub Actions (`.github/workflows/`), scripts (`scripts/` o `setup-lab.sh`) o aplicaciones web estáticas (`recursos/*.html`).

En su lugar, repórtalo de forma privada mediante:

1. **GitHub Security Advisories (Recomendado):**  
   👉 [**Reportar una vulnerabilidad de forma privada**](https://github.com/edwinbermudez91/Fundamentos-Kubernetes/security/advisories/new)
2. **Contacto directo con el mantenedor:**  
   Si no puedes usar Security Advisories, contacta en privado a [`@edwinbermudez91`](https://www.linkedin.com/in/edwin-bermudez-cuervo) indicando los detalles para reproducirlo.

Nos comprometemos a revisar y responder los reportes de seguridad en el menor tiempo posible.
