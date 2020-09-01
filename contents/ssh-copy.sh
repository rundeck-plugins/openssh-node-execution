#!/bin/bash

#####
# ssh-copy.sh
# This script executes the system "scp" command to copy a file
# to a remote node.
# usage: ssh-copy.sh [username] [hostname] [file]
#
# It uses some environment variables set by RunDeck if they exist.  
#
# RD_NODE_SCP_DIR: the "scp-dir" attribute indicating the target
#   directory to copy the file to.
# RD_NODE_SSH_PORT:  the "ssh-port" attribute value for the node to specify
#   the target port, if it exists
# RD_NODE_SSH_KEYFILE: the "ssh-keyfile" attribute set for the node to
#   specify the identity keyfile, if it exists
# RD_NODE_SSH_OPTS: the "ssh-opts" attribute, to specify custom options
#   to pass directly to ssh.  Eg. "-o ConnectTimeout=30"
# RD_NODE_SCP_OPTS: the "scp-opts" attribute, to specify custom options
#   to pass directly to scp.  Eg. "-o ConnectTimeout=30". overrides ssh-opts.
# RD_NODE_SSH_TEST: if "ssh-test" attribute is set to "true" then do
#   a dry run of the ssh command
#####

USER=$1
shift
HOST=$1
shift

FILE=$RD_FILE_COPY_FILE
DIR=$RD_FILE_COPY_DESTINATION

# use RD env variable from node attributes for ssh-port value, default to 22:
PORT=${RD_NODE_SSH_PORT:-22}

