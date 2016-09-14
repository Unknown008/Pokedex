### Run only when sourced
if {[info exists argv0] && [file tail $argv0] ne "main.tcl"} {
  tk_messageBox -title Error \
    -message "This script should be run from the main.tcl script"
  exit
}

### Load database and create it
sqlite3 dex pokedexdb

### Populate database if files were updated
proc create_database {pokeDir gen poke move ability match movesetupdate} {
  set pokeDetails "pokeDetails$gen"
  set moveDetails "moveDetails$gen"
  set abilDetails "abilDetails$gen"
  set matcDetails "matcDetails$gen"
  if {$poke} {
    dex eval "DROP TABLE IF EXISTS $pokeDetails"
    dex eval "
      CREATE TABLE IF NOT EXISTS ${pokeDetails}(
        id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
        pokemon text,
        formname text,
        type text,
        genus text,
        ability1 text,
        ability2 text,
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
    "
    set pokefile [file join $pokeDir data gen$gen info]
    if {[file exists $pokefile]} {
      set f [open $pokefile r]
      set code "dex eval {
        INSERT INTO $pokeDetails VALUES(
          \$id,
          \$pokemon,
          \$formname,
          \$type,
          \$genus,
          \$ability1,
          \$ability2,
          \$hability,
          \$gender,
          \$egggroup,
          \$height,
          \$weight,
          \$legend,
          \$evolve_cond,
          \$hp,
          \$atk,
          \$def,
          \$spatk,
          \$spdef,
          \$spd,
          \$capture,
          \$final,
          \$stage,
          \$effort,
          \$hatch_counter,
          \$happiness,
          \$exp,
          \$forms,
          \$colour,
          \$base_exp
        )
      }"
      while {[gets $f line] != -1} {
        lassign [split $line "\t"] id pokemon formname type genus ability1 \
          ability2 hability gender egggroup height weight legend evolve_cond hp \
          atk def spatk spdef spd capture final stage effort hatch_counter \
          happiness exp forms colour base_exp
        eval $code
      }
      close $f
      #dex copy ignore $pokeDetails $pokefile "\t"
      set mtime [file mtime $pokefile]
      dex eval {INSERT INTO config VALUES($pokefile, $mtime)}
    }
  }
  if {$move} {
    dex eval "DROP TABLE IF EXISTS $moveDetails"
    dex eval "
      CREATE TABLE IF NOT EXISTS ${moveDetails}(
        id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
        name text,
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
    "
    set pokefile [file join $pokeDir data gen$gen moves]
    if {[file exists $pokefile]} {
      set f [open $pokefile r]
      set code "dex eval {
        INSERT INTO $moveDetails VALUES(
          \$id,
          \$name,
          \$type,
          \$class,
          \$pp,
          \$basepower,
          \$accuracy,
          \$priority,
          \$effect,
          \$contact,
          \$charging,
          \$recharge,
          \$detectprotect,
          \$reflectable,
          \$snatchable,
          \$mirrormove,
          \$punchbased,
          \$sound,
          \$gravity,
          \$defrosts,
          \$range,
          \$heal,
          \$infiltrate
        )
      }"
      while {[gets $f line] != -1} {
        lassign [split $line "\t"] id name type class pp basepower accuracy priority \
          effect contact charging recharge detectprotect reflectable snatchable \
          mirrormove punchbased sound gravity defrosts range heal infiltrate
        eval $code
      }
      close $f
      #dex copy ignore $moveDetails $pokefile "\t"
      set mtime [file mtime $pokefile]
      dex eval {INSERT INTO config VALUES($pokefile, $mtime)}
    }
  }
  
  if {$ability} {
    dex eval "DROP TABLE IF EXISTS $abilDetails"
    dex eval "
      CREATE TABLE IF NOT EXISTS ${abilDetails}(
        id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
        description text
      )
    "
    set pokefile [file join $pokeDir data gen$gen abilities]
    if {[file exists $pokefile]} {
      set f [open $pokefile r]
      set code "dex eval {
        INSERT INTO $abilDetails VALUES(
          \$id,
          \$description
        )
      }"
      while {[gets $f line] != -1} {
        lassign [split $line "\t"] id description
        eval $code
      }
      close $f
      #dex copy ignore $abilDetails $pokefile "\t"
      
      set mtime [file mtime $pokefile]
      dex eval {INSERT INTO config VALUES($pokefile, $mtime)}
    }
  }
  
  if {$match} {
    dex eval "DROP TABLE IF EXISTS $matcDetails"
    dex eval "
      CREATE TABLE IF NOT EXISTS ${matcDetails}(
        type1 text,
        type2 text,
        effectiveness float
      )
    "
    set pokefile [file join $pokeDir data gen$gen matchup]
    if {[file exists $pokefile]} {
      set f [open $pokefile r]
      set code "dex eval {
        INSERT INTO $matcDetails VALUES(
          \$type1,
          \$type2,
          \$effectiveness
        )
      }"
      while {[gets $f line] != -1} {
        lassign [split $line "\t"] type1 type2 effectiveness
        eval $code
      }
      close $f
      #dex copy ignore $matcDetails $pokefile "\t"
      set mtime [file mtime $pokefile]
      dex eval {INSERT INTO config VALUES($pokefile, $mtime)}
    }
  }
  
  if {$movesetupdate != ""} {
    foreach moveset [glob -nocomplain "[file join $pokeDir data gen$gen moves?]*"] {
      set tablename [file tail $moveset]
      if {$tablename ni $movesetupdate && $movesetupdate ne "all"} {continue}
      set f [open $moveset r]
      set table "$tablename$gen"
      dex eval "DROP TABLE IF EXISTS $table"
      dex eval "
        CREATE TABLE IF NOT EXISTS ${table}(
          id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
          moves text
        )
      "
      set code "dex eval {
        INSERT INTO $table VALUES(
          \$id,
          \$moves
        )
      }"
      while {[gets $f line] != -1} {
        set group [split $line \t]
        set id [lindex $group 0]
        set moves [join [lrange $group 1 end] \t]
        eval $code
      }
      close $f
      set mtime [file mtime $moveset]
      dex eval {INSERT INTO config VALUES($moveset, $mtime)}
    }
  }
}

