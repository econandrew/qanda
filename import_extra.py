#!/usr/local/bin/python3

import sqlite3
import sys
import csv

con = sqlite3.connect('qanda.db')
cur = con.cursor()

fields = ("ep_date", "gender", "occupation", "party")

cur.execute("DELETE FROM eps_panel_extra")
con.commit()

with open("extra/eps_panel_extra.csv", "r") as f:
    for r in csv.DictReader(f):
        #print("|{}|".format(r['name']))
        cur.execute("SELECT speaker_id FROM eps_panel WHERE ep_date = ? AND name = ?", [r['ep_date'], r['name']])
        panelRec = cur.fetchone()
        try:
            speakerId = panelRec[0]
            cur.execute(
                "INSERT INTO eps_panel_extra(speaker_id, {}) VALUES (?,?,?,?,?)".format(','.join(fields)),
                [speakerId]+[r[k] for k in fields]
            )
            con.commit()
        except TypeError:
            print("Speaker not found",r['ep_date'], r['name'])