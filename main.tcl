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
package require Tcl
package require Tk
package require Ttk
package require msgcat
package require Img
package require sqlite3
package require tooltip
package require tablelist

### Pokédex version
set version 0.01

### Safeguard cleaning everything on startup
catch {destroy [winfo children .]}

### Location of script
set pokeDir [file join [pwd] [file dirname [info script]]]

### Set up translations
::msgcat::mcload $pokeDir
namespace import ::msgcat::mc

### Import procedures
source [file join $pokeDir lib.tcl]
source [file join $pokeDir menu.tcl]

### Window configurations
wm title . [mc "Pok\u00E9dex v%s" $version]
wm iconname . Pokedex
wm geometry . +100+100
#wm iconbitmap . -default "favicon.ico"

### Tk theme
ttk::setTheme classic

### Type list
set typeList [list Grass Fire Water Bug Flying Electric Ground Rock Fighting Poison \
  Normal Psychic Ghost Ice Dragon Dark Steel Fairy]

### Current pokemon index
set curIdx ""
  
###
# Menu settings
###
set menu .menu
menu $menu -tearoff 0

### File
set m $menu.file
menu $m -tearoff 0
$menu add cascade -label [mc "File"] -menu $m -underline 0
$m add command -label [mc "Import mod"] -command {error "just testing"} \
  -accelerator Ctrl+I
$m add cascade -label [mc "Default generation"] -menu $m.gen -underline 0
$m add cascade -label [mc "Language"] -menu $m.lang -underline 0
$m add separator
$m add command -label [mc "Close"] -command {exit} -accelerator Ctrl+Q

bind . <Control-KeyPress-I> {error "just testing"}
bind . <Alt-KeyPress-F4> {exit}
bind . <Control-KeyPress-Q> {exit}

menu $m.gen -tearoff 0

menu $m.lang -tearoff 0
$m.lang add radio -label "English" -variable language
$m.lang invoke 0

### Tools
set m $menu.tools
menu $m -tearoff 0
$menu add cascade -label [mc "Tools"] -menu $m -underline 0
$m add command -label [mc "Search Pok\u00E9mon"] -command {error "just testing"}
$m add command -label [mc "Search Abilities"] -command {error "just testing"}
$m add command -label [mc "Search Moves"] -command {error "just testing"}
$m add command -label [mc "Search Items"] -command {error "just testing"}
$m add separator
$m add command -label [mc "Type matchup chart"] -command {type_matchup}
$m add command -label [mc "Damage calculator"] -command {error "just testing"}
$m add command -label [mc "Compare Pok\u00E9mon"] -command {error "just testing"}

### About
set m $menu.about
menu $m -tearoff 0
$menu add cascade -label [mc "About"] -menu $m -underline 0
$m add command -label [mc "Help"] -command {error "just testing"}
$m add command -label [mc "Credits"] -command poke_credits

. configure -menu $menu

### Get Pokémon species list
set pokemonFile [open [file join $pokeDir pokemon.txt] r]
fconfigure $pokemonFile -encoding utf-8
set pokeList [split [read $pokemonFile] "\n"]
close $pokemonFile

### Frames for animations
set frames [list]

### Left part of app
pack [ttk::frame .sidepane -padding 5] -fill y -side left

### Upper left being entry box
pack [ttk::frame .sidepane.top] -fill x -side top
pack [entry .sidepane.top.entry -width 16 -textvariable pokemonSpecies \
  -validate all -validatecommand {poke_autocomplete %W %d %v %P $pokeList}] \
  -pady {0 5} -expand 1 -fill x

### Lower left being list display of Pokémon
pack [ttk::frame .sidepane.bottom] -fill both -side top -expand 1
listbox .sidepane.bottom.list -yscrollcommand ".sidepane.bottom.scroll set" \
  -activestyle dotbox -selectmode browse -listvariable $pokeList
scrollbar .sidepane.bottom.scroll -command ".sidepane.bottom.list yview"
pack .sidepane.bottom.list .sidepane.bottom.scroll -side left -fill y -expand 1
.sidepane.bottom.list insert 0 {*}[lreplace $pokeList end end]

### Main part where information will be displayed
ttk::frame .mainpane
pack .mainpane -fill both -expand 1 -side right

### Insert tabs
ttk::notebook .mainpane.note
set note .mainpane.note

### Configure tab width and frame
#ttk::style configure Wider.TNotebook -mintabwidth 40
#$note configure -style Wider.TNotebook

pack $note -fill both -expand 1
ttk::notebook::enableTraversal $note

### Insert tabs
foreach {a b} [list 1 I 2 II 3 III 4 IV 5 V 6 VI] {
  ttk::frame $note.gen$a
  $note add $note.gen$a -text " Gen $b "
  $menu.file.gen add radio -label $b -variable generation \
    -command [list write_config $a "gen"] -value $a
}

foreach i [list 1 2 3 4 5 6] {
  image create photo default -format png \
    -file [file join $pokeDir data gen6 sprites default.png]

  grid [label $note.gen$i.lab -text [mc "Pok\u00E9mon"] -anchor n] \
    -row 0 -column 0
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
  scrollbar $note.gen$i.move.s -command "$note.gen$i.move.t yview"
  tablelist::tablelist $note.gen$i.move.t -columns {
    4 "Move"
    3 "Category" center
    3 "Type" center
    2 "PP" right
    2 "Pow" right
    2 "Acc" right
    6 "Learning"
  } -stretch all -background white -yscrollcommand "$note.gen$i.move.s set" \
    -arrowstyle sunken8x7 -showarrow 1 -resizablecolumns 0 \
    -labelcommand tablelist::sortByColumn
  $note.gen$i.move.t configcolumnlist {
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
    3 -sortcommand move_sort
    4 -sortcommand move_sort
    5 -sortcommand move_sort
  }

  pack $note.gen$i.move.t -fill both -expand 1 -side left
  pack $note.gen$i.move.s -fill y -side left
  
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

### Create database and load it
source [file join $pokeDir db.tcl]

### Binds
bind . <Control-q> {exit}
bind . <Alt-F4> {exit}
bind .sidepane.top.entry <KeyPress-Return> "poke_populate \$pokemonSpecies"
bind .sidepane.top.entry <KeyPress-Down> [list poke_focus $pokeList]
bind .sidepane.top.entry <ButtonPress-1> [list focus -force %W]
bind .sidepane.bottom.list <Double-ButtonPress-1> [list poke_entry %W $pokeList]
bind .sidepane.bottom.list <KeyPress-Return> [list list_populate_entry %W $pokeList]
bind .mainpane.note.gen6.down.sprite <Configure> {
  wm minsize . [winfo width .] [winfo height .]
}
