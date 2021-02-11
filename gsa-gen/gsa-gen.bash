#!/usr/bin/env bash

# 인코딩
# utf-8 lf

# GitHub
# https://github.com/ssokka/Ubuntu/tree/master/gsa-gen

timestamp(){
	echo "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

runtime() {
	local diff=$((($(date +"%s")-$1)))
	echo "$(timestamp) 소요 시간 | $((${diff}/3600))h:$((${diff}/60))m:$((${diff}%60))s"
}

requirements() {
	which bash &>/dev/null
	if [[ $? != 0 ]]; then
		echo -e "$(timestamp) Bash 설치\n"
		apk add --no-cache bash
		which bash &>/dev/null
		if [[ $? != 0 ]]; then
			echo -e "$(timestamp) ! Bash 설치 실패\n"
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
			source ${HOME}/google-cloud-sdk/completion.bash.inc
			source ${HOME}/google-cloud-sdk/path.bash.inc
			echo -e "$(timestamp) 구글 클라우드 SDK 삭제 명령어"
			echo -e "$(timestamp) rm -rf ${HOME}/google-cloud-sdk"
		else
			echo -e "$(timestamp) ! 구글 클라우드 SDK 설치 실패"
			exit
		fi
		echo
	else
		echo -e "$(timestamp) 구글 클라우드 SDK 업데이트"
		gcloud components update --quiet &>/dev/null
	fi
}

auth() {
	echo -e "$(timestamp) 구글 클라우드 SDK 자격 증명"
	while read -p "$(timestamp) 구글 계정 입력 | " GOOGLE_ACCOUNT; do
		if [[ "${GOOGLE_ACCOUNT}" == "" ]]; then
			echo -en "\033[1A\033[2K"
		else
			break
		fi
	done
	if [[ $(gcloud auth list 2>&1 | grep ${GOOGLE_ACCOUNT}) == "" ]]; then
		#gcloud auth revoke --all &>/dev/null
		echo -e "\n1. 웹 브라우저에서 아래 링크로 이동하세요."
		echo -e "2. 서비스 계정을 생성/수정할 구글 계정으로 로그인하세요."
		echo -e "3. Google Cloud SDK 엑세스 요청 화면에서 허용을 클릭하세요."
		echo -e "4. 인증 코드를 복사하세요."
		echo -e "5. 인증 코드 입력(Enter verification code)에 붙여넣으세요.\n"
		gcloud auth login
		if [[ $? != 0 ]]; then
			echo -e "\n$(timestamp) [오류] 구글 클라우드 SDK 자격 증명 실패"
			exit
		fi
	fi
	GOOGLE_ID=$(echo ${GOOGLE_ACCOUNT} | grep -Eo "\b^[A-Za-z0-9._%+-]+\b" | sed "s/\./-/g")
}

select_project() {
	gcloud config set account ${GOOGLE_ACCOUNT} &>/dev/null
	local list=$(gcloud projects list)
	echo --------------------------------------------------------------------------------
	echo -e "${list}"
	echo --------------------------------------------------------------------------------
	read -p "$(timestamp) PROJECT_ID 입력 | 빈칸 = 프로젝트 생성 | " PROJECT_ID
}

create_project() {
	if [[ -z ${PROJECT_ID} ]]; then
		while read -p "$(timestamp) 프로젝트 생성 ID 이름 입력 | " -e -i "rclone" PROJECT_NAME; do
			if [[ -z "${PROJECT_NAME}" ]]; then
				echo -en "\033[1A\033[2K"
			else
				break
			fi
		done
		while read -p "$(timestamp) 프로젝트 생성 번호 입력    | " -e -i "1" PROJECT_NUMBER; do
			if [[ -z "${PROJECT_NUMBER}" ]]; then
				echo -en "\033[1A\033[2K"
			else
				break
			fi
		done
		PROJECT_ID=${PROJECT_NAME}-$(printf "%05d" "${RANDOM}")$(printf "%05d" "${RANDOM}")
		PROJECT_NUMBER=$(printf "%02d" "${PROJECT_NUMBER}")
		echo -e "$(timestamp) 프로젝트 생성 ID   | ${PROJECT_ID}"
		echo -e "$(timestamp) 프로젝트 생성 이름 | ${GOOGLE_ID}-${PROJECT_NAME}"
		while read -p "$(timestamp) 프로젝트 생성 진행? [y|n] " choice; do
			case ${choice} in
				[yY] ) choice="true"; break;;
				[nN] ) choice="false"; break;;
				* ) echo -en "\033[1A\033[2K";;
			esac
		done
		if [[ "${choice}" == "true" ]]; then
			gcloud projects create ${PROJECT_ID} --name="${GOOGLE_ID}-${PROJECT_NAME}" &>/dev/null
			local code=$?
			# code=0 # 테스트
			if [[ ${code} != 0 ]]; then
				case ${code} in
					1)
						echo -e "$(timestamp) ! 프로젝트 ID 중복"
						PROJECT_ID=
						create_project
						;;
					2)
						echo -e "$(timestamp) ! 프로젝트 ID 규칙 오류"
						echo -e "$(timestamp) ! https://cloud.google.com/sdk/gcloud/reference/projects/create?hl=ko#PROJECT"
						;;
					*)
						echo -e "$(timestamp) ! 프로젝트 할당량 초과"
						echo -e "$(timestamp) ! https://cloud.google.com/resource-manager/docs/creating-managing-projects?hl=ko#managing_project_quotas"
						echo -e "$(timestamp) ! 오류 코드 번호 | ${code}"
						;; # 오류 코드 확인 필요
				esac
				exit
			fi
			sleep 0.25s
		else
			echo -e "$(timestamp) 구글 서비스 계정 생성 종료"
			echo --------------------------------------------------------------------------------
			exit
		fi
	fi
}

