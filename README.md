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
* Run fetch_cf_cli.sh script to fetch CF CLI binary and add it as a blob to the release. Specify 'n' when it asks if its the app binary.
* Adding custom code and binaries required for the service broker app:
  * Add any dependent files/templates under src/templates folder
  * Use the addBlob.sh to add a custom service broker app implementation (like jar/zip/tar/tgz) for the release
    * Respond with 'y' if adding an main app archive 
  * Edit the spec file under packages/<project>/ to include references to any other additional files/blobs addded
  * Edit the packaging file under packages/<project>/ to include copy over these additional files/blobs to $BOSH_INSTALL_TARGET/lib or other location.
* Edit the spec file under jobs/deploy-service-broker to refer to those dependent packages
* Adding runtime or late binding variables, attributes 
  * Bosh would passing on runtime attributes from the deployment manifest to the job instance via relationship graph.
   * The variable should be defined under the job properties (under some defined structure) in the manifest
   * Bosh would understand that a given property or attribute is required for a specific job based on the reference to the attribute inside the job's spec file. The job spec file should provide the hierarchy or nesting order of the variable in relation to the top element and also provide a sample description of the variable. Default can be specified that would allow bosh to use that value in the absence of value from the deployment manifest file.
   * At the job execution time, these variables can be evaluated to be processed by the job instance.
   * Steps to add an attribute or variable definition: 
    * Add or edit the templates under src folder as needed for any additional scripts, setupServiceBrokerEnv.sh etc.
      * Example: ```export PLAN_PARAMS=TEMPLATE_PLAN_PARAMS```
      Here, the TEMPLATE_PLAN_PARAMS would be substituted with real values based on parameters passed to the job running the deploy-service-broker errand.
    * Customize/edit the deploy.sh.erb file under jobs/deploy-service-broker/templates to tweak various attributes, setup, configurations etc to kick off the cf app push with the right parameters.
     * Add the necessary variables that need to be retreived from the properties passed to the errand.
      * Example: ```export PLAN_PARAMS=<%= properties.my_test_sb.plan_params %> ```
      Here the `plan_params` is defined under properties -> my_test_sb hierarchy.
      The associated deployment manifest should have plan_params nested inside my_test_sb 
   * Remove the variables that are not required as absence of the variable in the manifest can cause failures (ex: TARGET_SERVER.., DRIVER_DOWNLOAD_URL etc. if they are not needed).
```
properties:
  domain: 10.244.0.34.xip.io
  app_domains: 10.244.0.34.xip.io
  my_test_sb:
    encryption_key: 'test'
    app_name: MyTestServiceBroker
    app_uri: mytestsb
    plan_params: "plan_param1,plan_param2"
```

     * Edit the update_env_variable_script function to do the substitution of template variables with real variable values.
      * Example:`` \`s/TEMPLATE_PLAN_PARAMS/${PLAN_PARAMS}/g \` ```
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
