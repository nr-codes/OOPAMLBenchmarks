#!/usr/bin/env bash

cd ../
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
  echo 'REMOTE' > docker_remote_oop.sh"
HORIZON="${HORIZON//REMOTE/$HORIZON_REMOTE}"

AMPLIFY="tar -xvf aml.tgz && cd aml && \
  echo 'REMOTE' > docker_remote_ampl.sh"
AMPLIFY="${AMPLIFY//REMOTE/$AMPL_REMOTE}"

# copy content and run
cp -r src/urdf src/replay oop/

tar -czvf oop.tgz oop
tar -czvf aml.tgz aml

docker run -d --rm -v /tmp/.X11-unix:/tmp/.X11-unix --name ${CONTAINER_NAME} \
  --env=DISPLAY --network="host" ${IMAGE} sleep infinity

docker cp ./src/ampl.linux64.tgz "${CONTAINER_NAME}:/home/user"
docker exec borealis bash -c "${AMPL}"
docker exec borealis bash -c "ampl/amplkey activate --uuid ${KEY}"

docker cp ./aml.tgz "${CONTAINER_NAME}:/home/user"
docker exec borealis bash -c "${AMPLIFY}"

docker cp ./oop.tgz "${CONTAINER_NAME}:/home/user"
docker exec borealis bash -c "${HORIZON}"

# uncomment to debug/run code in the container
# might be useful to comment other lines
docker exec "${CONTAINER_NAME}" bash -c "${VIM}"
docker exec -it "${CONTAINER_NAME}" bash

docker stop "${CONTAINER_NAME}"

rm oop.tgz aml.tgz
cd src/
