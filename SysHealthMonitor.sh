#!/bin/bash
healthfile=$1
date +'%d_%m_%Y'>> $healthfile
vmstat 21599 4 >> $healthfile #four times a day with equal interval

