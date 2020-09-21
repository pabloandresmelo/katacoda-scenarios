#!/bin/bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Globals
#
DEBUG=false
GITHUB="github.com"
GITHUBAPIURL="https://api.github.com"
COLQUESTION="\u001b[36m"
COLINFO="\u001b[37m"
COLLOGS="\u001b[35m"
COLRESET="\u001b[m"
REPO=pet-clinic
ORGREPO=dxc-technology

if [ "$DEBUG" = false ] ; then
  CURL_NODEBUG="-sS"
fi

# Install Python pre-req
echo -e "${COLINFO}Instalando dependencias ...${COLRESET}"
2>/dev/null 1>/dev/null python3 -m pip install pyyaml requests

#
# Ask for GitHub PAT
#
echo -e "${COLQUESTION}Por favor crea e ingresa tu token de acceso personal generado en ${GITHUB} at https://${GITHUB}/settings/tokens:${COLRESET}"
read TOKEN
export TOKEN

echo -e "${COLLOGS} Obteniendo la informacion desde GitHub ......${COLRESET}"
USER_JSON=$(curl ${CURL_NODEBUG} -H "Authorization: token ${TOKEN}" -H "Accept: application/vnd.github.v3+json" -X GET ${GITHUBAPIURL}/user)

SHORTNAME=$(echo $USER_JSON | jq -r '.login')
export SHORTNAME

EMAIL=$(echo $USER_JSON | jq -r '.email//empty')
if [ -z "$EMAIL" ]; then
  EMAIL=${SHORTNAME}@noemail.com
fi
export EMAIL
git config --global user.email "${EMAIL}"

check_credentials()
{
  curl ${CURL_NODEBUG} -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3+json" -X GET ${GITHUBAPIURL} | grep "current_user_url"
  CREDS_NOT_OK=$?
  if [ $CREDS_NOT_OK -ne 0 ]; then
    echo -e "${COLQUESTION}Error: Al parecer tus credenciales no son válidas. Por favor ingresa a tu cuenta de GitHub y crea un token de acceso personal con el permiso de 'repo' y 'admin: repo_hook' ingresando a la direccion, en tu navegador web.  https://github.com/settings/tokens/new ${COLRESET}"
    exit -1
  fi
}
check_credentials

# Copy the repository template https://github.com/dxc-technology/pet-clinic to the user
pet_clinic_copy()
{
  echo -e "${COLINFO}Copiando.. $REPO a los repositorios del usuario..${COLRESET}"
  echo -e "${COLLOGS}"

  # Clone the template repository
  rm -fr /tmp/${REPO}
  git clone https://$TOKEN@${GITHUB}/${ORGREPO}/${REPO}.git /tmp/${REPO}
  cd /tmp/${REPO}
  rm -fR .git
  git init
  git remote add origin https://$SHORTNAME:$TOKEN@${GITHUB}/${SHORTNAME}/${REPO}.git

  git add LICENSE
  git commit -m "agregando la información de uso y licenciamiento.."
  git push origin master

  # Disable vulnerability alerts
  curl --location --request DELETE $GITHUBAPIURL/repos/$SHORTNAME/$REPO/vulnerability-alerts \
    --header 'Accept: application/vnd.github.dorian-preview+json' \
    --header "Authorization: token $TOKEN" \
    --header 'Cookie: logged_in=no'
  
  git add -f .
  git commit -m "Realizando el commit inicia para la aplicación Pet Clinic"
  git push origin master
  cd -
}

# Check if user repository already exists
echo -e "${COLLOGS}"
curl ${CURL_NODEBUG} -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3+json" -X GET ${GITHUBAPIURL}/repos/$SHORTNAME/$REPO/contents/Jenkinsfile | grep "Not Found"
REPO_DOES_NOT_EXIST=$?
if [ $REPO_DOES_NOT_EXIST -eq 0 ]; then
  curl ${CURL_NODEBUG} -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3+json" -X POST --data "{\"name\":\"${REPO}\"}" ${GITHUBAPIURL}/user/repos | grep "Not Found"
  USER_HAS_NO_ACCESS_TO_REPO=$?
  if [ $USER_HAS_NO_ACCESS_TO_REPO -eq 0 ]; then
    echo -e "${COLQUESTION} Error: Al parecer tus credenciales no son válidas. Por favor ingresa a tu cuenta de GitHub y crea un token de acceso personal con el permiso de 'repo' y 'admin: repo_hook' ingresando a la direccion, en tu navegador web.  https://github.com/settings/tokens/new${COLRESET}"
    exit 1
  fi
 
  curl ${CURL_NODEBUG} -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3+json" -X GET ${GITHUBAPIURL}/repos/${ORGREPO}/${REPO} | grep "Not Found"
  PETCLINIC_NOT_AVAILABLE=$?
  if [ $PETCLINIC_NOT_AVAILABLE -eq 0 ]; then
    echo -e "${COLQUESTION}Error: Hace falta un recurso para poder ejecutar el escenario. por favor envíe un problema a https://${GITHUB}/${ORGREPO}/devops-dojo/issues .${COLRESET}"
    exit 1
  else
    pet_clinic_copy
  fi
else
  echo -e "${COLINFO}Repository" https://${GITHUB}/${SHORTNAME}/${REPO} "already exists. Skipping.${COLRESET}"
fi

# Provision GitHub issue labels
python3 ./github-labels.py github-labels.yaml

# Provision user stories in GitHub
python3 ./github-issues.py github-issues.yaml

# Ready!
touch /tmp/petclinic_ready
echo -e "${COLINFO}You are all set! Click on 'CONTINUE'.${COLRESET}"
