pipeline {
    agent any

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
                pip install -r requirements.txt --cache-dir .pip-cache
                '''
            }
        }

        stage('FastAPI Import Test') {
            steps {
                sh '''#!/usr/bin/env bash
                set -euo pipefail
                . app/venv/bin/activate
                python - <<'EOF'
from app.main import app
print("FastAPI app import OK")
EOF
                '''
            }
        }

        stage('PR Checks') {
            when {
                expression { env.CHANGE_ID != null }
            }
            steps {
                echo "🔍 Running PR checks for PR #${env.CHANGE_ID}"
                sh '''#!/usr/bin/env bash
set -euo pipefail
. app/venv/bin/activate
pytest
        '''
            }
        }

        stage('Main Branch Tests') {
            when {
                allOf {
                    branch 'main'
                    expression { env.CHANGE_ID == null }
                }
            }
            steps {
                echo "🧪 Running full test suite on main"
                sh '''#!/usr/bin/env bash
set -euo pipefail
. app/venv/bin/activate
pytest --junitxml=reports/junit.xml
        '''
            }
        }



        stage('Test Report') {
            when {
                allOf {
                    branch 'main'
                    expression { env.CHANGE_ID == null }
                }
            }
            steps {
                junit 'reports/junit.xml'
            }
        }

        stage('Deploy (Fake)') {
            when {
                allOf {
                    branch 'main'
                    expression { currentBuild.currentResult == 'SUCCESS' }
                }
            }
            steps {
                echo '🚀 Deploying application to production server (fake)'
                echo '✅ Deployment completed'
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
            echo "🏁 Build finished with status: ${currentBuild.currentResult}"
        }
    }
}
