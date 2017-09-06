# OpenSSH Node Execution Plugins

This plugin provides a node-executor and file-copier using OpenSSH. Use this plugin if you want to access remote servers using ssh/scp commands (as an alternative of the default SSH plugin of rundeck, which is a Java Plugin based on JSCH library).

## Dry run mode

You can configure the plugin to just print the invocation string to the console. This can be useful when defining the configuration properties.


## Plugin Configuration Properties

* Private Key or Password Authentication.
* Password Authentication needs `sshpass` installed on the rundeck server.
* Both password and private key are taken from the key storage.
* It accepts custom SSH settings 
* Attributes can be defined at project or node level (eg: ssh-authentication, ssh-password-storage-path, ssh-options, ssh-key-storage-path)
* Dry run? If set true, just print the command invocation that would be used but do not execute the command. This is useful to preview.

## Configuration

The plugin can be configured as a default node executor and file copier for a Project. Use the Simple Conguration tab to see the configuration properties. 

Also you can define the configuration at node level, setting the node-executor and file-copier attributes.

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
