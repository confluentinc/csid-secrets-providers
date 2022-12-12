#!/usr/bin/env groovy

def config = jobConfig {
    slackChannel = '#csid-build'
    nodeLabel = 'docker-debian-jdk17'
    runMergeCheck = false
    downStreamValidate = false
    extraBuildArgs = ''
    extraDeployArgs = ''
    mavenBuildGoals = 'clean verify install dependency:analyze validate'
    mavenFlags = '-U -Dmaven.wagon.http.retryHandler.count=10 --batch-mode'
}

def javaOptions = ""
def isConnector = false
def job = {
    def maven_command = sh(script: """if test -f "${env.WORKSPACE}/mvnw"; then echo "${env.WORKSPACE}/mvnw"; else echo "mvn"; fi""", returnStdout: true).trim()
    def returnAfterBuild = false

    stage('Build') {
        archiveArtifacts artifacts: 'pom.xml'
        withVaultEnv([["artifactory/tools_jenkins", "user", "TOOLS_ARTIFACTORY_USER"],
            ["artifactory/tools_jenkins", "password", "TOOLS_ARTIFACTORY_PASSWORD"]]) {
            withVaultEnv(config.secret_env_list) {
                withDockerServer([uri: dockerHost()]) {
                    def mavenSettingsFile = "${env.WORKSPACE_TMP}/maven-global-settings.xml"
                    withMavenSettings("maven/jenkins_maven_global_settings", "settings", "MAVEN_GLOBAL_SETTINGS", mavenSettingsFile) {
                        withMaven(globalMavenSettingsFilePath: mavenSettingsFile,
                            options: [findbugsPublisher(disabled: true)]) {
                            // findbugs publishing is skipped in both steps because multi-module projects cause
                            // extra copies to be reported. Instead, use commonPost to collect once at the end
                            // of the build.

                            sh '''
                                # Hide login credential from below
                                set +x

                                # cc-root ECR access
                                $(aws ecr get-login --no-include-email --region us-west-2)
                            '''
                            devprodECRAccess()

                            if(config.loadNPMCreds) {
                                loadNPMCredentials()
                            }

                            withVaultFile(config.secret_file_list) {
                                def mavenBuild = {
                                    sh """
                                        ${javaOptions}
                                        ${maven_command} ${config.extraBuildArgs} ${config.mavenFlags} -P${config.mavenProfiles} ${config.mavenBuildGoals}
                                    """
                                }
                                def buildCause = utilities.getBuildCause()
                                echo "Build Cause: ${buildCause}"
                                if (config.pinnedNanoVersions && buildCause != "BranchEventCause" && !config.isPrJob && !config.isReleaseJob) {
                                    // Pinned Nanoversion project will ONLY bump their dependencies on master and release branches.
                                    // They will NOT bump dependencies when triggered by a branch commit (aka BranchEventCause), so that
                                    // commits and dependency bumps are evaluated and nanoversioned independently.
                                    preHash = sh(script: "git log -1 --oneline --format=%h", returnStdout: true).trim()
                                    ciTool("ci-update-version ${env.WORKSPACE} ${repo_name} --pinned-nano-versions --update-dependency-versions --no-update-project-version", config.isPrJob)
                                    postHash = sh(script: "git log -1 --oneline --format=%h", returnStdout: true).trim()
                                    if (!preHash.equals(postHash)) { // then there was a dependency bump
                                        try {
                                          mavenBuild()
                                        } catch (mavenFailure) {
                                          echo "🛑 maven failed: $mavenFailure"
                                          currentBuild.result = 'ABORTED'
                                          currentBuild.description = 'ATTENTION REQUIRED: Bumping dependencies caused the build to fail. Check the build log for details. Please manually bump the dependency and resolve the failure.'
                                          config.slackExtraDetails += "\n" + currentBuild.description
                                          error(currentBuild.description)
                                        }
                                        // We bumped dependencies and the tests passed, so we push the dep bump and exit.
                                        try {
                                          sh "git push origin HEAD:${env.BRANCH_NAME} --atomic"
                                          echo "🛑 Exiting early to push a successful version bump."
                                          currentBuild.result = 'SUCCESS'
                                          currentBuild.description = 'Bumped dependencies. The push will trigger a subsequent build.'
                                          config.slackExtraDetails += "\n" + currentBuild.description
                                          returnAfterBuild = true
                                          return
                                        } catch (gitfailure) {
                                          echo "🛑 git push failed: $gitfailure"
                                          currentBuild.result = 'ABORTED'
                                          currentBuild.description = 'Failed to push dependency update. May need to be triggered to try again.'
                                          config.slackExtraDetails += "\n" + currentBuild.description
                                          error(currentBuild.description)
                                        }
                                    } else {
                                        // There weren't any dependency bumps, so this is a regular build (update project version and try to publish a nanoversion)
                                        ciTool("ci-update-version ${env.WORKSPACE} ${repo_name} --pinned-nano-versions --no-update-dependency-versions --update-project-version", config.isPrJob)
                                    }
                                } else if (config.nanoVersion && !config.isReleaseJob) {
                                    if (config.pinnedNanoVersions) {
                                        // Since we skipped the first block, we won't bump dependencies, but only the project version and then proceed to (maybe) publish a nanoversion
                                        ciTool("ci-update-version ${env.WORKSPACE} ${repo_name} --pinned-nano-versions --no-update-dependency-versions --update-project-version", config.isPrJob)
                                    } else {
                                        ciTool("ci-update-version ${env.WORKSPACE} ${repo_name}", config.isPrJob)
                                    }
                                }
                                mavenBuild()
                            }
                        }
                    }
                }
            }
        }

        try {
            step([$class: 'hudson.plugins.findbugs.FindBugsPublisher', pattern: '**/*bugsXml.xml'])
        } catch (findbugserror){
            echo "FindBugsPublisher failed: $findbugserror"
            currentBuild.result = 'Unstable'
        }

        step([$class: 'DependencyCheckPublisher'])
    }

    if (returnAfterBuild) {
        return
    }

    if(config.publish && config.isDevJob && !config.skipUploadDependency) {
        stage('upload dependency') {
            uploadDependency(config.secret_file_list)
        }
    }

    if(config.isPrJob && config.downStreamValidate) {
        //downstream validation for pr jobs
        stage('downstream validation') {
            currentBuild.description = downStreamValidation(config.nanoVersion)
        }
    }

    if (config.publish && (config.isDevJob || config.isPreviewJob)) {
        stage('Deploy to Cflt Repo') {
            withDockerServer([uri: dockerHost()]) {
                def mavenSettingsFile = "${env.WORKSPACE_TMP}/maven-global-settings.xml"
                withMavenSettings("maven/jenkins_maven_global_settings", "settings", "MAVEN_GLOBAL_SETTINGS", mavenSettingsFile) {
                    withMaven(globalMavenSettingsFilePath: mavenSettingsFile,
                        // skip publishing results again to avoid double-counting
                        options: [openTasksPublisher(disabled: true), junitPublisher(disabled: true), findbugsPublisher(disabled: true)]) {
                        if (config.isPreviewJob) {
                            env.deployOptions = env.deployPreviewOptions
                        }

                        if (config.nanoVersion && !config.isReleaseJob && !config.isPrJob) {
                            ciTool("ci-push-tag ${env.WORKSPACE} ${repo_name}")
                        }

                        sh """
                            ${javaOptions}
                            ${maven_command} ${config.extraDeployArgs} ${config.mavenFlags} -P${config.mavenProfiles} -D${env.deployOptions} deploy -DskipTests
                        """
                    }
                }
            }
        }

        stage('Deploy to CSID S3') {
            withVaultEnv([
                ["csid/s3-aws-creds", "AWS_ACCESS_KEY_ID", "CSID_AWS_ACCESS_KEY_ID"],
                ["csid/s3-aws-creds", "AWS_SECRET_ACCESS_KEY", "CSID_AWS_SECRET_ACCESS_KEY"]
            ]) {
                withDockerServer([uri: dockerHost()]) {
                    def mavenSettingsFile = "${env.WORKSPACE_TMP}/maven-global-settings.xml"
                    withMavenSettings("maven/jenkins_maven_global_settings", "settings", "MAVEN_GLOBAL_SETTINGS", mavenSettingsFile) {
                        withMaven(globalMavenSettingsFilePath: mavenSettingsFile,
                            // skip publishing results again to avoid double-counting
                            options: [openTasksPublisher(disabled: true), junitPublisher(disabled: true), findbugsPublisher(disabled: true)]) {
                            if (config.isPreviewJob) {
                                env.deployOptions = env.deployPreviewOptions
                            }

                            if (config.nanoVersion && !config.isReleaseJob && !config.isPrJob) {
                                ciTool("ci-push-tag ${env.WORKSPACE} ${repo_name}")
                            }

                            sh """
                              ${javaOptions}
                              ${maven_command} ${config.extraDeployArgs} ${config.mavenFlags} -Ppublish-to-s3 deploy -DskipTests -Daws.accessKeyId=${CSID_AWS_ACCESS_KEY_ID} -Daws.secretKey=${CSID_AWS_SECRET_ACCESS_KEY}
                            """
                        }
                    }
                }
            }
        }

        if (config.isDevJob && !config.isReleaseJob && !config.isPrJob && !config.downStreamRepos.isEmpty()) {
            stage("Start Downstream Builds") {
                config.downStreamRepos.each { repo ->
                    build(job: "confluentinc/${repo}/${env.BRANCH_NAME}",
                        wait: false,
                        propagate: false
                    )
                }
            }
        }
    }

    if (isConnector && config.connectCveScan){
        // generate docker images for connector cve scanning
        stage('CveScan'){
            cveScan()
        }
    }
}

runJob config, job, { commonPost(config) }