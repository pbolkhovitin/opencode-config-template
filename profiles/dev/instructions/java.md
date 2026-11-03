# Java Instructions

## Toolchain
- JDK: managed via sdkman (`sdk list java`)
- Build tool: Maven (pom.xml) or Gradle (build.gradle/build.gradle.kts)
- Test: JUnit 5 + Mockito

## Commands (Maven)
- Build: `mvn clean compile`
- Test: `mvn test`
- Package: `mvn package`
- Lint: `mvn checkstyle:check`
- Run: `mvn exec:java -Dexec.mainClass="com.example.Main"`

## Commands (Gradle)
- Build: `gradle build`
- Test: `gradle test`
- Lint: `gradle check`
- Run: `gradle run`

## Conventions
- Package naming: `com.<company>.<project>.<module>`
- Fields: private, use Lombok for getters/setters/constructors
- Stream API preferred over loops where readable
- Use records for immutable DTOs (Java 16+)
- Always close resources via try-with-resources

## Verify
```bash
java --version && mvn --version && sdk version
```
