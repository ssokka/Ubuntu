#!/usr/bin/env sh

# 인코딩
# utf-8 lf

# 설명 및 사용 방법
# https://sjva.me/bbs/board.php?bo_table=tip&wr_id=1581

path=/app/data/command/gsa-gen.bash
curl -o ${path} https://raw.githubusercontent.com/ssokka/ubuntu/master/gsa-gen.bash
sed -i '1s/bash/sh/' ${path}
sh /app/data/command/gsa-gen.bash
