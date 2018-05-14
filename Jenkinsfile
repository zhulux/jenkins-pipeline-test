node('docker-build-cn') {
    def IMAGE_NAME=optimus
    def app

    stage('Clone repository'){
        label 'docker-build-cn'
        checkout scm
        sh "git rev-parse HEAD > .git/commit-id"
        def commit_id = readFile('.git/commit-id').trim()
        println commit_id

    }

    stage('Build Image'){
        app = docker.build("optimus/helloworld")

    }

    stage('Test image'){
        echo 'TODO: add tests'
    }
    stage('Publish Image to Registry'){
        label 'docker-build-cn'
        docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
            app.push 'master'
            app.push $commit_id
        }
    }
    stage('Staging Deployment'){
        echo "deploy staging"
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
