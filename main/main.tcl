#!/bin/sh
# The next line restarts using wish \
exec wish "$0" ${1+"$@"}

# This is my first try at programming a Pokédex, and I hope it'll be awesome! 
# It will be written in Tcl/Tk and if there are things that I don't like, I
# will probably switch to Python or something...

#######################################################
#       ____          __     __       __              #
#      / __ \ ____   / /__ _/_/  ____/ /___   _  __   #
#     / /_/ // __ \ / //_// _ \ / __  // _ \ | |/_/   #
#    / ____// /_/ // ,<  /  __// /_/ //  __/_>  <     #
#   /_/     \____//_/|_| \___\ \____/ \___\/_/|_|     #
#                                                     #
#######################################################

### Import libraries
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Those are the versions with which the application was written in.
# Tcl for main code
# Tk for GUI; canvas features are quite specific to version
# Ttk for pretty GUI
# msgcat to ease multi lingual features
# Img for picture handling
# sqlite3 for database management. Most info stored in DB
# tooltip for tooltips; messages that appear on mouse hover
# tablelist for moves table
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package require Tcl       8.6
package require Tk        8.6
package require Ttk       8.6
package require msgcat    1.5.2
package require Img       1.4.3
package require sqlite3   3.8.0.10
package require tooltip   1.4.5
package require tablelist 5.13

### Set up default encoding
encoding system utf-8

### Safeguard cleaning everything on startup
catch {destroy [winfo children .]}

namespace eval pokedex {
  set version        0.04
  set pokeDir        [file join [pwd] [file dirname [info script]]]
  set currentGen     6
  set pokemon        "Pok\u00E9mon"
  set pokedex        "Pok\u00E9dex"
  set pokemonSpecies ""
  
  set generations [list 1 2 3 4 5 6 7]
  set lastIDs [list 151 251 386 493 649 721 807]
  set genRoman [list I II III IV V VI VII]
  set typeList [list Grass Fire Water Bug Flying Electric Ground Rock Fighting \
    Poison Normal Psychic Ghost Ice Dragon Dark Steel Fairy]
  set frames [list]
  set games [list {RB Y} {GS C} {RS E FRLG} {DP Pt HGSS} {BW B2W2} {XY ORAS} {SM USUM}]
  
  array set current {
    gen 6
    idx ""
    game1 2
    game2 2
    game3 3
    game4 3
    game5 2
    game6 2
    game7 2
  }
  
  set pokemonFile [open [file join $pokedex::pokeDir pokemon.txt] r]
  fconfigure $pokemonFile -encoding utf-8
  set pokeList [split [read $pokemonFile] "\n"]
  close $pokemonFile
  
  set TrickorTreat 0
  set ForestCurse 0
}

### Imports
source [file join $pokedex::pokeDir lib.tcl]
source [file join $pokedex::pokeDir menu.tcl]
source [file join $pokedex::pokeDir db.tcl]

### Set up translations
::msgcat::mcload $pokedex::pokeDir
namespace import ::msgcat::mc

### Window configurations like title, favicon and relative window position
wm title . [mc "$pokedex::pokedex v%s" $pokedex::version]
wm iconname . Pokedex
wm geometry . +100+100
#wm iconbitmap . -default "favicon.ico"

### Tk theme
ttk::setTheme vista
#ttk::style configure "." -background #F0F0F0

### Menu settings
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# All the menu items in the main window
# File - Some general commands
# Tools - Some specific tools like calculators, matchups, etc
# About - Information not related to the coding of the app, but about the app
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
set menu .menu
menu $menu -tearoff 0

###
# File
#
# Import mod         - Import file containing Pokémon details other than the usual ones
# Default generation - Set the tab and other minor settings when the app is opened
# Language           - Choose language
# Close              - Exit the app
#
set m $menu.file
menu $m -tearoff 0
$menu add cascade -label [mc "File"] -menu $m -underline 0
$m add command -label [mc "Import mod"] -command {error "Not implemented yet"} \
  -accelerator Ctrl+I
$m add cascade -label [mc "Default generation"] -menu $m.gen -underline 0
$m add cascade -label [mc "Language"] -menu $m.lang -underline 0
$m add separator
$m add command -label [mc "Close"] -command {exit} -accelerator Ctrl+Q

menu $m.gen -tearoff 0

