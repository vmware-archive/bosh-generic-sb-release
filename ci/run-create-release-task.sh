# Use -p to run in privileged/root mode to install wget via apt-get

fly execute -p                           \
      -c scripts/create-release/task.yml \
      -i repo=..
