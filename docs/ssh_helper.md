# ssh_helper.sh

The ssh helper is useful on those clusters where the submit node cannot
connect to the jsonrpc url (because a firewall is blocking that port).

Essentially, it runs the part of the client that downloads the idle job
list, then transfers that to the cluster head node to be read by the client.

This is usually run as a cron job at some interval.

## Steps

1. Download job list from server.

2. Save as a json file in a temporary directory.

3. `scp` the file to the cluster submit node. This generally requires an
   ssh key to be installed.

## SSH Tips

Use a different ssh key for each cluster, using a config file to
select the correct one.

`~/.ssh/config`:

    Host SUBMITNODE
        User REMOTEUSERNAME
        IdentityFile ~/.ssh/PRIVATE_KEY

Since you're going to want to use a key without a passphrase
(otherwise this would be rather pointless), it helps to add some security.

On the SUBMITNODE:

`~/.ssh/authorized_keys`:

    from="SSH_NODE",command="scp -f ~/glidein_state" PUBLIC_KEY

This restricts the key to only connect from your node, and only scp the
glidein state file.

### Remote cron

If for some reason the submit node doesn't have a working cron, you can
remotely call the client from a machine with cron.

`~/.ssh/authorized_keys`:

    from="SSH_NODE",command="/usr/bin/python PATH_TO_PYGLIDEIN/client.py --config=CONFIG_FILE" PUBLIC_KEY

This restricts the key to only connect from your node, and only execute the
client command.
