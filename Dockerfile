# Stage 1: Build (빌드 및 테스트 환경)
FROM python:3.10-slim AS builder
WORKDIR /build
COPY app/requirements.txt .
# 의존성을 특정 폴더(__pypackages__)에 설치
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Run (실제 운영 환경)
FROM python:3.10-slim
WORKDIR /app

# builder 스테이지에서 설치된 라이브러리만 쏙 빼오기
COPY --from=builder /root/.local /root/.local
# 소스 코드 복사
COPY app/ ./app/

# 환경 변수 설정 (설치된 라이브러리 경로 인식)
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONPATH=/app

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]