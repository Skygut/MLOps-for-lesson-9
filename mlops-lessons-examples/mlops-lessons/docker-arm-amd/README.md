## Building images on MacOS M-series

* building image on mac os
    * starting podman 
    ```
    podman machine init && podman machine start
    ```
    * building docker image
    ```
    podman build -t dimilov/mlops:linux-arm -f Dockerfile
    STEP 1/5: FROM alpine:latest
    STEP 2/5: WORKDIR /app
    --> Using cache f7ca365e4cf49a38439ba4f4f8feae9b324d430ec43adc0e75db0f8d4e4c935e
    --> f7ca365e4cf4
    STEP 3/5: COPY mlops.sh .
    --> Using cache 5b6d7edf9b41d4fc32bf1196fb82c239797737bbf3356e77f3342ab10f3e2adc
    --> 5b6d7edf9b41
    STEP 4/5: RUN chmod +x mlops.sh
    --> Using cache 5e57b2f5fcf92e5e0c5b7d574454a8832ec7761596ea4ba96b8e84795d8d3cb6
    --> 5e57b2f5fcf9
    STEP 5/5: CMD ["./mlops.sh", "from", "CMD"]
    --> Using cache 706a48abcedba62ad8cf248106413adbd989c9b369d33e17c67b7aab361874e9
    COMMIT dimilov/mlops:linux-arm
    --> 706a48abcedb
    Successfully tagged localhost/dimilov/mlops:linux-arm
    706a48abcedba62ad8cf248106413adbd989c9b369d33e17c67b7aab361874e9
    ```
    * pushing to registry:
    ```
    podman push dimilov/mlops:linux-arm
    ```
* using arm macos image on linux
    * pulling image
    ```
    docker pull dimilov/mlops:linux-arm
    ```
    * starting container
    ```
    docker run -it dimilov/mlops:linux-arm sh
    WARNING: The requested image's platform (linux/arm64/v8) does not match the detected host platform (linux/amd64/v3) and no specific platform was requested
    ```
* building image on mac os with linux/amd64 support
    * building image with option `--platform linux/amd64`
    ```
    podman build --platform linux/amd64 -t dimilov/mlops:latest-amd64 -f Dockerfile                 
    STEP 1/5: FROM alpine:latest
    Resolved "alpine" as an alias (/etc/containers/registries.conf.d/000-shortnames.conf)
    Trying to pull docker.io/library/alpine:latest...
    Getting image source signatures
    Copying blob sha256:9824c27679d3b27c5e1cb00a73adb6f4f8d556994111c12db3c5d61a0c843df8
    Copying config sha256:9234e8fb04c47cfe0f49931e4ac7eb76fa904e33b7f8576aec0501c085f02516
    Writing manifest to image destination
    STEP 2/5: WORKDIR /app
    --> 5c5380bbb066
    STEP 3/5: COPY mlops.sh .
    --> 8252e13eba0b
    STEP 4/5: RUN chmod +x mlops.sh
    --> 22083419917a
    STEP 5/5: CMD ["./mlops.sh", "from", "CMD"]
    COMMIT dimilov/mlops:latest-amd64
    --> 6904682ac714
    Successfully tagged localhost/dimilov/mlops:latest-amd64
    6904682ac714e77b943122c2806729085c864236448f4f2dcdb74fce027a453f
    ```
    * pushing to registry
    ```
    podman push dimilov/mlops:latest-amd64
    ```
* using arm macos image on linux created with `--platform linux/amd64` option
    * pulling image
    ```
    docker pull dimilov/mlops:latest-amd64
    ```
    * starting container
    ```
    docker run -it dimilov/mlops:latest-amd64 sh
    /app #
    ```
!! Important note: after building image with flag `--platform linux/amd64` all further builds will be created with linux/amd64, to switch back to linux/arm use `--platform linux/arm`


