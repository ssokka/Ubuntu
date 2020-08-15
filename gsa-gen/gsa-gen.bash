#!/usr/bin/env bash

# 인코딩
# utf-8 lf

# GitHub
# https://github.com/ssokka/Ubuntu/tree/master/gsa-gen

# 프로젝트 이름, 기존 프로젝트 수정 시 사용
PROJECT_NAME=""

# 프로젝트 시작 번호
PROJECT_START=1

# 프로젝트 종료 번호
PROJECT_END=1

# 프로젝트명 접두사
PROJECT_PREFIX=rclone

# 프로젝트 당 서비스 계정 생성 개수, 최대 100개
SAS_LIMIT=100

# 기본 작업 폴더
DIR_WORK=${HOME}

# 서비스 계정 키 폴더
DIR_KEY=accounts

# SJVA 도커 Rclone Expand 작업 폴더
DIR_SJVA_WORK="/app/data/rclone_expand"

init() {
	if [[ -n "${PROJECT_NAME}" ]]; then
		PROJECT_START=1
		PROJECT_END=1
	fi
	if [[ PROJECT_END -gt 12 ]]; then
		PROJECT_END=12
	fi
	if [[ -f "/app/sjva.py" ]]; then
		DIR_WORK=${DIR_SJVA_WORK}
	fi
}

timestamp(){
	echo "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

runtime() {
	local diff=$((($(date +"%s")-$1)))
	echo "$(timestamp) + 소요 시간 $((${diff}/3600))h:$((${diff}/60))m:$((${diff}%60))s"
}

install() {
	which bash &>/dev/null
	if [[ $? != 0 ]]; then
		echo -e "$(timestamp) Bash 설치\n"
		apk add --no-cache bash
		which bash &>/dev/null
		if [[ $? != 0 ]]; then
			echo -e "$(timestamp) [ERROR] Bash 설치 실패\n"
			exit
		fi
		echo
	fi
	export PATH=$PATH:$HOME/google-cloud-sdk/bin
	which gcloud &>/dev/null
	if [[ $? != 0 ]]; then
		echo -e "$(timestamp) 구글 클라우드 SDK 설치\n"
		curl https://sdk.cloud.google.com > install.sh && bash install.sh --disable-prompts
		which gcloud &>/dev/null
		if [[ $? == 0 ]]; then
			echo -e "$(timestamp) 구글 클라우드 SDK 삭제 명령어"
			echo -e "$(timestamp) rm -rf ${HOME}/google-cloud-sdk"
		else
			echo -e "$(timestamp) [ERROR] 구글 클라우드 SDK 설치 실패"
			echo
			exit
		fi
		echo
	fi
}

auth() {
	gcloud auth revoke --all &>/dev/null
	echo -e "$(timestamp) 구글 클라우드 SDK 자격 증명"
	echo
	echo -e "   + 1. 웹 브라우저에서 아래 링크로 이동하세요."
	echo -e "   + 2. 서비스 계정을 생성/수정할 구글 계정으로 로그인하세요."
	echo -e "   + 3. Google Cloud SDK 엑세스 요청 화면에서 허용을 클릭하세요."
	echo -e "   + 4. 인증 코드를 복사하세요."
	echo -e "   + 5. 인증 코드 입력(Enter verification code)에 붙여넣으세요."
	echo
	gcloud auth login --brief
	if [[ $? != 0 ]]; then
		echo -e "$(timestamp) [ERROR] 구글 클라우드 SDK 자격 증명 실패"
		echo
		exit
	fi
	local pattern="\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b"
	ACCOUNT=$(gcloud auth list 2>&1 | grep -Eo ${pattern})
	if [[ "${ACCOUNT}" == "" ]]; then
		ACCOUNT=$(gcloud config list 2>&1 | grep -Eo ${pattern})
	fi
	if [[ "${ACCOUNT}" != "" ]]; then
		ID=$(echo ${ACCOUNT} | grep -Eo "\b^[A-Za-z0-9._%+-]+\b" | sed "s/\./-/g")
		echo -e "$(timestamp) 구글 계정 ${ACCOUNT}"
		gcloud config set account ${ACCOUNT} &>/dev/null
		echo
	else
		echo -e "$(timestamp) [ERROR] 구글 계정 확인 필요 ${ACCOUNT}"
		echo
		exit
	fi
}

create_projects() {
	if [[ -n "${PROJECT_NAME}" ]]; then
		# 기존 프로젝트 이름
		PROJECT=${PROJECT_NAME}
	else
		# 신규 프로젝트 이름 : xxx-rclone01
		# ${1:-} : 프로젝트 번호 by for loop
		PROJECT="${ID}-${PROJECT_PREFIX}${1:-}"
	fi
	
	gcloud config set project ${PROJECT} &>/dev/null
	echo -e "$(timestamp) 프로젝트 목록"
	local list=$(gcloud projects list)
	echo -e "${list}"
	echo
	if [[ ${list} != *"${PROJECT}"* ]]; then
		echo -e "$(timestamp) 프로젝트 생성 ${PROJECT}"
		gcloud projects create ${PROJECT} &>/dev/null
		local code=$?
		if [[ ${code} != 0 ]]; then
			echo -e "$(timestamp) [ERROR] 프로젝트 생성 불가 ${PROJECT}"
			case ${code} in
				1)
					echo -e "+ 프로젝트 ID 중복 ${PROJECT}"
					;;
				2)
					echo -e "+ 프로젝트 ID 규칙 오류"
					echo -e "  https://cloud.google.com/sdk/gcloud/reference/projects/create?hl=ko#PROJECT"
					;;
				*)
					echo -e "+ 프로젝트 할당량 초과"
					echo -e "  https://cloud.google.com/resource-manager/docs/creating-managing-projects?hl=ko#managing_project_quotas"
					echo -e "오류 코드 번호 : ${code}"
					;; # 오류 코드 확인 필요
			esac
			echo
			exit
		fi
		sleep 0.25s
	fi
	echo -e "$(timestamp) 프로젝트 선택 ${PROJECT}"
	gcloud config set project ${PROJECT} &>/dev/null
	echo
}

