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

## Build the Release

### Rename the package and jobs 
* Rename the release and all files using the renameRelease.sh file (provide 'generic' and desired name as arguments)
### Add CF CLI binary as Blob
* Run fetch_cf_cli.sh script to fetch CF CLI binary and add it as a blob to the release. Specify 'N' when it asks if its the app binary.
### Add Custom Service Broker App content as Blob
* Adding custom code and binaries required for the service broker app:
  * Add any dependent files/templates under src/templates folder
  * Use the addBlob.sh to add a custom service broker app implementation (like jar/zip/tar/tgz) for the release
    * Respond with 'Y' if adding the main app archive 
    * This will automatically update the spec and packaging file for the package to include the app binary.
    * The packaging file would be automatically updated only in case of 'Y' as input for only the first blob added as application binary.
  * Edit the packaging file under packages/<project>/ to copy over any other additional files/blobs to $BOSH_INSTALL_TARGET/lib or other location.
    * The packaging file would be not be updated to include non-app bits ('N' as input) or any additional blobs added, even if they are also considered app bits.
### Edit runtime variables for the Jobs
* Bosh job properties navigation
  * Bosh would pass on runtime attributes from the deployment manifest to the job instance via a relationship graph.
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
      Here the `plan_params` is defined under properties -> my_test_sb hierarchy in the bosh deployment manifest.
      The associated deployment manifest should have plan_params nested inside my_test_sb 
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
### Edit the deploy.sh.erb file
 * Remove the variables from the deploy.sh.erb that are not required as absence of the variable in the manifest can cause failures (ex: remove TARGET_SERVER.., DRIVER_DOWNLOAD_URL etc. if they are not needed).
     * Edit the update_env_variable_script function to do the substitution of template variables with real variable values.
      * Example:`` \`s/TEMPLATE_PLAN_PARAMS/${PLAN_PARAMS}/g \` ```
    * For any new parameter or variable added or modified, ensure the related spec includes those newer or modified attribute names and associated description.
   * At the job execution time, these variables can be evaluated to be processed by the job instance.
## Bosh Manifest Generation 
* Edit the deployment manifest files to test against bosh-lite or vSphere directly using Bosh.
  * Use the make_manifest.sh script to generate the manifest file according to target platform (warden, vsphere, aws-ec2).
   * Before running the make_manifest.sh, set the bosh target to the target Bosh director 
   * Edit the templates/*-broker-properties.yml file to update the following elements:
     * CF domain, app domain names
     * CF API endpoint
     * App Name and URI
     * CF credentials (to create org, spaces and deploy the app to CF)
     * User credentials to access the Service broker app
     * Endpoint to download any dependencies or 3rd party libraries required by service broker application
     * Persistence store details
     * Managed target server details
     * Internal Plans managed by Broker
     * On Demand plans to be created on the broker
   * Run the make_manifest.sh providing 'warden' or 'vsphere' to indicate the platform
   * A new manifest would be generated with the Bosh Director UUID based on the bosh target
 * Edit the run.sh script to point to the newly generated manifest rather than the boiler plate templates
 * Note: Everytime, new properties/attributes are added in the job spec or erb files, make sure corresponding changes are added to the templates/*properties.yml file and manifest is regenerated.
## Deployment
* Use run.sh script to do full clean, build, deploy:
  * Create a release file using createRelease.sh script
  * Deploy the release to Bosh
* Do the deployment using 'bosh deploy' directly or via run.sh
* Note: Always generate the latest bosh manifest file (using make_manifest.sh) before running this script.
## Running Errands
* Run bosh errands. Sample:
   bosh run errand deploy-service-broker
   bosh run errand register-broker
   bosh run errand destroy-broker
   
* or use the runErrands.sh shell script to specify the option to test/run.
## Tile Generation
* Once all changes are complete, edit the `*tile.yml` to add the associated changes for all related attributes, metadata that needs to be passed on to the bosh deployment.
  * Any new attribute or property added should be first defined in the property blueprints (like type/configurable/default etc) and also within the job related manifest section.
    If the property should be exposed/configurable by user, it should be part a form_type section
   Example: Adding a new property called *internal_plan_names* would require:
   ```
  - name: internal_plan_names
    type: string
    configurable: true
    default: "p-internal-plan1,p-internal-plan2"
   ```
   and within the manifest section:
   ```
  manifest: ! "domain: (( ..cf.cloud_controller.system_domain.value ))\napp_domains:\n
    \ - (( ..cf.cloud_controller.apps_domain.value ))\nssl:\n  skip_cert_verify: ((
    ..cf.ha_proxy.skip_cert_verify.value ))\nuaa:\n  clients:\n    generic_broker:\n
    \     secret: test\ngeneric_broker:\n
    \ app_name: (( app_name.value ))\n
    \ app_uri: (( app_uri.value ))\n
    \ internal_plan_names: (( internal_plan_names.value ))\n
    \ encryption_key: (( .properties.encryption_key.secret ))\n  cf:\n    admin_user:
    \ (( ..cf.uaa.system_services_credentials.identity ))\n    admin_password: (( ..cf.uaa.system_services_credentials.password
    \ ))\n  broker:\n    user: (( .properties.broker_credentials.identity ))\n    password:
    \ (( .properties.broker_credentials.password ))\n    internal_plan_names: (( *internal_plan_names*.value ))\n"
   ```
* Create a custom image for the tile by first generating an image and converting it to Base-64 encoding [use this link](www.base64-image.de/step-2.php) and use that in the image tag in the tile file.
* Run createTile.sh to generate the Ops Mgr Tile (.pivotal file).
* `Important: Backup the Ops Mgr configuration before proceeding to next step.`
## Tile Import into Ops Mgr
* Import the Tile into non-Production version of Ops Mgr.
* Verify the Tile works before proceeding with any changes.
 * Rollback the tile import if Ops Mgrs reports 500 or throws Errors.
 * Fix the tile content/metadata based on checking the Ops Mgr log (check /tmp/logs/production.log on Ops Mgr vm)
* Configure the Tile with necesary metadata and apply changes to test/deploy the Service Broker.
