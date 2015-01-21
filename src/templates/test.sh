
function add_parameterized_env_vars() {
  cat setupServiceBrokerEnv.sh | while read env_var_entry
  do
    echo $env_var_entry | grep "^#" >/dev/null
    if [ "$?" != "0" ]; then
      formatted_env_var=`echo $env_var_entry | sed -e 's/export//;s/=/ /g';`
      echo cf set-env $APP_NAME  ${formatted_env_var}
    fi
  done
}

add_parameterized_env_vars