enable_apis() {
	# 필수 APIs
	local e_apis=("drive.googleapis.com")
	
	# 불필요 APIs
	local d_apis=""
	
	# 필수 APIs 제외 필터
	local filter=""
	
	# 필수 APIs 단일 라인
	local tmp=""
	
	for api in ${e_apis[@]}; do
		tmp+="${api} "
		filter+="NOT config.name=${api} AND "
	done
	filter=${filter:0:-5}
	
	for api in $(gcloud services list --filter="${filter}" --format="table(NAME)" | sed 1d); do
		d_apis+="${api} "
	done
	
	e_apis=${tmp:0:-1}
	
	if [[ "${d_apis}" != "" ]]; then
		echo -e "$(timestamp) 불필요한 API 사용 중지"
		while read -r line; do
			echo -e "- ${line}"
		done <<< $(gcloud services list --filter="${filter}" --format="table(TITLE)" | sed 1d)
		gcloud services disable --force ${d_apis:0:-1} &>/dev/null
		echo
	fi
	echo -e "$(timestamp) 구글 드라이브 API 사용"
	gcloud services enable ${e_apis} &>/dev/null
	echo
}

create_sas() {
	# 2020.08.12
	# 서비스 계정 키를 다시 다운로드할 방법이 없다.
	# 서비스 계정 키 중복을 회피하는 간단한 방법은
	# 서비스 계정을 모두 삭제한 후 다시 생성하면 된다.

	# 서비스 계정 목록
	local list=$(gcloud iam service-accounts list --format="table(EMAIL)" | sed 1d)

	# 서비스 계정 개수
	local total=$(echo "${list}" | wc -l)
	total=$(printf "%03d" ${total})

	# 서비스 계정 키 중복 방지
	if [[ -n "${list}" ]]; then
		local count=1
		local stime=$(date +"%s")
		for email in ${list}; do
			echo -en "$(timestamp) 기존 서비스 계정 삭제 (키 중복 방지) $(printf "%03d" ${count})/${total}개\r"
			gcloud iam service-accounts delete ${email} --quiet &>/dev/null
			((count++))
		done
		echo
		runtime ${stime}
		echo
	fi

	# 서비스 계정 이메일 전체 내용
	local tes=""

	# 서비스 계정 이메일 내용 구분자
	local ess=",\n"						

	# 서비스 계정 이메일 정보 파일 : account-rclone01-xxx.txt
	FILE_EMAIL="${DIR_WORK}/${PROJECT}.txt"
	touch "${FILE_EMAIL}"
	
	echo -e "$(timestamp) 서비스 계정"
	local stime=$(date +"%s")
	for num_s in $(seq 1 ${SAS_LIMIT}); do
		if [[ ${num_s} == ${SAS_LIMIT} ]]; then
			ess=""
		fi
		num_s=$(printf "%03d" ${num_s})
		SAS_LIMIT=$(printf "%03d" ${SAS_LIMIT})

		# 프로젝트 번호
		local num_p=${1:-}
		
		# 서비스 계정 이름 : xxx-p01-sa001
		local name="${ID}-p${num_p}-sa${num_s}"
		
		# 서비스 계정 이메일 접두사 : xxx-p01-sa001@xxx-rclone01
		local prefix=${name}@${PROJECT}
		
		# 서비스 계정 이메일
		local email=${prefix}.iam.gserviceaccount.com
		
		# 서비스 계정 생성
		echo -en "$(timestamp) + 생성   ${num_s}/${SAS_LIMIT}개 ${name}\r"
		gcloud iam service-accounts create ${name} &>/dev/null
		if [[ ${num_s} == ${SAS_LIMIT} ]]; then
			echo
		fi
		
		# 서비스 계정 키 생성
		echo -en "$(timestamp) + 키     ${num_s}/${SAS_LIMIT}개\r"
		gcloud iam service-accounts keys create "${DIR_WORK}/${DIR_KEY}/${prefix}.json" --iam-account=${email} &>/dev/null
		if [[ ${num_s} == ${SAS_LIMIT} ]]; then
			echo
		fi
		
		# 서비스 계정 이메일 저장
		echo -en "$(timestamp) + 이메일 ${num_s}/${SAS_LIMIT}개\r"
		if [[ ${tes} != *"${email}"* ]]; then
			tes+=${email}${ess}
		fi
		if [[ ${num_s} == ${SAS_LIMIT} ]]; then
			echo
		fi
    done
	runtime ${stime}
	echo -e ${tes} > "${FILE_EMAIL}"
}

