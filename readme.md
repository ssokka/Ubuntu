# 스크립트
- 설명  
  구글 서비스 계정 생성기
- 환경 
  리눅스 계열 bash
- 실행  
  curl https://raw.githubusercontent.com/ssokka/ubuntu/master/gsa-gen | bash -
- 확인 
  windows 10 x64 wsl2 ubuntu 20.04 tls

# 특징
- 불필요한 Google APIs 제거
- 서비스 계정 및 키 파일을 일정한 규칙으로 생성
- 구글 그룹스에 서비스 계정 추가 시 복사/붙여넣기용 텍스트 파일 생성

# 변수
- PROJECT_START=1  
  프로젝트 시작 번호
- PROJECT_END=1  
  프로젝트 종료 번호
- PROJECT_INFIX=rclone  
  프로젝트 이름 접요사
- NUM_SAS_PER_PROJECT=100  
  프로젝트 당 서비스 계정 수, 최대 100개
- DIR_WORK=$(pwd)  
  기본 저장 경로
- DIR_KEY=accounts  
  서비스 계정 키 저장 폴더

# 참고
- 프로젝트 명 규칙  
  구글_ID-PROJECT_INFIX-프로젝트_번호 [ex] test-rclone-01
- 구글 서비스 계정  
  https://cloud.google.com/iam/docs/service-accounts?hl=ko
- 구글 클라우드 SDK  
  https://cloud.google.com/sdk/docs?hl=ko
- gcloud  
  https://cloud.google.com/sdk/gcloud/reference?hl=ko
- sa-gen  
  https://github.com/88lex/sa-gen