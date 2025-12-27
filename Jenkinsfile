pipeline {
    agent none
    
    options {
        timestamps()
    }

    stages {
        stage('Init') {
            steps {
                script {
                    // PR 여부 판단 (GitHub + Gitea 모두 대응)
                    env.IS_PR = (
                        env.CHANGE_ID != null ||
                        (env.BRANCH_NAME != null && env.BRANCH_NAME.startsWith('PR-'))
                    ).toString()

                    echo "BRANCH_NAME = ${env.BRANCH_NAME}"
                    echo "CHANGE_ID   = ${env.CHANGE_ID}"
                    echo "IS_PR       = ${env.IS_PR}"
                }
            }
        }

        stage('Docker Phase') {
            agent {
                    docker {
                    image 'lyh4215/jenkins-ci-agent:latest'
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker'
                }
            }
            stages {
                stage('FastAPI Import Test') {
                    steps {
                        sh '''#!/usr/bin/env bash
                        set -euo pipefail
                        python - <<'EOF'
from app.main import app
print("FastAPI app import OK")
EOF
                        '''
                    }
                }

                stage('PR Checks') {
                    when {
                        expression { env.IS_PR == 'true' }
                    }
                    steps {
                        echo "🔍 Running PR checks for PR #${env.CHANGE_ID}"
                        sh '''#!/usr/bin/env bash
                        set -euo pipefail
                        pytest \
                        --cov=app \
                        --cov-report=xml \
                        --cov-report=term
                        '''
                    }
                }

                stage('Main Branch Tests & Coverage') {
                    when {
                        allOf {
                            branch 'main'
                            expression { env.IS_PR == 'false' }
                        }
                    }
                    steps {
                        echo "🧪 Running full test suite on main"
                        sh '''#!/usr/bin/env bash
                        set -euo pipefail
                        pytest \
                        --junitxml=reports/junit.xml \
                        --cov=app \
                        --cov-report=xml \
                        --cov-report=term
                        '''
                    }
                }



                stage('Test Report') {
                    when {
                        allOf {
                            branch 'main'
                            expression { env.IS_PR == 'false' }
                        }
                    }
                    steps {
                        junit 'reports/junit.xml'
                    }
                }

                stage('Extract Coverage') {
                    when {
                        expression { env.IS_PR == 'true' }
                    }
                    steps {
                        sh '''
                        python - <<'EOF'
import xml.etree.ElementTree as ET

root = ET.parse("coverage.xml").getroot()
line_rate = float(root.get("line-rate")) * 100

with open("coverage.txt", "w") as f:
    f.write(f"{line_rate:.2f}")
EOF
                        '''
                    }
                }

                    stage('Comment Coverage to PR') {
                when {
                    expression { return env.CHANGE_ID != null }
                }
                steps {
                    withCredentials([usernamePassword(credentialsId: 'jenkins-ci-app', 
                                                        passwordVariable: 'GITHUB_TOKEN', 
                                                        usernameVariable: 'GITHUB_APP_USER')]) {
                        script {
                            // 1. 데이터 준비 (Groovy 영역)
                            def report = readFile('coverage.txt').trim()
                            env.REPORT_DATA = "### ✅ Coverage Report\n\n```\n${report}\n```"
                            env.PR_NUMBER = env.CHANGE_ID
                            env.REPO_PATH = "lyh4215/jenkins-study"

                            // 2. 실행 (Shell 영역) - 작은따옴표 3개 사용
                            sh '''
                            JSON_PAYLOAD=$(python3 - <<'EOF'
import json, os
data = {'body': os.environ.get('REPORT_DATA', '')}
print(json.dumps(data))
EOF
                            )

                            curl -s -H "Authorization: token $GITHUB_TOKEN" \
                                -H "Content-Type: application/json" \
                                -X POST \
                                -d "$JSON_PAYLOAD" \
                                "https://api.github.com/repos/$REPO_PATH/issues/$PR_NUMBER/comments"
                            '''
                            }
                        }
                    }
                }

            }
        }
        

        stage('Build & Push Production Image') {
            agent { label 'built-in' }
            when {
                allOf {
                    branch 'main'
                    expression { currentBuild.currentResult == 'SUCCESS' }
                }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId : 'docker-pat',
                    passwordVariable: 'DOCKER_PASSWORD',
                    usernameVariable: 'DOCKER_USERNAME'
                )]) {
                // Docker Hub 로그인을 위해 withCredentials 사용 가능
                    script {
                        // 1. 운영용 이미지 빌드
                        def prodImage = docker.build("lyh4215/jenkins-study-app:latest", "-f Dockerfile .")
                        
                        // 2. 푸시 (로그인 세션 필요)
                        echo "Attempting Docker Login..."
                        sh label : 'DockerLogin', script: 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        
                        echo "Pushing Image..."
                        prodImage.push()
                    }
                }
            }
        }

        stage('Deploy (Approval)') {
            agent { label 'built-in' }
            when {
                allOf {
                    branch 'main'
                    expression { currentBuild.currentResult == 'SUCCESS' }
                    expression { env.IS_PR == 'false' }
                }
            }
            steps {
                script {
                    input message: '🚀 Deploy to production?',
                        ok: 'Deploy'
                }

                echo '🚀 Deploying application (fake)'
            }
        }

    }

    post {
        success {
            node('built-in') {echo '✅ Pipeline succeeded'}
        }
        failure {
            node('built-in') {echo '❌ Pipeline failed'}
        }
        unstable {
            node('built-in') {echo '⚠️ Pipeline unstable'}
        }
        always { node('built-in') {
            archiveArtifacts artifacts: 'reports/*.xml', allowEmptyArchive: true
            archiveArtifacts artifacts: 'coverage.xml', allowEmptyArchive: true

            recordCoverage(
            tools: [[
                parser: 'COBERTURA',
                pattern: 'coverage.xml'
            ]],
            id: 'coverage',
            name: 'Python Coverage',
            sourceCodeRetention: 'EVERY_BUILD',
            qualityGates: [
                [threshold: 70.0, metric: 'LINE', baseline: 'PROJECT'],
                [threshold: 60.0, metric: 'BRANCH', baseline: 'PROJECT']
            ]
            )


            echo "🏁 Build finished with status: ${currentBuild.currentResult}"
        }}
        aborted {node('built-in') {
            echo '⛔ Deployment was aborted by user'
        }}

    }
}
