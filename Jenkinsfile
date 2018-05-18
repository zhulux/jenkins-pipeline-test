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
      steps {
        echo 'TODO: add tests'
      }
    }
    // build image and upload image to docker registry
    stage('Publish Image to Registry') {
      agent {
        label 'docker-build-cn'
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

        //docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
        //  app.push("${BRANCH_NAME}-${BUILD_ID}")
        //}
      }

    }

    // deploy image to staging
    stage('Staging Deployment') {
      agent {
        label 'docker-build-cn'
      }
      when {
        branch 'staging'
      }
      steps {
        echo 'stage deploy'
      }
    }
    // approve deploy product ?
    stage('Go for Production?') {
      agent {
        label 'docker-build-cn'
      }
      steps {
        echo 'stage deploy'
        echo 'kubectl set image deployment_name=${IMAGE_REPO}:${BUILD_ID}'
      }
    }
    // deploy production
    stage('Production Deployment') {
      agent {
        label 'docker-build-cn'
      }
      when {
        tag "v*"
      }
      steps {
        echo 'product deploy'
        echo '${tag}'
        echo 'kubectl set image deployment_name=${IMAGE_REPO}:${BRANCH_NAME}'
        echo 'kubectl set image deployment_name=${IMAGE_REPO}:${tag}'
      }
    }


  }

}