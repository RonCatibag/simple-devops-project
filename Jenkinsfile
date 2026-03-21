pipeline {
    agent any

    environment {
        APP_IMAGE   = 'node-js-sample'
        APP_CONTAINER = 'node-app'
        APP_PORT    = '5000'
        REPO_URL    = 'https://github.com/heroku/node-js-sample.git'
    }

    stages {
        stage('Clone') {
            steps {
                git branch: 'main', url: "${REPO_URL}"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    writeFile file: 'Dockerfile', text: """\
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --production
COPY . .
EXPOSE ${APP_PORT}
CMD ["npm", "start"]
"""
                    sh "docker build -t ${APP_IMAGE}:latest ."
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh """
                        docker stop ${APP_CONTAINER} || true
                        docker rm   ${APP_CONTAINER} || true
                        docker run -d \
                            --name ${APP_CONTAINER} \
                            --network ci-net \
                            --restart unless-stopped \
                            -p ${APP_PORT}:${APP_PORT} \
                            ${APP_IMAGE}:latest
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sh """
                    sleep 5
                    curl -f http://${APP_CONTAINER}:${APP_PORT}/ || \
                    curl -f http://localhost:${APP_PORT}/
                """
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed — app deployed successfully.'
        }
        failure {
            echo 'Pipeline failed — check the logs above.'
        }
    }
}
