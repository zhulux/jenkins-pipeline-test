#!groovy

// keep 20 builds history
properties([[$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '20']]]);
def lib = library('ci-shared-libs').com.starup
def msgUtils = lib.MessageLego.new()
def buildAgent = 'docker-build-bj3a'
def dockerHub = 'registry.astarup.com/astarup'
def projectName = 'optimus'
buildHttpProxy = "http://proxy_hk.astarup.com:39628"
dockerRegistryUrl = "https://registry.astarup.com"
dockerregistryCredentialsid = "8e212ee4-a5ca-48f0-9822-2a3af5fa17da"
currentBuild.result = "SUCCESS"
imageName = "${dockerHub}/${projectName}"
imageTag = ''
shortCommitId = ''
versionTagRegex = /^v(\d+\.){0,2}\d+$/

def commitMsg = ''
def branch = env.BRANCH_NAME
def bearychatHookUrl = env.BEARYCHAT_HOOK_URL
def bearychatHookGroup = 'testgroup'
def kubeTestNs = 'test'
def kubeQaNs = 'qa'
def kubeStageNs = 'staging'
def kubeProdNs = 'production'
def targetPath = "./jobs"


def STAGING_DEPLOY_CONTAINER = ["optimus-optimus":"optimus-optimus", "optimus-sidekiq":"optimus-sidekiq", "optimus-faktory":"optimus-faktory", "optimus-sidekiq-slow":"optimus-sidekiq-slow"]
def PRODUCT_DEPLOY_CONTAINER = ["prod-optimus-prod-optimus":"prod-optimus-optimus", "prod-optimus-sidekiq":"prod-optimus-sidekiq", "prod-optimus-faktory":"prod-optimus-faktory", "prod-optimus-sidekiq-slow":"prod-optimus-sidekiq-slow"]
def stageConfigMap = "optimus"
def prodConfigMap = "optimus-optimus"
def Object image


/*
 Jenkinsfile main body
*/

try {
  node("${buildAgent}") {
    stage("Checkout Project") {
      def scmVars = checkout scm
      imageTag = genImageTag(env.BRANCH_NAME)
    }

    stage("Build Image") {
      image = dockerBuild("${imageName}","${buildHttpProxy}")
    }

    stage("Unit test") {
      try {
        runElixirTests()
      } catch (someErr) {
        throw someErr
      } finally {
        // bearyNotifySend Notify
      }
    }
  }

  if (branch == 'staging') {
    namespace = "${kubeStageNs}"

    stage("Publish Image to Registry") {
      node("${buildAgent}") {
        dockerPush(image,"$imageTag")
      }
    }

    stage("Deploy to Staging") {
      // deploy to staging
      // SUCCESSFUL Notify bearychatSend
      node("${buildAgent}") {
        kubeDBMigrate(imageFullName: "${imageName}:${imageTag}", namespace: "${namespace}", command: '"bundle", "exec", "rails", "db:migrate"', configMap: "${stageConfigMap}")

        // deploy multi service (key: deploymentName, value: containerName)
        STAGING_DEPLOY_CONTAINER.each { key, value ->
            deployToServer(namespace: "${namespace}", deploymentName: key, imageFullName: "${imageName}:${imageTag}", containerName: value)
        }
      }
    }

    stage("Create ETL Job on kubernetes staging") {
      node("${buildAgent}") {
        updateEtlTask("${namespace}", "${imageTag}", "${targetPath}")
        commitMsg = getCommitMsg()
        deployMsg = msgUtils.deployMsg("${branch}", "${namespace}", "http://optimus.zhulu.ltd","${commitMsg}")
        bearyNotifySend attachments: "${deployMsg}", channel: "${bearychatHookGroup}", endpoint: "${bearychatHookUrl}"
      }
    }


  } else if (branch ==~ versionTagRegex) {
    namespace = "${kubeProdNs}"

    stage("Publish Image to Registry") {
      node("${buildAgent}") {
        dockerPush(image,"$imageTag")
      }
    }

    stage("Deploy to Production") {
      waitForApprove("Deploy to Production?", 3)
      node("${buildAgent}") {
        kubeDBMigrate(imageFullName: "${imageName}:${imageTag}", namespace: "${namespace}", command: '"bundle", "exec", "rails", "db:migrate"', configMap: "${prodConfigMap}")

        PRODUCT_DEPLOY_CONTAINER.each { key, value ->
          deployToServer(namespace: "${namespace}", deploymentName: key, imageFullName: "${imageName}:${imageTag}", containerName: value)
        }
      }
    }

    stage("Create ETL Job on kubernetes Production") {
      node("${buildAgent}") {
        updateEtlTask("${namespace}", "${imageTag}", "${targetPath}")
        commitMsg = getCommitMsg()
        deployMsg = msgUtils.deployMsg("${branch}", "${namespace}", "http://optimus.zhulu-inc.com","${commitMsg}")
        bearyNotifySend attachments: "${deployMsg}", channel: "${bearychatHookGroup}", endpoint: "${bearychatHookUrl}"
      }
    }

    // SUCCESSFUL Notify bearychatSend

  } else if (branch ==~ /^od-(\d+\.){0,2}\d+$/) {
    docker.image('ruby:2.4.2').inside('-u root'){
      stage('od gem build & push') {
        sh "./dao-od-gem-jenkins.sh"
      }
    }
    commitMsg = getCommitMsg()
    deployMsg = msgUtils.deployMsg("${branch}", "odGems", "http://optimus.zhulu-inc.com","${commitMsg}")
    bearyNotifySend attachments: "${deployMsg}", channel: "${bearychatHookGroup}", endpoint: "${bearychatHookUrl}"
  }


} catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException e) {
  node("${buildAgent}") {
    echo e.getCauses().join(", ")
    currentBuild.result = "ABORTED"
    errorMsg = msgUtils.errorMsg("${aborteMsg}")
    bearyNotifySend attachments: "${errorMsg}", channel: "${bearychatHookGroup}", endpoint: "${bearychatHookUrl}"
  }
} catch (err) {
  node("${buildAgent}") {
    currentBuild.result = "FAILURE"
    errorMsg = msgUtils.errorMsg(err,'')
    bearyNotifySend attachments: "${errorMsg}", channel: "${bearychatHookGroup}", endpoint: "${bearychatHookUrl}"
    throw err
  }
}



def updateEtlTask(namespace, imageTag, targetFilePath) {
  /*
    Create cronjob from local job template, but jobBuilder generate and job
    template must exist on project rpository.
  */
    sh "sed -i 's/IMAGE_TAG/$imageTag/g' jobBuilder.groovy"
    sh "groovy jobBuilder.groovy"
    // Check target job file
    sh "cat $targetFilePath/*"
    echo "Delete the previous cronjob"
    // Delete old cronjob
    sh "kubectl delete cronjob -l app=optimus-job -n $namespace"
    // Create cronjob from targetpath
    sh "kubectl create -f $targetFilePath -n $namespace"
}

def runElixirTests() {
    docker.image(imageName).inside {
        sh 'echo success'
    }
}

