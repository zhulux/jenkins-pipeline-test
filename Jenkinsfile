#!groovy
// docker host list [ docker-build-bj3a、docker-build-cn ]

//handle multi deployment with same image
// dep deployment optimus
def DEP_DB_MIGRATE_DEPLOY = ["optimus-optimus":"optimus-optimus"]
def DEP_DB_MIGRATE_DEPLOY_PROD = ["optimus-optimus":"optimus-optimus"]

//migrate after
def STAGING_DEPLOY_CONTAINER = ["optimus-sidekiq":"optimus-sidekiq", "optimus-faktory":"optimus-faktory", "optimus-sidekiq-slow":"optimus-sidekiq-slow"]
def PRODUCT_DEPLOY_CONTAINER = ["optimus-sidekiq":"optimus-sidekiq", "optimus-faktory":"optimus-faktory", "optimus-sidekiq-slow":"optimus-sidekiq-slow"]

// test pipeline deployment
def TEST_DEPLOY_CONTAINER = ["helm-repo": "helm-repo"]

// build image host
// def BUILD_IMAGE_HOST = 'docker-build-cn'
def BUILD_IMAGE_HOST = 'docker-build-bj3a'

pipeline {
  agent none
// Global environment affect pipeline scope
  environment {
    IMAGE_REPO = "registry.astarup.com/astarup"
    IMAGE_NAME = "pipeline-test"
    DEPLOYMENT_NAME = ""
    DEPLOYMENT_NAME_PROD = ""
    CONTAINER_NAME = ""
    DOCKER_REGISTRY_CREDENTIALSID = "8e212ee4-a5ca-48f0-9822-2a3af5fa17da"
    DOCKER_REGISTRY_URL = "https://registry.astarup.com/astarup"
    GEM_SERVER = "https://zhulux.com/private-test"
    PUSH_KEY = "${ZHULUX_GEM_KEY}"
    DAO_COMMIT_TAG = "${BRANCH_NAME}"
    KUBERNETES_UI = "http://k8s.zhulu.ltd/#!/deployment?namespace"
    STAGING_CONTEXT = 'kubernetes-admin@kubernetes'
    PROD_CONTEXT = 'devadmin-context'
  }
  stages {
    // clone remote repo step
    stage('Clone Repository') {
      agent {
        label "${BUILD_IMAGE_HOST}"
      }
      steps {
        script {
          try {
            if ( env.BRANCH_NAME == 'master' ) {
              echo "Current branch is ${env.BRANCH_NAME}"
            } else if(env.BRANCH_NAME ==~ /v.*/ ) {
              echo "Current branch is ${env.BRANCH_NAME}"
            } else if(env.BRANCH_NAME ==~ /od.*/ ) {
              echo "CUrrent branch is ${env.BRANCH_NAME}"
            }
            commit_id = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

          } catch (exc) {
            echo "some error"
          }

        }
     }
    }

    // build gem package
    stage('od gem build & push') {
      agent { 
        docker { 
          image 'ruby:2.4.2'
          args '-u root'
        } 
      }
      when {
        tag "od*"
      }
      steps {
//        sh "./dao-od-gem.sh"
        sh "date"
      }

    }


    // Note: exec sh must have agent or node
    // test image inside service
    stage('Test image') {
      agent {
        label "${BUILD_IMAGE_HOST}"
      }
      options {
        skipDefaultCheckout()
      }
      steps {
        echo 'TODO: add tests'
        bearychat_notify_start()
      }
    }

    stage('Publish Image to Registry') {
      agent {
        label "${BUILD_IMAGE_HOST}"
      }
      options {
        skipDefaultCheckout()
      }
      when {
        anyOf { branch 'staging'; tag 'v*' }
      }
      steps {
        script {
          try {
            retry(3) {
              dockerImageBuild("$IMAGE_NAME", currentBranchToTag("$BRANCH_NAME"))
              notifySuccessful()
            }
          } catch (exc) {
            currentBuild.result = "FAILED"
            notifyFailed()
            throw exc
          }
        }
      }

    }

    stage('db migrate use kubectl run') {
      agent {
        label 'docker-build-bj3a'
      }
      options {
        skipDefaultCheckout()
      }
      when {
        anyOf { branch 'staging'; tag 'v*' }
      }
      steps {
        script {
          try {
            if (BRANCH_NAME == 'staging') {
              kubeRunMigrate('staging', "$STAGING_CONTEXT", 'db-db-haha', "$IMAGE_REPO/$IMAGE_NAME", currentBranchToTag("$BRANCH_NAME"), 'env')
            } else if (BRANCH_NAME ==~ /v.*/){
              kubeRunMigrate('production', "$PROD_CONTEXT", 'db-db-haha', "$IMAGE_REPO/$IMAGE_NAME", currentBranchToTag("$BRANCH_NAME"), 'env')
            }
          } catch (err) {
            bearychat_notify_failed()
            throw err
          }
        }
      }
    }


    // deploy image to staging
    stage('Staging Deployment') {
      agent {
        //label 'k8s-publish'
        label "${BUILD_IMAGE_HOST}"
      }
      options {
        skipDefaultCheckout()
      }
      when {
        branch 'staging'
      }
      steps {
        echo 'stage deploy'
        milestone(1)
        timeout(time:2, unit:'MINUTES'){
          input 'Deploy to Staging?'
        }
        milestone(2)

        kubeRollUpdate(TEST_DEPLOY_CONTAINER, "$IMAGE_REPO/$IMAGE_NAME", currentBranchToTag("$BRANCH_NAME"), "devops", "$STAGING_CONTEXT")

        // check roll update status
        
        kubeRollStatus(TEST_DEPLOY_CONTAINER, "devops", "$STAGING_CONTEXT", 'false')

        //bearychat_notify_successful()
        bearychat_notify_deploy_successful()
      
      }
    }
    // approve deploy product ?
    stage('Go for Production?') {
      agent {
        //label 'k8s-publish'
        label "${BUILD_IMAGE_HOST}"
      }
      options {
        skipDefaultCheckout()
      }
      when {
        tag "v*"
      }
      steps {
        milestone(1)
        timeout(time:2, unit:'MINUTES'){
          input 'Deploy to Production?'
        }
        milestone(2)
      }
    }
    // deploy production
    stage('Production Deployment') {
      agent {
        //label 'k8s-publish'
        label "${BUILD_IMAGE_HOST}"
      }
      options {
        skipDefaultCheckout()
      }
      when {
        tag "v*"
      }
      steps {
        echo 'product deploy'
        script {
          try {
            kubeRollUpdate(TEST_DEPLOY_CONTAINER, "$IMAGE_REPO/$IMAGE_NAME", currentBranchToTag("$BRANCH_NAME"), "production", "$PROD_CONTEXT")
            kubeRollStatus(STAGING_DEPLOY_CONTAINER, "staging", "$STAGING_CONTEXT", 'true')
            bearychat_notify_deploy_successful('production')
          } catch (exc) {
            currentBuild.result = "FAILED"
            throw exc
            bearychatNotifyDeployFailed
          }
        }
      }
    }
  }
}


