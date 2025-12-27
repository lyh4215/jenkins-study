pipeline {
    agent any
    
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

        stage('Setup Python') {
            steps {
                sh '''
                python -m venv venv
                . venv/bin/activate
                pip install --upgrade pip
                pip install -r app/requirements.txt --cache-dir .pip-cache
                pip install pytest pytest-cov
                '''
            }
        }

        stage('FastAPI Import Test') {
            steps {
                sh '''#!/usr/bin/env bash
                set -euo pipefail
                . venv/bin/activate
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
. venv/bin/activate

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
. venv/bin/activate
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
                    def report = readFile('coverage.txt').trim()
                    
                    // 1. URL 직접 지정 (가장 확실함)
                    // 'lyh4215/your-repo-name' 부분을 실제 레포 이름으로 바꾸세요.
                    def repoFullName = "lyh4215/jenkins-study" 
                    def apiUrl = "https://api.github.com/repos/${repoFullName}/issues/${env.CHANGE_ID}/comments"
                    
                    // 2. JSON Body 생성 (Shell Injection 방지를 위해 single quote 사용)
                    def commentBody = "### ✅ Coverage Report\n\n```\n${report}\n```"
                    
                    // 3. 실행: ${GITHUB_TOKEN} 대신 \$GITHUB_TOKEN 을 써서 쉘 변수임을 명시 (보안 권장)
                    sh """
# Python에서 환경변수(os.environ)를 읽어 JSON으로 직렬화
        JSON_PAYLOAD=$(python3 - <<'EOF'
import json, os
data = {'body': os.environ['REPORT_DATA']}
print(json.dumps(data))
EOF
                        curl -s -H "Authorization: token $GITHUB_TOKEN" \
                            -X POST \
                            -H "Content-Type: application/json" \
                            -d '{"body": "$JSON_PAYLOAD"}' \
                            "${apiUrl}"
                    """
                    }
                }
            }
        }


        stage('Deploy (Approval)') {
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
            echo '✅ Pipeline succeeded'
        }
        failure {
            echo '❌ Pipeline failed'
        }
        unstable {
            echo '⚠️ Pipeline unstable'
        }
        always {
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
        }
        aborted {
            echo '⛔ Deployment was aborted by user'
        }

    }
}
