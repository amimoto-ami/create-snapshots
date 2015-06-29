# Creating Snaphosts for AMIMOTO

## What's amimoto

[AMIMOTO is an High Performance WordPress Cloud Hosting on Amazon Web Services.](http://amimoto-ami.com/)

## Creating Snaphosts for AMIMOTO

AMIMOTO can backup enverything you need.

If you are hoping backup AMIMOTO environments, you should just run following.

```
curl -L https://raw.githubusercontent.com/amimoto-ami/create_snapshots/master/create_snapshot.sh | bash
```

## Creating Snaphosts with cron

Puts following with `crontab -e`.

```
00 04 * * * /usr/bin/curl -s https://raw.githubusercontent.com/miya0001/create-snapshot/master/create_snapshot.sh | /bin/bash
```

Snapshot will be crated every day at 4:00 AM, and it will be keep two snaphosts, so old snaphosts will be removed automatically.
