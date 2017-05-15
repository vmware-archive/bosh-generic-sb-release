# Bosh-generic-sb-release

A [Bosh release](http://docs.cloudfoundry.org/bosh/create-release.html) for any generic service broker that would be deployed as an application on [Cloud Foundry](http://www.pivotal.io/platform-as-a-service/cloud-foundry), along with scripts to generate an Ops Mgr Tile of the [Service Broker](http://docs.cloudfoundry.org/services/api.html).

NOTE: This tools is deprecated and not supported. Kindly use [tile-generator](https://github.com/cf-platform-eng/tile-generator) to wrap brokers/apps with bosh releases and create Pivotal Tiles.

This is a scaffolding to generate a bosh release that would be used to deploy a service broker as an application to Cloud Foundry. 
It also includes scripts to generate an Operations Manager Tile (in form of .pivotal file).

This is purely an experimental release and highly recommended to not test against a production system.

## Structure
* A Bosh release would be generated containing a custom developed Service Broker implementation of the Service Broker interface for brokering services to Cloud Foundry Applications.
  * Using the steps described and provided scripts, users will be able to create a Bosh release around a custom service broker implementation (to Database or other services) and deploy it to their Cloud Foundry Environment
  * The service broker implementation application would be deployed to Cloud Foundry as a separate application, followed by its registration as a service broker with the Cloud Foundry Cloud Controller.
  * Users will then be able to access the new service broker via the Cloud Foundry Marketplace
  * The exposed services brokered by the new service broker implementation can then be bound to user applications running on Cloud Foundry.
  * Scripts bundled with the release will also handle the de-registration/purging of the services and underlying service broker.

* There are 3 errands that would be accessible through Bosh using this release
  * deploy-service-broker that would use the release bits (bundled with service broker app code) to deploy the custom service broker application to CF.
  * register-broker would register the service broker to CF
  * destroy-broker would delete/de-register the service broker from CF.

Once the job has been deployed via bosh deploy, one can execute 'bosh run errand deploy-service-broker' to run the named errand.
* The release along with any necessary stemcells and the modified tile.yml file can be used to create a Pivotal Operations Manager Tile to be imported into PCF Ops Mgr. Edit the tile to specify the right stemcell version based on Ops Mgr version.
* The metadata for the errands would be generated based on either user generated deployment manifest or via the Ops Mgr Tile configurations.

## Build the Release
Steps to building the Bosh Release

### Pre-Req
Needs installation of Bosh Cli gems in the local environment to create bosh releases (along with Ruby)

### Rename the Release
Rename the release and all related files using the renameRelease.sh file (provide desired name as arguments)
```
# Name of the release would be modified from generic to ABCImpl to yield ABCImpl-service-broker
./renameRelease.sh ABCImpl
```


### Customize the Release
Customizing release using customizeRelease.sh script
  * Choose the version of Ops Mgr to deploy to and also the version of the release (for tracking) 
    * Its okay to go with Ops Mgr 1.3 version of the tile and deploy to a Pivotal Ops Mgr running 1.4 as the Ops Mgr would automatically upgrade that to 1.4 metadata version. But the stemcell should refer to version available to the Ops Mgr 1.4 or later, not 1.3.
  * Add Custom Variables that need to be exposed via the Tile or Manifest which in turn would be consumed by the Service Broker App. For example, the service broker app might require the CF domain information in form of a variable 'CF_DOMAIN_ENDPOINT' or it might need a Github Account access token in form of a variable 'github_accesstoken'. These variables might be having a default value or would be defined later via the Tile by the user. These variables would be bound to default or other user defined values and bound to the service broker application in form of Environment variables (using cf set-env AppName envVariableName envVariableValue) allowing loose coupling/late binding.
  Note: Avoid using env variable names with '.' (period) character as these will cause failures when exporting it in unix shells. Use '_' (underscore) or other options to avoid using spaces, '.' etc.
    * Also, these variables might or might not be exposed to the end-user. The generated tile would have labels exposing the properties based on user responding to the script.
  * Does the Service Broker need persistence store to manage/store its configurations? It can be a database with endpoint, service name, user credentials to connect and store the data.
  * Does the Service Broker need to know about a target service that would be defined later by the end-user?
  * Does the Service Broker app need any additional third party libraries/drivers to function that should be downloaded separately before getting deployed as an app on CF?
  * Does the Service Broker have inbuilt internal services that need to be registered and exposed?
  * Does the Service Broker allow user defined plans?

Sample output:
```
./customizeRelease.sh

  This script will customize the Service Broker Release and Ops Mgr Tile generation based on user inputs
  Things that would be customized include:
     - Custom defined dynamic variables/parameters that would be passed along as environment variables to the application
     - Expose the user defined parameters via the Tile UI
     - Use or not use persistence (mysql or custom database persistence)
     - Allow user to pull down external third party libraries that are required by the service broker app
     - Allow registration of either in-built or user defined plans

Starting customization........

Version of Pivotal Ops Mgr to deploy on:
  Reply with 1.3 or 1.4 or other version: 1.4

Version for the Service Broker release
  Reply with something like 1.0 or 2.0 or 5.1: 5.5

Does the Service Broker Application require any configurable parameter/variables for its functioning
     Externalized parameters can be dynamic or user defined like some github access token
     and needs to be part of the Service Broker App via environment variable
Example:  cf set-env ServiceBrokerApp <MyVariable> <TestValue>
Reply y or n : y

Variable name (without spaces, enter n to stop): github_username
Enter short description of Variable (spaces okay): Github Username
Enter long description of Variable (spaces okay): Github user name to connect
Enter a default value (use quotes if containing spaces): testuser
Should this be configurable or exposed to end-user, reply with y or n: n

Variable name (without spaces, enter n to stop): github_accesstoken
Enter short description of Variable (spaces okay): Github Access token
Enter long description of Variable (spaces okay): Access token to connect to Github account
Enter a default value (use quotes if containing spaces):
Should this be configurable or exposed to end-user, reply with y or n: y

Variable name (without spaces, enter n to stop): n

Does the Service Broker need to download any external driver/library? Reply y or n : n

Does the Service Broker need a persistence store? . Reply y or n : n

Does the Service Broker need to manage a target service? . Reply y or n : n

Does the Service Broker allow customized user defined plans? . Reply y or n : n

Does the Service Broker support an in-built plan(s) ?. Reply y or n : y

Provide name of the internal plan (if multiple plans, use comma as separator without spaces): p-internal-config-plan

```
 
 Based on the user inputs, various entries would be automatically created/edited/updated to either bind environment variables, remove unwanted sections within the tiles, deployment manifest and job template files as well as within the environment template files used to bind the various variables to the application.

### Add CF CLI binary as Blob
Run fetch_cf_cli.sh script to fetch CF CLI binary and add it as a blob to the release.
To upgrade the CF cli, edit/update the download link specified inside the fetch_cf_cli.sh script.

### Add Custom Service Broker App content as Blob
Adding custom code and binaries required for the service broker app:
  * Add any dependent files/templates under src/templates folder
  * If running on bosh-lite, set the create_open_security_group attribute to true to allow the service broker app to interact with other apps.
  * Use the addBlob.sh to add a custom service broker app implementation (like jar/zip/tar/tgz) for the release
    * Respond with 'y' if adding the main app archive 
    * This will automatically update the spec and packaging file for the package to include the app binary.
    * The packaging file would be automatically updated only in case of 'y' as input for only the first blob added as application binary.
  * Edit the packaging file under packages/<project>/ to copy over any other additional files/blobs to $BOSH_INSTALL_TARGET/lib or other location.
    * The packaging file would be not be updated to include non-app bits ('n' as input) or any additional blobs added, even if they are also considered app bits.

### Edit runtime variables for the Jobs
Its important to understand how properties defined inside Bosh Job are referenced/navigated
  * Bosh would pass on runtime attributes from the deployment manifest to the job instance via a relationship graph.
   * The variable should be defined under the job properties (under some top or nested structure) in the manifest
   * Bosh would understand that a given property or attribute is required for a specific job based on the reference to the attribute inside the job's spec file. The job spec file should provide the hierarchy or nesting order of the variable in relation to the top element and also provide a sample description of the variable. Default can be specified that would allow bosh to use that value in the absence of value from the deployment manifest file.
   * At the job execution time, these variables can be evaluated to be processed by the job instance.
   * The customizeRelease.sh script would have already added any necessary attribute or variable definitions: 
    * Check and edit the templates under src folder as needed for any additional scripts, setupServiceBrokerEnv.sh etc.
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
Note: Whenever a new variable is added, it should be referenceable in the spec file, the manifest and the job template erb file. The customizeRelease.sh script would have already updated all the necessary files. But would be worth it to check once for accuracy.
If a variable is moved or modified, the same set of files should be updated.

### Edit the deploy.sh.erb file
Remove the variables from the deploy.sh.erb that are not required as absence of the variable in the manifest can cause failures (ex: remove TARGET_SERVER.., DRIVER_DOWNLOAD_URL etc. if they are not needed).
   * Edit the update_env_variable_script function to do the substitution of template variables with real variable values.
    * Example:`` \`s/TEMPLATE_PLAN_PARAMS/${PLAN_PARAMS}/g \` ```
  * For any new parameter or variable added or modified, ensure the related spec includes those newer or modified attribute names and associated description.
 * At the job execution time, these variables can be evaluated to be processed by the job instance.

## Bosh Manifest Generation 
  * Edit the deployment manifest files to test against bosh-lite or vSphere directly using Bosh.
  * Use the make_manifest.sh script to generate the manifest file according to target platform (warden, vsphere, aws-ec2).
   * Before running the make_manifest.sh, set the bosh target to the target Bosh director 
   * Edit the templates/*-properties.yml file to update the following elements:
     * CF domain, app domain names
     * CF API endpoint
     * App Name and URI
     * CF credentials (to create org, spaces and deploy the app to CF)
     * User credentials to access the Service broker app
     * Endpoint to download any dependencies or 3rd party libraries required by service broker application
     * Persistence store details
     * Managed target server details
     * Internal Services managed by Broker
     * On Demand plans to be created on the broker
     * If running on bosh-lite, set the create_open_security_group attribute to true to allow the service broker app to interact with other apps.
   * Run the make_manifest.sh providing 'warden' or 'vsphere' to indicate the platform
   * A new manifest would be generated with the Bosh Director UUID based on the bosh target
   * If any variables were added via the customizeRelease script and no default values were provided, the teplate file would have '_FILL_ME_' as value. Please edit before deploying the manifest (or even before generating the manifest). 
 * Edit the run.sh script to point to the newly generated manifest rather than the boiler plate templates
 * Note: Everytime, new properties/attributes are added in the job spec or erb files, make sure corresponding changes are added to the templates/*properties.yml file and manifest is regenerated.

## Deployment
* Use run.sh script to do full clean, build, deploy:
  * Create a release file using createRelease.sh script
  * Deploy the release to Bosh
* Do the deployment using 'bosh deploy' directly or via run.sh
* Note: Always generate the latest bosh manifest file (using make_manifest.sh) before running this script.
 * Note: If the deployment fails with similar errors, it indicates the network subnet is in use. Choose a different subnet (example: choose 10.244.3 rather than 10.244.1 via a global search-replace inside the generated manifest file).
 ```
 Started compiling packages > spring_service_broker/43f050bd3571814827e267f0d8d7abb289accbe9. Failed: Creating VM with agent ID 'd6266e99-af23-4ac9-8026-4e8ac08a1696': Creating container: network already acquired: 10.244.1.12/30 (00:00:00)

 Error 100: Creating VM with agent ID 'd6266e99-af23-4ac9-8026-4e8ac08a1696': Creating container: network already acquired: 10.244.1.12/30
 ```

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
   Example: Adding a new property called *internal_service_names* would require:
   ```
  - name: internal_service_names
    type: string
    configurable: true
    default: "p-internal-service1,p-internal-service2"
   ```
   and within the manifest section:
   ```
  manifest: |
    domain: (( ..cf.cloud_controller.system_domain.value ))
    app_domains:
      - (( ..cf.cloud_controller.apps_domain.value ))
    ssl:
      skip_cert_verify: (( ..cf.ha_proxy.skip_cert_verify.value ))
    uaa:
      url: https://uaa.(( ..cf.cloud_controller.system_domain.value ))
      clients:
        corneliatest_broker:
          secret: test
    corneliatest_broker:
      app_name: (( .properties.app_name.value ))
      app_uri: (( .properties.app_uri.value ))
      create_open_security_group: (( .properties.create_open_security_group.value ))
      app_push:
        org_quota: (( .properties.org_quota.value ))
        timeout: 180
        memory: (( .properties.memory.value ))
### CUSTOM_VARIABLE_MANIFEST_BEGIN_MARKER
      github_username: (( .properties.github_username.value ))
      github_accesstoken: (( .properties.github_accesstoken.value ))
### CUSTOM_VARIABLE_MANIFEST_END_MARKER
      encryption_key: (( .properties.encryption_key.secret ))
      cf:
        admin_user: (( ..cf.uaa.system_services_credentials.identity ))
        admin_password: (( ..cf.uaa.system_services_credentials.password ))
      broker:
        user: (( .properties.broker_credentials.identity ))
        password: (( .properties.broker_credentials.password ))
        internal_service_names: (( .properties.internal_service_names.value ))
   ```
* Create a custom image for the tile by first creating an image and converting it to [Base-64 encoding](http://www.base64-image.de/step-2.php) and use that in the image tag in the tile file. Ensure the sizes are less than an inch in height and width for it to fit inside the tile.
* Run createTile.sh to generate the Ops Mgr Tile (.pivotal file).

## Tile Import into Ops Mgr
`Important: Backup the Ops Mgr configuration before proceeding to next step.`
* Change the name of the Tile and versions as necessary. 
 Note: The version bundled in this repo is for Ops Manager 1.3 but can also be imported into Ops Mgr 1.4. 
 Stemcell references would change based on version of Ops Mgr used.

 If running on Ops Mgr v1.4, edit the stemcell references inside the v1.4 tile file:
 ```
stemcell:                                                  # [3]
  # Use following stemcell references for Ops Mgr 1.4 and vSphere
  version: '2865.1'                                                        # UNCOMMENT for Ops Mgr 1.4
  name: bosh-vsphere-esxi-ubuntu-trusty-go_agent                           # UNCOMMENT for vSphere and Ops Mgr 1.4
  file: bosh-stemcell-2865.1-vsphere-esxi-ubuntu-trusty-go_agent.tgz       # UNCOMMENT for vSphere and Ops Mgr 1.4

  # Use following stemcell references for Ops Mgr 1.4 and AWS
  #name: light-bosh-aws-xen-hvm-ubuntu-trusty-go_agent                     # UNCOMMENT for AWS and Ops Mgr 1.4
  #file: light-bosh-stemcell-2865.1-aws-xen-hvm-ubuntu-trusty-go_agent.tgz # UNCOMMENT for AWS and Ops Mgr 1.4

 ```
Uncomment the AWS stemcell reference if running on AWS and comment off the vSphere.
If the stemcell version available or being used has changed, modify the version accordingly.

 If running on Ops Mgr v1.3, edit the stemcell references inside the v1.3 tile file (there is no AWS support for Ops Mgr v1.3) for vsphere or vcloud:
 ```
stemcell:                                                  # [3]
  # Use following stemcell references for Ops Mgr 1.3 and vSphere
  # Edit if CF/Elastic Runtime is using a different stemcell version
  version: '2690.3'                                                        # UNCOMMENT for Ops Mgr 1.3
  name: bosh-vsphere-esxi-ubuntu-trusty-go_agent                           # UNCOMMENT for vSphere and Ops Mgr 1.3
  file: bosh-stemcell-2690.3-vsphere-esxi-ubuntu-trusty-go_agent.tgz       # UNCOMMENT for vSphere and Ops Mgr 1.3

 ```
 Comment off the stemcells for Ops Mgr v1.4 if running on Ops Mgr v1.3. If the stemcell version available or being used has changed, modify the version accordingly.

* Import the Tile into non-Production version of Ops Mgr.
* Verify the Tile works before proceeding with any changes.
 * Rollback the tile import if Ops Mgrs reports 500 or throws Errors.
 * Fix the tile content/metadata based on checking the Ops Mgr log (check /tmp/logs/production.log on Ops Mgr vm)
* Configure the Tile with necesary metadata and apply changes to test/deploy the Service Broker.
