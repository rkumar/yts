#!/usr/bin/env ruby
# Description: Browse YIFY database
# Last update: 2018-06-09 14:55
# 2018-03-19
require 'umbra'
require 'umbra/label'
require 'umbra/listbox'
require 'umbra/box'
require 'umbra/togglebutton'
require 'umbra/field'
require 'umbra/menu'
require 'umbra/textbox'
require 'sqlite3'

#---------- TODO
# fetch rating, genre, language from imdb database
#xdownload torrent, and optionally start torrent.
#x5. sort by rating
# 6. remove horror
# 7. join with IMDB and show actors
# DONE update movie_status table in imdb.sqlite so we have one source for all
# DONE join with movie_status and use that only, otherwise i will be updating status twice.
# TODO how about opening subtitle's page using imdbid
# TODO - how can i query on actors and directors, later language

def startup # {{{
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Time.now.to_s
    $log.info "YIFY #{$0} started on #{today}"
    FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK,   FFI::NCurses::GREEN) # statusline
    dbname = "yify.sqlite"
    @imdbfile = '/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/imdbdata/imdb.sqlite'
    @db = SQLite3::Database.new(dbname)
    @tablename = "yify"
    @total = @db.get_first_value("select count(*) from #{@tablename}")
end # }}}
def flow row, scol, *widgets # {{{
  widgets.each do |w|
    w.row = row
    w.col = scol
    if w.width and w.width > 0
      scol += w.width + 1
    elsif w.text 
      scol += w.text.length + 1
    else
      scol += 10
    end
  end
end # }}}
def get_data db, sql # {{{
  #$log.debug "SQL: #{sql} "
  $columns, *rows = db.execute2(sql)
  #$log.debug "XXX COLUMNS #{sql}, #{rows.count}  "
  content = rows
  return nil if content.nil? or content[0].nil?
  $datatypes = content[0].types #if @datatypes.nil?
  return content
end # }}}
# update the status field in the yify table
# We need to update in list also, for highlighting to show
def update_status lb # {{{
  row = lb.list()[lb.current_index]
  id = row.first

  h = { :x => :hide, :i => :interested, :n => 'not interested', :s => :seen, :m => 'seen by mum',
        :"1" => :bad, :"2" => :average , :"3" => :good , :"4" => :vgood, :"5" => :great, :"0" => :unrated }
  m = Menu.new "Movie Status Menu", h
  ch = m.getkey
  #menu_text = h[ch.to_sym]
  return unless ch # escape pressed
  $log.debug "  update_status: setting #{id} to #{ch} "
  ret = @db.execute("UPDATE #{@tablename} SET status = ? WHERE rowid = ?", [ ch.to_s, id ])
  row[-1] = ch.to_s # update row in list also
  $log.debug "  update_status: get #{ret} "
  update_status_in_imdb(lb)
end # }}}
def sort_menu lb # {{{
  h = { :y => :year, :r => :rating, :t => :title, :i => :id, :n => "newest" }
  m = Menu.new "Sort Menu", h
  ch = m.getkey
  l = lb.list
  sorted = nil
  #@query ="SELECT m.rowid, id, year, title, rating, genres, ms.status FROM #{@tablename} m LEFT JOIN imdb.movie_status ms ON m.imdbid = ms.imdbid "
  case ch
  when "y"
    sorted = l.sort_by { |k| k[2] }
  when "n"
    sorted = l.sort_by { |k| k[2].to_i()*-1 }
  when "r"
    sorted = l.sort_by { |k| k[4].to_f()*-1 }
  when "t"
    sorted = l.sort_by { |k| k[3] }
  when "i"
    sorted = l.sort_by { |k| k[1] }
  else
    alert("sortmenu got #{ch} unhandled")
    return
  end
  lb.list = sorted if sorted
end # }}}
def view_details lb, db # {{{
  data = lb.current_row()
  #id = data.first
  id = data[0,4]
  id = get_id(lb)
  row = @db.get_first_row("SELECT cast(id as text), title, cast(year as text), language, genres, url, imdbid, rating, description_full FROM #{@tablename} WHERE rowid = #{id}")
  desc = wrap_text(row[-1]) if row[-1]
  desc ||= ["No description"]
  row[-1] = "--------------------"
  row.push(*desc)

  #$log.debug "  ROWW: #{row}"
  view row