# extract any :port from hostname
XHOST=$(expr "$HOST" : '\(.*\):')
if [ ! -z "$XHOST" ] ; then
    PORT=${HOST#"$XHOST:"}
    #    echo "extracted port $PORT and host $XHOST from $HOST"
    HOST=$XHOST
fi

SSHOPTS="-p -P $PORT -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet $RD_CONFIG_SSH_OPTIONS"

authentication=`echo "$RD_CONFIG_AUTHENTICATION" | awk '{ print tolower($1) }'`

if [ "$authentication" != "privatekey" ] && [ "$authentication" != "password" ] ; then
    echo "wrong ssh authentication type, use privatekey or password"
    exit 1
fi

if [[ -n "${RD_CONFIG_SSH_PASSWORD_OPTION:-}" ]] ; then
    option="$(sed 's/option.//g' <<<$RD_CONFIG_SSH_PASSWORD_OPTION)"
    rd_secure_password=$(echo "RD_PRIVATE_$option" | awk '{ print toupper($0) }')
fi

if [[ -n "${RD_CONFIG_SSH_KEY_PASSPHRASE_OPTION:-}" ]] ; then
    option="$(sed 's/option.//g' <<<$RD_CONFIG_SSH_KEY_PASSPHRASE_OPTION)"
    rd_secure_passphrase=$(echo "RD_PRIVATE_$option" | awk '{ print toupper($0) }')
fi

if [[ "$RD_NODE_USERNAME" =~ \$\{(.*)\} ]]; then
    username=${BASH_REMATCH[1]}
    if [[ "job.username" == "$username" ]] ; then
        USER=$RD_JOB_USERNAME
    fi

    if [[ "option.username" == "$username" ]] ; then
        USER=$RD_OPTION_USERNAME
    fi
fi

if [[ "privatekey" == "$authentication" ]] ; then

    #use ssh-keyfile node attribute from env vars
    if [[ -n "${RD_NODE_SSH_KEYFILE:-}" ]]
    then
        SSHOPTS="$SSHOPTS -i $RD_NODE_SSH_KEYFILE"
    elif [[ -n "${RD_CONFIG_SSH_KEY_STORAGE_PATH:-}" ]]
    then
        mkdir -p "/tmp/.ssh-exec"
        SSH_KEY_STORAGE_PATH=$(mktemp "/tmp/.ssh-exec/ssh-keyfile.$USER@$HOST.XXXXX")
        # Write the key data to a file
        echo "$RD_CONFIG_SSH_KEY_STORAGE_PATH" > "$SSH_KEY_STORAGE_PATH"
        SSHOPTS="$SSHOPTS -i $SSH_KEY_STORAGE_PATH"

        trap 'rm "$SSH_KEY_STORAGE_PATH"' EXIT

    fi
    RUNSCP="scp $SSHOPTS $FILE $USER@$HOST:$DIR"

    if [[ -n "${!rd_secure_passphrase}" ]]; then
        mkdir -p "/tmp/.ssh-exec"
        SSH_KEY_PASSPHRASE_STORAGE_PATH=$(mktemp "/tmp/.ssh-exec/ssh-passfile.$USER@$HOST.XXXXX")
        echo "${!rd_secure_passphrase}" > "$SSH_KEY_PASSPHRASE_STORAGE_PATH"

        RUNSCP="sshpass -P passphrase -f $SSH_KEY_PASSPHRASE_STORAGE_PATH scp $SSHOPTS $FILE $USER@$HOST:$DIR"

        trap 'rm "$SSH_KEY_PASSPHRASE_STORAGE_PATH"' EXIT
    fi

    ## add PASSPHRASE for key
    if [[ -n "${RD_CONFIG_SSH_KEY_PASSPHRASE_STORAGE_PATH:-}" ]]
    then
        mkdir -p "/tmp/.ssh-exec"
        SSH_KEY_PASSPHRASE_STORAGE_PATH=$(mktemp "/tmp/.ssh-exec/ssh-passfile.$USER@$HOST.XXXXX")
        echo "$RD_CONFIG_SSH_KEY_PASSPHRASE_STORAGE_PATH" > "$SSH_KEY_PASSPHRASE_STORAGE_PATH"
        RUNSCP="sshpass -P passphrase -f $SSH_KEY_PASSPHRASE_STORAGE_PATH scp $SSHOPTS $FILE $USER@$HOST:$DIR"

        trap 'rm "$SSH_KEY_PASSPHRASE_STORAGE_PATH"' EXIT

    fi
fi

if [[ "password" == "$authentication" ]] ; then
    mkdir -p "/tmp/.ssh-exec"
    SSH_PASS_STORAGE_PATH=$(mktemp "/tmp/.ssh-exec/ssh-passfile.$USER@$HOST.XXXXX")

    if [[ -n "${!rd_secure_password}" ]]; then
        echo "${!rd_secure_password}" > "$SSH_PASS_STORAGE_PATH"
    else
        echo "$RD_CONFIG_SSH_PASSWORD_STORAGE_PATH" > "$SSH_PASS_STORAGE_PATH"
    fi

    RUNSCP="sshpass -f $SSH_PASS_STORAGE_PATH scp $SSHOPTS $FILE $USER@$HOST:$DIR"

    trap 'rm "$SSH_PASS_STORAGE_PATH"' EXIT
fi

#if ssh-test is set to "true", do a dry run
if [[ "true" == "$RD_CONFIG_DRY_RUN" ]] ; then
    echo "[ssh-copy]" "$RUNSCP"
    exit 0
fi

#clean keys and password
unset RD_CONFIG_SSH_KEY_STORAGE_PATH
unset RD_NODEEXECUTOR_SSH_KEY_STORAGE_PATH
unset RD_NODEEXECUTOR_SSH_KEY_PASSPHRASE_STORAGE_PATH
unset RD_CONFIG_SSH_PASSWORD_STORAGE_PATH
unset RD_NODEEXECUTOR_SSH_PASSWORD_STORAGE_PATH

#finally, execute scp but don't print to STDOUT
$RUNSCP 1>&2 || exit $? # exit if not successful

echo "$RD_FILE_COPY_DESTINATION" # echo remote filepath

#done
