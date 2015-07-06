# Creating Snaphosts for AMIMOTO

## What's AMIMOTO

[AMIMOTO is a High Performance WordPress Cloud Hosting on Amazon Web Services.](http://amimoto-ami.com/)

## Creating Snaphosts for AMIMOTO

### SSH into your instance

```
ssh ec2-user@<ip-address>
```

### Creating an IAM user

Create Accesss Key ID and Secret Accesss Key.

See [http://aws.amazon.com/iam/](http://aws.amazon.com/iam/).

Example policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot",
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "*"
        }
    ]
}
```

### Configuring the AWS Command Line Interface

Set IAM Access Key ID and Secret Access Key

```
aws configure
```

See also [http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

### Run the following command.

```
curl -L https://raw.githubusercontent.com/amimoto-ami/create-snapshots/master/create_snapshot.sh | bash
```

## Creating Snaphosts with cron

Put the following with `crontab -e`.

```
00 04 * * * /usr/bin/curl -s https://raw.githubusercontent.com/amimoto-ami/create-snapshots/master/create_snapshot.sh | /bin/bash
```

Snapshot will be created everyday at 4:00 AM, and two snaphosts are kept, so old snaphosts will be removed automatically.

You can get notifications by email, see also [https://github.com/amimoto-ami/set-mail-aliases](https://github.com/amimoto-ami/set-mail-aliases).
