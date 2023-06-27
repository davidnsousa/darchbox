#!/bin/bash

# check whether internet connection is on

while ! ping -q -c 1 -W 1 ping.eu > /dev/null ; do
    sleep 5
done

# check for Arch linux updates and save the number of updates to file

echo 0 > ~/.nupdates
yay -Qu | wc -l > ~/.nupdates

# check for desktop environment updates

last_commit_date=$(curl -s https://api.github.com/repos/davidnsousa/dlemonbox/commits | jq -r '.[0].commit.committer.date')
last_commit_date_timsetamp=$(date -d $last_commit_date +%s)

last_update_date=$(cat ~/.last_update_date)

if [ $last_commit_date_timsetamp -gt $last_update_date ]; then
	touch ~/.update_de
else
  test -e ~/.update_de && rm ~/.update_de
fi
