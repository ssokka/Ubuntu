#!/usr/bin/env sh

# 인코딩
# utf-8 lf

# 설명 및 사용 방법
# https://sjva.me/bbs/board.php?bo_table=tip&wr_id=1581


path=/app/data/command/gsa-gen.bash
curl -o ${path} https://raw.githubusercontent.com/ssokka/ubuntu/master/gsa-gen/gsa-gen.bash

if [[ -f "${path}" ]]; then
    apk add --no-cache bash
    which bash &>/dev/null
    if [[ $? == 0 ]]; then
        bash /app/data/command/gsa-gen.bash
    fi
fi
