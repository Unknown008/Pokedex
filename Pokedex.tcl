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
#   /_/     \____//_/|_| \___/ \____/ \___//_/|_|     #
#                                                     #
#######################################################

### Import libraries
package require Tcl 8.5
package require Tk  8.5
package require Ttk
package require msgcat
package require Img
package require sqlite3
package require tooltip

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
source "$pokeDir/lib.tcl"

### Window configurations
wm title . [mc "Pok\u00E9dex v%s" $version]
wm iconname . [mc "Pok\u00E9dex"]
#wm iconbitmap . -default "favicon.ico"

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
$m add cascade -label [mc "Language"] -menu $m.lang -underline 0
$m add separator
$m add command -label [mc "Close"] -command {exit} -accelerator Ctrl+Q

bind . <Control-KeyPress-I> {error "just testing"}
bind . <Alt-KeyPress-F4> {exit}
bind . <Control-KeyPress-Q> {exit}

menu $m.lang -tearoff 0
$m.lang add radio -label "English" -variable language
$m.lang invoke 1

### Tools
set m $menu.tools
menu $m -tearoff 0
$menu add cascade -label [mc "Tools"] -menu $m -underline 0
$m add command -label [mc "Search Pok\u00E9mon"] -command {error "just testing"}
$m add command -label [mc "Search Abilities"] -command {error "just testing"}
$m add command -label [mc "Search Moves"] -command {error "just testing"}
$m add command -label [mc "Search Items"] -command {error "just testing"}
$m add separator
$m add command -label [mc "Type matchup chart"] -command {error "just testing"}
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
set pokemonFile [open "$pokeDir/pokemon.txt" r]
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
.sidepane.bottom.list insert 0 {*}$pokeList

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
foreach {a b} {1 I 2 II 3 III 4 IV 5 V 6 VI} {
  ttk::frame $note.gen$a
  $note add $note.gen$a -text " Gen $b "
}

foreach i {1 2 3 4 5 6} {
  image create photo default -file "$pokeDir/data/sprites-6/default.png" \
    -format png
  
  grid [ttk::label $note.gen$i.lab -text [mc "Pok\u00E9mon"] -anchor n] \
    -row 0 -column 0
  grid [ttk::frame $note.gen$i.down] -row 1 -column 0 -sticky nw
  grid [label $note.gen$i.down.sprite -image default] -row 0 -column 0 -sticky nw
  grid [ttk::frame $note.gen$i.down.info] -row 0 -column 1 -sticky nw
  
  label $note.gen$i.down.info.formlab -text [mc "Form name:"]
  label $note.gen$i.down.info.typelab -text [mc "Type:"]
  label $note.gen$i.down.info.genulab -text [mc "Genus:"]
  label $note.gen$i.down.info.abillab -text [mc "Abilities:"]
  label $note.gen$i.down.info.gendlab -text [mc "Gender Ratio:"]
  label $note.gen$i.down.info.eggglab -text [mc "Egg Group:"]
  label $note.gen$i.down.info.heiglab -text [mc "Height:"]
  label $note.gen$i.down.info.weiglab -text [mc "Weight:"]
  
  text $note.gen$i.down.info.formvar -width 40 -height 1 -font TkDefaultFont \
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
  
  grid columnconfigure $note.gen$i.down.info 0 -minsize 70
  grid columnconfigure $note.gen$i.down.info 1 -minsize 200
  grid columnconfigure $note.gen$i 0 -weight 1
  grid rowconfigure $note.gen$i 0 -weight 1
}

update idletasks
after idle [wm minsize . [winfo width .] [winfo height .]]

### Load database and create it from txt if it doesn't exist
sqlite3 dex pokedexdb
dex eval {
  CREATE TABLE IF NOT EXISTS pokeDetails(
    id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
    pokemon text,
    formname text,
    type text,
    genus text,
    ability text,
    hability text,
    gender text,
    egggroup text,
    height float,
    weight float,
    legend bool,
    evolve_cond text,
    hp int,
    atk int,
    def int,
    spatk int,
    spdef int,
    spd int,
    capture int,
    final bool,
    stage int,
    effort int,
    hatch_counter int,
    happiness int,
    exp int,
    forms int,
    colour text,
    base_exp int
  )
}

dex eval {
  CREATE TABLE IF NOT EXISTS moveDetails(
    id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
    type text,
    class text,
    pp int,
    basepower int,
    accuracy int,
    priority int,
    effect text,
    contact bool,
    charging bool,
    recharge bool,
    detectprotect bool,
    reflectable bool,
    snatchable bool,
    mirrormove bool,
    punchbased bool,
    sound bool,
    gravity bool,
    defrosts bool,
    range int,
    heal bool,
    infiltrate bool
  )
}

dex eval {
  CREATE TABLE IF NOT EXISTS abilDetails(
    id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
    description text
  )
}

if {![dex exists {SELECT 1 FROM pokeDetails}]} {
  dex copy ignore pokeDetails "$pokeDir/data/info" "\t"
  dex copy ignore moveDetails "$pokeDir/data/moves-5.txt" "\t"
  dex copy ignore abilDetails "$pokeDir/data/abilities-5.txt" "\t"
}

# Binds
bind .sidepane.top.entry <KeyPress-Return> "poke_populate \$pokemonSpecies"
bind .sidepane.top.entry <KeyPress-Down> [list poke_focus $pokeList]
bind .sidepane.bottom.list <Double-ButtonPress-1> [list poke_entry %W $pokeList]
bind .sidepane.bottom.list <KeyPress-Return> [list list_populate_entry %W $pokeList]
