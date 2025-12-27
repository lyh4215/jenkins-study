# 1. 베이스 이미지 선택 (가벼운 slim 버전 권장)
FROM python:3.10-slim

# 2. 메타데이터 설정
LABEL maintainer="lyh4215"
LABEL description="Custom Python build agent for FastAPI CI"

# 3. 시스템 의존성 설치 (curl, git, jq 등 자주 쓰는 도구들)
# --no-install-recommends로 이미지 용량 최소화
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# 4. 파이썬 빌드 도구 및 테스트 라이브러리 미리 설치
# 이렇게 하면 Jenkins 실행 시 매번 설치할 필요가 없음
RUN pip install --no-cache-dir \
    pytest \
    pytest-cov \
    fastapi \
    httpx \
    uvicorn

# 5. 작업 디렉토리 설정 (Jenkins가 자동으로 마운트하지만 기본값 설정)
WORKDIR /app

# 6. (선택) Jenkins 유저 권한 이슈 방지를 위해 UID/GID 매칭이 필요할 수 있음
# 우선 기본 root로 진행 후 권한 에러 시 조정