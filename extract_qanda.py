#!/usr/local/bin/python3

import sqlite3
from lxml import etree
import datetime
import sys
import re

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
    'JUDGE'
])

# TODO need to do postnominals too

clean_name_cache = {}
def clean_name(name):
    try:
        return clean_name_cache[name]
    except KeyError: 
        # Make sure names are within latin-1 character set so we can use Excel etc to manipulate
        outname = name.encode('ascii', errors="ignore").decode('ascii')
        name_parts = outname.split(' ')
        if name_parts[0] in honorifics:
            outname = ' '.join(name_parts[1:])
        clean_name_cache[name] = outname
        return outname

con = sqlite3.connect('qanda.db')

# Open file
filename = sys.argv[1]
try:
    doc = open(filename, encoding="iso-8859-1")
    parser = etree.HTMLParser()
    tree = etree.parse(doc, parser)

    # ************ EPISODE **************
    # Extract date
    epDatetext = tree.xpath('//p[@id="epDate"]')[0].text.strip()
    epDate = datetime.datetime.strptime(epDatetext, '%A %d %B, %Y')

    # Extract title
    epTheme = tree.xpath('//div[@id="middleCol"]/h2')[0].text.strip()

    # Create eps entry
    with con:
        cur = con.cursor()
        # todo SQL encode this as good practice
        #print(epDate)
        #print(epTheme)
        cur.execute("INSERT INTO eps(ep_date, theme) VALUES (?,?)", (epDate.strftime('%Y-%m-%d'), epTheme))
        #epId = cur.lastrowid

    # ************ TRANSCRIPT **************
    # Extract transcript
    # (show, seq, topic, speaker, speech)
    reAction = re.compile("^\(.*\)$")
    reSpeech = re.compile("^([A-Z ]*):(.*)$")

    epScript = tree.xpath('//div[@id="transcript"]')
    seq = 0
    speeches = []
    try:
        for speechtext in epScript[0].itertext():
            speechtext = speechtext.strip()
            if reAction.match(speechtext):
                pass # We don't currently save actions
                #print speechtext
        #        seq = seq + 1
            else:
                m = reSpeech.match(speechtext)
                if m:
                    speaker = clean_name(m.group(1).strip())
                    script = m.group(2).strip()
                    wc = len(script.split(None))
                    speeches.append((epDate, seq, speaker, script, wc))
                    seq = seq + 1
    except IndexError:
        print("({}) No transcript found for episode of {} ('{}')".format(filename, epDate, epTheme))
        sys.exit(-1)

    for (epDate, seq, speaker, script, wc) in speeches:
        #todo sqlencode
        cur.execute("SELECT speaker_id FROM speakers WHERE name LIKE ?", (speaker,))
        speakerRec = cur.fetchone()
        if speakerRec:
            speakerId = speakerRec[0]
        else:
            cur.execute("INSERT INTO speakers(name) VALUES (?)", (speaker,))
            speakerId = cur.lastrowid

        cur.execute("INSERT INTO speeches(ep_date, seq, speaker_id, name, script, wc) VALUES (?,?,?,?,?,?)",
                    (epDate.strftime('%Y-%m-%d'), seq, speakerId, speaker, script, wc))

    # Extract bios
    # (name, bio)
    epBios = tree.xpath('//div[@class="presenter"]')
    for epBio in epBios:
        name = clean_name(epBio.xpath('a/h4')[0].text.strip().upper())
        bio = '\r\n'.join(epBio.xpath('p/text()')).strip()

        cur.execute("SELECT speaker_id FROM speakers WHERE name LIKE ?", (name,))
        speakerRec = cur.fetchone()
        if speakerRec:
            speakerId = speakerRec[0]
        else:
            cur.execute("INSERT INTO speakers(name) VALUES (?)", (name,))
            speakerId = cur.lastrowid

        try:
            cur.execute("INSERT INTO eps_panel(ep_date, speaker_id, name, bio) VALUES (?, ?, ?, ?)",
                        (epDate.strftime('%Y-%m-%d'), speakerId, name, bio))
        except sqlite3.IntegrityError:
            print("({}) Error: panellist {} may appear twice".format(filename, name))

    # Close file
    # Commit changes
    con.commit()
    doc.close()
except Exception as e:
    print("({}) Uncaught exception".format(sys.argv[1]))
    raise