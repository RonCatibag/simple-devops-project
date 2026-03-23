import groovy.yaml.YamlSlurper

def jobMapDir = new File("${WORKSPACE}/jenkins-job-dsl-seed/jenksins-job-map")

jobMapDir.eachFileMatch(~/.+\.yaml$/) { file ->
    def yaml = new YamlSlurper().parse(file)
    def projects = yaml.projects ?: []

    projects.each { project ->
        def jobName    = project.name
        def repoUrl    = project.repo
        def branch     = project.branch ?: 'main'
        def jenkinsfilePath = project.jenkinsfile ?: 'Jenkinsfile'
        def agentLabel = project.agent_label ?: 'docker-agent'
        def cronTrigger = project.cron ?: ''
        def pollScm     = project.poll_scm ?: ''
        def description = project.description ?: "Auto-generated job for ${jobName}"
        def folder      = project.folder ?: ''

        if (folder) {
            this.folder(folder) {
                displayName(folder.capitalize())
            }
        }

        def fullJobName = folder ? "${folder}/${jobName}" : jobName

        pipelineJob(fullJobName) {
            this.description(description)

            if (project.parameters) {
                parameters {
                    project.parameters.each { param ->
                        stringParam(param.name, param.default_value ?: '', param.description ?: '')
                    }
                }
            }

            definition {
                cpsScm {
                    scm {
                        git {
                            remote {
                                url(repoUrl)
                                credentials('jenkins-github-user')
                            }
                            branches("*/${branch}")
                        }
                    }
                    scriptPath(jenkinsfilePath)
                    lightweight(true)
                }
            }

            triggers {
                if (project.github_push != false) {
                    githubPush()
                }
                if (cronTrigger) {
                    cron(cronTrigger)
                }
                if (pollScm) {
                    scm(pollScm)
                }
            }

            properties {
                disableConcurrentBuilds()
                buildDiscarder {
                    strategy {
                        logRotator {
                            numToKeepStr('10')
                            artifactNumToKeepStr('5')
                        }
                    }
                }
            }

            logRotator {
                numToKeep(10)
                artifactNumToKeep(5)
            }
        }
    }
}
