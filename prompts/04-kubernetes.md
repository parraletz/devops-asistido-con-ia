# Demo 4 · Endurecer un manifiesto de Kubernetes

**Archivo:** `demos/04-kubernetes/deployment.antes.yaml` → resultado esperado parecido a `deployment.yaml`

## Prompt
```
Revisa demos/04-kubernetes/deployment.antes.yaml para producción.
La app expone /health/live y /health/ready en el puerto 3000, usa ~80Mi de memoria
y corre como el usuario node (uid 1000). Agrega:
- tag de imagen fijo, 2 réplicas, rolling update sin indisponibilidad
- requests/limits razonables, liveness y readiness probes
- securityContext restrictivo (no root, sin escalamiento, rootfs de solo lectura)
- un Service ClusterIP
Explica cualquier valor que elijas y dime cuáles debo ajustar con métricas reales.
```

## Cluster local con kind
```bash
kind create cluster --name curso
docker build -t catalogo-api:1.0.0 app
kind load docker-image catalogo-api:1.0.0 --name curso     # kind no descarga de un registry: se carga la imagen local
kubectl config use-context kind-curso
# Clusters como Talos avisan con Pod Security "restricted" por defecto; en kind se activa así:
kubectl label ns default pod-security.kubernetes.io/warn=restricted
```

## Validación humana
```bash
# 1. Sin cluster: validación de esquema
docker run --rm -i ghcr.io/yannh/kubeconform:v0.6.7 -strict -summary - < demos/04-kubernetes/deployment.yaml

# 2. Contra el cluster, sin cambiar nada: el API server aplica admission y Pod Security
kubectl apply --dry-run=server -f demos/04-kubernetes/deployment.antes.yaml
#   → Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation, capabilities,
#     runAsNonRoot, seccompProfile
kubectl apply --dry-run=server -f demos/04-kubernetes/deployment.yaml          # sin warnings

# 3. Simular el caso real: el "antes" ya está desplegado y queremos aplicar el "después"
kubectl apply -f demos/04-kubernetes/deployment.antes.yaml
kubectl diff  -f demos/04-kubernetes/deployment.yaml
#   → The Deployment "catalogo-api" is invalid: spec.selector: ... field is immutable

# 4. Desplegar el "después" (en un cluster de práctica: recrear el Deployment)
kubectl delete deployment catalogo-api        # el hook/permisos lo bloquean si lo pide la IA: lo ejecuta una persona
kubectl apply -f demos/04-kubernetes/deployment.yaml
kubectl rollout status deploy/catalogo-api
kubectl port-forward svc/catalogo-api 8080:80 & curl -s localhost:8080/health/ready

# Alternativa: usar la imagen publicada por el CI (multi-arquitectura: amd64 + arm64)
kubectl set image deploy/catalogo-api api=ghcr.io/parraletz/catalogo-api:1.0.0

# Limpieza
kind delete cluster --name curso
```

**Puntos a remarcar:**
- Los `requests/limits` que propone la IA son una suposición. Los números reales salen de tus métricas (en el incidente de la demo 6 veremos por qué importan).
- **El selector de un Deployment es inmutable.** La IA cambió `app` por `app.kubernetes.io/name` (buena práctica), pero no avisó que eso impide aplicar el cambio sobre un Deployment existente. `kubeconform` no lo detecta; `kubectl diff` contra el cluster real, sí. En producción hay que planear el cambio (Deployment nuevo + mover el tráfico del Service, o conservar el selector viejo).
- **kubeconform valida el esquema; el API server valida las políticas.** El "antes" es YAML válido, pero el cluster avisa que viola Pod Security `restricted`. El "después" pasa limpio.
- El `securityContext` restrictivo funciona: los pods arrancan como uid 1000 con rootfs de solo lectura porque la app no escribe a disco. Si tu app escribe, necesitas un `emptyDir` para esa ruta.
