# OpenSSH Node Execution Plugins

This plugin provides a node-executor and file-copier using OpenSSH. Use this plugin if you want to access remote servers using SSH/SCP commands (as an alternative to the default SSH plugin of Rundeck, which is a Java Plugin based on JSCH library).

## Requirements
* Password Authentication and Passphrase need `sshpass` installed on the rundeck server.
* For passing passphrase ``sshpass`` version 1.0.6+ is needed


## Dry run mode

You can configure the plugin to just print the invocation string to the console. This can be useful when defining the configuration properties.


## Plugin Configuration Properties

* Private Key or Password Authentication.
* Private Key can be used with Passphrase
* Both password and private key are taken from the key storage.
* It accepts custom SSH settings 
* Attributes can be defined at Project or Node level (eg: ssh-authentication, ssh-password-storage-path, ssh-options, ssh-key-storage-path)
* Dry run? If set true, just print the command invocation that would be used but do not execute the command. This is useful to preview.

## Configuration

The plugin can be configured as a default node executor and file copier for a Project. Use the Simple Configuration tab to see the configuration properties. 

Also, you can define the configuration at Node Level, setting the node-executor and file-copier attributes.

Settings:

* **authentication**: Authentication.Authentication SSH Type (password or privatekey). A node attribute named ssh-authentication will override this value.
* **ssh_key_storage_path**: SSH key Storage Path. Optional storage path for ssh-key saved on the key storage. Can contain property references to node attributes. A node attribute named ssh-key-storage-path will override this value.
* **ssh_key_passphrase_storage_path**: SSH key Passphrase Storage Path. Optional storage path for ssh-key Passphrase. Can contain property references to node attributes. A node attribute named ssh-key-passphrase-storage-path will override this value.
* **ssh_password_storage_path**: SSH Password Storage Path. Optional storage path for ssh-key Passphrase. Can contain property references to node attributes. A node attribute named ssh-key-passphrase-storage-path will override this value.
* **ssh_options**: SSH Custom Options. Add custom settings to SSH connection. Eg: -o ConnectTimeout=10. A node attribute named ssh-options will override this value.
* **ssh_password_option**: SSH Password with a Job Option. Get the password form a job option (eg: `option.password`). The Job must define a Secure Remote Authentication Option to prompt the user for the password before execution. A node attribute named ssh-password-option will override this value.
* **ssh_key_passphrase_option**: SSH Passphrase with a Job Option. Get the passphrase form a job option (eg: `option.passphrase`). The Job must define a Secure Remote Authentication Option to prompt the user for the passphrase before execution. A node attribute named ssh-key-passphrase-option will override this value.

## Dynamic Username

You can use a dynamic username, defining the username value( `username` node attribute)  from the job runner or from an input option.

* ${job.username} - uses the username of the user executing the Rundeck execution.
* ${option.username} - uses the value of a job option named "username". 


## Password or Passphrase from Secure Remote Authentication 

You can pass Password or Passphrase from a Job's Secure Remote Authentication Option.

* ssh-password-option = "option.NAME" where NAME is the name of the Job's Secure Remote Authentication Option.
* ssh-key-passphrase-option = "option.NAME" where NAME is the name of the Job's Secure Remote Authentication Option.


## Examples

Default project properties examples:

```
service.FileCopier.default.provider=ssh-copier
service.NodeExecutor.default.provider=ssh-exec

project.plugin.NodeExecutor.ssh-exec.authentication=password
project.plugin.NodeExecutor.ssh-exec.ssh_key_passphrase_option=option.passphrase
project.plugin.NodeExecutor.ssh-exec.ssh_options=-o ConnectTimeout\=10
project.plugin.NodeExecutor.ssh-exec.ssh_password_option=option.password
project.plugin.NodeExecutor.ssh-exec.ssh_password_storage_path=keys/node/user.password

project.plugin.FileCopier.ssh-copier.authentication=password
project.plugin.FileCopier.ssh-copier.ssh_key_passphrase_option=option.passphrase
project.plugin.FileCopier.ssh-copier.ssh_options=-o ConnectTimeout\=10
project.plugin.FileCopier.ssh-copier.ssh_password_option=option.password
project.plugin.FileCopier.ssh-copier.ssh_password_storage_path=keys/node/user.password
```


Basic node definition (overwrite the default settings)
```
<node name="RemoteNode" 
       description="Remote SSH Node" 
       tags="vagrant" 
       hostname="192.168.0.1" 
       osArch="Linux" 
       osFamily="x86_64" 
       osName="Linux" 
       osVersion="10.12.6" 
       username="vagrant" 
       node-executor="ssh-exec" 
       file-copier="ssh-copier" 
       ssh-authentication="password"  
       ssh-password-storage-path ="keys/node/user.password" 
       ssh-options="-o ConnectTimeout=5000"/>
```

Using password from option Secure Remote Authentication
```
<node name="RemoteNode" 
       description="Remote SSH Node" 
       tags="vagrant" 
       hostname="192.168.0.1" 
       osArch="Linux" 
       osFamily="x86_64" 
       osName="Linux" 
       osVersion="10.12.6" 
       username="vagrant" 
       node-executor="ssh-exec" 
       file-copier="ssh-copier" 
       ssh-authentication="password"  
       ssh-password-option="option.password" 
       ssh-options="-o ConnectTimeout=5000"/>
```
*a Secure Remote Authentication Option must be created on the job

Using dynamic username
```
<node name="RemoteNode" 
       description="Remote SSH Node" 
       tags="vagrant" 
       hostname="192.168.0.1" 
       osArch="Linux" 
       osFamily="x86_64" 
       osName="Linux" 
       osVersion="10.12.6" 
       username="${job.username}" 
       node-executor="ssh-exec" 
       file-copier="ssh-copier" 
       ssh-authentication="password"  
       ssh-password-option="option.password" 
       ssh-options="-o ConnectTimeout=5000"/>
```

Using dynamic username from job option
```
<node name="RemoteNode" 
       description="Remote SSH Node" 
       tags="vagrant" 
       hostname="192.168.0.1" 
       osArch="Linux" 
       osFamily="x86_64" 
       osName="Linux" 
       osVersion="10.12.6" 
       username="${option.username}" 
       node-executor="ssh-exec" 
       file-copier="ssh-copier" 
       ssh-authentication="password"  
       ssh-password-option="option.password" 
       ssh-options="-o ConnectTimeout=5000"/>
```
*a option called `username`  must be added to the job