// custom define function

void notifySuccessful() {
  emailext (
    to: "jianguohan@zhulux.com,${env.CHANGE_AUTHOR_EMAIL}",
    subject: "构建成功: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
    body: """<p>SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
      <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>""",
    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
    )
}

void notifyFailed() {
  emailext (
    to: "jianguohan@zhulux.com,${env.CHANGE_AUTHOR_EMAIL}",
    subject: "构建失败: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
    body: """<p>Failed: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
      <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>""",
    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
    )
}

// BearychatSend notify

void bearychat_notify_start() {
  bearychatSend color: "#00FFFF", attachmentText: "Started Pipeline [${env.JOB_NAME} #${env.BUILD_NUMBER}](${env.BUILD_URL})"
}

// build image success or failed notify
void bearychat_notify_successful() {
  bearychatSend title: "构建成功: ${env.JOB_NAME} ${env.BUILD_NUMBER}", url: "${env.BUILD_URL}"
  bearychatSend message: " Job ${env.JOB_NAME} 已经执行完成", color: "#00ff00", attachmentText: "Project: ${env.JOB_BASE_NAME}, 状态: 镜像构建成功, 镜像名字: ${env.IMAGE_NAME}"
}

void bearychat_notify_failed() {
  bearychatSend message: "构建失败: [${env.JOB_NAME} 执行中断, 请点击这里检查原因！](${env.BUILD_URL})", color: "#ff0000", attachmentText: "状态: 镜像构建失败"
}


