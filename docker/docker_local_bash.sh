#!/usr/bin/env bash

# turn off '&' replacement with docker_remote_template in bash 5.2 and later
if shopt -p patsub_replacement &>/dev/null; then
  shopt -u patsub_replacement
fi

# default values
RUNS=10
KEY=""
HELP="Usage: $0 [--runs N] --key AMPL_KEY \
  \n  -h,--help         This help message. \
  \n  -r,--runs N       Run examples N times (default is 10). \
  \n  -k,--key AMPL_KEY (NEVER SHARE OR ADD TO A COMMIT) \
  \n                    AMPL examples require \
  \n                      1) an AMPL key provided as input to this script, and \
  \n                      2) the AMPL CLI as a compressed linux tarball.  It \
  \n                         must be stored in src/ as src/ampl.linux64.tgz. \
  \n                         The CLI can be downloaded with an AMPL account. \
  \n                         See https://portal.ampl.com/account/ampl.\n"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -k|--key)
      KEY="$2"
      shift 2
      ;;
    -r|--runs)
      RUNS="$2"
      shift 2
      ;;
    -h|--help)
      printf "$HELP"
      exit 0
      ;;
    *)
      echo "Unknown option: $1.  Use -h for options summary."
      exit 1
      ;;
  esac
done

if [[ -z "$KEY" || ! -e src/ampl.linux64.tgz ]]; then
  echo "$0: Missing AMPL key or CLI.  Provide missing pre-requisite(s).  Use -h for more info."
  exit 1
fi

# template script to run in docker container
read -r -d '' REMOTE < src/docker_remote_template.sh

# aml version
AML_REMOTE="~/ampl/ampl"
AML_REMOTE="${REMOTE//RUN/$AML_REMOTE}"
AML_REMOTE="${AML_REMOTE//SCRIPT/run}"
AML_REMOTE="${AML_REMOTE//LIB/aml}"
AML_REMOTE="${AML_REMOTE//OUT/out}"

# oop version
OOP_REMOTE="python3"
OOP_REMOTE="${REMOTE//RUN/$OOP_REMOTE}"
OOP_REMOTE="${OOP_REMOTE//SCRIPT/py}"
OOP_REMOTE="${OOP_REMOTE//LIB/oop}"
OOP_REMOTE="${OOP_REMOTE//OUT/mat}"

# container info
IMAGE=francescoruscelli/horizon
CONTAINER_NAME=borealis

AMPL="tar -xvf ampl.linux64.tgz && mv ampl.linux-intel64 ampl"
VIM="sudo apt update && sudo apt install vim -y"

OOP="tar -xvf oop.tgz && cd oop && \
  echo 'REMOTE' > docker_remote_oop.sh && . docker_remote_oop.sh"
OOP="${OOP//REMOTE/$OOP_REMOTE}"

AML="tar -xvf aml.tgz && cd aml && \
  echo 'REMOTE' > docker_remote_ampl.sh && . docker_remote_ampl.sh"
AML="${AML//REMOTE/$AML_REMOTE}"

# copy content and run
cp -r src/urdf src/replay oop/

tar -czvf oop.tgz oop
tar -czvf aml.tgz aml

for ((i = 1; i <= RUNS; i++)); do
  echo "----------- run $i of $RUNS"
  docker run -d --rm --name ${CONTAINER_NAME} --network="host" ${IMAGE} sleep infinity

  # AML
  docker cp ./src/ampl.linux64.tgz "${CONTAINER_NAME}:/home/user"
  docker exec borealis bash -c "${AMPL}"
  docker exec borealis bash -c "ampl/amplkey activate --uuid ${KEY}"

  docker cp ./aml.tgz "${CONTAINER_NAME}:/home/user"
  docker exec borealis bash -c "${AML}"

  docker cp "${CONTAINER_NAME}:/home/user/aml_out.tgz" .
  tar -xvf aml_out.tgz

  # OOP
  docker cp ./oop.tgz "${CONTAINER_NAME}:/home/user"
  docker exec borealis bash -c "${OOP}"
  docker cp "${CONTAINER_NAME}:/home/user/oop_out.tgz" .
  tar -xvf oop_out.tgz

  docker stop "${CONTAINER_NAME}"
  sleep 10 # fragile, but consistent in avoiding CONTAINER_NAME errors
done

./src/parse_ipopt.awk aml_out/*.txt oop_out/*.txt > ipopt_output.csv
cp src/ipopt_output.xlsx

tar -czvf ipopt_runs.tgz oop_out/*.txt oop_out/*.mat \
  aml_out/*.txt aml_out/*.out oop aml \
  ipopt_output.csv ipopt_output.xlsx 

rm oop.tgz aml.tgz oop_out.tgz aml_out.tgz
rm -r oop_out aml_out
