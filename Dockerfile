# ============================================================
# STAGE 1: Build the application (Maven)
# ============================================================
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Set working directory
WORKDIR /app

# Copy only the pom.xml first (cache dependencies)
COPY pom.xml .

# Pre-download all dependencies
RUN mvn -B -q dependency:go-offline

# Copy application source
COPY src ./src

# Build application
RUN mvn -B -q package -DskipTests


# ============================================================
# STAGE 2: Runtime (Small, secure)
# ============================================================
FROM eclipse-temurin:17-jre-alpine AS runtime
# ✔ Alternative (even smaller): gcr.io/distroless/java17

WORKDIR /app

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring

# Copy JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Set non-root user
USER spring

# JVM & container optimization
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75"

EXPOSE 4321

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]