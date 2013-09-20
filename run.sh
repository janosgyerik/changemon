#!/bin/sh -e
#
# monitor the output of commands
#

cd $(dirname "$0")

jobs_dir=jobs
mailer=./mailer.sh

msg() {
    echo '*' $*
}

sendalert() {
    $mailer $file $job $subject
}

msg running jobs in $jobs_dir ...

for job in $(ls $jobs_dir); do
    todays_file=$jobs_dir/$job/out/$(date --iso).txt
    last_file=$jobs_dir/$job/out/last.txt
    diff_file=$jobs_dir/$job/out/diff.txt
    run_script=$jobs_dir/$job/run.sh

    if test -s $todays_file; then
        msg job $job already executed today, skipping
        continue
    else
        msg running job $job ...
    fi

    mkdir -p $(dirname "$todays_file")
    > $todays_file
    $run_script > $todays_file
    test -s $todays_file || {
        subject='empty output'
        file=$run_script
        sendalert
    }

    if test -f "$last_file"; then
        diff $last_file $todays_file > $diff_file || :
        test -s $diff_file && {
            subject='difference detected'
            file=$diff_file
            sendalert
        }
    else
        subject='first run'
        file=$todays_file
        sendalert
    fi

    cp -v $todays_file $last_file
done

msg done.
