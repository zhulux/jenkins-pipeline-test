#!groovy
pipeline {
  agent none
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
      steps {
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