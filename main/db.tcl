### Load database and create it
sqlite3 dex pokedexdb

namespace eval pokedb {
  ### Create config file and check if other tables need to be created/updated
  proc db_init {} {
    upvar note note menu menu
    dex eval {
      CREATE TABLE IF NOT EXISTS config (
        param text PRIMARY KEY ON CONFLICT ABORT UNIQUE,
        value text
      )
    }
    
    dex eval {
      CREATE TABLE IF NOT EXISTS mtimes (
        filename text PRIMARY KEY ON CONFLICT ABORT UNIQUE,
        mtime text
      )
    }

    if {![dex exists {SELECT 1 FROM config}]} {
      # Configuration table
      # abilitydef - def-ault mode of ability tab
      #    0 - description
      #    1 - pokemon list
      # movedef - def-ault mode of move tab
      #    0 - description
      #    1 - pokemon list
      # gen - default generation to open to
      # genN game - default game to open to
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
          ('movedef', 0),
          ('gen', $pokedex::current(gen)),
          ('gen1 game', 2),
          ('gen2 game', 2),
          ('gen3 game', 3),
          ('gen4 game', 3),
          ('gen5 game', 2),
          ('gen6 game', 2),
          ('gen7 game', 2),
          ('language', 'English'),
          ('matchup', 0),
          ('matchuphide', 1)
      }
    }
    
    ### Buiding database
    # progress bar

    
    array set mtimes [dex eval {SELECT * FROM mtimes}]

    # Building types
    set mtime [file mtime [file join data types]]
    if {![info exists mtimes(types)]} {
      dex eval {
        CREATE TABLE types(
          type text,
          gen int,
          colour text
        )
      }
      dex eval {INSERT INTO mtimes (filename, mtime) VALUES ('types', '')}
      set mtimes(types) ""
    }
    if {$mtimes(types) != $mtime} {
      import {data types} types {type gen colour}
      dex eval {UPDATE mtimes SET mtime = :mtime WHERE filename = 'types'}
    }
    
    # Building itypes - introduced double typings
    set mtime [file mtime [file join data itypes]]
    if {![info exists mtimes(itypes)]} {
      dex eval {
        CREATE TABLE itypes(
          type1 text,
          type2 text,
          gen int
        )
      }
      dex eval {INSERT INTO mtimes (filename, mtime) VALUES ('itypes', '')}
      set mtimes(itypes) ""
    }
    if {$mtimes(itypes) != $mtime} {
      import {data itypes} itypes {type1 type2 gen}
      dex eval {UPDATE mtimes SET mtime = :mtime WHERE filename = 'itypes'}
    }
    
    # Building natures
    set mtime [file mtime [file join data nature]]
    if {![info exists mtimes(nature)]} {
      dex eval {
        CREATE TABLE nature(
          name text,
          boost text,
          nerf text
        )
      }
      dex eval {INSERT INTO mtimes (filename, mtime) VALUES ('nature', '')}
      set mtimes(nature) ""
    }
    if {$mtimes(nature) != $mtime} {
      import {data nature} nature {name boost nerf}
      dex eval {UPDATE mtimes SET mtime = :mtime WHERE filename = 'nature'}
    }
    
    # Building abilities language
    set mtime [file mtime [file join data abilities]]
    if {![info exists mtimes(abilities)]} {
      dex eval {
        CREATE TABLE abilities(
          id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
          english text,
          japanese text,
          korean text,
          german text,
          french text
        )
      }
      dex eval {INSERT INTO mtimes (filename, mtime) VALUES ('abilities', '')}
      set mtimes(abilities) ""
    }
    if {$mtimes(abilities) != $mtime} {
      import {data abilities} abilities {id english japanese korean german french}
      dex eval {UPDATE mtimes SET mtime = :mtime WHERE filename = 'abilities'}
    }
    
    # Building moves language
    set mtime [file mtime [file join data moves]]
    if {![info exists mtimes(moves)]} {
      dex eval {
        CREATE TABLE moves(
          id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
          english text,
          japanese text,
          korean text,
          german text,
          french text
        )
      }
      dex eval {INSERT INTO mtimes (filename, mtime) VALUES ('moves', '')}
      set mtimes(moves) ""
    }
    if {$mtimes(moves) != $mtime} {
      import {data moves} moves {id english japanese korean german french}
      dex eval {UPDATE mtimes SET mtime = :mtime WHERE filename = 'moves'}
    }
    
    # Building main tables
    foreach gen $pokedex::generations {
      create_database $gen
    }
    
    set pokedex::current(gen) [dex eval {SELECT value FROM config WHERE param = 'gen'}]
    $note select [expr {$pokedex::current(gen)-1}]
    
