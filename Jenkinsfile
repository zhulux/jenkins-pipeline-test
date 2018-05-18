#!groovy
pipeline {
  agent none

  environment {
    IMAGE_REPO = "registry.astarup.com:5000/helloworld"
  }
  stages {
    // clone repo step
    stage('Clone Repository') {
      agent {
        label 'docker-build-cn'
      }
      steps {
        checkout scm
      }
      when { branch 'staging' }
        steps {
          sh "git rev-parse HEAD > .git/commit-id"
          sh "echo -n `git rev-parse HEAD` | head -c 7 > .git/commit-id"
        }
      when { tag "v.*" }
        steps {
          sh "git describe --tags --abbrev=0 > .git/tag-id"
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
        tag_id = readFile('.git/tag-id').trim()
      }
      steps {
        //when {
          //expression { env.BRANCH_NAME ==~ /v.*/}
         //sh "git describe --tags --abbrev=0 > .git/tag-id"
        //}
        echo 'publish image'
        echo commit_id
        echo tag_id

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
      }
    }
    // deploy production
    stage('Production Deployment') {
      agent {
        label 'docker-build-cn'
      }
      steps {
        echo 'product deploy'
      }
    }


  }

}