menu $m.lang -tearoff 0
$m.lang add radio -label "English" -variable language
$m.lang invoke 0

###
# Tools
#
# Search Pokémon    - Search one or more Pokémon from various details
# Search Abilities  - Search one or more abilities from various details
# Search Moves      - Search one or more moves from various details
# Search Items      - Search one or more items from various details
# Type Matchup      - Type matchup chart with various options
# Damage calculator - Calculate damage dealt when a Pokémon attacks another one
# Compare Pokémon   - Compare two Pokémon on various aspects
#
set m $menu.tools
menu $m -tearoff 0
$menu add cascade -label [mc "Tools"] -menu $m -underline 0
$m add command -label [mc "Search $pokedex::pokemon"] -command {error "Not implemented yet"}
$m add command -label [mc "Search Abilities"] -command {error "Not implemented yet"}
$m add command -label [mc "Search Moves"] -command {error "Not implemented yet"}
$m add command -label [mc "Search Items"] -command {error "Not implemented yet"}
$m add separator
$m add command -label [mc "Type matchup chart"] -command {pokemenu::type_matchup}
$m add command -label [mc "Damage calculator"] -command {pokemenu::damage_calculator}
$m add command -label [mc "Compare Pok\u00E9mon"] -command {error "Not implemented yet"}

###
# About
#
# About   - Version details, license
# Help    - Guidance about using this app
# Credits - Sites, people who helped
#
set m $menu.about
menu $m -tearoff 0
$menu add cascade -label [mc "About"] -menu $m -underline 0
$m add command -label [mc "Help"] -command {error "Not implemented yet"}
$m add command -label [mc "Credits"] -command pokemenu::poke_credits

. configure -menu $menu

### Generation of the main window
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Filling of the pane at the right, with the list of species and entry box
# at the top with autocomplete features.
#
# Main pane has two parts, the upper detailing the different specifics to
# the Pokémon, and the bottom part the moves the Pokémon can learn.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

### Left part of app
pack [ttk::frame .sidepane -padding 5] -fill y -side left

### Upper left being entry box
pack [ttk::frame .sidepane.top] -fill x -side top
pack [entry .sidepane.top.entry -width 16 -textvariable pokedex::pokemonSpecies \
  -validate all -validatecommand {pokelib::poke_autocomplete %W %d %v %P}] \
  -pady {0 5} -expand 1 -fill x

### Lower left being list display of Pokémon
pack [ttk::frame .sidepane.bottom] -fill both -side top -expand 1
listbox .sidepane.bottom.list -yscrollcommand ".sidepane.bottom.scroll set" \
  -activestyle dotbox -selectmode browse -listvariable $pokedex::pokeList
scrollbar .sidepane.bottom.scroll -command ".sidepane.bottom.list yview"
pack .sidepane.bottom.list .sidepane.bottom.scroll -side left -fill y -expand 1
.sidepane.bottom.list insert 0 {*}$pokedex::pokeList

### Main part where information will be displayed
ttk::frame .mainpane
pack .mainpane -fill both -expand 1 -side right

### Create styles for notebook
ttk::style configure G.TNotebook {*}[ttk::style configure TNotebook]

### Insert tabs
ttk::notebook .mainpane.note -style G.TNotebook
set note .mainpane.note

### Configure tab width and frame
#ttk::style configure Wider.TNotebook -mintabwidth 40
#$note configure -style Wider.TNotebook

pack $note -fill both -expand 1
ttk::notebook::enableTraversal $note

### Insert tabs
foreach a $pokedex::generations b $pokedex::genRoman {
  ttk::frame $note.gen$a
  $note add $note.gen$a -text " Gen $b "
  $menu.file.gen add cascade -label $b -menu $menu.file.gen.game$a
  menu $menu.file.gen.game$a -tearoff 0
}

