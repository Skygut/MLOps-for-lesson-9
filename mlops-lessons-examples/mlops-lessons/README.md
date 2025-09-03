# mlops-lessons


## container with model

```
cd model-docker-example/
docker build -t image-classifier-model .
```

view docs
```
curl http://localhost:8000/docs
```

## mutlistage

build
```
docker build -t ml-inference-app .
```
run
```
docker run -p 8000:8000 ml-inference-app
```