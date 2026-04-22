#!/usr/bin/env bash

# turn off '&' replacement with docker_remote_template in bash 5.2 and later
shopt -u patsub_replacement

# get number of runs
runs="${1:-10}"

# template script to run in docker container
read -r -d '' REMOTE < src/docker_remote_template.sh

# ampl version
AMPL_REMOTE="~/ampl/ampl"
AMPL_REMOTE="${REMOTE//RUN/$AMPL_REMOTE}"
AMPL_REMOTE="${AMPL_REMOTE//SCRIPT/run}"
AMPL_REMOTE="${AMPL_REMOTE//LIB/aml}"
AMPL_REMOTE="${AMPL_REMOTE//OUT/out}"

# oop version
HORIZON_REMOTE="python3"
HORIZON_REMOTE="${REMOTE//RUN/$HORIZON_REMOTE}"
HORIZON_REMOTE="${HORIZON_REMOTE//SCRIPT/py}"
HORIZON_REMOTE="${HORIZON_REMOTE//LIB/oop}"
HORIZON_REMOTE="${HORIZON_REMOTE//OUT/mat}"

# container info
IMAGE=francescoruscelli/horizon
CONTAINER_NAME=borealis

AMPL="tar -xvf ampl.linux64.tgz && mv ampl.linux-intel64 ampl"
KEY="" # insert your key here
VIM="sudo apt update && sudo apt install vim -y"

HORIZON="tar -xvf oop.tgz && cd oop && \
  echo 'REMOTE' > docker_remote_oop.sh && . docker_remote_oop.sh"
HORIZON="${HORIZON//REMOTE/$HORIZON_REMOTE}"

AMPLIFY="tar -xvf aml.tgz && cd aml && \
  echo 'REMOTE' > docker_remote_ampl.sh && . docker_remote_ampl.sh"
AMPLIFY="${AMPLIFY//REMOTE/$AMPL_REMOTE}"

# copy content and run
cp -r src/urdf src/replay oop/

tar -czvf oop.tgz oop
tar -czvf aml.tgz aml

for ((i = 1; i <= runs; i++)); do
  echo "----------- run $i of $runs"
  docker run -d --rm --name ${CONTAINER_NAME} --network="host" ${IMAGE} sleep infinity

  docker cp ./src/ampl.linux64.tgz "${CONTAINER_NAME}:/home/user"
  docker exec borealis bash -c "${AMPL}"
  docker exec borealis bash -c "ampl/amplkey activate --uuid ${KEY}"

  docker cp ./aml.tgz "${CONTAINER_NAME}:/home/user"
  docker exec borealis bash -c "${AMPLIFY}"

  docker cp ./oop.tgz "${CONTAINER_NAME}:/home/user"
  docker exec borealis bash -c "${HORIZON}"

  # uncomment to debug/run code in the container
  # might be useful to comment other lines
  #docker exec "${CONTAINER_NAME}" bash -c "${VIM}"
  #docker exec -it "${CONTAINER_NAME}" bash

  docker cp "${CONTAINER_NAME}:/home/user/oop_out.tgz" .
  docker cp "${CONTAINER_NAME}:/home/user/aml_out.tgz" .

  docker stop "${CONTAINER_NAME}"
  sleep 10 # fragile, but consistent in avoiding CONTAINER_NAME errors

  tar -xvf oop_out.tgz
  tar -xvf aml_out.tgz
done

./src/parse_ipopt.awk aml_out/*.txt oop_out/*.txt > ipopt_output.csv

tar -czvf ipopt_runs.tgz oop_out/*.txt oop_out/*.mat \
  aml_out/*.txt aml_out/*.out ipopt_output.csv oop aml

rm oop.tgz aml.tgz oop_out.tgz aml_out.tgz
rm -r oop_out aml_out
