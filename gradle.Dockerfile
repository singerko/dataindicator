# gradle.Dockerfile
# Kontajner pre Android build s Gradle a Android SDK.
FROM openjdk:17-jdk-slim

# Nastavenie prostredia
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# Inštalácia závislostí
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Stiahnutie Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm cmdline-tools.zip

# Inštalácia Android SDK komponentov
RUN yes | sdkmanager --licenses > /dev/null 2>&1 && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null 2>&1

# Stiahnutie Gradle
RUN wget -q https://services.gradle.org/distributions/gradle-8.5-bin.zip && \
    unzip -q gradle-8.5-bin.zip -d /opt && \
    mv /opt/gradle-8.5 /opt/gradle && \
    rm gradle-8.5-bin.zip

ENV PATH=$PATH:/opt/gradle/bin

# Nastavenie pracovného adresára
WORKDIR /app

# Kopírovanie projektu
COPY . .

# Spustenie buildu s zipalign a optimalizáciami
CMD ["sh", "-c", "gradle :app:assembleRelease --no-daemon --max-workers=4 && echo 'APK built and zipaligned successfully'"]
