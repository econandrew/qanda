CREATE TABLE eps (
    ep_date DATE PRIMARY KEY,
    theme TEXT
);

CREATE TABLE eps_panel (
    ep_date DATE NOT NULL,
    speaker_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    bio TEXT,
  FOREIGN KEY (ep_date) REFERENCES eps(ep_date),
  FOREIGN KEY (speaker_id) REFERENCES speakers(speaker_id),
  PRIMARY KEY (ep_date, speaker_id)
);

CREATE TABLE eps_panel_extra (
  ep_date DATE NOT NULL,
  speaker_id INTEGER NOT NULL,
  gender INTEGER,
  occupation TEXT,
  party TEXT,
  FOREIGN KEY (ep_date) REFERENCES eps(ep_date),
  FOREIGN KEY (speaker_id) REFERENCES speakers(speaker_id),
  PRIMARY KEY (ep_date, speaker_id)
);

CREATE TABLE speakers (
    speaker_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE speeches (
    ep_date DATE NOT NULL,
    seq INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    speaker_id INTEGER NOT NULL,
    script TEXT NOT NULL,
    wc INTEGER,
    FOREIGN KEY (ep_date) REFERENCES eps(ep_date),
    FOREIGN KEY (speaker_id) REFERENCES speakers(speaker_id),
    PRIMARY KEY (ep_date, seq)
);