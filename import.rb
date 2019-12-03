#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: json.rb
#  Description: read a json file from yts containing 50 movies and insert into sqlite
#       Author:  r kumar
#         Date: 2018-04-03 - 12:13
#  Last update: 2019-10-31 12:02
#      License: MIT License
# ----------------------------------------------------------------------------- #
# ISSUES
#   The json file contains entries in reverse order of id, latest first. So while inserting
#     I need to reverse it.
#   The files often contains entries that have already been inserted, but with additional info
#     such as genre or rating. Therefore we need to update later entries over earlier ones.
#
require 'json'
    # h = JSON.parse(str)
require 'sqlite3'
dbname = "yify.sqlite"
@db = SQLite3::Database.new(dbname)
#require 'color' # see ~/work/projects/common/color.rb
  # print color("Hello there black reverse on yellow\n", "black", "on_yellow", "reverse")

# --- some common stuff ---
## date in yyyy-mm-dd format
#today = Date.today.to_s
#now = Time.now.to_s
# include? exist? each_pair split gsub


def read_file_in_loop filename
  line = IO.read(filename)
  #$stderr.puts line.class
  hash = JSON.parse(line)
  h = hash["data"]["movies"]
  #$stderr.puts h.class
  #$stderr.puts h.size
  arr = []
  h.each_with_index do |mov, ix|
    #$stderr.puts mov.keys
    newhash = {}
    %w{ id imdb_code title title_english year runtime summary description_full rating mpa_rating language date_uploaded url}.each { |key|
      #arr << mov[key]
      newhash[key] = mov[key]
    }
    newhash["imdbid"] = newhash["imdb_code"]
    newhash.delete "imdb_code"
    if mov["genres"]
      #arr << mov["genres"].join(",") if mov["genres"]
      newhash["genres"] = mov["genres"].join(", ") if mov["genres"]
    else
      #arr << "-"
      newhash["genres"] = "-"
    end
    if mov["torrents"]
      newhash["torrent_url"] = mov["torrents"][0]["url"]  # added 2018-04-18 - so we can download from program
    end
    #str = arr.join("\t")
    #puts str
    arr << newhash
  end
  # so entries are in order of id.
  arr = arr.reverse
  table_upsert_hash @db, "yify", arr
end
# actually since sometimes the data gets updated, we should insert and then update other fields
def table_insert_hash db, table, array # {{{
  $stderr.puts "inside table_insert_hash " if $opt_verbose
  array.each do |hash|
    str = "INSERT OR IGNORE INTO #{table} ("
    qstr = [] # question marks
    fields = [] # field names
    bind_vars = [] # values to insert
    hash.each_pair { |name, val|
      fields << name
      bind_vars << val
      qstr << "?"
    }
    fstr = fields.join(",")
    str << fstr
    str << ") values ("
    str << qstr.join(",")
    str << ");"
    $stderr.puts "#{hash["id"]}: #{hash["imdbid"]}    #{hash["title"]} " if $opt_verbose
    #puts " #{hash["Title"]} #{hash["imdbID"]} "
    db.execute(str, bind_vars)
    #rowid = @db.get_first_value( "select last_insert_rowid();")
    #return rowid
  end
end # }}}
def table_upsert_hash db, table, array
  $stderr.puts "inside table_upsert_hash " if $opt_verbose
  array.each do |hash|
    id = hash["id"]
    imdbid = hash["imdbid"]
    str = "INSERT OR IGNORE INTO #{table} (id, imdbid) values ( #{id} , \"#{imdbid}\" );"
    db.execute(str);
    #puts str
    str =  "UPDATE #{table} SET "
    qstr = [] # question marks
    #fields = [] # field names
    bind_vars = [] # values to insert
    hash.each_pair { |name, val|
      #fields << name
      # don't allow null to overwrite data, 2018-04-12
      if val and val != "" and val != "-"
        bind_vars << val
        qstr << "#{name} = ?"
      end
    }
    #fstr = fields.join(",")
    #str << fstr
    #str << ") values ("
    str << qstr.join(",")
    str << " WHERE imdbid = \"#{imdbid}\" ;"
    #str << ");"
    #puts str
    $stderr.puts "#{hash["id"]}: #{hash["imdbid"]}    #{hash["title"]} " if $opt_verbose
    #puts " #{hash["Title"]} #{hash["imdbID"]} "
    db.execute(str, bind_vars) unless bind_vars.empty?
    #rowid = @db.get_first_value( "select last_insert_rowid();")
    #return rowid
  end
end

def _process filename
  read_file_in_loop filename
  require 'fileutils'
  FileUtils.mv filename, 'json/'
end


# -------------- process_args ------------------------------------------------ #
#  for each filename on command line call
#  --------------------------------------------------------------------------- #
def process_args args
  args.each do |file|
    if File.exist? file
      _process file
    else
      $stderr.puts "ERROR: Cannot open file: #{file}."
      exit 1
    end
  end
end

if __FILE__ == $0
  #include Color
  #filename = nil
  $opt_verbose = false
  $opt_debug = false
  $opt_quiet = false
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
        $opt_verbose = v
      end
      opts.on("--debug", "Show debug info") do
        options[:debug] = true
        $opt_debug = true
      end
      opts.on("-q", "--quiet", "Run quietly") do |v|
        $opt_quiet = true
      end
    end.parse!

    p options if $opt_debug
    p ARGV if $opt_debug

    files = nil
    if ARGV.count == 0
      files = Dir.glob("list-movies-*.json")
      if files.count == 0
        $stderr.puts "Can't find json files here. If already run, do 'just sync' now"
        exit 1
      end
    else
      files = ARGV
    end

=begin
    # --- if processing just one file ---------
    filename=ARGV[0] || "list-movies-#{today}.json"
    unless File.exist? filename
      $stderr.puts "File: #{filename} does not exist. Aborting"
      exit 1
    end
    read_file_in_loop filename
    exit 0
=end

    # OR
    #
    # --- if processing multiple files ---------
    if files.size > 0
      $stderr.puts "==> processing files: #{files.size}" if $opt_verbose
      process_args files
    else
      # passed as stdin
      $stderr.puts "   Expecting filenames passed as stdin " if $opt_verbose
      $stdin.each_line do |file|
        if File.exist? file
          _process file
        else
          $stderr.puts "ERROR: Cannot open file: #{file}."
          exit 1
        end
      end
    end
  ensure
  end
end

