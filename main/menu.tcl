### Run only when sourced
if {[info exists argv0] && [file tail $argv0] ne "main.tcl"} {
  tk_messageBox -title Error \
    -message "This script should be run from the main.tcl script"
  exit
}

### Matchup window
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# This window callable from the menu will list the various types that Pokémon
# can have and the weakness/resist multiplier for both mono and dual typed
# Pokémon, plus the effects of Forest's Curse and Trick-or-Treat
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
proc type_matchup {} {
  global typeList
  set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
  set mode [dex eval {SELECT value FROM config WHERE param = 'matchup'}]
  set hidden [dex eval {SELECT value FROM config WHERE param = 'matchuphide'}]
  
  set w .matchup
  catch {destroy $w [winfo children $w]}
    
  toplevel $w
  wm title $w [mc "Matchup chart"]
  sub_position $w +50+10
  
  switch $gen {
    1 {set px 375}
    6 {set px 450}
    default {set px 425}
  }
  
  set stat [expr {$mode ? "normal" : "disabled"}]
  
  # Trick or treat and Forest's Curse
  proc matchup {type gen} {
    upvar tot tot fc fc
    set c .matchup.frame4.f.c
    set values [$c find withtag eff]
    foreach v $values {
      lassign [lrange [lindex [$c itemconfigure $v -tags] 4] 1 2] defer atker
      set ceff [lindex [$c itemconfigure $v -text] 4]
      switch $type {
        Ghost {
          set stat $tot
        }
        Grass {
          set stat $fc
        }
      }
      if {[string first $type $defer] != -1} {continue}
      if {$stat} {
        set aeff [dex eval "
          SELECT effectiveness FROM matcDetails$gen
          WHERE type1 = '$type' AND type2 = '$atker'
        "]
        set neff [expr {$aeff*$ceff}]
      } else {
        lassign [regexp -all -inline {[A-Z][a-z]+} $defer] type1 type2
        set neff [dex eval "
          SELECT effectiveness FROM matcDetails$gen
          WHERE (type1 = '$type1' AND type2 = '$atker') OR
                (type1 = '$type2' AND type2 = '$atker')
        "]
        set active ""
        if {$tot} {
          set active Ghost
        } elseif {$fc} {
          set active Grass
        }
        if {$active != ""} {
          set aeff [dex eval "
            SELECT effectiveness FROM matcDetails$gen
            WHERE type1 = '$active' AND type2 = '$atker'
          "]
          set neff [expr {$aeff*$neff}]
        }
      }
      $c itemconfigure $v -text $neff
    }
  }
  
  # Switch between matchup types
  proc matchup_mode {mode px whiteList types gen otypes} {
    global typeList
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
    set max [expr {$px+(25*[binom 18 2])}]

    set itypes [dex eval {SELECT type1, type2 FROM itypes WHERE gen > $gen}]
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
          [lsearch [array names myTypes] $type1] == -1 ||
          [lsearch [array names myTypes] $type2] == -1 ||
          ([lsearch $ilist [list $type1 $type2]] != -1 && $hidden == 1)
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
              [expr {[llength $typeList]*$max*25}] -fill "" -outline "" \
              -tags "effvbar v$atker"
          }
          set eff [dex eval "
            SELECT effectiveness FROM matcDetails$gen
            WHERE (type1 = '$type1' AND type2 = '$atker') OR
                  (type1 = '$type2' AND type2 = '$atker')
          "]
          set eff [expr {[lindex $eff 0]*[lindex $eff 1]}]
          incr d 25
          $f.c create text $d [expr {$height+12}] -text $eff \
            -justify center -fill black -tags "eff $type1$type2 $atker sec"
        }
        incr height 25
      }
    }
    scrollbar $f4.vscroll -orient vertical
    $f4.vscroll configure \
      -command "sync_scroll [list [list $f.c yview $f3.c yview]]"
    grid $f4.vscroll -row 0 -column 1 -sticky nsew
    $f3.c configure -yscrollcommand "$f4.vscroll set" \
      -scrollregion "0 0 100 $height"
    $f.c configure -yscrollcommand "$f4.vscroll set" \
      -scrollregion "0 0 $px $height"
      
    proc mouse_scroll {a b d} {
      $a yview scroll [expr {-$d/120}] units
      $b yview scroll [expr {-$d/120}] units
    }
      
    bind $f3.c <MouseWheel> [list mouse_scroll $f3.c $f.c %D]
    bind $f.c <MouseWheel> [list mouse_scroll $f3.c $f.c %D]
  }
  
  # Show/hide extended mode
  proc hide {px whiteList types gen otypes} {
    upvar hidden hide
    set mode [dex eval {SELECT value FROM config WHERE param = 'matchup'}]
    if {!$mode} {return}
    set hidden [expr {$hide ? 0 : 1}]
    dex eval {UPDATE config SET value = $hide WHERE param = 'matchuphide'}
    matchup_mode 1 $px $whiteList $types $gen $otypes
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
    -command [list matchup_mode 0 $px $whiteList [array get types] $gen $otypes]
  $m add radio -label "Extended Mode" -variable mode -value 1 \
    -command [list matchup_mode 1 $px $whiteList [array get types] $gen $otypes] 
  $m add separator
  $m add check -label [mc "Add Trick-Or-Treat"] -variable tot \
    -command [list matchup Ghost $gen]
  $m add check -label [mc "Add Forest's Curse"] -variable fc \
    -command [list matchup Grass $gen]
  $m add check -label [mc "Hide illegal typing"] -variable hidden \
    -command [list hide $px $whiteList [array get types] $gen $otypes]
  $w configure -menu $menu
  
  # Top left pane
  set f1 [frame $w.frame1]
  grid $f1 -row 0 -column 0 -sticky nsew
  # Top right pane
  set f2 [frame $w.frame2]
  grid $f2 -row 0 -column 1 -sticky nsew
  # Bottom left pane
  set f3 [frame $w.frame3]
  grid $f3 -row 1 -column 0 -sticky nsew
  # Bottom right pane
  set f4 [frame $w.frame4]
  grid $f4 -row 1 -column 1 -sticky nsew
  grid rowconfigure $w 1 -weight 1
  
  canvas $f2.c -width $px -height 70 -highlightthickness 0
  pack $f2.c -fill both -expand 1
  $f2.c create rectangle 0 0 $px 20 -outline white -fill white
  $f2.c create text [expr {$px/2}] 0 -text "ATTACKER" -anchor n -justify center
 
  set i -25
  foreach type $typeList {
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
  foreach type $typeList {
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
        $f.c create rectangle [expr {$d+15}] 0 [expr {$d+34}] \
          [expr {[llength $typeList]*25}] -fill "" -outline "" \
          -tags "effvbar v$atker"
      }
      set eff [dex eval "
        SELECT effectiveness FROM matcDetails$gen
        WHERE type1 = '$type' AND type2 = '$atker'
      "]
      incr d 25
      $f.c create text $d [expr {$i+12}] -text $eff \
        -justify center -fill black -tags "eff $type $atker"
    }
  }
  $m invoke 5
  $m invoke $mode  
  $m entryconfigure 5 -state $stat

  set catk ""
  set cdef ""
  $f.c bind eff <Enter> [list change_matchup 1 $f.c]
  $f.c bind eff <Leave> [list change_matchup 0 $f.c]
  
  wm maxsize $w 0 [expr {$px+70}]
  wm minsize $w 0 220
  after idle [wm resizable $w 0 1]
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
    "update_win \$atker \$defer \$umove $gen $w"
  
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
    lassign [calculate_damage $atker $defer Normal $move $gen] \
      res1 res2 res3 res4
    # foreach i {1 2 3 4} {
      # $w.result$i delete 0 end
      # $w.result$i insert 0 [set res$i]
    # }
  }
  
}

### Credits window
proc poke_credits {} {
  set w .pokecredits
  catch {destroy $w}
  toplevel $w
  wm title $w [mc "Credits"]
  wm resizable $w 0 0
  focus $w
  # http://www.pkparaiso.com/xy/sprites_pokemon.php
  label $w.lab -justify left -text "\
    \u00A9 1995-2015 The Pok\u00E9mon Company\n\
    \u00A9 1995-2015 Nintendo\n\
    \u00A9 1995-2015 Creatures Inc.\n\
    \u00A9 1995-2015 Game Freak Inc.
  "
  pack $w.lab
}
