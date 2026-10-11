# ---- build ----
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B -DskipTests package

# ---- run ----
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN useradd --system --no-create-home gym
COPY --from=build /app/target/*.jar app.jar
USER gym
EXPOSE 8080
ENV THYMELEAF_CACHE=true
ENTRYPOINT ["java","-jar","/app/app.jar"]
