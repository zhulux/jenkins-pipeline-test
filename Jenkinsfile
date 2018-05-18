#!groovy
pipeline {
  agent none

  environment {
    IMAGE_REPO = "registry.astarup.com:5000/helloworld"
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

        echo 'publish image'
      steps {
        script {
          app = docker.build("helloworld")
          docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
            if ( env.BRANCH_NAME == 'staging') {
              app.push("${BRANCH_NAME}-${BUILD_ID}")
            }else if( env.BRANCH_NAME ==~ /v.*/ ){
              app.push("${BRANCH_NAME}")
            }
          }
         }
         //docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
         //   app.push("${BRANCH_NAME}-${BUILD_ID}")
         //}
       }

      }

    }

    // deploy image to staging
    stage('Staging Deployment') {
      agent {
        label 'docker-build-cn'
      }
      options {
        skipDefaultCheckout()
      }
      when {
        branch 'staging'
      }
      steps {
        echo 'stage deploy'
        echo "kubectl set image deployment_name=${IMAGE_REPO}:${BUILD_ID}"
      }
    }
    // approve deploy product ?
    stage('Go for Production?') {
      agent {
        label 'docker-build-cn'
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
        echo "kubectl set image deployment_name=${env.IMAGE_REPO}:${env.BRANCH_NAME}"
      }
    }


  }

}