foreach i $pokedex::generations {
  # Transparent 256x192 image for place holder
  image create photo default -format png \
    -file [file join $pokedex::pokeDir data default.png]

  text $note.gen$i.lab -width 30 -height 2 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.lab insert end [mc "$pokedex::pokemon"]
  $note.gen$i.lab configure -state disabled
  grid $note.gen$i.lab -column 0 -row 0
  
  grid [frame $note.gen$i.down] -row 1 -column 0 -sticky nw
  grid [label $note.gen$i.down.sprite -image default] -row 0 -column 0 -sticky nw
  grid [frame $note.gen$i.down.info] -row 0 -column 1 -sticky nw
  
  label $note.gen$i.down.info.formlab -text [mc "Form name:"]
  label $note.gen$i.down.info.typelab -text [mc "Type:"]
  label $note.gen$i.down.info.genulab -text [mc "Genus:"]
  label $note.gen$i.down.info.abillab -text [mc "Abilities:"]
  label $note.gen$i.down.info.gendlab -text [mc "Gender Ratio:"]
  label $note.gen$i.down.info.eggglab -text [mc "Egg Group:"]
  label $note.gen$i.down.info.heiglab -text [mc "Height:"]
  label $note.gen$i.down.info.weiglab -text [mc "Weight:"]
  
  # #F0F0F0 is the colour of the default grey background. White is the default
  # background of the text widget and would't appear too nice when placed on
  # that grey widget
  text $note.gen$i.down.info.formvar -width 40 -height 1.5 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.down.info.formvar insert end [mc "Unknown"]
  $note.gen$i.down.info.formvar configure -state disabled
  text $note.gen$i.down.info.typevar -width 40 -height 1 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.down.info.typevar insert end [mc "Unknown"]
  $note.gen$i.down.info.typevar configure -state disabled
  text $note.gen$i.down.info.genuvar -width 40 -height 1 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.down.info.genuvar insert end [mc "Unknown"]
  $note.gen$i.down.info.genuvar configure -state disabled
  text $note.gen$i.down.info.abilvar -width 40 -height 1 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.down.info.abilvar insert end [mc "Unknown"]
  $note.gen$i.down.info.abilvar configure -state disabled
  $note.gen$i.down.info.abilvar tag configure hidden -foreground purple
  text $note.gen$i.down.info.gendvar -width 40 -height 1 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.down.info.gendvar insert end " - / -  %"
  $note.gen$i.down.info.gendvar configure -state disabled
  $note.gen$i.down.info.gendvar tag configure male -foreground blue
  $note.gen$i.down.info.gendvar tag configure female -foreground red
  text $note.gen$i.down.info.egggvar -width 40 -height 1 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.down.info.egggvar insert end [mc "Unknown"]
  $note.gen$i.down.info.egggvar configure -state disabled
  text $note.gen$i.down.info.heigvar -width 40 -height 1 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.down.info.heigvar insert end [mc "Unknown"]
  $note.gen$i.down.info.heigvar configure -state disabled
  text $note.gen$i.down.info.weigvar -width 40 -height 1 -font TkDefaultFont \
    -background "#F0F0F0" -relief flat
  $note.gen$i.down.info.weigvar insert end [mc "Unknown"]
  $note.gen$i.down.info.weigvar configure -state disabled
  
  grid [ttk::frame $note.gen$i.move] -row 2 -column 0 -sticky nsew
  
  # Style for game tabs
  ttk::style configure G$i.TNotebook {*}[ttk::style configure TNotebook]
  
  set game $note.gen$i.move.game
  ttk::notebook $game -style G$i.TNotebook
  pack $game -fill both -expand 1 -side left
  ttk::notebook::enableTraversal $game
  
  set id 0
  foreach a [lindex $pokedex::games $i-1] {
    set f [string tolower $a]
    ttk::frame $game.$f
    $game add $game.$f -text " $a "
    $menu.file.gen.game$i add radio -label $a -variable pokedex::current(game$i) \
      -command [list pokelib::write_config $id "gen$i game"] \
      -value $id
    
    scrollbar $game.$f.s -command "$game.$f.t yview"
    tablelist::tablelist $game.$f.t -columns {
      4 "Move"
      3 "Category" center
      3 "Type" center
      2 "PP" right
      2 "Pow" right
      2 "Acc" right
      6 "Learning"
    } -stretch all -background white -yscrollcommand "$game.$f.s set" \
      -arrowstyle sunken8x7 -showarrow 1 -resizablecolumns 0 \
      -labelcommand tablelist::sortByColumn
    $game.$f.t configcolumnlist {
      0 -labelalign center
      1 -labelalign center
      2 -labelalign center
      3 -labelalign center
      4 -labelalign center
      5 -labelalign center
      6 -labelalign center
      3 -sortmode command
      4 -sortmode command
      5 -sortmode command
      6 -sortmode command
      3 -sortcommand pokelib::move_sort
      4 -sortcommand pokelib::move_sort
      5 -sortcommand pokelib::move_sort
      6 -sortcommand pokelib::levelup_sort
    }

    pack $game.$f.t -fill both -expand 1 -side left
    pack $game.$f.s -fill y -side left
    incr id
  }
  
  grid $note.gen$i.down.info.formlab -row 0 -column 0 -sticky nw
  grid $note.gen$i.down.info.formvar -row 0 -column 1 -sticky nw
  grid $note.gen$i.down.info.typelab -row 1 -column 0 -sticky nw
  grid $note.gen$i.down.info.typevar -row 1 -column 1 -sticky nw
  grid $note.gen$i.down.info.genulab -row 2 -column 0 -sticky nw
  grid $note.gen$i.down.info.genuvar -row 2 -column 1 -sticky nw
  grid $note.gen$i.down.info.abillab -row 3 -column 0 -sticky nw
  grid $note.gen$i.down.info.abilvar -row 3 -column 1 -sticky nw
  grid $note.gen$i.down.info.gendlab -row 4 -column 0 -sticky nw
  grid $note.gen$i.down.info.gendvar -row 4 -column 1 -sticky nw
  grid $note.gen$i.down.info.eggglab -row 5 -column 0 -sticky nw
  grid $note.gen$i.down.info.egggvar -row 5 -column 1 -sticky nw
  grid $note.gen$i.down.info.heiglab -row 6 -column 0 -sticky nw
  grid $note.gen$i.down.info.heigvar -row 6 -column 1 -sticky nw
  grid $note.gen$i.down.info.weiglab -row 7 -column 0 -sticky nw
  grid $note.gen$i.down.info.weigvar -row 7 -column 1 -sticky nw
  
  grid columnconfigure $note.gen$i 0 -weight 1
  grid rowconfigure $note.gen$i 0 -weight 0
  grid rowconfigure $note.gen$i 2 -weight 1
  grid columnconfigure $note.gen$i.down.info 0 -minsize 70
  grid columnconfigure $note.gen$i.down.info 1 -minsize 200 -weight 1
  grid columnconfigure $note.gen$i.down.sprite 0 -weight 1
}