proc db_init {} {
  global currentGen pokeDir generations
  upvar note note menu menu
  dex eval {
    CREATE TABLE IF NOT EXISTS config (
      param text PRIMARY KEY ON CONFLICT ABORT UNIQUE,
      value text
    )
  }

  if {![dex exists {SELECT 1 FROM config}]} {
    # Configuration table
    # abilitydef - def-ault mode of ability tab
    #    0 - description
    #    1 - pokemon list
    # gen - default generation to open to
    # language - default language
    # matchup - basic or extended mode
    #    0 - basic
    #    1 - extended
    # matchuphide - default hiding of illegal typings
    #    0 - show all typings
    #    1 - hide illegal typings
    dex eval {
      INSERT INTO config (param, value) VALUES
        ('abilitydef', 0),
        ('gen', $currentGen),
        ('language', 'English'),
        ('matchup', 0),
        ('matchuphide', 1)
    }
       
    ### Buiding database
    # progress bar
    
    # Building main tables
    foreach gen $generations {
      create_database $pokeDir $gen 1 1 1 1 "all"
    }
    
    # Buikding types
    dex eval {
      CREATE TABLE types(
        type text,
        gen int,
        colour text
      )
    }
    set f [open [file join $pokeDir data types] r]
    while {[gets $f line] != -1} {
      lassign [split $line "\t"] type gen colour
      dex eval {
          INSERT INTO types VALUES(
            $type,
            $gen,
            $colour
        )
      }
    }
    close $f
    #dex copy ignore types [file join $pokeDir data types] "\t"
    
    # Building itypes - introduced double typings
    dex eval {
      CREATE TABLE itypes(
        type1 text,
        type2 text,
        gen int
      )
    }
    set f [open [file join $pokeDir data itypes] r]
    while {[gets $f line] != -1} {
      lassign [split $line "\t"] type1 type2 gen
      dex eval {
        INSERT INTO itypes VALUES(
          $type1,
          $type2,
          $gen
        )
      }
    }
    close $f
    #dex copy ignore itypes [file join $pokeDir data itypes] "\t"
    
    # Building natures
    dex eval {
      CREATE TABLE nature(
        name text,
        boost text,
        nerf text
      )
    }
    set f [open [file join $pokeDir data nature] r]
    while {[gets $f line] != -1} {
      lassign [split $line "\t"] name boost nerf
      dex eval {
          INSERT INTO nature VALUES(
            $name,
            $boost,
            $nerf
        )
      }
    }
    close $f
    #dex copy ignore itypes [file join $pokeDir data nature] "\t"
    
    $note select [expr {$currentGen-1}]
  } else {
    array set mtimes [dex eval {SELECT * FROM config WHERE param LIKE '%data_gen%'}]
    
    foreach gen $generations {
      lassign [list 0 0 0 0 ""] poke move ability matchup moveset
      set files [glob -nocomplain -type f "[file join $pokeDir data gen$gen]/*"]
      foreach file $files {
        set newmtime [file mtime $file]
        set table [file tail $file]
        if {![info exists mtimes($file)]} {
          # If there are new movesets
          if {[regexp {moves[A-Z]} $file]} {
            dex eval {INSERT INTO config VALUES($file, $mtime)}
            lappend moveset $table
          }
        } elseif {$mtimes($file) != $newmtime} {
          dex eval {UPDATE config SET value = $pokeDate WHERE param = $file}
          switch -regexp $table {
            {^info} {set poke 1}
            {^moves} {set move 1}
            {^abilities} {set ability 1}
            {^matchup} {set matchup 1}
            {^moves[A-Z]} {lappend moveset $table}
          }
        }
      }
      create_database $pokeDir $gen $poke $move $ability $matchup $moveset
    }
  }
  set gen [dex eval {SELECT value FROM config WHERE param = 'gen'}]
  $menu.file.gen invoke [expr {$gen-1}]
  $note select [expr {$gen-1}]
}

db_init
