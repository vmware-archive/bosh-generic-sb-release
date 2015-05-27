#!/bin/sh
echo ""
echo "  This script will customize the Service Broker Release and Ops Mgr Tile generation based on user inputs"
echo "  Things that would be customized include:"
echo "     - Custom defined dynamic variables/parameters that would be passed along as environment variables to the application "
echo "     - Expose the user defined parameters via the Tile UI"
echo "     - Use or not use persistence (mysql or custom database persistence)"
echo "     - Allow user to pull down external third party libraries that are required by the service broker app"
echo "     - Allow registration of either in-built or user defined plans"

echo ""
echo "Starting customization........"
 
echo ""
echo "Version of Pivotal Ops Mgr to deploy" 
printf "  Reply with 1.3 or 1.4 or other version: "
read opsMgrVersion
sed -i.bak "s/OPS_MGR_VERSION/${opsMgrVersion}/g" createTile.sh

echo ""
echo "Version for the Service Broker release" 
printf "  Reply with something like 1.0 or 1.3 or 1.4: "
read releaseVersion
sed -i.bak "s/RELEASE_VERSION/${releaseVersion}/g" createRelease.sh createTile.sh *tile-*.yml
rm *.bak

echo ""
echo "  Does the Service Broker Application require any configurable parameter/variables for its functioning"
echo "     Externalized parameters can be dynamic or user defined like some github access token"
echo "     and needs to be part of the Service Broker App via environment variable"
echo "     Example:  cf set-env ServiceBrokerApp <MyVariable> <TestValue>"
echo ""

printf "  Reply y or n: "
read requireEnvVariables
if [ "${requireEnvVariables:0:1}" == "y" ]; then
  specTmp="spec.tmp"
  propTmp="prop.tmp"
  erbTmp1="erb1.tmp"
  erbTmp2="erb2.tmp"
  tileTmp1="tile1.tmp"
  tileTmp2="tile2.tmp"
  tileTmp3="tile3.tmp"

  for tmp in  $specTmp $propTmp $erbTmp1 $erbTmp2 $tileTmp1 $tileTmp2 $tileTmp3
  do
    rm $tmp 2>/dev/null; touch $tmp
  done

  brokerName=`grep broker.app_name jobs/deploy-service-broker/spec `
  brokerName=`basename ${brokerName} '.app_name:' `
  while true
  do
    printf "    Variable name (without spaces, use _ instead of '.' or '-'), enter n to stop: "
    read variableName
    if [ "${variableName}" == "n" -o "${variableName}" == "no" ]; then
      break
    fi

    variableName=`echo $variableName | sed -e 's/ /_/g;s/-/_/g;s/\./_/g;' `
    echo "    Modified name (with spaces, '.', '-' converted to '_'): ${variableName}"
    echo ""
    printf "    Enter short description of Variable (spaces okay): "
    read variableLabel
    printf "    Enter long description of Variable (spaces okay): "
    read variableDescrp
    printf "    Enter a default value (use quotes if containing spaces): "
    read defaultValue
    if [ "$defaultValue" == "" ]; then
      defaultValue="_FILL_ME_"
    fi
    printf "    Should this be configurable or exposed to end-user, reply with y or n: "
    read exposable

    #variableName_upper=`echo $variableName | awk '{print toupper($0)}' `
    templated_variableName=TEMPLATE_${variableName}
    echo "export ${variableName}=${templated_variableName}"  >> src/templates/setupServiceBrokerEnv.sh
    echo "  ${brokerName}.${variableName}:"  >> $specTmp
    echo "    description: '${variableDescrp}'"  >> $specTmp
    echo "    default: '${defaultValue}'"  >> $specTmp

    echo "export ${variableName}=<%= properties.${brokerName}.${variableName} %>" >> $erbTmp1
    echo "  cf set-env \${APP_NAME}-\${APP_VERSION} $variableName \"\$${variableName}\" " >> $erbTmp2

    if [ "${exposable:0:1}" == "y" ]; then
