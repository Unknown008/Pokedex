namespace eval pokemenu {
  ### Matchup window
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # This window callable from the menu will list the various types that Pokémon
  # can have and the weakness/resist multiplier for both mono and dual typed
  # Pokémon, plus the effects of Forest's Curse and TrickorTreat
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  proc type_matchup {} {
    set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
    set mode [dex eval {SELECT value FROM config WHERE param = 'matchup'}]
    set hidden [dex eval {SELECT value FROM config WHERE param = 'matchuphide'}]
    
    set w .matchup
    catch {destroy $w [winfo children $w]}
      
    toplevel $w
    wm title $w [mc "Matchup chart"]
    pokelib::sub_position $w +50+10
    
    switch $gen {
      1 {set px 375}
      2 {set px 425}
      3 {set px 425}
      4 {set px 425}
      5 {set px 425}
      6 {set px 450}
      7 {set px 450}
    }
    
    set stat [expr {$mode ? "normal" : "disabled"}]
    
    set whiteList [list Ground Rock Fighting Poison Ghost Dragon Dark]
    set dbtypeList [dex eval {SELECT type, colour FROM types WHERE gen <= $gen}]
    set otypes [list]
    foreach {type colour} $dbtypeList {
      set types($type) $colour
      lappend otypes $type
    }
    
    set menu $w.menu
    menu $menu -tearoff 0
    set m $menu.options
    menu $m -tearoff 0
    $menu add cascade -label [mc "Options"] -menu $m -underline 0
    $m add radio -label "Basic Mode" -variable mode -value 0 \
      -command [list pokemenu::matchup_mode 0 $px $whiteList [array get types] $gen $otypes]
    $m add radio -label "Extended Mode" -variable mode -value 1 \
      -command [list pokemenu::matchup_mode 1 $px $whiteList [array get types] $gen $otypes] 
    $m add separator
    $m add check -label [mc "Add Trick-or-Treat"] -variable pokedex::TrickorTreat \
      -command [list pokemenu::matchup Ghost $gen]
    $m add check -label [mc "Add Forest's Curse"] -variable pokedex::ForestCurse \
      -command [list pokemenu::matchup Grass $gen]
    $m add check -label [mc "Hide illegal typing"] -variable hidden \
      -command [list pokemenu::hide $px $whiteList [array get types] $gen $otypes]
    $w configure -menu $menu
    
    # Top left pane
    set f1 [frame $w.frame1 -background white]
    grid $f1 -row 0 -column 0 -sticky nsew
    # Top right pane
    set f2 [frame $w.frame2 -background white]
    grid $f2 -row 0 -column 1 -sticky nsew
    # Bottom left pane
    set f3 [frame $w.frame3 -background white]
    grid $f3 -row 1 -column 0 -sticky nsew
    # Bottom right pane
    set f4 [frame $w.frame4 -background white]
    grid $f4 -row 1 -column 1 -sticky nsew
    grid rowconfigure $w 1 -weight 1
    
    canvas $f2.c -width $px -height 70 -highlightthickness 0 -background white
    pack $f2.c -fill both -expand 1
    $f2.c create rectangle 0 0 $px 20 -outline white -fill white
    $f2.c create text [expr {$px/2}] 0 -text "ATTACKER" -anchor n -justify center
   
    set i -25
    foreach type $pokedex::typeList {
      incr i 25
      if {[lsearch $otypes $type] == -1} {continue}
      $f2.c create rectangle $i 20 [expr {$i+25}] 69 -fill $types($type) \
        -outline black -tags "atk $type"
      set fcolour [expr {[lsearch $whiteList $type] != -1 ? "white" : "black"}]
      $f2.c create text [expr {$i+12}] 45 -text $type -justify center \
        -fill $fcolour -angle 90 -tags "ulabels"
    }
    
    canvas $f3.c -width 100 -height $px -highlightthickness 0
    label $f3.l -text "DEFENDER" -wraplength 1 -justify center -background white
    grid $f3.l -row 0 -column 0 -sticky nsew
    grid $f3.c -row 0 -column 1 -sticky nsew
    grid rowconfigure $f3 0 -weight 1
    
    $f3.c create rectangle 0 0 100 $px -fill white -outline white -tags "sbg"

    set f [frame $f4.f]
    canvas $f.c -width $px -height $px -highlightthickness 0 -background white
    pack $f.c -expand 1 -fill both
    grid $f -row 0 -column 0 -sticky nsew
    grid rowconfigure $f4 0 -weight 1

    set i -25
    foreach type $pokedex::typeList {
      incr i 25
      if {[lsearch $otypes $type] == -1} {continue}
      $f3.c create rectangle 50 $i 99 [expr {$i+25}] -fill $types($type) \
        -outline black -tags "batk $type"
      set fcolour [expr {[lsearch $whiteList $type] != -1 ? "white" : "black"}]
      $f3.c create text 75 [expr {$i+12}] -text $type -justify center \
        -fill $fcolour -tags "batk $type"
      $f.c create rectangle 0 [expr {$i+3}] [expr {([llength $otypes]*25)-2}] \
        [expr {$i+21}] -fill "" -tags "effhbar h$type" -outline ""
      set d -13
      for {set n 0} {$n < [llength $otypes]} {incr n} {
        set atker [lindex $otypes $n]
        if {[llength [$f.c find withtag effvbar]] < [llength $otypes]} {
          $f.c create rectangle [expr {$d+15}] 0 [expr {$d+38}] \
            [expr {[llength $pokedex::typeList]*25}] -fill "" -outline "" \
            -tags "effvbar v$atker"
        }
        set eff [dex eval "
          SELECT effectiveness FROM matchDetails$gen
          WHERE type1 = '$type' AND type2 = '$atker'
        "]
        incr d 25
        $f.c create text $d [expr {$i+12}] -text $eff \
          -justify center -fill black -tags "eff $type $atker"
      }
    }
    set curmode [dex eval {SELECT value FROM config WHERE param = 'matchuphide'}]
    if {$curmode != $hidden} {
      $m invoke 5
    }
    $m invoke $mode  
    $m entryconfigure 5 -state $stat

    set catk ""
    set cdef ""
    $f.c bind eff <Enter> [list pokemenu::change_matchup 1 $f.c]
    $f.c bind eff <Leave> [list pokemenu::change_matchup 0 $f.c]
    
    #wm maxsize $w 0 [expr {$px+70}]
    wm minsize $w 0 220
    after idle [wm resizable $w 0 1]
  }

  # Trick-or-treat and Forest's Curse
  proc matchup {type gen} {
    set c .matchup.frame4.f.c
    set values [$c find withtag eff]
    switch $type {
      Ghost {
        set stat $pokedex::TrickorTreat
        set other $pokedex::ForestCurse
        set ::pokedex::ForestCurse 0
      }
      Grass {
        set stat $pokedex::ForestCurse
        set other $pokedex::TrickorTreat
        set ::pokedex::TrickorTreat 0
      }
    }
    foreach v $values {
      lassign [lrange [lindex [$c itemconfigure $v -tags] 4] 1 2] defer atker
      set ceff [lindex [$c itemconfigure $v -text] 4]
      if {$stat && !$other} {
        set aeff [dex eval "
          SELECT effectiveness FROM matchDetails$gen
          WHERE type1 = '$type' AND type2 = '$atker'
        "]
        set neff [expr {$aeff*$ceff}]
      } else {
        lassign [regexp -all -inline {[A-Z][a-z]+} $defer] type1 type2
        set neff [dex eval "
          SELECT effectiveness FROM matchDetails$gen
          WHERE (type1 = '$type1' AND type2 = '$atker') OR
                (type1 = '$type2' AND type2 = '$atker')
        "]
        set active ""
        if {$pokedex::TrickorTreat} {
          set active Ghost
        } elseif {$pokedex::ForestCurse} {
          set active Grass
        }
        if {$active != "" && ![string match "*$type*" $defer]} {
          set aeff [dex eval "
            SELECT effectiveness FROM matchDetails$gen
            WHERE type1 = '$active' AND type2 = '$atker'
          "]
          set neff [::tcl::mathop::* {*}$neff $aeff]
        } else {
          set neff [::tcl::mathop::* {*}$neff]
        }
      }
      $c itemconfigure $v -text $neff
    }
  }
  
  # Switch between matchup types
  proc matchup_mode {mode px whiteList types gen otypes} {
    set hidden [dex eval {SELECT value FROM config WHERE param = 'matchuphide'}]
    dex eval {UPDATE config SET value = $mode WHERE param = 'matchup'}

    set f2 .matchup.frame2
    set f3 .matchup.frame3
    set f4 .matchup.frame4
    set menu .matchup.menu.options
    # Shorter name; main/bigger frame
    set f $f4.f
    
    if {!$mode} {
      $menu entryconfigure 3 -state disabled
      $menu entryconfigure 4 -state disabled
      $menu entryconfigure 5 -state disabled
      if {[winfo exists $f4.vscroll]} {
        destroy $f4.vscroll
      }
      $f3.c configure -yscrollcommand "" -scrollregion "0 0 0 0"
      $f.c configure -yscrollcommand "" -scrollregion "0 0 0 0"
      bind $f3.c <MouseWheel> {}
      bind $f.c <MouseWheel> {}
      return
    }
    foreach {col val} $types {
      set myTypes($col) $val
    }
    $menu entryconfigure 3 -state normal
    $menu entryconfigure 4 -state normal
    $menu entryconfigure 5 -state normal
    set height $px
    set max [expr {$px+(25*[pokelib::binom [llength $pokedex::typeList] 2])}]

    set itypes [dex eval {SELECT type1, type2 FROM itypes WHERE gen <= $gen}]
    set ilist [lmap {a b} $itypes {list $a $b}]
    
    # Remove secondary types figures and hbars
    $f3.c delete aatk
    $f.c delete sec
    catch {destroy $f4.vscroll}
    set add [list]
    for {set i 0} {$i < [llength $otypes]} {incr i} {
      for {set j [expr {$i+1}]} {$j < [llength $otypes]} {incr j} {
        set type1 [lindex $otypes $i]
        set type2 [lindex $otypes $j]
        if {
          $type1 ni [array names myTypes] ||
          $type2 ni [array names myTypes] ||
          ([list $type1 $type2] ni $ilist && [list $type2 $type1] ni $ilist && $hidden == 1) ||
          ($type2 == "???")
        } {continue}
        $f3.c create rectangle 0 $height 50 [expr {$height+25}] \
          -fill $myTypes($type1) -outline black -tags "aatk $type1$type2"
        $f3.c create rectangle 50 $height 99 [expr {$height+25}] \
          -fill $myTypes($type2) -outline black -tags "aatk $type1$type2"
        set fcolour1 [expr {
          [lsearch $whiteList $type1] != -1 ? "white" : "black"
        }]
        set fcolour2 [expr {
          [lsearch $whiteList $type2] != -1 ? "white" : "black"
        }]
        $f3.c create text 25 [expr {$height+12}] -text $type1 \
          -justify center -fill $fcolour1 -tags "aatk $type1$type2"
        $f3.c create text 75 [expr {$height+12}] -text $type2 \
          -justify center -fill $fcolour2 -tags "aatk $type1$type2"
        $f.c create rectangle 0 [expr {$height+2}] \
          [expr {([llength $otypes]*25)-2}] [expr {$height+21}] \
          -fill "" -tags "effhbar h$type1$type2 sec" -outline ""

        set d -13
        for {set k 0} {$k < [llength $otypes]} {incr k} {
          set atker [lindex $otypes $k]
          if {
            [llength [$f.c find withtag effvbar]] < [expr {2*[llength $otypes]}]
          } {
            $f.c create rectangle [expr {$d+15}] $height [expr {$d+34}] \
              [expr {[llength $pokedex::typeList]*$max*25}] -fill "" -outline "" \
              -tags "effvbar v$atker"
          }
          set eff [dex eval "
            SELECT effectiveness FROM matchDetails$gen
            WHERE (type1 = '$type1' AND type2 = '$atker') OR
                  (type1 = '$type2' AND type2 = '$atker')
          "]
          set eff [expr {[lindex $eff 0]*[lindex $eff 1]}]
          
          if {$pokedex::TrickorTreat} {
            set gh [dex eval "
              SELECT effectiveness FROM matchDetails$gen
              WHERE type1 = 'Ghost' AND type2 = '$atker'
            "]
            set eff [expr {$eff*$gh}]
          } elseif {$pokedex::ForestCurse} {
            set gr [dex eval "
              SELECT effectiveness FROM matchDetails$gen
              WHERE type1 = 'Grass' AND type2 = '$atker'
            "]
            set eff [expr {$eff*$gr}]
          }
          incr d 25
          $f.c create text $d [expr {$height+12}] -text $eff \
            -justify center -fill black -tags "eff $type1$type2 $atker sec"
        }
        incr height 25
      }
    }
    scrollbar $f4.vscroll -orient vertical
    $f4.vscroll configure \
      -command "pokelib::sync_scroll [list [list $f.c yview $f3.c yview]]"
    grid $f4.vscroll -row 0 -column 1 -sticky nsew
    $f3.c configure -yscrollcommand "$f4.vscroll set" \
      -scrollregion "0 0 100 $height"
    $f.c configure -yscrollcommand "$f4.vscroll set" \
      -scrollregion "0 0 $px $height"
      
    bind $f3.c <MouseWheel> [list pokelib::mouse_scroll $f3.c $f.c %D]
    bind $f.c <MouseWheel> [list pokelib::mouse_scroll $f3.c $f.c %D]
  }
  
  # Show/hide extended mode
  proc hide {px whiteList types gen otypes} {
    upvar hidden hide
    set mode [dex eval {SELECT value FROM config WHERE param = 'matchup'}]
    if {!$mode} {return}
    set hidden [expr {!$hide}]
    dex eval {UPDATE config SET value = $hide WHERE param = 'matchuphide'}
    pokemenu::matchup_mode 1 $px $whiteList $types $gen $otypes
  }
  
  # Event when mouse hovers over different matchup
  proc change_matchup {status w} {
    if {$status} {
      set id [$w find withtag current]
      set l [$w gettags $id]
      lassign $l - def atk -
      $w itemconfigure h$def -fill #c4d1df
      $w itemconfigure v$atk -fill #c4d1df
      uplevel "set catk $atk"
      uplevel "set cdef $def"
    } else {
      uplevel "$w itemconfigure h\$cdef -fill {}"
      uplevel "$w itemconfigure v\$catk -fill {}"
      uplevel "set catk {}"
      uplevel "set cdef {}"
    }
    update idletasks
  }
  
  ### Damage Calculator Window
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # This window callable from the menu will give a window where the damage
  # can be calculated from the attack(s) of a single Pokémon.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  proc damage_calculator {} {
    set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
    catch {destroy .dmgcalc [winfo children .dmgcalc]}
    
    set w .dmgcalc
    toplevel $w
    wm title $w [mc "Damage Calculator"]
    label $w.poke1 -text "Attacker:"
    label $w.poke2 -text "Defender:"
    label $w.move -text "Move:"
    entry $w.atker -width 16 -textvariable atker
    entry $w.defer -width 16 -textvariable defer
    entry $w.emove -width 16 -textvariable umove
    entry $w.result1 -width 16 -textvariable res1
    entry $w.result2 -width 16 -textvariable res2
    entry $w.result3 -width 16 -textvariable res3
    entry $w.result4 -width 16 -textvariable res4
    ttk::button $w.calculate -text "Calculate" -command \
      "pokemenu::update_win \$atker \$defer \$umove $gen $w"
    
    grid $w.poke1 -row 0 -column 0
    grid $w.poke2 -row 1 -column 0
    grid $w.atker -row 0 -column 1
    grid $w.defer -row 1 -column 1
    grid $w.move -row 2 -column 0
    grid $w.emove -row 2 -column 1
    grid $w.result1 -row 3 -column 0
    grid $w.result2 -row 3 -column 1
    grid $w.result3 -row 3 -column 2
    grid $w.result4 -row 3 -column 3
    grid $w.calculate -row 4 -column 3
    
  }
  
  proc update_win {atker defer move gen w} {
    # atker same format list as defer with indice:
    # 0 - pokemon id
    # 1 - pokemon level
    # 2 - pokemon atk stat
    # 3 - pokemon spatk stat
    # 4 - pokemon ability
    # 5 - pokemon item
    # 6 - pokemon current status*
    set details1 [dex eval "
      SELECT atk, spatk, type FROM pokeDetails$gen
      WHERE id = '[lindex $atker 0]'
    "]
    set details2 [dex eval "
      SELECT def, spdef, type FROM pokeDetails$gen
      WHERE id = '[lindex $atker 0]'
    "]
    
    
    set atker [list 100 1 284 100 [lindex $details1 2] Static None Normal]
    set defer [list 100 1 196 100 [lindex $details2 2] Static None Normal]
    
    
    lassign [calculate_damage $atker $defer Normal $move $gen {n n}] \
      res1 res2 res3 res4
    # foreach i {1 2 3 4} {
      # $w.result$i delete 0 end
      # $w.result$i insert 0 [set res$i]
    # }
  }
  
  ### Credits window
  proc poke_credits {} {
    set w .pokecredits
    catch {destroy $w}
    toplevel $w
    
    wm geometry $w +200+200
    pack [frame $w.fm] -padx 10 -pady 10
    set w $w.fm
    
    grid [frame $w.fup] -row 0 -column 0
    
    label $w.fup.l1 -text "Author:" -justify left
    label $w.fup.l2 -text "Git:" -justify left
    label $w.fup.l3 -text "Wiki:" -justify left
    label $w.fup.l4 -text "Jerry Yong" -justify left
    label $w.fup.l5 -text "https://github.com/Unknown008/Pokedex.git" \
      -foreground blue -justify left -font {"Segeo UI" 9 underline}
    label $w.fup.l6 -text "https://github.com/Unknown008/Pokedex/wiki/Documentation" \
      -foreground blue -justify left -font {"Segeo UI" 9 underline}
    bind $w.fup.l5 <ButtonPress-1> {
      eval exec [auto_execok start] "https://github.com/Unknown008/Pokedex.git" &
    }
    bind $w.fup.l6 <ButtonPress-1> {
      eval exec [auto_execok start] "https://github.com/Unknown008/Pokedex/wiki/Documentation" &
    }
    bind $w.fup.l5 <Enter> [list $w configure -cursor "hand2"]
    bind $w.fup.l5 <Leave> [list $w configure -cursor "ibeam"]
    bind $w.fup.l6 <Enter> [list $w configure -cursor "hand2"]
    bind $w.fup.l6 <Leave> [list $w configure -cursor "ibeam"]
    
    grid $w.fup.l1 -row 0 -column 0 -sticky w
    grid $w.fup.l2 -row 1 -column 0 -sticky w
    grid $w.fup.l3 -row 2 -column 0 -sticky w
    grid $w.fup.l4 -row 0 -column 1 -sticky w
    grid $w.fup.l5 -row 1 -column 1 -sticky w
    grid $w.fup.l6 -row 2 -column 1 -sticky w
    grid columnconfigure $w 0 -minsize 50
    
    grid [labelframe $w.fdown -padx 2 -pady 2 -text "GNU General Public Licence" \
      -labelanchor n] -row 1 -column 0 -pady 10
    text $w.fdown.t -setgrid 1 \
      -height 26 -autosep 1 -wrap word -width 60 \
      -font {"Segeo UI" 9} -relief flat -background "#F0F0F0"
    pack $w.fdown.t -expand yes -fill both
    set year [clock format [clock scan now] -format "%Y"]
    $w.fdown.t insert end "
      Pok\u00E9dex - Yes, another Pok\u00E9dex with the most common features
      other Pok\u00E9dex have plus a few more features I felt would be
      interesting to have.
        
      \tCredits:
      \t\u00A9 1996-$year The Pok\u00E9mon Company
      \t\u00A9 1996-$year Nintendo
      \t\u00A9 1996-$year Creatures Inc.
      \t\u00A9 1996-$year Game Freak Inc.
    "
    
    $w.fdown.t tag bind credits:veekun <Any-Enter> \
      [list pokelib::linkify $w.fdown.t credits:veekun 1]
    $w.fdown.t tag bind credits:veekun <Any-Leave> \
      [list pokelib::linkify $w.fdown.t credits:veekun 0]
    $w.fdown.t insert end "\tVeekun\n" credits:veekun
    $w.fdown.t tag bind credits:veekun <ButtonPress-1> {
      eval exec [auto_execok start] "http://veekun.com/" &
    }
    
    $w.fdown.t tag bind credits:bulba <Any-Enter> \
      [list pokelib::linkify $w.fdown.t credits:bulba 1]
    $w.fdown.t tag bind credits:bulba <Any-Leave> \
      [list pokelib::linkify $w.fdown.t credits:bulba 0]
    $w.fdown.t insert end "\tbulbapedia\n" credits:bulba
    $w.fdown.t tag bind credits:bulba <ButtonPress-1> {
      eval exec [auto_execok start] "http://bulbapedia.bulbagarden.net/" &
    }
    
    $w.fdown.t tag bind credits:smogon <Any-Enter> \
      [list pokelib::linkify $w.fdown.t credits:smogon 1]
    $w.fdown.t tag bind credits:smogon <Any-Leave> \
      [list pokelib::linkify $w.fdown.t credits:smogon 0]
    $w.fdown.t insert end "\tsmogon\n" credits:smogon
    $w.fdown.t tag bind credits:smogon <ButtonPress-1> {
      eval exec [auto_execok start] "http://www.smogon.com/" &
    }
    
    $w.fdown.t tag bind credits:pkparaiso <Any-Enter> \
      [list pokelib::linkify $w.fdown.t credits:pkparaiso 1]
    $w.fdown.t tag bind credits:pkparaiso <Any-Leave> \
      [list pokelib::linkify $w.fdown.t credits:pkparaiso 0]
    $w.fdown.t insert end "\tpkparaiso.com\n" credits:pkparaiso
    $w.fdown.t tag bind credits:pkparaiso <ButtonPress-1> {
      eval exec [auto_execok start] "http://www.pkparaiso.com/" &
    }
    
    $w.fdown.t insert end "
      This program is free software: you can redistribute it and/or modify
      it under the terms of the GNU General Public License as published by
      the Free Software Foundation, either version 3 of the License, or
      (at your option) any later version.
      This program is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
      GNU General Public License for more details.
      You should have received a copy of the GNU General Public License
      along with this program. If not, see <http://www.gnu.org/licenses/>
    "
    $w.fdown.t configure -state disabled
    
    grid [ttk::button $w.b -text OK -command [list pokemenu::credits_close $w] \
      -style [ttk::style theme use vista]] -row 2 -column 0
    
    focus $w
  }
      
  proc credits_close {w} {
    destroy [winfo parent $w]
    focus .
  }
}
