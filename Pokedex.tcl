#!/bin/sh
# the next line restarts using wish \
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

package require Tcl 8.5
package require Tk  8.5
package require Ttk
package require msgcat


set version 0.01
catch {destroy [winfo children .]}
set pokeDir [file join [pwd] [file dirname [info script]]]
::msgcat::mcload $pokeDir
namespace import ::msgcat::mc
source "$pokeDir/lib.tcl"
wm title . [mc "Pok\u00E9dex v%s" $version]
wm iconname . [mc "Pok\u00E9dex"]
#wm iconbitmap . -default "favicon.ico"

set menu .menu
menu $menu -tearoff 0

set m $menu.file
menu $m -tearoff 0
$menu add cascade -label [mc "File"] -menu $m -underline 0
$m add command -label [mc "Import mod"] -command {error "just testing"} \
  -accelerator Ctrl+I
$m add separator
$m add command -label [mc "Close"] -command {exit} -accelerator Ctrl+Q

bind . <Control-KeyPress-I> {error "just testing"}
bind . <Alt-KeyPress-F4> {exit}
bind . <Control-KeyPress-Q> {exit}

set m $menu.search
menu $m -tearoff 0
$menu add cascade -label [mc "Search"] -menu $m -underline 0
$m add command -label [mc "Pok\u00E9mon"] -command {error "just testing"}
$m add command -label [mc "Abilities"] -command {error "just testing"}
$m add command -label [mc "Moves"] -command {error "just testing"}
$m add command -label [mc "Items"] -command {error "just testing"}

set m $menu.about
menu $m -tearoff 0
$menu add cascade -label [mc "About"] -menu $m -underline 0
$m add command -label [mc "Help"] -command {error "just testing"}
$m add command -label [mc "Credits"] -command poke_credits

. configure -menu $menu

pack [ttk::frame .sidepane -padding 5] -fill y -side left

pack [ttk::frame .sidepane.top] -fill x -side top
pack [entry .sidepane.top.entry -width 16 -textvariable pokemonSpecies \
  -validate all -validatecommand {poke_autocomplete %W %d %v %P $pokeList}] \
  -pady {0 5} -expand 1 -fill x

set pokemonFile [open "${pokeDir}/pokemon.txt" r]
fconfigure $pokemonFile -encoding utf-8
set pokeList [split [read $pokemonFile] "\n"]
close $pokemonFile

pack [ttk::frame .sidepane.bottom] -fill both -side top -expand 1
listbox .sidepane.bottom.list -yscrollcommand ".sidepane.bottom.scroll set" \
  -activestyle dotbox -selectmode browse -listvariable $pokeList
scrollbar .sidepane.bottom.scroll -command ".sidepane.bottom.list yview"
pack .sidepane.bottom.list .sidepane.bottom.scroll -side left -fill y -expand 1
.sidepane.bottom.list insert 0 {*}$pokeList

ttk::frame .mainpane
pack .mainpane -fill both -expand 1 -side right

set fr .mainpane
ttk::notebook $fr.note

#ttk::style configure Wider.TNotebook -mintabwidth 40
#$fr.note configure -style Wider.TNotebook

pack $fr.note -fill both -expand 1
ttk::notebook::enableTraversal $fr.note

ttk::frame $fr.note.gen1
$fr.note add $fr.note.gen1 -text "Gen I"

ttk::frame $fr.note.gen2
$fr.note add $fr.note.gen2 -text "Gen II"

ttk::frame $fr.note.gen3
$fr.note add $fr.note.gen3 -text "Gen III"

ttk::frame $fr.note.gen4
$fr.note add $fr.note.gen4 -text "Gen IV"

ttk::frame $fr.note.gen5
$fr.note add $fr.note.gen5 -text "Gen V"

ttk::frame $fr.note.gen6
$fr.note add $fr.note.gen6 -text "Gen VI"

after idle [wm minsize . [winfo width .] [winfo height .]]

set lb .listbox

# Binds
bind .sidepane.top.entry <KeyPress-Return> "poke_populate \$pokemonSpecies"
bind .sidepane.top.entry <KeyPress-Down> [list focus .listbox.l]
bind .sidepane.bottom.list <Double-ButtonPress-1> [list poke_entry %W $pokeList]










































