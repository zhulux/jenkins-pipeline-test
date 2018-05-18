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
        sh "git rev-parse HEAD > .git/commit-id"
        sh "echo -n `git rev-parse HEAD` | head -c 7 > .git/commit-id"
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

      }
      steps {
        //when {
          //expression { env.BRANCH_NAME ==~ /v.*/}
         //sh "git describe --tags --abbrev=0 > .git/tag-id"
        //}
        echo 'publish image'
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