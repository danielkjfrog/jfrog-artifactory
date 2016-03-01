#!/usr/bin/env bash

DB_PROPERTIES=${ARTIFACTORY_HOME}/misc/db/${DB_TYPE}.properties
STORAGE_FILE=${ARTIFACTORY_HOME}/etc/storage.properties
TOMCAT_LIB=${ARTIFACTORY_HOME}/tomcat/lib
CONNECTOR_DOWNLOAD_URL=http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz
CONNECTOR_FOLDER=`basename ${CONNECTOR_DOWNLOAD_URL} .tar.gz`

downloadAndInstallArtifactory(){
    echo "Downloading Artifactory version: ${ARTIFACTORY_VERSION}..."
    curl -u${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD} -o /tmp/jfrog-artifactory-pro-${ARTIFACTORY_VERSION}.deb \
    https://repo.artifactoryonline.com/artifactory/libs-releases-local/org/artifactory/pro/deb/jfrog-artifactory-pro/${ARTIFACTORY_VERSION}/jfrog-artifactory-pro-${ARTIFACTORY_VERSION}.deb
    echo "Installing Artifactory version: ${ARTIFACTORY_VERSION}..."
    dpkg -i /tmp/jfrog-artifactory-pro-${ARTIFACTORY_VERSION}.deb
}

downloadAndPlaceConnectors(){
    echo "Placing Connectors in TOMCAT folder..."
    echo "Downloading MySQL Connector..."
    curl -L -o /tmp/${CONNECTOR_FOLDER}.tar.gz ${CONNECTOR_DOWNLOAD_URL}
    tar xvzf /tmp/${CONNECTOR_FOLDER}.tar.gz -C /tmp/
    cp /tmp/${CONNECTOR_FOLDER}/${CONNECTOR_FOLDER}-bin.jar ${TOMCAT_LIB}
    echo "Downloading Oracle Connector..."
    curl -u${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD} -o \
    ${TOMCAT_LIB}/ojdbc6.jar https://repo.artifactoryonline.com/artifactory/jcenter-cache/com/oracle/ojdbc6/11.2.0.3/ojdbc6-11.2.0.3.jar
    echo "Downloading Postgres Connector..."
    curl -u${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD} -o \
    ${TOMCAT_LIB}/postgresql-9.2-1002.jdbc4.jar \
    https://repo.artifactoryonline.com/artifactory/jfrog-libs-cache/postgresql/postgresql/9.2-1002.jdbc4/postgresql-9.2-1002.jdbc4.jar
}

prepareStorageProperties(){
    if [ -v DB_TYPE ]; then
        echo "Creating storage.properties to ${DB_TYPE}..."
        sed s/localhost/${DB_TYPE}_db_container/ < ${DB_PROPERTIES} > ${STORAGE_FILE}
        if [ "$DB_TYPE" == "oracle" ]; then
            echo "Oracle database detected. Adjusting SID (xe) in connector..."
            sed -i 's/ORCL/xe/g' ${STORAGE_FILE}
        fi
    fi
}

provideLicense(){
    echo "Saving Artifactory License..."
    curl -o ${ARTIFACTORY_HOME}/etc/artifactory.lic -u${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD} ${LIC_URL}
}

startArtifactory(){
    echo "Starting Artifactory as a service..."
    service artifactory wait
}

if [ -v ARTIFACTORY_USER ] && [ -v ARTIFACTORY_PASSWORD ] && [ -v ARTIFACTORY_VERSION ]; then
    downloadAndInstallArtifactory
    downloadAndPlaceConnectors
    prepareStorageProperties
    if [ -v LIC_URL ]; then
        provideLicense
        startArtifactory
    else
        echo "License URL (LIC_URL) must to be set for using Artifactory Pro."
        exit 1
    fi
else
    echo "Make sure you provided ALL ENVIRONMENT VARIABLES: ARTIFACTORY_USER, ARTIFACTORY_PASSWORD, ARTIFACTORY_VERSION."
    exit 1
fi