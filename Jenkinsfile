#!groovy

def MULTI_DEPLOYMENT = ['first', 'second', 'three']
pipeline {
  agent none
// Global environment affect pipeline scope
  environment {
    HTTP_PROXY = ""
    IMAGE_REPO = "registry.astarup.com:5000"
    IMAGE_NAME = "pro_hello"
    DEPLOYMENT_NAME = "helloworld"
    DEPLOYMENT_NAME_PROD = "helloworld-prod"
    CONTAINER_NAME = "helloworld"
   // MULTI_DEPLOYMENT = ['first', 'second', 'three']
    
  }
  stages {
    // clone remote repo step
    stage('Clone Repository') {
      agent {
        label 'docker-build-cn'
      }
      steps {
        script {
          try {
            if ( env.BRANCH_NAME == 'staging' ) {
              sh "git rev-parse HEAD > .git/commit-id"
              sh "echo -n `git rev-parse HEAD` | head -c 7 > .git/commit-id"
            } else if(env.BRANCH_NAME ==~ /v.*/ ) {
              sh "git describe --tags --abbrev=0 > .git/tag-name"
              sh "git rev-parse HEAD > .git/commit-id"
              sh "echo -n `git rev-parse HEAD` | head -c 7 > .git/commit-id"
            }
          }
          catch (exc) {
            echo "Because current work branch is ${env.BRANCH_NAME},Can be ignored."
          }

        }
      }
    }

    stage('Loop test echo') {
      steps {
        echo_all(MULTI_DEPLOYMENT)
      }
    }
    // Note: exec sh must have agent or node
    stage('Loop sh') {
      agent { label 'docker-build-cn' }
      steps {
        loop_of_sh(MULTI_DEPLOYMENT)
      }
    }

    // test image inside service
    stage('Test image') {
      agent {
        label 'docker-build-cn'
      }
      options {
        skipDefaultCheckout()
      }
      steps {
        echo 'TODO: add tests'
      }
    }
    // build image and upload image to docker registry
    stage('Publish Image to Registry') {
      agent {
        label 'docker-build-cn'
      }
      options {
        skipDefaultCheckout()
      }
      environment {
        commit_id = readFile('.git/commit-id').trim()
        //tag_name = readFile('.git/tag-name').trim()
      }
      steps {
        script {
          if ( env.BRANCH_NAME ==~ /v.*/ ) {
            tag_name = BRANCH_NAME
            echo tag_name
          }
        }
        script {
          try {
            retry(3) {
              app = docker.build("${env.IMAGE_NAME}","--build-arg http_proxy=${env.HTTP_PROXY} .")
              docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
                if ( env.BRANCH_NAME == 'staging') {
                  app.push("${BRANCH_NAME}-${BUILD_ID}")
                }else if( env.BRANCH_NAME ==~ /v.*/ ){
                  app.push("${BRANCH_NAME}")
                }
              }
            }
            notifySuccessful()
          }
          catch (exc) {
            currentBuild.result = "FAILED"
            notifyFailed()
            throw exc
          }
        }
        echo 'publish image'

      }

    }

    // deploy image to staging
    stage('Staging Deployment') {
      agent {
        label 'k8s-publish'
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
        echo "kubectl set image deployment_name=${IMAGE_REPO}/${IMAGE_NAME}:${BUILD_ID}"
        sh "kubectl config use-context kubernetes-admin@kubernetes --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
        sh "kubectl set image deployment ${DEPLOYMENT_NAME} ${CONTAINER_NAME}=${IMAGE_REPO}/${IMAGE_NAME}:${BRANCH_NAME}-${BUILD_ID} --namespace staging --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
      
      }
    }
    // approve deploy product ?
    stage('Go for Production?') {
      agent {
        label 'k8s-publish'
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
        label 'k8s-publish'
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
        sh "kubectl config use-context devadmin-context --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
        sh "kubectl set image deployment ${DEPLOYMENT_NAME_PROD} ${CONTAINER_NAME}=${IMAGE_REPO}/${env.IMAGE_NAME}:${env.BRANCH_NAME} --namespace production --kubeconfig=/home/devops/.kube/jenkins-k8s-config"
      }
    }
  }


}


// custom define function

void notifySuccessful() {
  emailext (
    to: "jianguohan@zhulux.com",
    subject: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
    body: """<p>SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
      <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>""",
    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
    )
}

void notifyFailed() {
  emailext (
    to: "jianguohan@zhulux.com",
    subject: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
    body: """<p>SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
      <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>""",
    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
    )
}


void echo_all(list) {
  list.each {
    item -> echo "hello ${item}"
  }
}

void loop_of_sh(list) {
  list.each {
    item ->
    sh "echo Hello ${item}"
  }
}
