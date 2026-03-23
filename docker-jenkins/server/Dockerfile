# patchable
FROM jenkins/jenkins:2.549-jdk21

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dio.jenkins.plugins.artifact_manager_jclouds.s3.S3BlobStoreConfig.deleteArtifacts=true -Dio.jenkins.plugins.artifact_manager_jclouds.s3.S3BlobStoreConfig.deleteStashes=true -Dhudson.model.DirectoryBrowserSupport.CSP=\"default-src 'self'; style-src 'self' 'unsafe-inline' https://stackpath.bootstrapcdn.com/ https://cdnjs.cloudflare.com/ajax/libs/font-awesome/ https://cdnjs.cloudflare.com/ajax/libs/highlight.js/ https://cdn.datatables.net/v/bs4/; script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com/ajax/libs/jquery/ https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/ https://cdn.datatables.net/v/bs4/ https://cdnjs.cloudflare.com/ajax/libs/clipboard.js/ https://cdnjs.cloudflare.com/ajax/libs/remarkable/ https://cdnjs.cloudflare.com/ajax/libs/highlight.js/; font-src 'self' data: https://cdnjs.cloudflare.com/ajax/libs/font-awesome/;\""

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg lsb-release && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y --no-install-recommends \
        docker-ce-cli docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*
USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt -w /usr/share/jenkins/jenkins.war --verbose