#      echo "      - reference: .properties.${variableName}"  >> $tileTmp1
      echo "      - reference: .${variableName}"  >> $tileTmp1
      echo "        label: ${variableLabel}  "  >> $tileTmp1
      echo "        description: ${variableDescrp}  "  >> $tileTmp1
    fi

    echo "- name: ${variableName}"  >> $tileTmp2
    echo "  type: string "  >> $tileTmp2
    echo "  configurable: true" >> $tileTmp2
    echo "  default: ${defaultValue}" >> $tileTmp2

    echo "      ${variableName}: (( .properties.${variableName}.value ))"  >> $tileTmp3
    echo "    ${variableName}: ${defaultValue}"  >> $propTmp

    echo ""
  done

  sed -i.bak "/CUSTOM_VARIABLE_BEGIN_MARKER/r./${specTmp}" jobs/deploy-service-broker/spec
  sed -i.bak "/CUSTOM_VARIABLE_BEGIN_MARKER/r./${erbTmp1}" jobs/deploy-service-broker/templates/deploy.sh.erb
  sed -i.bak "/CUSTOM_VARIABLE_ENV_BEGIN_MARKER/r./${erbTmp2}" jobs/deploy-service-broker/templates/deploy.sh.erb

  sed -i.bak "/CUSTOM_VARIABLE_LABEL_BEGIN_MARKER/r./${tileTmp1}" *tile.yml 
  sed -i.bak "/CUSTOM_VARIABLE_DEFN_BEGIN_MARKER/r./${tileTmp2}" *tile.yml 
  sed -i.bak "/CUSTOM_VARIABLE_MANIFEST_BEGIN_MARKER/r./${tileTmp3}" *tile.yml
  sed -i.bak "/CUSTOM_VARIABLE_MANIFEST_BEGIN_MARKER/r./${propTmp}" templates/*properties.yml
  rm *.tmp
fi

echo ""
printf "Does the Service Broker need to download any external driver/library? Reply y or n : "
read downloadDriver
if [ "${downloadDriver:0:1}" == "n" ]; then
  sed -i.bak "/DRIVER_DOWNLOAD_BEGIN_MARKER/,/DRIVER_DOWNLOAD_END_MARKER/ { d; }" jobs/deploy-service-broker/spec jobs/deploy-service-broker/templates/deploy.sh.erb templates/*properties.yml  *tile.yml
fi

echo ""
printf "Does the Service Broker need a persistence store? Reply y or n : "
read persistenceStore
if [ "${persistenceStore:0:1}" == "y" ]; then
  printf "Can the Service Broker use CF's default MySQL Service (if available) for persistence? Reply y or n : "
  read persistenceStoreType
  if [ "${persistenceStoreType:0:1}" == "y" ]; then
    echo "Going with MySQL service binding for persistence"
    sed -i.bak "s/ persistence_store_type: .*/ persistence_store_type: mysql/g" templates/*properties.yml *tile.yml 
    sed -i.bak "/PERSISTENCE_STORE_BEGIN_MARKER/,/PERSISTENCE_STORE_END_MARKER/ { d; }" jobs/deploy-service-broker/spec jobs/deploy-service-broker/templates/deploy.sh.erb templates/*properties.yml  *tile.yml
  else
    echo "Going with Custom persistence"
    sed -i.bak "s/ persistence_store_type: .*/ persistence_store_type: custom/g" templates/*properties.yml *tile.yml 
  fi
else 
  sed -i.bak "s/ persistence_store_type: .*/ persistence_store_type: none/g" templates/*properties.yml *tile.yml 
  sed -i.bak "/PERSISTENCE_STORE_BEGIN_MARKER/,/PERSISTENCE_STORE_END_MARKER/ { d; }" jobs/deploy-service-broker/spec jobs/deploy-service-broker/templates/deploy.sh.erb templates/*properties.yml  *tile.yml
fi

echo ""
printf "Does the Service Broker need to manage a target service? Reply y or n : "
read targetService
if [ "${targetService:0:1}" == "n" ]; then
  sed -i.bak "/TARGET_SERVICE_BEGIN_MARKER/,/TARGET_SERVICE_END_MARKER/ { d; }" jobs/deploy-service-broker/spec jobs/deploy-service-broker/templates/deploy.sh.erb templates/*properties.yml  *tile.yml
fi

echo ""
printf "Does the Service Broker allow customized user defined plans? Reply y or n : "
read userPlans
if [ "${userPlans:0:1}" == "n" ]; then
  sed -i.bak "/ON_DEMAND_PLAN_BEGIN_MARKER/,/ON_DEMAND_PLAN_END_MARKER/ { d; }" jobs/deploy-service-broker/spec jobs/deploy-service-broker/templates/deploy.sh.erb templates/*properties.yml  *tile.yml
fi

echo ""
printf "Does the Service Broker support in-built service(s)? Reply y or n : "
read internalServices
if [ "${internalServices:0:1}" == "y" ]; then
  printf "Provide name of the internal service (if multiple services, use comma as separator without spaces) without quotes: "
  read internalServiceNames
  internalServiceNames=`echo $internalServiceNames | sed -e 's/"//g;' | sed -e "s/\'//g;" `
  sed -i.bak "s/INTERNAL_SERVICE_NAME/${internalServiceNames}/g" jobs/deploy-service-broker/spec jobs/deploy-service-broker/templates/deploy.sh.erb templates/*properties.yml *tile.yml
else
  sed -i.bak "s/INTERNAL_SERVICE_NAME//g"  templates/*properties.yml *tile.yml 
fi

find . -name *bak | xargs rm 
echo ""
