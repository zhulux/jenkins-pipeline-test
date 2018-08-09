import groovy.json.JsonSlurper

// keep 20 builds history
properties([[$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '20']]]);
currentBuild.result = "SUCCESS"

buildHttpProxy = "http://proxy_hk.astarup.com:39628"
dockerHub = 'registry.astarup.com/astarup'
projectName = 'tag-service'
name = "${projectName}"
buildAgent = 'docker-build-bj3a'
commit = ''
imageName = ''
branch = env.BRANCH_NAME
dockerRegistryUrl = "https://registry.astarup.com/"
dockerregistryCredentialsid = "8e212ee4-a5ca-48f0-9822-2a3af5fa17da"

versionTagRegex = /^v(\d+\.){0,2}\d+$/

def run() {
    def forDeployment = (env.BRANCH_NAME == 'master') || (env.BRANCH_NAME ==~ versionTagRegex)
    def forPR = !forDeployment

    if (forDeployment) {
        runForDeployment()
    }

    if (forPR) {
        runForPR()
    }
}

def runForPR() {
    checkoutRepo()
    def image = buildImage(proxy = buildHttpProxy)
    runTests(image.imageName())
    notifyGitHub()
}

def runForDeployment() {
    checkoutRepo()
    def image = buildImage(proxy = buildHttpProxy)

    runElixirTests(image.imageName())
    pushToRepository(image)

    if (deploymentNamespace() == "production") {
        confirmDeployment()
    }

    deployToServer(image.imageName(),
                   generateImageTag(),
                   "tag-service",
                   "tag-service",
                   deploymentNamespace())
}

def deploymentNamespace() {
    if (env.BRANCH == "master") {
        return "staging"
    }
    if (env.BRANCH ==~ versionTagRegex) {
        return "production"
    }
}

def confirmDeployment() {
    stage('Confirm Deployment') {
        timeout(time: 1, unit: 'DAYS') {
            input 'Deploy to Production?'
        }
    }
}

def checkoutRepo() {
    stage('Checkout Project') {
        checkout(scm)
    }
}

def buildImage(dockerfile = null, proxy = null) {
    stage("Build image") {
        def imageName = generateImageName()
        def buildArgs = []
        if dockerfile != null {
            buildArgs += ["-f", dockerfile]
        }
        if proxy != null {
            buildArgs += ["--build-arg", "HTTP_PROXY=${proxy}"]
        }

        return docker.build(imageName, buildArgs.join(" "))
    }
}

def runElixirTests(image) {
    docker.image(image).inside {
        stage('Testing elixir project') {
            sh 'echo success'
        }
    }
}

def notifyGithub() {
    stage('Notify Github') {
        sh 'echo skipped'
    }
}

def generateImageName(projectName) {
    if (projectName == null) {
        raise "Must specify projectName"
    }
    return projectName
}

def generateImageTag() {
    def tag = null
    if (env.BRANCH_NAME = 'master') {
        return "staging-$commit_id"
    } else if (env.BRANCH_NAME ==~ versionTagRegex) {
        return env.BRANCH_NAME
    } else {
        raise "Invalid branch, unable to generate image name"
    }
}

def pushToRepository(imageName, app) {
    stage('Pushing docker image to repository') {
        docker.withRegistry(
            env.dockerRegistryUrl
            env.dockerregistryCredentialsid
        ) {
            app.push(generateImageTag())
        }
    }
}

def deployToServer(imageName,
                   imageTag,
                   deploymentName,
                   containerName,
                   namespace,
                   context="kubernetes-admin@kubernetes",
                   config="/home/devops/.kube/jenkins-k8s-config") {
    stage("Deploy to ${namespace}") {
        // deploy
        def deployCmd = [
            "kubectl set image deployment",
            deploymentName,
            "${containerName}=${imageName}:${imageTag}",
            "--namespace=${namespace}",
            "--context=${context}",
            "--kubeconfig=${config}"
        ]
        sh(deployCmd.join(" "))

        // wait for status update
        def rolloutCmd = [
            "kubectl rollout status",
            "deployment/${deploymentName}",
            "--namespace=${namespace}",
            "--context=${context}",
            "--kubeconfig=${config}"
        ]
        sh(rolloutCmd.join(" "))
    }
}
