#!/bin/sh
# Maven Wrapper script

MAVEN_VERSION=3.9.6
MAVEN_HOME="${MAVEN_HOME:-$HOME/.m2/wrapper/maven-$MAVEN_VERSION}"

if [ ! -d "$MAVEN_HOME" ]; then
    echo "Downloading Maven $MAVEN_VERSION..."
    mkdir -p "$MAVEN_HOME"
    curl -fsSL "https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -xzC "$MAVEN_HOME" --strip-components=1
fi

exec "$MAVEN_HOME/bin/mvn" "$@"