# [구글 서비스 계정](https://cloud.google.com/iam/docs/service-accounts?hl=ko)

- 구글 계정당 12개 프로젝트 생성 가능 (삭제 대기 프로젝트 포함)
- 30일 후 삭제 대기 프로젝트 완전 삭제
- 프로젝트당 서비스 계정 생성 최대 개수 100개 [참고](https://cloud.google.com/iam/docs/faq#what_is_the_maximum_number_of_service_accounts_i_can_have_in_a_project)
- 구글 서비스 계정당 일일 업로드 제한 750GByte


# 스크립트

## 특징

- 불필요한 Google APIs 제거
- 프로젝트 ID, 서비스 ID, 키 파일 이름 생성 규칙 적용
- 서비스 계정 키 중복 방지 (기존 서비스 계정 삭제)
- 서비스 계정 이메일 목록 파일 생성
- Sh SHELL (SJVA Docker) 환경 실행 가능


## 개발 환경

- Windows 10 x64 WSL2 Uuntu 20.04 TLS


## 실행 환경

- Ubuntu
- Windows 10 WSL Ubuntu
- SJVA Docker


## 요구 조건

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive#silent)
  - 자동 설치됩니다.
  - 삭제 명령어
  |번호|명령어|
  |:---:|:---|
  |1|```rm -rf ${HOME}/google-cloud-sdk & rm -rf ${HOME}/.config/gcloud```|

- Bash Shell
  - Sh Shell 환경(SJVA Docker)일 경우 자동 설치됩니다.

## 변수

- PROJECT_NAME=""
  - 프로젝트 이름
    - 사용 시
      - 지정한 이름대로 사용됩니다.
      - 3개 변수(PROJECT_START, PROJECT_END, PROJECT_SUFFIX)는 무시됩니다.
    - 미사용 시
      - 자동으로 지정됩니다.
      - 형식 xxx-p01-sa008@xxx-rclone01

- PROJECT_START=1
  - 프로젝트 시작 번호

- PROJECT_END=1
  - 프로젝트 종료 번호

- PROJECT_SUFFIX=rclone
  - 프로젝트 이름 접미사

- SAS_LIMIT=100
  - 서비스 계정 생성 개수

- DIR_WORK=${HOME}
  - 기본 작업 폴더

- DIR_KEY=accounts
  - 서비스 계정 키 폴더

- DIR_SJVA_WORK="/app/data/rclone_expand"
  - SJVA Docker Rclone Expand 작업 폴더


# gsa-gen.bash

## 실행 환경
- Ubuntu
- Windows 10 WSL Ubuntu
- 기타 Bash Shell

## 변수 값 기본 사용

|번호|명령어|
|:---:|:---|
|1|```curl -O https://raw.githubusercontent.com/ssokka/ubuntu/master/gsa-gen/gsa-gen.bash && bash gsa-gen.bash```|

## 변수 값 수정 사용

|번호|명령어|
|:---:|:---|
|1|```curl -O https://raw.githubusercontent.com/ssokka/ubuntu/master/gsa-gen/gsa-gen.bash```|
|2|```vi gsa-gen.bash```|
||변수 값 수정|
|3|```bash gsa-gen.bash```|


# gsa-gen.sh

## 실행 환경
- SJVA Docker
- 기타 Sh Shell

## 변수 값 기본 사용
- SJVA Docker 사용 시 실행 위치
  - SJVA 웹 >> 시스템 >> Command

|번호|명령어|
|:---:|:---|
|1|```curl -o /app/data/command/gsa-gen.sh https://raw.githubusercontent.com/ssokka/ubuntu/master/gsa-gen/gsa-gen.sh```|
|참고|첫 실행 시 장시간 화면이 멈춰있다면 "닫기" 후 다시 "실행"|
|2|```sh /app/data/command/gsa-gen.sh```|

## 변수 값 수정 사용

|번호|명령어|
|:---:|:---|
|1|```curl -o /app/data/command/gsa-gen.bash https://raw.githubusercontent.com/ssokka/ubuntu/master/gsa-gen.bash```|
|2|```vi gsa-gen.bash```|
||변수 값 수정|
|3|```apk add --no-cache bash```|
|4|```bash /app/data/command/gsa-gen.bash```|


## 생성 규칙 (예시)

- 서비스 계정 이메일
  - xxx-p01-sa008@xxx-rclone01.iam.gserviceaccount.com
- 서비스 계정 키 파일
  - xxx-p01-sa001@xxx-rclone01.json
- xxx
  - 구글 ID
- p01
  - 프로젝트 번호
- sa001
  - 서비스 계정 번호
- rclone01
  - 프로젝트 이름


## 업데이트 내역

  - 2020.08.14-02
    - 실행 파일 분리 : gsa-gen.bash, gsa-gen.sh
  - 2020.08.14-01
    - 구글 클라우드 SDK 설치 방식 변경 : 압축 해제
    - 구글 클라우드 SDK 자격 증명 간단 도움말 추가
    - 프로젝트명, 서비스 계정명, 키 파일명 규칙 변경
    - 소요 시간 표시
    - SJVA 도커 환경 실행 가능
  - 2020.08.13-01 
    - 구글 클라우드 SDK 자격 증명 계정 오류 수정 
  - 2020.08.12-04
    - 서비스 키 확인 수 0개 오류 수정
    - 서비스 계정 생성 사이 지연 시간 제거
    - 한줄 실행 명령어 변경
  - 2020.08.12-03
    - 서비스 계정 키 다중 생성 방지
    - 기존 프로젝트에 대한 서비스 계정 다시 생성
  - 2020.08.12-02
    - 서비스 계정 생성 사이 지연 시간 적용
  - 2020.08.12-01
    - 최초 배포


## 스크린샷

### Windows 10 x64 WSL2 Uuntu 20.04 TLS

![](https://cdn.discordapp.com/attachments/700986162201755689/743827576715214949/unknown.png)

### SJVA Docker (SJVA 웹 >> 시스템 >> Command)

![](https://cdn.discordapp.com/attachments/700986162201755689/743735960096735283/unknown.png)

![](https://cdn.discordapp.com/attachments/700986162201755689/743737409052606514/unknown.png)

![](https://cdn.discordapp.com/attachments/700986162201755689/743737436005204069/unknown.png)

![](https://cdn.discordapp.com/attachments/700986162201755689/743737464019222628/unknown.png)

![](https://cdn.discordapp.com/attachments/700986162201755689/743737490577555466/unknown.png)

### SJVA Docker (SJVA 웹 >> 시스템 >> FileBrowser.xyz)

![](https://cdn.discordapp.com/attachments/700986162201755689/743738071454973962/unknown.png)


## 참고

- [구글 클라우드 SDK](https://cloud.google.com/sdk/docs?hl=ko)
- [gcloud](https://cloud.google.com/sdk/gcloud/reference?hl=ko)
- [sa-gen](https://github.com/88lex/sa-gen)
- [AutoRclone](https://github.com/xyou365/AutoRclone)
- [gclone](https://github.com/donwa/gclone)
