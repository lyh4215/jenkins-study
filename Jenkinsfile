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
                expression { env.IS_PR == 'true' }
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
. app/venv/bin/activate
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
            tools: [
                cobertura(
                pattern: 'coverage.xml'
                )
            ],
            globalThresholds: [
                lineCoverage: 70
            ]
            )

            echo "🏁 Build finished with status: ${currentBuild.currentResult}"
        }
        aborted {
            echo '⛔ Deployment was aborted by user'
        }

    }
}
