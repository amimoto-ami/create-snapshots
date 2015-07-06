#!/usr/bin/env bash

set -ex

SHELLDIR=`dirname ${0}`
SHELLDIR=`cd ${SHELLDIR}; pwd`
SHELLNAME=`basename $0`

AZ=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
LN=`echo $((${#AZ} - 1))`
REGION=`echo ${AZ} | cut -c 1-${LN}`
SNAPSHOTS_PERIOD=2

AWS="/usr/bin/aws --region ${REGION}"

INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
INSTANCE_NAME=`${AWS} ec2 describe-instances --instance-ids ${INSTANCE_ID} --output json | jq -r '.Reservations[].Instances[].Tags[] | select(.Key == "Name").Value'`

if [ !INSTANCE_NAME ] ; then
    error 'Unable to locate credentials. You can configure credentials by running "aws configure".'
    exit 1
fi

error() {
    echo -e "\e[31m${@}\e[m"
}

success() {
    echo -e "\e[32m${@}\e[m"
}

create_snapshot() {
    VOL_ID=`${AWS} ec2 describe-instances --instance-ids ${INSTANCE_ID} --output text | grep EBS | awk '{print $5}'`
    if [ -z ${VOL_ID} ] ; then
        error "ERR: ec2-describe-instances"
        exit 1
    fi
    SNAPSHOT_ID=`${AWS} ec2 create-snapshot --volume-id ${VOL_ID} --description "Created by SYSTEMBK(${INSTANCE_ID}) from ${VOL_ID}" --output json | jq -r .SnapshotId`
    if [ $? != 0 ] ; then
        error "ERR: ec2-create-snapshot"
        exit 1
    fi
    ${AWS} ec2 create-tags --resources ${SNAPSHOT_ID} --tags "Key=Name,Value=${INSTANCE_NAME}-$(date '+%Y/%m/%d')"
    if [ $? != 0 ] ; then
        error "ERR: ec2-create-tags"
        exit 1
    fi
}

delete_old_snapshot() {
    SNAPSHOTS=`${AWS} ec2 describe-snapshots --output text | grep ${VOL_ID} | grep "Created by SYSTEMBK" | wc -l`
    while [ ${SNAPSHOTS} -gt ${SNAPSHOTS_PERIOD} ]
    do
        ${AWS} ec2 delete-snapshot --snapshot-id `${AWS} ec2 describe-snapshots --output text | grep ${VOL_ID} | grep "Created by SYSTEMBK" | sort -k 11,11 | awk 'NR==1 {print $10}'`
        if [ $? != 0 ] ; then
            error "ERR: ${SHELLDIR}/${SHELLNAME} ec2-delete-snapshot"
            exit 1
        fi
        SNAPSHOTS=`${AWS} ec2 describe-snapshots | grep ${VOL_ID} | grep "Created by SYSTEMBK" | wc -l`
    done
}

sudo yum install jq

create_snapshot
delete_old_snapshot
success "Snapshot was created successfully!"

exit 0
