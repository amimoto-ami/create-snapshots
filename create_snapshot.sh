#!/usr/bin/env bash

set -ex

SHELLDIR=`dirname ${0}`
SHELLDIR=`cd ${SHELLDIR}; pwd`
SHELLNAME=`basename $0`

LOG_DIR="~/logs"
LOG_SAVE_PERIOD=14
LOG_FILE="${LOG_DIR}/${SHELLNAME}.log"

REGION=ap-northeast-1
SNAPSHOTS_PERIOD=2

AWS="/usr/bin/aws --region ${REGION}"

INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

rotate_log() {
    (( cnt=${LOG_SAVE_PERIOD} ))
    while (( cnt > 0 ))
    do
        logfile1=${LOG_FILE}.$cnt
        (( cnt=cnt-1 ))
        logfile2=${LOG_FILE}.$cnt
        if [ -f $logfile2 ]; then
            mv $logfile2 $logfile1
        fi
    done

    if [ -f $LOG_FILE ]; then
        mv ${LOG_FILE} ${LOG_FILE}.1
    fi
    touch $LOG_FILE
}

print_msg() {
    echo "`date '+%Y/%m/%d %H:%M:%S'` $1" | tee -a ${LOG_FILE}
}

create_snapshot() {
    print_msg "Create snapshot Start"
    VOL_ID=`${AWS} ec2 describe-instances --instance-ids ${INSTANCE_ID} --output text | grep EBS | awk '{print $5}'`
    if [ -z ${VOL_ID} ] ; then
        echo ${VOL_ID}
        print_msg "ERR:ec2-describe-instances"
        logger -f ${LOG_FILE}
        exit 1
    fi
    print_msg "ec2-describe-instances Success : ${VOL_ID}"
    ${AWS} ec2 create-snapshot --volume-id ${VOL_ID} --description "Created by SYSTEMBK(${INSTANCE_ID}) from ${VOL_ID}" >> ${LOG_FILE} 2>&1
    if [ $? != 0 ] ; then
        print_msg "ERR:${SHELLDIR}/${SHELLNAME} ec2-create-snapshot"
        logger -f ${LOG_FILE}
        exit 1
    fi
    print_msg "Create snapshot End"
}

delete_old_snapshot() {
    print_msg "Delete old snapshot Start"
    SNAPSHOTS=`${AWS} ec2 describe-snapshots --output text | grep ${VOL_ID} | grep "Created by SYSTEMBK" | wc -l`
    while [ ${SNAPSHOTS} -gt ${SNAPSHOTS_PERIOD} ]
    do
        ${AWS} ec2 delete-snapshot --snapshot-id `${AWS} ec2 describe-snapshots --output text | grep ${VOL_ID} | grep "Created by SYSTEMBK" | sort -k 11,11 | awk 'NR==1 {print $10}'` >> ${LOG_FILE} 2>&1
        if [ $? != 0 ] ; then
            print_msg "ERR:${SHELLDIR}/${SHELLNAME} ec2-delete-snapshot"
            logger -f ${LOG_FILE}
            exit 1
        fi
        SNAPSHOTS=`${AWS} ec2 describe-snapshots | grep ${VOL_ID} | grep "Created by SYSTEMBK" | wc -l`
    done
    print_msg "Delete old snapshot End"
}

rotate_log

print_msg "INF:$SHELLDIR/${SHELLNAME} START"
create_snapshot
delete_old_snapshot
print_msg "INF:$SHELLDIR/${SHELLNAME} END"

exit 0