check_sas() {
	sleep 1s
	echo
	echo -e "$(timestamp) 확인"
	echo -e "$(timestamp) + 프로젝트      ${PROJECT}"

	# 서비스 계정 개수 확인
	local cnt_s=$(gcloud iam service-accounts list --format="table(EMAIL)" | sed 1d | wc -l)
	echo -e "$(timestamp) + 서비스 계정   ${cnt_s}개"
	
	# 서비스 계정 키 개수 확인
	local cnt_k=0
	if [[ -d "${DIR_WORK}/${DIR_KEY}" ]]; then
		cnt_k=$(ls -al "${DIR_WORK}/${DIR_KEY}" | grep ".*@${PROJECT}\..*" | grep "^-" | awk "{print $9}" | wc -l)
	fi
	echo -e "$(timestamp) + 서비스 키     ${cnt_k}개, 폴더 ${DIR_WORK}/${DIR_KEY}/"
	
	# 서비스 계정 이메일 개수 확인
	local cnt_e=$(cat "${FILE_EMAIL}" | wc -l)
	echo -e "$(timestamp) + 서비스 이메일 ${cnt_e}개, 파일 ${FILE_EMAIL}"
	echo
}

sas_email() {
	if [[ -f "${FILE_EMAIL}" && $((${PROJECT_END}-${PROJECT_START})) == 0 ]]; then
		read -p "$(timestamp) 서비스 계정 이메일 확인 (y/n)? " answer
		case ${answer:0:1} in
			y|Y)
				cat "${FILE_EMAIL}"
			;;
		esac
		echo
	fi
}

main() {
	echo -e "\n$(timestamp) 구글 서비스 계정 생성 스크립트\n"
	init
	install
	auth
	for PROJECT_NUM in $(seq ${PROJECT_START} ${PROJECT_END}); do
		if [[ $((${PROJECT_END}-${PROJECT_START})) != 0 ]]; then
			echo
		fi
		for function in create_projects enable_apis create_sas check_sas sas_email; do
			eval ${function} $(printf "%02d" ${PROJECT_NUM})
		done
	done
}

main
