#!groovy
pipeline {
  agent none

  environment {
    IMAGE_REPO = "registry.astarup.com:5000"
    IMAGE_NAME = "pro_hello"
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
          app = docker.build("${env.IMAGE_NAME}")
          retry(3) {
            docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
              if ( env.BRANCH_NAME == 'staging') {
                app.push("${BRANCH_NAME}-${BUILD_ID}")
              }else if( env.BRANCH_NAME ==~ /v.*/ ){
                app.push("${BRANCH_NAME}")
              }
            }
          }
        }
        echo 'publish image'
      }

    }

    // deploy image to staging
    stage('Staging Deployment') {
      agent {
        label 'k8s'
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
      }
    }
    // approve deploy product ?
    stage('Go for Production?') {
      agent {
        label 'k8s'
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
        label 'k8s'
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
      }
    }


  }

}