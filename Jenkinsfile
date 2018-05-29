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
    //PUSH_KEY = ""
    DAO_COMMIT_TAG = "${BRANCH_NAME}"
    PUSH_KEY = credentials('gem_key')
    
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
        multi_deploy(STAGING_DEPLOY_CONTAINER)
      
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
