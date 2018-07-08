#!groovy
// docker host list [ docker-build-bj3a、docker-build-cn ]

//handle multi deployment with same image
// dep deployment optimus
def DEP_DB_MIGRATE_DEPLOY = ["optimus-optimus":"optimus-optimus"]
def DEP_DB_MIGRATE_DEPLOY_PROD = ["optimus-optimus":"optimus-optimus"]

//migrate after
def STAGING_DEPLOY_CONTAINER = ["optimus-sidekiq":"optimus-sidekiq", "optimus-faktory":"optimus-faktory", "optimus-sidekiq-slow":"optimus-sidekiq-slow"]
def PRODUCT_DEPLOY_CONTAINER = ["optimus-sidekiq":"optimus-sidekiq", "optimus-faktory":"optimus-faktory", "optimus-sidekiq-slow":"optimus-sidekiq-slow"]

// build image host
def BUILD_IMAGE_HOST = 'docker-build-cn'

pipeline {
  agent none
// Global environment affect pipeline scope
  environment {
    IMAGE_REPO = "registry.astarup.com/astarup"
    IMAGE_NAME = "optimus"
    DEPLOYMENT_NAME = ""
    DEPLOYMENT_NAME_PROD = ""
    CONTAINER_NAME = ""
    DOCKER_REGISTRY_CREDENTIALSID = "8e212ee4-a5ca-48f0-9822-2a3af5fa17da"
    DOCKER_REGISTRY_URL = "https://registry.astarup.com/"
    GEM_SERVER = "https://zhulux.com/private-test"
    PUSH_KEY = "${ZHULUX_GEM_KEY}"
    DAO_COMMIT_TAG = "${BRANCH_NAME}"
    KUBERNETES_UI = "http://k8s.zhulu.ltd/#!/deployment?namespace"
    STAGING_ENV = "staging"
    STAGING_DB = "${STAGING_OPTIMUS_DB_URL}"
    PRODUCT_ENV = "production"
    PRODUCT_DB = "${PRODUCT_OPTIMUS_DB_URL}"
    SENTRY_DSN = "${SENTRY_DSN}"
    
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
        sh "./dao-od-gem.sh"
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
    // build image and upload image to docker registry
//    stage('Publish Image to Registry') {
//      agent {
//        label 'docker-build-cn'
//      }
//      options {
//        skipDefaultCheckout()
//      }
//      when {
//        anyOf { branch 'staging'; tag 'v*' }
//      }
//      steps {
//        script {
//          if ( env.BRANCH_NAME ==~ /v.*/ ) {
//            tag_name = BRANCH_NAME
//            echo tag_name
//          }
//        }
//        script {
//          try {
//            retry(3) {
//              app = docker.build("${env.IMAGE_NAME}","--build-arg http_proxy=${env.HTTP_PROXY} .")
//              docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
//                if ( env.BRANCH_NAME == 'staging') {
//                  app.push("${BRANCH_NAME}-${BUILD_ID}")
//                }else if( env.BRANCH_NAME ==~ /v.*/ ){
//                  app.push("${BRANCH_NAME}")
//                }
//              }
//            }
//            notifySuccessful()
//          }
//          catch (exc) {
//            currentBuild.result = "FAILED"
//            notifyFailed()
//            throw exc
//          }
//        }
//        echo 'publish image'
//
//      }
//
//    }

    stage('db migrate use kubectl run') {
      agent {
        label 'docker-build-bj3a'
      }
// every exec db migrate
//      when {
//        branch 'staging'
//      }
      options {
        skipDefaultCheckout()
      }

      steps {
        script {
          try {
            kubeRunMigrate( 'staging', 'db-hahaha', 'bundle", "exec", "rails", "db:migrate')
            //getBranchMigrate(BRANCH_NAME)
          } catch (err) {
            bearychat_notify_failed()
            throw err
          }

        }
        println "hahaha, belowbelow"

//        println "below is deploy test!!!!"
//        multi_deploy_new(STAGING_DEPLOY_CONTAINER)
//        println "below is product deoloytest !!! GO"
//        multi_deploy_new(PRODUCT_DEPLOY_CONTAINER, 'production')
      }

    }

    stage('Staging DB Mirgate') {
      agent {
        docker {
          label 'docker-build-cn'
          image '$IMAGE_REPO/$IMAGE_NAME:staging-90'
          args '-e OPTIMUS_DB_URL="$STAGING_DB_URL" -e RAILS_ENV=staging'
        }
      }
      when {
        branch 'staging'
      }
      options {
        skipDefaultCheckout()
      }
      steps {
        println 'rails_env=${RAILS_ENV:-development}'
        println 'echo $RAILS_ENV'
        println 'echo ==Rails environment: $rails_env'
        println 'bundle exec rails db:migrate'
        println '${STAGING_DB_URL}'
        println '$STAGING_DB_URL'
      }
    }

    stage('Production DB Mirgate') {
      agent {
        docker {
          label 'docker-build-cn'
          image "${env.IMAGE_REPO}/${env.IMAGE_NAME}:${BRANCH_NAME}"
          args "-e OPTIMUS_DB_URL=${env.PRODUCT_DB_URL} -e RAILS_ENV='production'"
        }
      }
      when {
        tag 'v*'
      }
      options {
        skipDefaultCheckout()
      }
      steps {
        println 'rails_env=${RAILS_ENV:-development}'
        println 'echo ==Rails environment: $rails_env'
        println 'bundle exec rails db:migrate'
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
        echo "kubectl set image deployment_name=${IMAGE_REPO}/${IMAGE_NAME}:${BRANCH_NAME}-${BUILD_ID}"

        multi_deploy(DEP_DB_MIGRATE_DEPLOY)
        sh "sleep 3"
        multi_deploy(STAGING_DEPLOY_CONTAINER)
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
        echo "${env.IMAGE_NAME}"
        echo "kubectl set image deployment_name=${env.IMAGE_REPO}/${env.IMAGE_NAME}:${env.BRANCH_NAME}"
        //sh "kubectl config use-context devadmin-context --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
        //sh "kubectl set image deployment ${DEPLOYMENT_NAME_PROD} ${CONTAINER_NAME}=${IMAGE_REPO}/${env.IMAGE_NAME}:${env.BRANCH_NAME} --namespace production --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
        multi_deploy_prod(DEP_DB_MIGRATE_DEPLOY_PROD)
        multi_deploy_prod(PRODUCT_DEPLOY_CONTAINER)
       // println "start 1"
       // bearychat_notify_start()
       // println "build successful"
       // bearychat_notify_successful()
       // println "build failed"
       // bearychat_notify_failed()
        println "deploy successs"
        bearychat_notify_deploy_successful('production')
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


// db_migrate notify

//void bearychat_notify_successful() {
//  bearychatSend title: "构建成功: ${env.JOB_NAME} ${env.BUILD_NUMBER}", url: "${env.BUILD_URL}"
//  bearychatSend message: " Job ${env.JOB_NAME} 已经执行完成", color: "#00ff00", attachmentText: "Project: ${env.JOB_BASE_NAME}, 状态: 镜像构建成功, 镜像名字: ${env.IMAGE_NAME}"
//}
//
//void bearychat_notify_failed() {
//  bearychatSend message: "构建失败: [${env.JOB_NAME} 执行中断, 请点击这里检查原因！](${env.BUILD_URL})", color: "#ff0000", attachmentText: "状态: 镜像构建失败"
//}



// deploy namespace notify
void bearychat_notify_deploy_successful(namespace='staging') {
  bearychatSend title: "Successful Deploy to ${namespace}, Click here to check!", url: "${env.KUBERNETES_UI}=${namespace}"
}

//void multi_deploy(song_list) {
//  sh "echo Going to echo a list"
//  for (int i = 0; i < sone_list.size(); i++) {
//    sh "echo Hello ${sone_list[i]}"
//  }
//}


void multi_deploy(song_list, namespace='staging') {
  song_list.each { key, value ->
    println "kubectl set image deployment ${key} ${value}=${IMAGE_REPO}/${IMAGE_NAME}:${BRANCH_NAME}-${BUILD_ID} --namespace ${namespace}  --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
  }
}

void multi_deploy_prod(song_list, namespace='production') {
  song_list.each { key, value ->
    println "kubectl set image deployment ${key} ${value}=${IMAGE_REPO}/${IMAGE_NAME}:${BRANCH_NAME} --namespace ${namespace}  --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
  }
}

// exec db migrate
//void db_migrate(namespace='staging') {
//  sh "kubectl run optimus-migrate --image=${IMAGE_REPO}/${IMAGE_NAME}:staging-90 --attach=true --rm=true --restart='Never' --env='namespace=${NAMESPACE}' -- bash start.sh"
//
//  sh "kubectl run optimus-migrate --image=${IMAGE_REPO}/${IMAGE_NAME}:${BRANCH_NAME} --attach=true --rm=true --restart='Never' --env='namespace=${NAMESPACE}' --namespace ${namespace} --kubeconfig=/home/devops/.kube/jenkins-k8s-config --context=${env.KUBERNETES_PRODUCT_CONTEXT} -- bash start.sh"
//
//}


// db migrate performance
void db_migrate(namespace='staging') {
  if (namespace=='staging') {
    sh "kubectl run optimus-migrate --image=${IMAGE_REPO}/${IMAGE_NAME}:staging-90 --attach=true --rm=true --restart='Never' --env='RAILS_ENV=${STAGING_ENV}' --env='OPTIMUS_DB_URL=${STAGING_DB}' --env='SENTRY_DSN=${SENTRY_DSN}' --namespace ${namespace}  --kubeconfig=/home/devops/.kube/jenkins-k8s-config -- env "
    println "current namespace is ${namespace}"
  } else if (namespace=='production'){
    sh "kubectl run optimus-migrate --image=${IMAGE_REPO}/${IMAGE_NAME}:staging-90 --attach=true --rm=true --restart='Never' --env='RAILS_ENV=${PRODUCT_ENV}' --env='OPTIMUS_DB_URL=${PRODUCT_DB}' --env='SENTRY_DSN=${SENTRY_DSN}' --namespace ${namespace}  --kubeconfig=/home/devops/.kube/jenkins-k8s-config -- env "
    println "current namespace is ${namespace}"
  } else {
    println "Nothing"
  }
}

void multi_deploy_new(song_list, namespace='staging') {
  if (namespace=='staging') {
    song_list.each { key, value ->
      println "kubectl set image deployment ${key} ${value}=${IMAGE_REPO}/${IMAGE_NAME}:${BRANCH_NAME}-${BUILD_ID} --namespace ${namespace}  --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
    } 
  } else if (namespace=='production') {
    song_list.each { key, value -> 
      println "kubectl set image deployment ${key} ${value}=${IMAGE_REPO}/${IMAGE_NAME}:${BRANCH_NAME} --namespace ${namespace}  --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
    }
  } else {
    println "Nothing at all"
  }
}


void getBranchMigrate(String branch) {
    if ( branch == 'staging' ){
        db_migrate('staging')
    } else if ( branch ==~ /v.*/ ) {
        db_migrate('production')
    } else {
        println 'Nothing'
    }
}

//void kubeRunMigrate(namespace,pod_name,image,run_env){
//    def image = ${IMAGE_REPO}/${IMAGE_NAME}:BRANCH_NAME
//    sh "kubectl run optimus-migrate --image=${IMAGE_REPO}/${IMAGE_NAME}:staging-90 --attach=true --rm=true --restart='Never' --overrides='{"spec": {"containers": [{"image": "image", "args": ["command"], "name": "podname", "envFrom": [{"configMapRef": {"name": "configmap"}}, {"secretRef": {"name": "secrets"}}]}]}}'"
//
//    sh “kubectl run ${pod_name} --image=${image} --attach=true --rm=true --restart='Never' --overrides=''”
//
//}

//    sh "kubectl run optimus-migrate --image=${IMAGE_REPO}/${IMAGE_NAME}:staging-90 --attach=true --rm=true --restart='Never' --overrides='{"spec": {"containers":
//    [{"image": "image", "args": ["command"], "name": "podname", "envFrom": [{"configMapRef": {"name": ""}}, {"secretRef": {"name": "secrets"}}]}]}}'"



//def thr = Thread.currentThread()
//def build = thr.executable
//// get build parameters
//def buildVariablesMap = build.buildVariables 
//// get all environment variables for the build
//def buildEnvVarsMap = build.envVars

//String jobName = buildEnvVarsMap?.JOB_NAME


// get env from jenkins system
//void get_env(env_name) {
//  if (env_name=='STAGING_OPTIMUS_DB_URL') {
//    println env.STAGING_OPTIMUS_DB_URL
//  } else if (env_name=='PRODUCT_OPTIMUS_DB_URL') {
//    return env.PRODUCT_OPTIMUS_DB_URL
//  } else if (env_name=='SENTRY_DSN') {
//    return env.SENTRY_DSN
//  } else {
//    println 'Nothing'
//  }
//}


def kubeRunMigrate(namespace='default',pod_name='db-migration',command='time') {
    if ( namespace == 'staging' ){
        tag = "${BRANCH_NAME}-${commit_id}"
    } else if ( namespace == 'production' ){
        tag = "${BRANCH_NAME}"
    } else {
        println "Nothing to do!"
    }
    image = "$IMAGE_REPO/$IMAGE_NAME:$commit_id"
    fileContents = """{"spec": {"containers": [{"image": "$image", "command": ["$command"], "name": "$pod_name", "envFrom": [{"configMapRef": {"name": "db-url-info"}}]}]}}"""
//    fileContents = '{"spec": {"containers": [{"image": "registry.astarup.com/astarup/optimus:staging-90", "command": ["env"], "name": "optimus-migra", "envFrom": [{"configMapRef": {"name": "db-url-info"}}]}]}}'
    sh "kubectl run ${pod_name} --image=${image} --attach=true --rm=true --restart=Never --namespace ${namespace} --context=kubernetes-admin@kubernetes --kubeconfig=/home/devops/.kube/jenkins-k8s-config --overrides='${fileContents}'"
}

