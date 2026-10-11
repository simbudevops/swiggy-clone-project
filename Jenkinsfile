pipeline {
    agent any

    tools {
        jdk 'java21'
        nodejs 'node23'
    }

    environment {
        // Name from: Manage Jenkins -> Tools -> SonarQube Scanner installations
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/simbudevops/swiggy-clone-project.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // Name from: Manage Jenkins -> System -> SonarQube servers
                withSonarQubeEnv('sonar') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Swiggy \
                        -Dsonar.projectKey=Swiggy
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    // Needs a webhook in SonarQube: http://<jenkins-ip>:8080/sonarqube-webhook/
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('TRIVY FS SCAN') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub-creds', toolName: 'docker') {
                        sh 'docker build -t swiggy .'
                        sh 'docker tag swiggy simbudevops/swiggy:latest'
                        sh 'docker push simbudevops/swiggy:latest'
                    }
                }
            }
        }

        stage('TRIVY Image Scan') {
            steps {
                sh 'trivy image simbudevops/swiggy:latest > trivy.txt'
            }
        }

        stage('Deploy to Container') {
            steps {
                sh 'docker rm -f swiggy || true'
                sh 'docker run -d --name swiggy -p 3000:3000 simbudevops/swiggy:latest'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivyfs.txt, trivy.txt', allowEmptyArchive: true
        }
    }
}
