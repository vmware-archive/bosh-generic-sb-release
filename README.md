# Bosh-generic-sb-release
Bosh release for a generic service broker that would be deployed as an app on Cloud Foundry, along with support for Ops Mgr Tile generation.

This is a scaffolding to generate a bosh release that would be used to deploy a service broker as an application to Cloud Foundry. 
It also includes scripts to generate an Operations Manager Tile (in form of .pivotal file).

This is purely an experimental release and highly recommended to not test against a production system.

## Structure:
* There are 3 errands that would be accessible through Bosh using this release
  * deploy-service-broker that would use the release bits (bundled with service broker app code) to deploy a custom service broker application to CF.
  * register-broker would register the service broker to CF
  * destroy-broker would delete/de-register the service broker from CF.

Once the job has been deployed via bosh deploy, one can execute ' bosh run errand deploy-service-broker' to run the named errand.
* The release along with any necessary stemcells and the modified tile.yml file can be used to create a Tile to be imported into PCF Ops Mgr.
* The metadata for the errands would be generated based on either deployment manifest used during bosh deploy or via the Ops Mgr Tile configurations.

## Steps:
* Rename the release and all files using the renameRelease.sh file (provide 'generic' and desired name as arguments)
* Adding custom code and binaries required for the service broker app:
  * Add any dependent files/templates under src/templates folder
  * Use the addBlob.sh to add a custom service broker app implementation (like jar/zip/tar/tgz) for the release
    * Respond with 'y' if adding an main app archive 
  * Edit the spec file under packages/<project>/ to include references to any new additional files/blobs addded
* Edit the spec file under jobs/deploy-service-broker to refer to those dependent packages
* Add or edit the templates under src folder as needed for any additional scripts, setup etc.
* Customize/edit the deploy.sh.erb file under jobs/deploy-service-broker/templates to tweak various attributes, setup, configurations etc to kick off the cf app push with the right parameters.
* For any new parameter or variable added or modified, edit the related spec with those attribute names and description.
* Edit the deployment manifest files to test against bosh-lite or vSphere directly using Bosh.
* Use run.sh script to do full clean, build, deploy:
  * Create a release file using createRelease.sh script
  * Deploy the release to Bosh
* Do the deployment using 'bosh deploy'
* Run bosh errands. Sample:
   bosh run errand deploy-service-broker
   bosh run errand register-broker
   bosh run errand destroy-broker
* Once all changes are complete, edit the `*tile.yml` to add the associated changes for all related attributes, metadata that needs to be passed on to the bosh deployment.
* Create a custom image for the tile by first generating an image and converting it to Base-64 encoding [use this link][www.base64-image.de/step-2.php] and use that in the image tag in the tile file.
* Run createTile.sh to generate the Ops Mgr Tile (.pivotal file).
* Backup the Ops Mgr configuration before proceeding to next step.
* Import the Tile into Ops Mgr.
* Configure the Tile with necesary metadata and apply changes to deploy the Service Broker.
