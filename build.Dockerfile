# build.Dockerfile
# Alternatívny build kontajner (Maven build).
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

# Stiahnutie Maven
ENV MAVEN_VERSION=3.9.6
RUN wget -q https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz && \
    tar -xzf apache-maven-3.9.6-bin.tar.gz -C /opt && \
    mv /opt/apache-maven-3.9.6 /opt/maven && \
    rm apache-maven-3.9.6-bin.tar.gz

ENV PATH=$PATH:/opt/maven/bin

# Nastavenie pracovného adresára
WORKDIR /app

# Kopírovanie projektu
COPY . .

# Spustenie buildu
CMD ["mvn", "clean", "package", "-q"]
