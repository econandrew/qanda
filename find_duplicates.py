#!/usr/local/bin/python3

import sqlite3
import sys

honorifics = set([
    'ADM','ADMINISTRATIVE','AMB','AMBASSADOR','ATTORNEY','ATTY','BR','BROTHER','CAPT','CAPTAIN','CMDR','COACH','COL',
    'COLONEL','COMMANDER','CORPORAL','CPL','DOCTOR','DR','FATHER','FR','GEN','GENERAL','GOV','GOVERNOR','HON','HONORABLE',
    'LIEUTENANT','LIEUTENANT COLONEL','LT','LT COL','MAJ','MAJOR','MASTER','MISS','MONSIGNOR','MR','MRS','MS','MSGR','OFC',
    'OFFICER','PRES','PRESIDENT','PRIVATE','PROF','PROFESSOR','PVT','REP','REPRESENTATIVE','REV','REVEREND','SARGENT',
    'SEC','SECRETARY','SEN','SENATOR','SGT','SISTER','SR','SUPERINTENDENT','SUPT','TREAS','TREASURER','ADM',
    'ADMINISTRATIVE','AMB','AMBASSADOR','ATTORNEY','ATTY','BR','BROTHER','CAPT','CAPTAIN','CMDR','COACH','COL','COLONEL',
    'COMMANDER','CORPORAL','CPL','DOCTOR','DR','FATHER','FR','GEN','GENERAL','GOV','GOVERNOR','HON','HONORABLE',
    'LIEUTENANT','LIEUTENANT COLONEL','LT','LT COL','MAJ','MAJOR','MASTER','MISS','MONSIGNOR','MR','MRS','MS','MSGR',
    'OFC','OFFICER','PRES','PRESIDENT','PRIVATE','PROF','PROFESSOR','PVT','REP','REPRESENTATIVE','REV','REVEREND',
    'SARGENT','SEC','SECRETARY','SEN','SENATOR','SGT','SISTER','SR','SUPERINTENDENT','SUPT','TREAS','TREASURER',
])

names = {}

con = sqlite3.connect('qanda.db')
cur = con.cursor()

def merge_speakers(id_merge, id_keep):
    cur.execute("UPDATE speeches SET speaker_id = ? WHERE speaker_id = ?", [id_keep, id_merge])
    cur.execute("UPDATE eps_panel SET speaker_id = ? WHERE speaker_id = ?", [id_keep, id_merge])
    cur.execute("DELETE FROM speakers WHERE speaker_id = ?",[id_merge])
    con.commit()

for speaker_id, name in cur.execute("SELECT speaker_id, name FROM speakers WHERE speaker_id IN (SELECT speaker_id FROM eps_panel)"):
    names[name] = speaker_id

for name in names:
    name_parts = name.split(' ')
    if name_parts[0] in honorifics:
        base_name = ' '.join(name_parts[1:])
        if base_name in names:
            print('Possible duplicate')
            print('\t', name)
            print('\t', base_name)
            print('Merge [Y/N]?')
            reply = sys.stdin.readline()
            if reply[0] in ('y','Y'):
                print('Merging.')
                merge_speakers(names[name], names[base_name])