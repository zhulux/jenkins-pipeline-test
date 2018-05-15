#!groovy

node('docker-build-cn') {
    def app

    stage('Clone repository'){
        label 'docker-build-cn'
        checkout scm 
        sh "git rev-parse HEAD > .git/commit-id"
        def commit_id = readFile('.git/commit-id').trim()
        println commit_id
        app = docker.build("helloworld")
    }
    stage('Test image'){
        echo 'TODO: add tests'
    }

    stage('Publish Image to Registry'){
        label 'docker-build-cn'
        docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
            app.push("${BRANCH_NAME}")
            app.push("${CHANGE_ID}")
        }
    }
}

node('k8s') {
    stage('Staging Deployment'){
        echo "deploy staging"
        sh "date"
    }
    stage('Go for Production?'){
        milestone(1)
        input 'Deploy to Production?'
        milestone(2)
    }
    stage('Production Deployment'){
        echo "deploy to product"

    }

}

