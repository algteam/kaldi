#!/usr/bin/python

import ctypes;
import re;
import os;
import sys;


def getname(filename):
    index = filename.find(".wav");
    tmpf = filename[0:index];
    return tmpf; 


enroll_wav = sys.argv[1];
enroll_result = sys.argv[2];

filepath = [];
filedir = [];
filename = [];
spk=[];

for parent, dirnames, filenames in os.walk(enroll_wav):
    for fn in filenames:
        path = os.path.join(parent, fn);

        index = path.find(".wav");
        if -1 == index:
            continue;
        filepath.append(path);

filepath.sort(cmp=None,key=None,reverse=False);
for line in filepath:
    ln = line.split('/');
    ln.reverse();
    filename.append(ln[0]);
    filedir.append(ln[1]);
    if ln[1] not in spk:
        spk.append(ln[1]);

uttlist = open(enroll_result + '/data/enroll/utt.list', 'w')
utt2spk = open(enroll_result + '/data/enroll/utt2spk', 'w')
wavscp = open(enroll_result + '/data/enroll/wav.scp', 'w')
spk2utt = open(enroll_result + '/data/enroll/spk2utt', 'w')

for i in range(len(filename)):
    index = filename[i].find(".wav");
    tmpf = filename[i][0:index];
    utt2spk.write(tmpf + ' ' +  filedir[i] + '\n');
    uttlist.write(tmpf + '\n');
    wavscp.write(tmpf + ' ' + filepath[i] + '\n'); 

for speaker in spk:
    spk2utt.write(speaker);
    for i in range(len(filedir)):
        if speaker == filedir[i]:
            spk2utt.write(' ' + getname(filename[i]));
    spk2utt.write('\n')













