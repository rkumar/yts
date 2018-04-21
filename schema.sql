#DROP TABLE yify;

CREATE TABLE yify(id INTEGER,
imdbid TEXT, 
title TEXT,
title_english TEXT,
year INTEGER,
runtime INTEGER,
summary TEXT,
description_full TEXT,
rating TEXT,
mpa_rating TEXT,
language TEXT,
genres TEXT,
date_uploaded TEXT,
url TEXT,
torrent_url TEXT,
status TEXT);
CREATE UNIQUE INDEX yify_imdbid ON yify(imdbid);
CREATE UNIQUE INDEX yify_id ON yify(id);