    foreach i $pokedex::generations {
      set pokedex::current(game$i) [dex eval "SELECT value FROM config WHERE param = 'gen$i game'"]
      $menu.file.gen.game$i invoke [expr {$pokedex::current(game$i)}]
      $note.gen$i.move.game select [expr {$pokedex::current(game$i)}]
    }
  }

  ### Populate database if files were updated
  proc create_database {gen} {
    array set mtimes [dex eval {SELECT * FROM mtimes}]
    
    set mtime [file mtime [file join data gen$gen info]]
    if {![info exists mtimes([file join gen$gen info])]} {
      dex eval "
        CREATE TABLE pokeDetails${gen}(
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
          base_exp int,
          pre_evos text
        )
      "
      dex eval "INSERT INTO mtimes (filename, mtime) VALUES ('[file join gen$gen info]', '')"
      set mtimes([file join gen$gen info]) ""
    }
    if {$mtimes([file join gen$gen info]) != $mtime} {
      import [list data gen$gen info] pokeDetails$gen {
        id
        pokemon
        formname
        type
        genus
        ability1
        ability2
        hability
        gender
        egggroup
        height
        weight
        legend
        evolve_cond
        hp
        atk
        def
        spatk
        spdef
        spd
        capture
        final
        stage
        effort
        hatch_counter
        happiness
        exp
        forms
        colour
        base_exp
        pre_evos
      }
      dex eval "UPDATE mtimes SET mtime = :mtime WHERE filename = '[file join gen$gen info]'"
    }
    
    set mtime [file mtime [file join data gen$gen moves]]
    if {![info exists mtimes([file join gen$gen moves])]} {
      dex eval "
        CREATE TABLE moveDetails${gen}(
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
      "
      dex eval "INSERT INTO mtimes (filename, mtime) VALUES ('[file join gen$gen moves]', '')"
      set mtimes([file join gen$gen moves]) ""
    }
    if {$mtimes([file join gen$gen moves]) != $mtime} {
      import [list data gen$gen moves] moveDetails${gen} {
        id
        type
        class
        pp
        basepower
        accuracy
        priority
        effect
        contact
        charging
        recharge
        detectprotect
        reflectable
        snatchable
        mirrormove
        punchbased
        sound
        gravity
        defrosts
        range
        heal
        infiltrate
      }
      dex eval "UPDATE mtimes SET mtime = :mtime WHERE filename = '[file join gen$gen moves]'"
    }
    
    if {$gen > 2} {
      set mtime [file mtime [file join data gen$gen abilities]]
      if {![info exists mtimes([file join gen$gen abilities])]} {
        dex eval "
          CREATE TABLE abilDetails${gen}(
            id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
            flavour text,
            description text
          )
        "
        dex eval "INSERT INTO mtimes (filename, mtime) VALUES ('[file join gen$gen abilities]', '')"
        set mtimes([file join gen$gen abilities]) ""
      }
      if {$mtimes([file join gen$gen abilities]) != $mtime} {
        import [list data gen$gen abilities] abilDetails$gen {
          id
          flavour
          description
        }
        dex eval "UPDATE mtimes SET mtime = :mtime WHERE filename = '[file join gen$gen abilities]'"
      }
    }
    
    set mtime [file mtime [file join data gen$gen matchup]]
    if {![info exists mtimes([file join gen$gen matchup])]} {
      dex eval "
        CREATE TABLE matchDetails${gen}(
          type1 text,
          type2 text,
          effectiveness float
        )
      "
      dex eval "INSERT INTO mtimes (filename, mtime) VALUES ('[file join gen$gen matchup]', '')"
      set mtimes([file join gen$gen matchup]) ""
    }
    if {$mtimes([file join gen$gen matchup]) != $mtime} {
      import [list data gen$gen matchup] matchDetails$gen {
        type1
        type2
        effectiveness
      }
      dex eval "UPDATE mtimes SET mtime = :mtime WHERE filename = '[file join gen$gen matchup]'"
    }
    
    foreach movefile [glob -nocomplain [file join data gen$gen ver* *]] {
      set tablename [join [lrange [file split $movefile] end-1 end] _]
      set mtime [file mtime $movefile]
      set value [file join {*}[lrange [file split $movefile] 1 end]]
      if {![info exists mtimes($value)]} {
        dex eval "
          CREATE TABLE ${tablename}(
            id text PRIMARY KEY ASC ON CONFLICT ABORT UNIQUE,
            moves text
          )
        "
        dex eval "INSERT INTO mtimes (filename, mtime) VALUES ('$value', '')"
        set mtimes($value) ""
      }
      
      if {$mtimes($value) != $mtime} {
        import [file split $movefile] $tablename {id moves}
        dex eval {UPDATE mtimes SET mtime = :mtime WHERE filename = :value}
      }
    }
  }

  proc import {filepath table fields} {
    dex eval "DELETE FROM $table"
    try {
      dex copy ignore $table [file join {*}$filepath] "\t"
    } on error {result options} {
      set f [open [file join {*}$filepath] r]
      fconfigure $f -encoding utf-8
      while {[gets $f line] != -1} {
        lassign [split $line "\t"] {*}$fields
        set values [join [lmap x $fields {
          set x [regsub -all {\'} [set $x] {''}]
          if {![string is integer $x] || $x eq ""} {set x '$x'} else {set x}
        }] ","]
        if {[catch {dex eval "INSERT INTO $table ([join $fields ,]) VALUES($values)"}]} {
          tk_messageBox -title test -message "INSERT INTO $table ([join $fields ,]) VALUES($values)"
          dex close
          file delete -force pokedexdb
          exit
        }
      }
      close $f
    }
  }
}
