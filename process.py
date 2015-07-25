#!/usr/local/bin/python

import sqlite3
from lxml import etree
import datetime
import sys
import re

con = sqlite3.connect('qanda.db')

# Open file
doc = open(sys.argv[1])
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
    cur.execute("INSERT INTO eps(date, theme) VALUES (?,?)", (epDate.strftime('%Y-%m-%d'), epTheme))
    epId = cur.lastrowid

# ************ TRANSCRIPT **************
# Extract transcript
# (show, seq, topic, speaker, speech)
reAction = re.compile("^\(.*\)$")
reSpeech = re.compile("^([A-Z ]*):(.*)$")

epScript = tree.xpath('//div[@id="transcript"]')
seq = 0
speeches = []
for speechtext in epScript[0].itertext():
    speechtext = speechtext.strip()
    if reAction.match(speechtext):
# for now, silently drop actions
        x = 1
#        print speechtext
#        seq = seq + 1
    else:
        m = reSpeech.match(speechtext)
        if m:
            speaker = m.group(1).strip()
            script = m.group(2).strip()
            wc = len(script.split(None))
            speeches.append((epId, seq, speaker, script, wc))
            seq = seq + 1

for (epId, seq, speaker, script, wc) in speeches:
    #todo sqlencode
    cur.execute("SELECT speaker_id FROM speakers WHERE name LIKE ?", (speaker,))
    speakerRec = cur.fetchone()
    if speakerRec:
        speakerId = speakerRec[0]
    else:
        cur.execute("INSERT INTO speakers(name) VALUES (?)", (speaker,))
        speakerId = cur.lastrowid

    cur.execute("INSERT INTO speeches(ep_id, seq, speaker_id, script, wc) VALUES (?,?,?,?,?)", (epId, seq, speakerId, script, wc))

# Extract bios
# (name, bio)
epBios = tree.xpath('//div[@class="presenter"]')
for epBio in epBios:
    name = epBio.xpath('a/h4')[0].text.strip().upper()
    bio = '\r\n'.join(epBio.xpath('p/text()')).strip()

    cur.execute("SELECT speaker_id FROM speakers WHERE name LIKE ?", (name,))
    speakerRec = cur.fetchone()
    if speakerRec:
        speakerId = speakerRec[0]
    else:
        cur.execute("INSERT INTO speakers(name) VALUES (?)", (name,))
        speakerId = cur.lastrowid

    cur.execute("INSERT INTO eps_panel(ep_id, speaker_id, bio) VALUES (?, ?, ?)", (epId, speakerId, bio))

# Close file
# Commit changes
con.commit()
doc.close()