enable_api() {
	gcloud config set project ${PROJECT_ID} &>/dev/null
	local code=$?
	if [[ ${code} != 0 ]]; then
		echo -e "$(timestamp) ! 프로젝트 ID '${PROJECT_ID}' 조회 불가"
		exit
	fi
	local e_apis=("drive.googleapis.com") # 필수 APIs
	local d_apis="" # 불필요 APIs
	local filter="" # 필수 APIs 제외 필터
	local tmp="" # 필수 APIs 단일 라인
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
			echo -e "$(timestamp) - ${line}"
		done <<< $(gcloud services list --filter="${filter}" --format="table(TITLE)" | sed 1d)
		gcloud services disable --force ${d_apis:0:-1} &>/dev/null
	fi
	echo -e "$(timestamp) 구글 드라이브 API 사용"
	gcloud services enable ${e_apis} &>/dev/null
}

create_sa() {
	# 2020.08.12
	# 서비스 계정 키를 다시 다운로드할 방법이 없다.
	# 서비스 계정 키 중복을 회피하는 간단한 방법은
	# 서비스 계정을 모두 삭제한 후 다시 생성하면 된다.
	gcloud config set project ${PROJECT_ID} &>/dev/null
	if [[ -z ${PROJECT_NAME} ]]; then
		PROJECT_NAME=$(gcloud projects list --filter="${PROJECT_ID}" --format="table(NAME)" | sed 1d)
	fi
	if [[ -z ${PROJECT_NUMBER} ]]; then
		PROJECT_NUMBER=$(echo ${PROJECT_ID} | cut -f 1 -d'-' | grep -Eo '[0-9]+' | sed -n '1p')
		PROJECT_NUMBER=$(printf "%02d" ${PROJECT_NUMBER})
	fi
	local items=$(gcloud iam service-accounts list --format="table(EMAIL)" | sed 1d) # 서비스 계정 이메일 목록
	local total=$(echo "${items}" | wc -l) # 서비스 계정 전체 개수
	total=$(printf "%03d" ${total})
	if [[ -n "${items}" ]]; then # 서비스 계정 키 중복 방지
		local count=1
		local stime=$(date +"%s")
		for item in ${items}; do
			echo -en "$(timestamp) 기존 서비스 계정 삭제 | 키 중복 방지 | $(printf "%03d" ${count})/${total}\r"
			gcloud iam service-accounts delete ${item} --quiet &>/dev/null
			((count++))
		done
		echo
		runtime ${stime}
	fi
	WORK_FOLDER=${HOME}/accounts # 기본 작업 폴더
	SJVA_FOLDER="/app/data/rclone_expand" # SJVA 도커 Rclone Expand 작업 폴더
	if [[ -f "/app/sjva.py" ]]; then
		WORK_FOLDER=${SJVA_FOLDER}
	fi
	while read -p "$(timestamp) 서비스 계정 키 폴더 경로 | " -e -i "${WORK_FOLDER}" WORK_FOLDER; do
		if [[ ! -d "${WORK_FOLDER}" ]]; then
			read -p "$(timestamp) 해당 경로 폴더 생성? [y|n] " choice
			case ${choice:0:1} in
				y|Y)
					mkdir -p "${WORK_FOLDER}"
					if [[ -d "${WORK_FOLDER}" ]]; then
						break
					fi
				;;
			esac
		else
			break
		fi
	done
	local tes="" # 서비스 계정 이메일 전체 내용
	local ess=",\n" # 서비스 계정 이메일 내용 구분자
	read -p "$(timestamp) 서비스 계정 최대 개수 입력 | " -e -i "100" limit
	local stime=$(date +"%s")
	for index in $(seq 1 ${limit}); do
		if [[ ${index} == ${limit} ]]; then
			ess=""
		fi
		str_index=$(printf "%03d" ${index})
		str_limit=$(printf "%03d" ${limit})
		local name="${GOOGLE_ID}-p${PROJECT_NUMBER}-sa${str_index}"
		local json="${PROJECT_NAME}-sa${str_index}.json"
		local mail="${name}@${PROJECT_ID}.iam.gserviceaccount.com"
		echo -en "$(timestamp) 서비스 계정 생성 | ${name} | ${str_index}/${str_limit}\r"
		gcloud iam service-accounts create ${name} &>/dev/null
		gcloud iam service-accounts keys create "${WORK_FOLDER}/${json}" --iam-account=${mail} &>/dev/null
		if [[ ${tes} != *"${mail}"* ]]; then
			tes+=${mail}${ess}
		fi
    done
	echo
	runtime ${stime}
	SA_EMAIL="${WORK_FOLDER}/${PROJECT_NAME}.txt"
	touch "${SA_EMAIL}"
	echo -e ${tes} > "${SA_EMAIL}"
}

