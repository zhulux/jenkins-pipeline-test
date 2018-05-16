#!groovy

node('docker-build-cn') {
    def app

    stage('Clone repository'){
        label 'docker-build-cn'
        checkout scm 
    }
    stage('Test image'){
        echo 'TODO: add tests'
    }

    stage('Publish Image to Registry'){
        label 'docker-build-cn'
        sh "git rev-parse HEAD > .git/commit-id"
        sh "echo -n `git rev-parse HEAD` | head -c 7 > .git/commit-id"
        sh "git describe --tags --abbrev=0 > .git/tag-id"
        def commit_id = readFile('.git/commit-id').trim()
        def tag_id = readFile('.git/tag-id').trim()
        println commit_id
        println tag_id

        app = docker.build("helloworld")
        docker.withRegistry('https://registry.astarup.com:5000/', '1466a13b-3c1d-4c7f-ae93-5a65487efd13') {
            app.push("${BRANCH_NAME}-${commit_id}")
            when {
                expression branch 'master'
            }
            steps {
                app.push("${tag_id}")
            }
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

