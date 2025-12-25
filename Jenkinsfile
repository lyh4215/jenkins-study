pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code'
            }
        }

        stage('Setup Python') {
            steps {
                dir('app') {
                    sh '''#!/usr/bin/env bash
                    set -euo pipefail
                    python --version
                    python -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    '''
                }
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

        stage('Run Tests') {
            steps {
                sh '''#!/usr/bin/env bash
                set -euo pipefail
                . app/venv/bin/activate
                pytest
                '''
            }
        }

    }
}