check() {
	gcloud iam service-accounts list --format="table(EMAIL)" > count.temp
	s_count=$(cat "count.temp" | sed 1d | wc -l)
	rm -f count.temp
	echo --------------------------------------------------------------------------------
	echo -e "$(timestamp) 구글 계정                 ${GOOGLE_ACCOUNT}"
	echo -e "$(timestamp) 프로젝트 ID               ${PROJECT_ID}"
	echo -e "$(timestamp) 프로젝트 이름             ${PROJECT_NAME}"
	echo -e "$(timestamp) 서비스 계정               ${s_count}개"
	echo -e "$(timestamp) 서비스 계정 이메일        $(cat "${SA_EMAIL}" | wc -l)개"
	echo -e "$(timestamp) 서비스 계정 키 폴더 경로  ${WORK_FOLDER}"
	echo -e "$(timestamp) 서비스 계정 키 파일       $(ls "${WORK_FOLDER}" | grep "${PROJECT_NAME}-sa" | wc -l)개"
	echo --------------------------------------------------------------------------------
	read -p "$(timestamp) 서비스 계정 키 파일 확인? [y|n] " choice
	case ${choice:0:1} in
		y|Y)
			echo --------------------------------------------------------------------------------
			ls "${WORK_FOLDER}" | grep "${PROJECT_NAME}-sa"
		;;
	esac
	echo --------------------------------------------------------------------------------
	read -p "$(timestamp) 서비스 계정 이메일 확인? [y|n] " choice
	case ${choice:0:1} in
		y|Y)
			echo --------------------------------------------------------------------------------
			cat "${SA_EMAIL}"
		;;
	esac
}

echo --------------------------------------------------------------------------------
echo -e "$(timestamp) 구글 서비스 계정 생성 시작"
echo --------------------------------------------------------------------------------
requirements
auth
select_project
create_project
enable_api
create_sa
check
echo --------------------------------------------------------------------------------
echo -e "$(timestamp) 구글 서비스 계정 생성 완료"
echo --------------------------------------------------------------------------------