// deploy namespace notify
void bearychat_notify_deploy_successful(namespace='staging') {
  bearychatSend title: "Successful Deploy to ${namespace}, Click here to check!", url: "${env.KUBERNETES_UI}=${namespace}"
}

void bearychatNotifyDeployFailed(namespace='staging') {
  bearychatSend title: "Failed deploy to ${namespace}, Click here to check!", url: "${env.KUBERNETES_UI}=${namespace}"
}



// db migrate performance

def kubeRunMigrate(namespace='default', cluster_context, pod_name='db-migration', image_name="$IMAGE_REPO/$IMAGE_NAME", image_tag="$BRANCH_NAME-$commit_id",command='time', cm_name='db-url-info') {
    jsonContent = """{"spec": {"containers": [{"image": "$image_name:${image_tag}", "command": ["$command"], "name": "$pod_name", "envFrom": [{"configMapRef": {"name": "$cm_name"}}]}]}}"""
    sh "kubectl run ${pod_name} --image=${image_name}:${image_tag} --attach=true --rm=true --restart=Never --namespace ${namespace} --context=${cluster_context} --kubeconfig=/home/devops/.kube/jenkins-k8s-config --overrides='${jsonContent}'"
}


// check rollupdate status
def kubeRollStatus(song_list, namespace, cluster_context, multi_deploy='false') {
    if (multi_deploy == 'false') {
        song_list.each { key, value ->
            sh "kubectl rollout status deployment/${key} -n ${namespace} --context=${cluster_context} --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
        }
    } else if (multi_deploy == 'true') {
        song_list.each { key, value ->
            println "kubectl rollout status deployment/${key} -n ${namespace} --context=${cluster_context} --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
        }
    }
    
}


// deploy update image
def kubeRollUpdate(song_list, image_name="$IMAGE_REPO/$IMAGE_NAME", image_tag="$BRANCH_NAME-$commit_id", namespace, cluster_context) {
    song_list.each { key, value ->
        sh "kubectl set image deployment ${key} ${value}=${image_name}:${image_tag} --namespace ${namespace} --context=${cluster_context} --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
    }

}

/*
build docker image
*/
def dockerImageBuild(image_name="$IMAGE_NAME", image_tag="$BRANCH_NAME-$commit_id", dockerfile_path=".", dockerfile_name="Dockerfile", http_proxy='') {
    app = docker.build("$IMAGE_REPO/${image_name}", "-f ${dockerfile_path}/${dockerfile_name} --build-arg http_proxy=${http_proxy} .")
    docker.withRegistry("${env.DOCKER_REGISTRY_URL}", "${env.DOCKER_REGISTRY_CREDENTIALSID}") {
      app.push("$image_tag")
    }
}

// branch to image tag
def currentBranchToTag(branch_name="$BRANCH_NAME") {
  if ( branch_name == 'staging') {
    image_tag = "$BRANCH_NAME-$commit_id"
  } else if( branch_name ==~ /v.*/ ) {
    image_tag = "$BRANCH_NAME"
  }
  return image_tag
}


/*
参考：
https://issues.jenkins-ci.org/browse/JENKINS-48315
https://issues.jenkins-ci.org/browse/JENKINS-44456
https://www.cloudbees.com/blog/top-10-best-practices-jenkins-pipeline-plugin
*/
