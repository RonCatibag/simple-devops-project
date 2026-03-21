# patchable
FROM jenkins/jenkins:2.549-jdk21

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dio.jenkins.plugins.artifact_manager_jclouds.s3.S3BlobStoreConfig.deleteArtifacts=true -Dio.jenkins.plugins.artifact_manager_jclouds.s3.S3BlobStoreConfig.deleteStashes=true -Dhudson.model.DirectoryBrowserSupport.CSP=\"default-src 'self'; style-src 'self' 'unsafe-inline' https://stackpath.bootstrapcdn.com/ https://cdnjs.cloudflare.com/ajax/libs/font-awesome/ https://cdnjs.cloudflare.com/ajax/libs/highlight.js/ https://cdn.datatables.net/v/bs4/; script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com/ajax/libs/jquery/ https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/ https://cdn.datatables.net/v/bs4/ https://cdnjs.cloudflare.com/ajax/libs/clipboard.js/ https://cdnjs.cloudflare.com/ajax/libs/remarkable/ https://cdnjs.cloudflare.com/ajax/libs/highlight.js/; font-src 'self' data: https://cdnjs.cloudflare.com/ajax/libs/font-awesome/;\""

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt -w /usr/share/jenkins/jenkins.war --verbose --latest false # set latest to false in case there's an issue on the plugins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt -w /usr/share/jenkins/jenkins.war --verbose