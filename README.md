# yts

This keeps a database of titles uploaded by yi_fy and a ncurses query program (`yify.rb`).

## Processes

 - There are files that pull the latest titles from yi_fy database `latest.sh`.

 - `import.rb` imports the new titles into the database yify.sqlite.

## Setup

Create the database using `schema.sql.`

There are scripts that upload all the earlier files into the database from the json files (`files.sh`).
This calls `import.rb` for each file. First it runs through the files with a running counter.
Then it goes through the day-wise files downloaded after I downloaded all the existing files.

`import.rb` loads the supplied files into the database (used for the files with date in name). This may be called everyday after running `latest.sh` (I run this in a cron job).

Mainly there is an ncurses program `yify.rb` that queries the database, pulls any new title details
that are not in our database from IMDB (using omdb).

This also links to other programs I have such as the OMDB database (IMDB titles).

I also update a status field in the database to indicate whether I am interested in a movie, or have seen a movie, or wish to hide a movie from showing up in the query program.

I suppose for anyone new here, who just wishes to check out the `yify.rb` program, I should dump the first few hundred rows into a file which they can load into the database.

I don't think git takes binary files so I am not uploading the sqlite3 database.

## Requirements

- ruby
- sqlite gem
- umbra gem (ncurses library)

## Ownership

Shifted from imbrium to rkumar since unable to access other repo.
Checking from 2013 Monterey laptop....
