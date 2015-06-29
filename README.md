# Creating Snaphosts for AMIMOTO

## What's AMIMOTO

[AMIMOTO is a High Performance WordPress Cloud Hosting on Amazon Web Services.](http://amimoto-ami.com/)

## Creating Snaphosts for AMIMOTO

AMIMOTO can backup enverything you need.

If you are hoping to backup AMIMOTO environments, you should just run following:

```
curl -L https://raw.githubusercontent.com/amimoto-ami/create-snapshots/master/create_snapshot.sh | bash
```

## Creating Snaphosts with cron

Put the following with `crontab -e`.

```
00 04 * * * /usr/bin/curl -s https://raw.githubusercontent.com/amimoto-ami/create-snapshots/master/create_snapshot.sh | /bin/bash
```

Snapshot will be created everyday at 4:00 AM, and two snaphosts are kept, so old snaphosts will be removed automatically.
