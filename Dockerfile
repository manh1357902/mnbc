# ---------- Build Spring Boot app ----------
FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

RUN chmod +x mvnw
RUN ./mvnw install -DskipTests

# ---------- Final image ----------
FROM alpine:3.18

# Install OpenJDK, MySQL, bash
RUN apk update && \
    apk add --no-cache openjdk17 mysql mysql-client bash

# Environment variables for MySQL
ENV MYSQL_DATABASE=demo \
    MYSQL_ROOT_PASSWORD=root \
    MYSQL_USER=user \
    MYSQL_PASSWORD=password

WORKDIR /app

# Copy app jar
COPY --from=build /workspace/app/target/*.jar app.jar

# Create MySQL init script
RUN echo "\
CREATE DATABASE IF NOT EXISTS demo;\n\
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';\n\
GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;\n\
CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY 'password';\n\
GRANT ALL ON demo.* TO 'user'@'%';\n\
FLUSH PRIVILEGES;\n\
" > /app/init.sql

# Create startup script
RUN echo "\
#!/bin/sh\n\
echo 'Initializing MySQL...'\n\
mkdir -p /run/mysqld\n\
chown -R mysql:mysql /run/mysqld\n\
mysql_install_db --user=mysql --datadir=/var/lib/mysql\n\
mysqld --user=mysql --init-file=/app/init.sql &\n\
echo 'Waiting for MySQL to start...'\n\
sleep 10\n\
echo 'Starting Spring Boot app...'\n\
java -jar /app/app.jar\n\
" > /app/start.sh && chmod +x /app/start.sh

EXPOSE 8080 3306
CMD ["/app/start.sh"]
