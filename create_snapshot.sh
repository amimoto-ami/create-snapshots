#!/usr/bin/env bash

set -ex

SHELLDIR=`dirname ${0}`
SHELLDIR=`cd ${SHELLDIR}; pwd`
SHELLNAME=`basename $0`

REGION=ap-northeast-1
SNAPSHOTS_PERIOD=1

AWS="/usr/bin/aws --region ${REGION}"

INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
INSTANCE_NAME=`aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --output json | jq -r '.Reservations[].Instances[].Tags[] | select(.Key == "Name").Value'`

print_msg() {
    echo "`date '+%Y/%m/%d %H:%M:%S'` $1"
}

create_snapshot() {
    print_msg "Create snapshot Start"
    VOL_ID=`${AWS} ec2 describe-instances --instance-ids ${INSTANCE_ID} --output text | grep EBS | awk '{print $5}'`
    if [ -z ${VOL_ID} ] ; then
        echo ${VOL_ID}
        print_msg "ERR:ec2-describe-instances"
        exit 1
    fi
    print_msg "ec2-describe-instances Success : ${VOL_ID}"
    ${AWS} ec2 create-snapshot --volume-id ${VOL_ID} --description "Created by SYSTEMBK(${INSTANCE_ID}) from ${VOL_ID}" --tag "Name=$(INSTANCE_NAME)"
    if [ $? != 0 ] ; then
        print_msg "ERR:${SHELLDIR}/${SHELLNAME} ec2-create-snapshot"
        exit 1
    fi
    print_msg "Create snapshot End"
}

delete_old_snapshot() {
    print_msg "Delete old snapshot Start"
    SNAPSHOTS=`${AWS} ec2 describe-snapshots --output text | grep ${VOL_ID} | grep "Created by SYSTEMBK" | wc -l`
    while [ ${SNAPSHOTS} -gt ${SNAPSHOTS_PERIOD} ]
    do
        ${AWS} ec2 delete-snapshot --snapshot-id `${AWS} ec2 describe-snapshots --output text | grep ${VOL_ID} | grep "Created by SYSTEMBK" | sort -k 11,11 | awk 'NR==1 {print $10}'`
        if [ $? != 0 ] ; then
            print_msg "ERR:${SHELLDIR}/${SHELLNAME} ec2-delete-snapshot"
            exit 1
        fi
        SNAPSHOTS=`${AWS} ec2 describe-snapshots | grep ${VOL_ID} | grep "Created by SYSTEMBK" | wc -l`
    done
    print_msg "Delete old snapshot End"
}

print_msg "START"
create_snapshot
delete_old_snapshot
print_msg "END"

exit 0