### Binds
bind . <Control-q> {exit}
bind . <Alt-F4> {exit}
bind . <Control-i> {error "just testing"}
bind . <Control-f> {
  .sidepane.top.entry selection range 0 end
  focus -force .sidepane.top.entry
}

bind .sidepane.top.entry <KeyPress-Return> "pokelib::poke_populate \$pokedex::pokemonSpecies"
bind .sidepane.top.entry <KeyPress-Down> [list pokelib::poke_focus %W $pokedex::pokeList]
bind .sidepane.top.entry <ButtonPress-1> [list focus -force %W]

bind .sidepane.bottom.list <Double-ButtonPress-1> [list pokelib::poke_entry %W]
bind .sidepane.bottom.list <KeyPress-Return> \
  [list pokelib::list_populate_entry %W $pokedex::pokeList]

bind .mainpane.note <<NotebookTabChanged>> {
  set pokedex::current(gen) [expr {[.mainpane.note index current]+1}]
  dex eval {UPDATE config SET value = $pokedex::current(gen) WHERE param = 'gen'}
}

### Populate database
pokedb::db_init

bind .mainpane.note.gen$pokedex::current(gen).down.sprite <Configure> {
  ttk::style configure TNotebook.Tab -anchor center
  ttk::style configure G.TNotebook.Tab -anchor center
  set notebookwidth [winfo width .mainpane.note.gen$pokedex::current(gen)]
  set tabcount [llength [winfo children .mainpane.note]]
  ttk::style configure TNotebook.Tab -width [expr {$notebookwidth/6/$tabcount}]
  
  foreach i $pokedex::generations {
    set tabcount [llength [winfo children .mainpane.note.gen$i.move.game]]
    ttk::style configure G$i.TNotebook.Tab -width [expr {int($notebookwidth/6)/$tabcount}] \
      -anchor center
  }
  update idletasks
  pokelib::resize_tabs
  wm minsize . [winfo width .] [winfo height .]
}