end # }}}
# remove a row from screen and also update database with hide status
def delete_row lb # {{{
  index = lb.current_index
  id = lb.list[lb.current_index].first
  lb.list().delete_at(index)
  lb.touch
  ret = @db.execute("UPDATE #{@tablename} SET status = ? WHERE rowid = ?", [ "x", id ])
end # }}}
# wraps given string to width characters, returning an array
# returns nil if null string given
def wrap_text(s, width=78)    # {{{
  return nil unless s
	s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n").split("\n")
end
def statusline win, str, column = 1
  # LINES-2 prints on second last line so that box can be seen
  win.printstring( FFI::NCurses.LINES-1, 0, " "*(win.width), 6, REVERSE)
  win.printstring( FFI::NCurses.LINES-1, column, str, 6, REVERSE)
end   # }}}
def view_in_browser lb # {{{
  curr = lb.current_index
  data = lb.list[curr]
  #imdbid = data[5]
  imdbid = get_columns_as_array(lb, "imdbid").first
  $log.debug "  view_in_browser :: imdbid:#{imdbid}. data:#{data}"
  system("open https://www.imdb.com/title/#{imdbid}/")
end # }}}
def join_imdb lb # {{{
  curr = lb.current_index
  data = lb.list[curr]
  #imdbid = data[5]
  imdbid = get_columns_as_array(lb, "imdbid").first
  $log.debug "  join :: imdbid:#{imdbid}. data:#{data}"
  file='/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/imdbdata/imdb.sqlite'
  res = %x{ sqlite3 #{file} -line "select * from imdb where imdbid = '#{imdbid}'"}
  $log.debug "  RETURNED rfom imdb with: "
  $log.debug "  #{res} "
  if res and !res.empty?
    res = wrap_text(res, 80)
    $log.debug "wrapped:  #{res} "
    view res
  else
    ret = alert("No data in #{File.basename(file)} for #{imdbid}. Shall I fetch?", buttons: ["Ok","Cancel"])
    # the dialog continues to show until the next command is over
    # should i do a refresh here, or panel update ?
    # If the next command hangs then the window also gets stuck on screen
    if ret == 0

      #$mywin.refresh # this solves the issue of the dialog remaining here, but user will wonder why
                     # app is unresponsive
      # f.sh fetches from omdb api
      command = File.expand_path("~/bin/src/f.sh")
      # system screwed up the display
      #system("#{command} #{imdbid}")
      res = %x{#{command} #{imdbid} 2>&1}

      $log.debug "==> f.sh: #{res}"
    end
  end
end # }}}
def generic_edit data, columns # {{{
  require 'umbra/messagebox'
  require 'umbra/labeledfield'
  array = []
  mb = MessageBox.new title: "Editing #{data.first}", width: 80 do
    data.each_with_index do |r, ix|
      f =  LabeledField.new label: columns[ix], name: columns[ix], text: r, col: 20, color_pair: CP_CYAN, attr: REVERSE
      add f
      array << f
    end
  end
  ret = mb.run
  # return a hash rather than an array. maybe we should pass a hash also
  return ret, array
end # }}}
def download_torrent lb # {{{
  index = lb.current_index
  id = lb.list[lb.current_index].first
  rowdata = get_data(@db, "select title, year, torrent_url from #{@tablename} WHERE rowid = #{id}")
  data = rowdata.first
  title, year, torrent_url = data
  stub = "#{title}_#{year}.torrent".tr(' ','_').tr("'","_").gsub('&','_')
  $log.debug "  download_torrent: stub:: #{stub} "

  if torrent_url
    res=%x{ wget --no-check-certificate -q -O #{stub} #{torrent_url} }
    $log.debug "  SYS : URL:#{torrent_url}"
    $log.debug "  SYS : #{res}"
    if File.exist? stub
      # TODO check that file is not empty since wget has been giving issues
      alert("Downloaded #{stub}")
    else
      alert("Error in download of #{stub}")
    end
  else
    alert("No url found. Check YIFY")
  end

end # }}}
def edit_row lb # {{{
  # TODO put actual widths and maxlens for various fields.
  index = lb.current_index
  id = lb.list[lb.current_index].first
  rowdata = get_data(@db, "select * from #{@tablename} WHERE rowid = #{id}")
  $log.debug "  DATA = #{rowdata}"
  $log.debug "  COLS = #{$columns}"
  return unless rowdata
  return if rowdata.empty?
  return if rowdata.first.empty?
  data = rowdata.first
  require 'umbra/messagebox'
  require 'umbra/labeledfield'
  
  array = []
  mb = MessageBox.new title: "Editing #{data.first}", width: 80 do
    data.each_with_index do |r, ix|
      x =  LabeledField.new label: $columns[ix], name: $columns[ix], text: r, col: 20, maxlen: 80, color_pair: CP_CYAN, attr: REVERSE
      array << x
      add x
    end
  end
  ret = mb.run
  if ret == 0
    # okay pressed
    _update_row(@db, id, $columns, data, array)
    # TODO the on-screen row also to be updated.
  end
end # }}}


def _update_row db, id, columns, data, array # {{{
  raise ArgumentError, "_update_row:: data and array don't match" if data.size != array.size
  raise ArgumentError, "_update_row:: columns and array don't match" if columns.size != array.size

  columns.each_with_index do |c, ix|
    next if c == "id" or c == "rowid"
    oldvalue = data[ix]
    value = array[ix].text
    if oldvalue != value
      $log.debug "  updating #{c} to #{value} for #{id}  "
      ret = db.execute("UPDATE #{@tablename} SET #{c} = ? WHERE rowid = ?", [ value, id ])
    end
  end
end # }}}
def update_genre(lb)
  imdbid = get_columns_as_array(lb, "imdbid").first
  $log.debug "  IMDBID is #{imdbid}"
  if !File.exist?(@imdbfile)
    alert "IMDB file does not exist!"
    return
  end
  db = SQLite3::Database.new(@imdbfile)
  genre, language = db.get_first_row("SELECT genre, language FROM imdb WHERE imdbid = '#{imdbid}'")
  $log.debug "  IMDB: #{genre} :: #{language}"
  if genre.nil? and language.nil?
    alert "No row in imdb.sqlite for #{imdbid}"
    return
  end
  #alert "  IMDB: #{genre}:: #{language}"
  #alert " Got #{data}"
  ret = @db.execute("UPDATE #{@tablename} SET genres = ?, language = ? WHERE imdbid = ?", [ genre, language, imdbid ])
  row = lb.list()[lb.current_index]
  row[5] = genre
  lb.touch
end
def update_status_in_imdb(lb)
  imdbid, status = get_columns_as_array(lb, "imdbid, status")
  $log.debug "  IMDBID is #{imdbid} status is #{status} "
  if !File.exist?(@imdbfile)
    alert "IMDB file does not exist!"
    return
  end
  db = SQLite3::Database.new(@imdbfile)
  count = db.get_first_value("SELECT count(1) FROM movie_status WHERE imdbid = '#{imdbid}'")
  if count == 0
    #alert "No row in imdb.sqlite movie_status for #{imdbid}"
    str = "INSERT INTO movie_status (imdbid, status) VALUES (?,?)"
    db.execute(str, [imdbid, status])
    return
  end
  #alert "  IMDB: #{genre}:: #{language}"
  ret = db.execute("UPDATE movie_status SET status = ? WHERE imdbid = ?", [ status, imdbid ])
end
def get_columns_as_array(lb, *cols)
  id = get_id(lb)
  $log.debug "  rowID is #{id} "
  columns = cols.join(", ")
  $log.debug "  get_columns: #{columns}"
  rows = @db.execute("select #{columns} from #{@tablename} where rowid = ?", [id])
  return rows.first
end
## returns rowid of current row
def get_id(lb)
  curr = lb.current_index
  data = lb.list[curr]
  id = data.first
end
begin
  include Umbra
  init_curses
  startup
  win = Window.new
  #$mywin = win
  statusline(win, " "*(win.width-0), 0)
  #win.box
  statusline(win, "Press C-q to quit #{win.height}:#{win.width}", 20)
  str = "----- YIFY titles (#{@total}) -----"
  win.title str
  @query ="SELECT m.rowid, id, year, title, rating, genres, ms.status FROM #{@tablename} m LEFT JOIN imdb.movie_status ms ON m.imdbid = ms.imdbid "
  @db.execute("ATTACH DATABASE ? AS imdb;", [ "/Volumes/Pacino/dziga_backup/rahul/Downloads/MOV/imdbdata/imdb.sqlite"])

  #query = "#{@query}, ms.status FROM #{@tablename} m, imdb.movie_status ms WHERE m.imdbid = ms.imdbid and ms.status != 'x'  ORDER BY m.rowid desc LIMIT 1000"
  #query = "#{@query} WHERE ms.status != 'x' or ms.status IS NULL  ORDER BY m.rowid desc LIMIT 1000"
  query = "#{@query} WHERE ms.status != 'x' or ms.status IS NULL  ORDER BY m.rowid desc "
  #query = "#{@query} FROM #{@tablename} WHERE status is NULL or status != 'x' ORDER BY id desc LIMIT 1000"
  alist = get_data @db, query

  catch(:close) do
    form = Form.new win
    boxrow = 2
    ltitle = Label.new text: "Title :", row: boxrow-1, col: 4, mnemonic: "T"
    title  = Field.new name: "title", row: ltitle.row, col: 20, width: 20, attr: REVERSE, color_pair: CP_CYAN
    lyear  = Label.new text: "Year :", row: boxrow-1, col: 4, mnemonic: "y"
    year   = Field.new name: "year", row: ltitle.row, col: 20, width: 4, attr: REVERSE, color_pair: CP_CYAN
    lyearto = Label.new text: "-", row: boxrow-1, col: 4
    yearto = Field.new name: "yearto", row: ltitle.row, col: 20, width: 4, attr: REVERSE, color_pair: CP_CYAN
    lgenre = Label.new text: "Genre :", row: boxrow-1, col: 4
    genre = Field.new name: "genre", row: ltitle.row, col: 20, width: 10, attr: REVERSE, color_pair: CP_CYAN
    lstatus = Label.new text: "Status :", row: boxrow-1, col: 4
    status = Field.new name: "status", row: ltitle.row, col: 20, width: 1, attr: REVERSE, color_pair: CP_CYAN

    ltitle.related_widget = title
    lyear.related_widget = year

    searchb = Button.new text: "Search", mnemonic: "s"

    form.add_widget ltitle, title, lyear, year, lyearto, yearto, lgenre, genre, lstatus, status, searchb
    flow(ltitle.row, 4, ltitle, title, lyear, year, lyearto, yearto, lgenre, genre, lstatus, status)
    searchb.col = FFI::NCurses.COLS-10
    searchb.row = ltitle.row

    box = Box.new row: boxrow, col: 0, width: win.width, height: win.height-7
    #lb = Listbox.new list: data
    #lb = Listbox.new list: alist
    lb = Listbox.new selection_key: 0 # Ctrl-0. We arent using selection here.
    # this event will register after listbox has been populated the first time. That is why I am setting 
    #  the list after the bind_event
    lb.bind_event(:CHANGED) { |list| box.title = "#{list.list().size} rows"; box.touch; }
    lb.list = alist
    lb.search_offset = 2
    def lb.value_of_row(line, ctr, state)
      #mark = mark_of_row(ctr, state)
      #"#{mark}%4s %4s %-50s %-3s %-s" % line[1,6]
      "%4s %4s %-50s %-3s %-s" % line[1,6]
    end
    def lb.to_searchable(index)
      value_of_row(self.list[index], index, nil)
    end
  
    def lb.color_of_row(index, state) # {{{
      arr = super
      if state == :NORMAL
        # make bold if it status is i
        row = self.list[index]
        status = row[-1]
        #$log.debug "#{index}.  STATUS =#{status}, row = #{row}"
        if status == "i"
          arr[0] = CP_YELLOW
          arr[1] = BOLD
        elsif ["x", "n", "1"].include?(status)
          arr[0] = CP_BLUE
        elsif ["4", "5"].include?(status)
          arr[0] = CP_GREEN
          arr[1] = BOLD
        end
      end
      arr
    end # }}}
    # some status have been set to blob from this program, so queries don't work as expected.
    # check select rowid, title, status from yify where typeof(status) = "blob";
    def lb.mark_of_row(index, state)  # {{{
      checkmark = "\u2713".encode('utf-8');
      xmark = "\u2717".encode('utf-8');
      emptymark = "\u2610".encode('utf-8');
      mark = super
      smark = " "
      if state == :NORMAL
        # make bold if it status is i
        row = self.list[index]
        status = row[-1]
        #$log.debug "#{index}.  STATUS =#{status}, row = #{row}"
        if status == "i" 
          smark = emptymark

        elsif ["x", "n"].include?(status)
          smark = xmark
        elsif status.nil? or status == "0" or status == "."
        else
          smark = checkmark
        end
      end
      return "#{smark}#{mark}"
    end # }}}
    #data = format_data alist, "%4s %8s %4s %-50s %-3s %-s"
    box.fill lb
    brow = box.row+box.height

    textb = Textbox.new row: brow, col: 0, width: FFI::NCurses.COLS-1, height: FFI::NCurses.LINES-brow-1

    # we are no longer showing these two test buttons taking up space and useless. REMOVE TODO

    # bind the most common event for a listbox which is ENTER_ROW
    lb.command do |ix|
      data = lb.current_row()
      #id = data[0,4]    ## FIXME change to use rowid
      id = get_id(lb)
      curr = lb.current_index+1
      #id = data.first
      # display some stuff in statusline for row under cursor
      row = @db.get_first_row("SELECT id, title, imdbid, status, language, description_full FROM #{@tablename} WHERE rowid = #{id}")
      #$log.debug "  ROW #{row.class} :: #{row}"
      statusline(win, "#{curr}/#{lb.list.size}. #{id}.#{row[1]}, #{row[2]}, (#{row[3]}), #{row[4]}        ")
      # display some stuff in textbox for row under cursor
      desc = wrap_text(row[-1], textb.width) if row[-1]
      textb.list = desc || ["No description"]

    end
    lb.bind_key(?s.getbyte(0), 'update status') { |w| update_status(w); w.cursor_down; }
    lb.bind_key(?v.getbyte(0), 'view details')  { view_details(lb, @db) }
    lb.bind_key(?V.getbyte(0), 'view IMDB')  { join_imdb(lb) }
    lb.bind_key(?S.getbyte(0), 'sort menu')  { sort_menu(lb) }
    lb.bind_key(?D.getbyte(0), 'delete row') { delete_row(lb) }
    lb.bind_key('o', 'open in browser')      { view_in_browser(lb) }
    lb.bind_key('e', 'edit row')             { edit_row(lb) }
    lb.bind_key('`', 'download torrent file'){ download_torrent(lb) }
    lb.bind_key('u', 'update genres'){ update_genre(lb) }
    searchb.command do # {{{
      # construct an sql statement using title, year and genre
      #sql = "SELECT id, imdbid, year, title, rating, genres FROM #{@tablename} WHERE "
      sql = "#{@query} "
      query = []
      bind_vars = []
      if title.text.length >= 3
        query << " TITLE LIKE ? "
        bind_vars << "%#{title.text}%"
      end
      if year.text.length == 4
        query << " YEAR >= ? "
        bind_vars << year.text.to_i
      end
      if yearto.text.length == 4
        query << " YEAR <= ? "
        bind_vars << yearto.text.to_i
      end
      if genre.text.length > 2
        query << " GENRES LIKE ? "
        bind_vars << "%#{genre.text}%"
      end
      if status.text.length > 0
        query << " ms.STATUS = ? "
        bind_vars << "#{status.text}"
      end
      if !query.empty?
        sql +=  "WHERE " + query.join("AND")
      end
      sql += " ORDER BY rating DESC"
      if query.empty?
        sql += " LIMIT 1000 "
      end
      $log.debug "  SQL: #{sql} "
      $log.debug "  ibv:  #{bind_vars.join ','} "
      #alert sql
      #alert bind_vars.join " , "
      #alist = get_data @db, query
      alist = @db.execute( sql, bind_vars)
      $log.debug "  SQL alist #{alist.class}, #{alist.size} "
      #data = format_data alist, "%4s %8s %4s %-50s %-3s %-s"
      #lb.list = data
      lb.list = alist
    end # }}}
    # bind to another event of listbox
    #lb.bind_event(:LEAVE_ROW) { |ix| statusline(win, "LEFT ROW #{ix.first}", 50) }
    #lb.bind_event(:LIST_SELECTION_EVENT) { |w| alert("You selected row #{w.selected_index || "none"} ") }
    #lb.bind_event(:LIST_SELECTION_EVENT) { |w| update_status(w.list[w.current_index]); w.cursor_down; }
    form.add_widget box, lb, textb
    form.pack
    form.select_first_field
    win.wrefresh

    while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
      begin
        form.handle_key ch
      rescue => e
        puts e
        puts e.backtrace.join("\n")
        $log.debug e.to_s
        $log.debug e.backtrace.join("\n")

      end
      win.wrefresh
    end
  end # close

rescue => e
  win.destroy if win
  win = nil
  FFI::NCurses.endwin
  puts "ex4 rescue"
  puts e
  puts e.backtrace.join("\n")
        $log.debug e.to_s
        $log.debug e.backtrace.join("\n")
ensure
  win.destroy if win
  FFI::NCurses.endwin
  if e
    puts "ex4 ensure"
    puts e 
    puts e.backtrace.join("\n")
        $log.debug e.to_s
        $log.debug e.backtrace.join("\n")
  end
end
