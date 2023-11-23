sshserver=$(cat $XDG_CONFIG_HOME/scripts/cloud_sync_conf | grep -w sshserver | awk '{print $2}')
remote_mount_point=$(cat $XDG_CONFIG_HOME/scripts/cloud_sync_conf | grep -w remote_mount_point | awk '{print $2}')
local_mount_point=$(cat $XDG_CONFIG_HOME/scripts/cloud_sync_conf | grep -w local_mount_point | awk '{print $2}')
sync_source_dir=$(cat $XDG_CONFIG_HOME/scripts/cloud_sync_conf | grep -w sync_source_dir | awk '{print $2}')
sync_target_dir=$(cat $XDG_CONFIG_HOME/scripts/cloud_sync_conf | grep -w sync_target_dir | awk '{print $2}')

cloud_sync() {
	if ps -e | grep -q sshfs; then
		rsync -avz --delete $sync_source_dir $sync_target_dir > $HOME/logs/sync_log
		notify-send "Cloud sync event $( echo $out | awk '{print $2 , $3}')"
	fi
}

check_connection() {
	while ! ping -q -c 1 -W 1 ping.eu > /dev/null ; do
		sleep 5
	done
}

monitor_and_sync() {
	while out=$(inotifywait -r -e modify,create,delete,move $sync_source_dir); do
		cloud_sync
	done
}

check_connection

sshfs -o reconnect $sshserver:$remote_mount_point $local_mount_point

cloud_sync

# the loop bellow re-runs inotify whenever it stops runing, for instance when a folder is deleted (inotify stops because it is watching directories recursively

while true; do
	monitor_and_sync
done
