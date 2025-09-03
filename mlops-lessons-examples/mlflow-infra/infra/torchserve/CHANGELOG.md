# TorchServe Helm Chart Changelog

## Version 0.1.0 - TorchServe 0.12.0+ Support

### 🚀 Updated for TorchServe 0.12.0+

#### ✨ New Features & Improvements

1. **Updated Command Line Arguments**
   - Changed from legacy argument format to TorchServe 0.12.0+ compatible arguments
   - Added `--model-store` argument for explicit model store path
   - Updated `--models` argument format to `--models=model_name=url`
   - Added `--foreground` flag for proper container execution
   - Added optional `--workflow-store` support

2. **Enhanced Configuration**
   - Added performance tuning options: `numberOfNettyThreads`, `jobQueueSize`, `asyncLogging`
   - Improved config.properties template with 0.12.0+ specific optimizations
   - Added support for new configuration options like `install_py_dep_per_model`

3. **Updated Image Version**
   - Default image tag updated to `0.12.0`
   - Chart appVersion updated to match TorchServe 0.12.0

4. **Kubernetes-Native Logging**
   - Configured TorchServe to log to stdout/stderr instead of log files
   - Added environment variables: `TS_LOG_STDOUT=true`, `LOG_LOCATION=""`, `METRICS_LOCATION=""`
   - Removed file-based logging to prevent permission errors in containerized environments
   - Follows 12-factor app principles for cloud-native applications

#### 🔧 Technical Changes

**Before (TorchServe < 0.12.0):**
```yaml
args:
  - "--start"
  - "--ts-config=/opt/torchserve/conf/config.properties"
  - "--model-config=/opt/torchserve/conf/model_config.yaml"
  - "--models"
  - "densenet161=https://example.com/model.mar"
```

**After (TorchServe 0.12.0+):**
```yaml
args:
  - "--start"
  - "--model-store=/home/model-server/model-store"
  - "--ts-config=/opt/torchserve/conf/config.properties"
  - "--models=densenet161=https://example.com/model.mar"
  - "--foreground"
```

#### 📝 Configuration Changes

**New config.properties optimizations:**
```properties
number_of_netty_threads=4
job_queue_size=100
async_logging=true
```

**New values.yaml options:**
```yaml
torchserve:
  config:
    numberOfNettyThreads: 4
    jobQueueSize: 100
    asyncLogging: true
```

#### 🛠 Migration Guide

If upgrading from an older version:

1. **Update image tag** in your values.yaml:
   ```yaml
   image:
     tag: "0.12.0"
   ```

2. **Review performance settings** and adjust if needed:
   ```yaml
   torchserve:
     config:
       numberOfNettyThreads: 4  # Adjust based on your CPU cores
       jobQueueSize: 100         # Adjust based on expected load
       asyncLogging: true        # Recommended for production
   ```

3. **Test your model deployments** to ensure compatibility with new argument format

#### 🔄 Backward Compatibility

- All existing configuration options are preserved
- Model configuration format remains the same
- Service endpoints and monitoring unchanged
- Storage and persistence configurations unchanged

#### 📋 Validation

To validate the upgrade:

```bash
# Check TorchServe version
kubectl exec deployment/torchserve -- torchserve --version

# Verify model loading
kubectl logs deployment/torchserve | grep "Model loaded successfully"

# Test inference endpoint
kubectl exec deployment/torchserve -- curl http://localhost:8080/ping

# Check logs are going to stdout (no file logging errors)
kubectl logs deployment/torchserve | grep -v "Could not create directory"
```

#### 🔧 Troubleshooting

**Fixed: Log Directory Permission Errors**
- **Problem**: `ERROR Unable to create file logs/access_log.log java.io.IOException: Could not create directory /serve/logs`
- **Solution**: Configured TorchServe to log to stdout instead of files
- **Verification**: Check that logs appear in `kubectl logs` without file creation errors

---

For more information about TorchServe 0.12.0 changes, see:
- [TorchServe Release Notes](https://github.com/pytorch/serve/releases)
- [TorchServe Configuration Documentation](https://pytorch.org/serve/configuration.html)
