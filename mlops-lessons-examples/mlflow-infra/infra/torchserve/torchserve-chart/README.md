# TorchServe Helm Chart

This Helm chart deploys TorchServe, PyTorch's model serving framework, on a Kubernetes cluster.

## Features

- **Model Serving**: Deploy and serve PyTorch models with REST and gRPC APIs
- **Auto-scaling**: Horizontal Pod Autoscaler support based on CPU/memory metrics
- **Monitoring**: Prometheus metrics and ServiceMonitor integration
- **Storage**: Persistent storage for models and workflows
- **Security**: Pod security contexts, network policies, and RBAC
- **High Availability**: Pod disruption budgets and multiple replicas
- **Configuration**: Flexible TorchServe configuration via ConfigMaps

## Quick Start

### Install with default values:

```bash
helm install torchserve . -n ml-inference --create-namespace
```

### Install with custom models:

```bash
helm install torchserve . -n ml-inference \
  --set torchserve.models.densenet161.url="https://torchserve.pytorch.org/mar_files/densenet161.mar" \
  --set torchserve.models.densenet161.initialWorkers=2
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of TorchServe replicas | `1` |
| `image.repository` | TorchServe image repository | `pytorch/torchserve` |
| `image.tag` | TorchServe image tag | `0.8.2` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### TorchServe Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `torchserve.config.inferencePort` | Inference API port | `8080` |
| `torchserve.config.managementPort` | Management API port | `8081` |
| `torchserve.config.metricsPort` | Metrics API port | `8082` |
| `torchserve.config.modelStore` | Model store path | `/home/model-server/model-store` |
| `torchserve.config.defaultWorkersPerModel` | Default workers per model | `1` |
| `torchserve.config.maxWorkers` | Maximum workers | `4` |

### Model Configuration

Configure models to be automatically loaded:

```yaml
torchserve:
  models:
    densenet161:
      url: "https://torchserve.pytorch.org/mar_files/densenet161.mar"
      initialWorkers: 2
      batchSize: 4
      maxBatchDelay: 100
      responseTimeout: 120
    resnet18:
      url: "https://torchserve.pytorch.org/mar_files/resnet-18.mar"
      initialWorkers: 1
```

### Persistence

Enable persistent storage for models:

```yaml
persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 20Gi
  accessMode: ReadWriteOnce
```

### Ingress

Enable ingress for external access:

```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: torchserve.example.com
      paths:
        - path: /
          pathType: Prefix
          service: inference
        - path: /management
          pathType: Prefix
          service: management
  tls:
    - secretName: torchserve-tls
      hosts:
        - torchserve.example.com
```

### Monitoring

Enable Prometheus monitoring:

```yaml
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    labels:
      release: prometheus-operator
```

### Auto-scaling

Enable horizontal pod autoscaling:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

## API Endpoints

Once deployed, TorchServe exposes the following endpoints:

- **Inference API**: `http://<service>:8080`
  - `GET /ping` - Health check
  - `POST /predictions/<model_name>` - Model inference
  - `GET /models` - List loaded models

- **Management API**: `http://<service>:8081`
  - `GET /models` - List all models
  - `POST /models` - Register a model
  - `DELETE /models/<model_name>` - Unregister a model
  - `PUT /models/<model_name>` - Update model configuration

- **Metrics API**: `http://<service>:8082`
  - `GET /metrics` - Prometheus metrics

## Examples

### Deploy with DenseNet model:

```bash
helm install torchserve . \
  --set torchserve.models.densenet161.url="https://torchserve.pytorch.org/mar_files/densenet161.mar" \
  --set persistence.enabled=true \
  --set metrics.serviceMonitor.enabled=true
```

### Test inference:

```bash
# Port forward to access locally
kubectl port-forward svc/torchserve 8080:8080

# Test health
curl http://localhost:8080/ping

# List models
curl http://localhost:8080/models

# Make inference (example with image)
curl -X POST http://localhost:8080/predictions/densenet161 -T image.jpg
```

## Security

This chart implements several security best practices:

- Non-root user execution
- Read-only root filesystem (where possible)
- Security contexts with minimal privileges
- Network policies for traffic control
- RBAC with minimal required permissions

## Troubleshooting

### Common Issues

1. **Models not loading**: Check the model URLs and ensure they're accessible
2. **Persistence issues**: Verify storage class exists and has sufficient space
3. **Memory errors**: Increase resource limits or reduce batch sizes
4. **Network issues**: Check network policies and service configurations

### Useful Commands

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=torchserve

# View logs
kubectl logs -l app.kubernetes.io/name=torchserve

# Check model status
kubectl exec <pod-name> -- curl localhost:8081/models

# Port forward for local testing
kubectl port-forward svc/torchserve 8080:8080
```

## License

This chart is licensed under the Apache 2.0 License.
