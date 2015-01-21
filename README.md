# Bosh-generic-sb-release
Bosh release for a generic service broker that would be deployed as an app on Cloud Foundry, along with tile generation.

This is a scaffolding to generate a bosh release that would be used to deploy a service broker as an application to Cloud Foundry. It also includes scripts to generate an Operations Manager Tile (in form of .pivotal file).

Structure:
1) There are 3 errands that would be accessible through bosh
 a) deploy-service-broker that would use the release bits to deploy a custom service broker application to CF.
 b) register-broker would register the service broker to CF
 c) destroy-broker would delete/de-register the service broker from CF.
Once the job has been deployed via bosh deploy, one can execute ' bosh run errand deploy-service-broker' to run the named errand.
2) The release along with any necessary stemcells and the modified tile.yml file can be used to create a Tile to be imported into PCF Ops Mgr.
3) The metadata for the errands would be generated based on either deployment manifest used during bosh deploy or via the Ops Mgr Tile configurations.

Steps:
1) Rename the release and all files using the renameRelease.sh file (providing 'generic' and desired name as arguments)
2) Use the addBlob.sh to add a custom service broker app implementation for the release
3) Add or edit the templates under src folder as needed for any additional scripts, setup etc.
4) Edit the spec file under packages/<project>/ to include those additional files
5) Edit the spec file under jobs/deploy-service-broker to refer to those packages
6) Customize/edit the deploy.sh.erb file under jobs/deploy-service-broker/templates to tweak various attributes, setup, configurations etc to kick off the cf app push with the right parameters.
7) Create a release file using createRelease.sh
8) Deploy the release to Bosh
9) Edit the deployment manifest files to test against bosh-lite or vSphere directly using Bosh
10) Do the deployment using 'bosh deploy'
11) Once all changes are complete, edit the `*tile.yml` to add the associated changes for all related attributes, metadata that needs to be passed on to the bosh deployment.
12) Run createTile.sh to generate the Ops Mgr Tile.
13) Import into Ops Mgr
14) Configure the tile and apply changes.
