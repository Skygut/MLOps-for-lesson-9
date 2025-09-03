# Dockerfile для прикладу CMD
FROM alpine:latest
WORKDIR /app
COPY mlops.sh .
# Додаємо права на виконання
RUN chmod +x mlops.sh
# CMD в формі exec
CMD ["./mlops.sh", "from", "CMD"]