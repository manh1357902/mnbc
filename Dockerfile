FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
RUN chmod +x mvnw
RUN ./mvnw install -DskipTests

FROM alpine:3.18

# Cài Java + MySQL + bash
RUN apk update && apk add --no-cache openjdk17 mysql mysql-client bash

ENV MYSQL_DATABASE=demo \
    MYSQL_ROOT_PASSWORD=root \
    MYSQL_USER=user \
    MYSQL_PASSWORD=password

WORKDIR /app
COPY --from=build /workspace/app/target/*.jar app.jar

# Tạo init.sql
RUN echo 'CREATE DATABASE IF NOT EXISTS demo;' > /app/init.sql && \
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';" >> /app/init.sql && \
    echo "GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;" >> /app/init.sql && \
    echo "CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY 'password';" >> /app/init.sql && \
    echo "GRANT ALL ON demo.* TO 'user'@'%';" >> /app/init.sql && \
    echo "FLUSH PRIVILEGES;" >> /app/init.sql

# Tạo start.sh
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'echo "Initializing MySQL..."' >> /app/start.sh && \
    echo 'mkdir -p /run/mysqld' >> /app/start.sh && \
    echo 'chown -R mysql:mysql /run/mysqld' >> /app/start.sh && \
    echo 'mysql_install_db --user=mysql --datadir=/var/lib/mysql' >> /app/start.sh && \
    echo 'mysqld --user=mysql --init-file=/app/init.sql &' >> /app/start.sh && \
    echo 'echo "Waiting for MySQL..."' >> /app/start.sh && \
    echo 'sleep 10' >> /app/start.sh && \
    echo 'echo "Starting Spring Boot..."' >> /app/start.sh && \
    echo 'java -jar /app/app.jar' >> /app/start.sh && \
    chmod +x /app/start.sh

RUN chmod +x /app/start.sh

EXPOSE 8080
ENTRYPOINT ["/bin/sh", "/app/start.sh"]
