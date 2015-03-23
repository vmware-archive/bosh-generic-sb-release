while true
do 
  echo "Please select one of the errands to run!"
  echo "1) deploy-service-broker"
  echo "2) register-broker"
  echo "3) destroy-broker"
  echo "4) Exit"

  printf "Enter selection: "
  read input

  case "$input" in
    1) arg="deploy-service-broker";;
    2) arg="register-broker";;
    3) arg="destroy-broker";;
    4) exit 0;;
    *) continue
  esac
  echo "Running bosh errand $arg" 
  bosh run errand  $arg
done
