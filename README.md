# yts

This keeps a list of titles uploaded by yi_fy.

There are files that pull the latest titles from yi_fy database `latest.sh`.

`import.rb` imports the new titles into the database yify.sqlite.

Create the database using schema.sql.

There are scripts that upload all the earlier files into the database from the json files.

Mainly there is an ncurses program yify.rb that queries the database, pulls any new title details
that are not in our database from IMDB (using omdb).

This also links to other programs I have such as the OMDB database (IMDB titles). 

I also update a status field to indicate whether I am interested in a movie, or have seen a movie, or wish to hide a movie.


I suppose for anyone new here, who just wishes to check out the `yify.rb` program, I should dump the first few hundred rows into a file which they can load into the database.
