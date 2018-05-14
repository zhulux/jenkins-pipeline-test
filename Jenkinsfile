node('docker-build-cn') {
    environment {
        IMAGE_NAME=optimus
    }

    stage('Clone repository'){
        label 'docker-build-cn'
        check scm
        sh "git rev-parse --short=8 > .git/commit-id"
        def commit_id = readFile('.git/commit-id').trim()
        println commit_id

    }

    stage('Build Image'){
        label 'docker-build-cn'
        def app = docker.build $IMAGE_NAME

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
