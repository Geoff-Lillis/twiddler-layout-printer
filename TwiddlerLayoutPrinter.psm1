function Get-SpecialKeys {
    @{'<Backspace>'                           = "←X"
        '<Left Ctrl><Backspace></Left Ctrl>'  = "←←X"
        '<UpArrow>'                           = "↑"
        '<PageUp>'                            = "PG↑"
        '<RightArrow>'                        = "→"
        '<DownArrow>'                         = "↓"
        '<PageDown>'                          = "PG↓"
        '<LeftArrow>'                         = "←"
        '<Left Ctrl><UpArrow></Left Ctrl>'    = "↑↑"
        '<Left Ctrl><RightArrow></Left Ctrl>' = "→→"
        '<Left Ctrl><DownArrow></Left Ctrl>'  = "↓↓"
        '<Left Ctrl><LeftArrow></Left Ctrl>'  = "←←"
        '<Return>'                            = "←|"
        '<PrintScreen>'                       = "PSC"
        '<Delete>'                            = "DEL"
        '<Escape>'                            = "ESC"
        '<Home>'                              = "HME"
        '<End>'                               = "END"
        '<F1>'                                = "F1"
        '<F10>'                               = "F10"
        '<F11>'                               = "F11"
        '<F12>'                               = "F12"
        '<F2>'                                = "F2"
        '<F3>'                                = "F3"
        '<F4>'                                = "F4"
        '<F5>'                                = "F5"
        '<F6>'                                = "F6"
        '<F7>'                                = "F7"
        '<F8>'                                = "F8"
        '<F9>'                                = "F9"
        '<Tab>'                               = "TAB"
        '<CapsLock>'                          = "CAP"
        '<NumLock>'                           = "NUM"
        ' '                                   = '_'
    }
}

function Get-AllPossibleChords {
    $Keys = "OLMR".ToCharArray()
    for ($i = 0; $i -lt $Keys.Length; $i++) {
        for ($j = 0; $j -lt $Keys.Length; $j++) {
            for ($k = 0; $k -lt $Keys.Length; $k++) {
                for ($l = 0; $l -lt $Keys.Length; $l++) {
                    $Keys[$l] + $Keys[$k] + $Keys[$j] + $Keys[$i]
                }
            }
        }    
    }
}

function Get-LayoutFromCSV {
    Param (
        #Test it exists, is valid CSV
        $Path
    )
    $SpecialKeys = Get-SpecialKeys
    $NoModifierKeysPrefix = "   O "
    Import-Csv -Path $Path | Where-Object { $_.Chord.StartsWith($NoModifierKeysPrefix) } |
        ForEach-Object {
            $Chord = $_.Chord -Replace $NoModifierKeysPrefix, ""
            [PSCustomObject]@{
                Chord      = $Chord
                KeyStrokes = $_.'Key Strokes'
                KeysCount  = ($Chord -replace "O", "").length
                Type       = Get-KeystrokeType $_.'Key Strokes' $SpecialKeys
            }
        }
}

function Get-KeystrokeType($Keystrokes, $SpecialKeys) {
    if (-not $Keystrokes) {
        "Unassigned"
    } elseif ($SpecialKeys.Contains($Keystrokes)) {
        "Special"
    } elseif ($Keystrokes.length -gt 1) {
        "MultiCharacter"
    } elseif ($Keystrokes -match "^[0-9]$") {
        "Number"
    } else {
        "Letter"
    }
}

function Get-ForegroundColorFromType ($Type) {
    switch ($Type) {
        "Unassigned" { "Magenta" }
        "Special" { "Cyan" }
        "MultiCharacter" { "Green" }
        "Number" { "Yellow" }
        "Letter" { "White" }
    }
}

function Get-RowWithOneKeyPressed ($Key) {
    switch ($Key) {
        "L" { " *          " }
        "M" { "     *      " }
        "R" { "         *  " }
    }
}
    
function Get-DisplayedKeystrokes($Keystrokes, $Type, $SpecialKeys) {
    $Return = switch ($Type) {
        "Unassigned" { "[]" }
        "Special" { $SpecialKeys[$Keystrokes] }
        Default { $Keystrokes }
    }
    $Return.PadLeft(2, " ").PadRight(4, " ")
}

function Get-CellContents ($ChordToKeystrokes, $PartialChord) {
    #Writing this in an attempt to remove duplicates
    #Get a better understanding of what's going on here.
    #It's not a grid. Cell? 
    foreach ($Row in 0..3) {
        $KeyAtRowToDisplay = $PartialChord.Chars($Row)
        if ($KeyAtRowToDisplay -eq "O") {
            $Start = $PartialChord.Substring(0, $Row)
            $End = $PartialChord.Substring($Row + 1)
            foreach ($Button in "LMR".ToCharArray()) {
                $Chord = "$Start$Button$End"
                if ($ChordToKeystrokes.ContainsKey($Chord)) {
                    $ChordToKeystrokes[$Chord]
                }
            }
        }
    }
}

function Get-ChordsWithoutDuplicatedKeystrokes ($ChordToKeystrokes) {
    #Make this clearer. Get-ReducedChordsThatStillPrintAllKeystrokes?
    $Chords = Get-AllPossibleChords
    foreach ($Chord in $Chords) {
        $Keystrokes = Get-CellContents $ChordToKeystrokes $Chord
        if ($null -eq $AlreadyPrinted) {
            $NovelKeystrokes = $Keystrokes
        } elseif ($Keystrokes) {
            $NovelKeystrokes = Compare-Object $AlreadyPrinted $Keystrokes | 
                Where-Object SideIndicator -EQ "=>"
        } else {
            $NovelKeystrokes = $null
        }
        if ($NovelKeystrokes.count -gt 0) {
            $Chord
            $AlreadyPrinted += $Keystrokes
        }
    }
}

function Write-FormattedRowContents {
    #You can't call it "Get" if it doesn't return anything and it changes state.
    #Write-FormattedRowContents?
    #Split out a "Write-RowWithPressedButton" and "Write-RowWithNoPressedButtons"
    Param (
        [ValidateRange(0,3)]
        [int]$Row,
        [Hashtable]
        $ChordToKeystrokes,
        [ValidatePattern('^(O|L|M|R){4}$')]
        $PartialChord
    )
    $KeyAtRowToDisplay = $PartialChord.Chars($Row)
    if ($KeyAtRowToDisplay -match "(L|M|R)") {
        Write-Host (Get-RowWithOneKeyPressed $KeyAtRowToDisplay) -NoNewline -ForegroundColor Red
    } else {
        $SpecialKeys = Get-SpecialKeys
        $Start = $PartialChord.Substring(0, $Row)
        $End = $PartialChord.Substring($Row + 1)
        foreach ($Button in "LMR".ToCharArray()) {
            $Chord = "$Start$Button$End"
            $Keystrokes = $ChordToKeystrokes[$Chord]
            $Type = Get-KeystrokeType $Keystrokes $SpecialKeys
            $ForegroundColor = Get-ForegroundColorFromType $Type
            $DisplayedKeystrokes = Get-DisplayedKeystrokes $Keystrokes $Type $SpecialKeys
            Write-Host $DisplayedKeystrokes -ForegroundColor $ForegroundColor -NoNewline
        }
    }
}

function Get-ChordToKeystrokesHashtable ($Layout) {
    $ChordToKeystrokes = @{}
    $Layout | ForEach-Object {
        $ChordToKeystrokes.Add($_.Chord, $_.KeyStrokes)
    }
    $ChordToKeystrokes
}

function Write-TopOfGrids ([int]$GridsToDisplay) {
    for ($i = 0; $i -lt $GridsToDisplay; $i++) {
        Write-Host "┌─────────────┐" -NoNewline
    }
    Write-Host
}

function Write-BottomOfGrids ([int]$GridsToDisplay) {
    for ($i = 0; $i -lt $GridsToDisplay; $i++) {
        Write-Host "└─────────────┘" -NoNewline
    }
    Write-Host
}

function Write-ChordName ([int]$GridsToDisplay, $ChordsToDisplay, $GridIndex) {
    for ($i = 0; $i -lt $GridsToDisplay; $i++) {
        Write-Host "│" -NoNewline
        Write-Host "    $($ChordsToDisplay[$GridIndex+$i])     " -NoNewline -ForegroundColor DarkGray
        Write-Host "│" -NoNewline 
    }
    Write-Host
}

function Write-FormattedRow ([int]$GridsToDisplay, $ChordsToDisplay, $ChordToKeystrokes, $GridIndex, $RowIndex) {
    for ($i = 0; $i -lt $GridsToDisplay; $i++) {
        Write-Host "│ " -NoNewline
        (Write-FormattedRowContents $RowIndex $ChordToKeystrokes $ChordsToDisplay[$GridIndex + $i])
        Write-Host "│" -NoNewline
    }
    Write-Host
}

function Format-Layout {
    Param(
        [Parameter(Mandatory)]
        $Layout, 
        $GridsPerRow = [math]::Floor($Host.UI.RawUI.WindowSize.Width / 15),
        [ValidateRange(0, 3)] 
        $MinUnusedKeys = 1, #Is this compatible with ReduceDuplicates?
        [switch]$ChordHeader,
        [switch]$ReduceDuplicates
    )
    $ChordToKeystrokes = Get-ChordToKeystrokesHashtable $Layout
    $ChordsToDisplay = if ($ReduceDuplicates) {
        Get-ChordsWithoutDuplicatedKeystrokes $ChordToKeystrokes
    } else {
        Get-AllPossibleChords | Where-Object { ([regex]::Matches($_, "O")).Count -ge $MinUnusedKeys }
    }
    for ($j = 0; $j -lt $ChordsToDisplay.Length; $j += $GridsPerRow) {
        $RemainingChordCount = ($ChordsToDisplay.Count - $j)
        $GridsToDisplayCount = [math]::min($RemainingChordCount, $GridsPerRow)
        Write-TopOfGrids $GridsToDisplayCount
        if ($ChordHeader) {
            Write-ChordName $GridsToDisplayCount -GridIndex $j -ChordsToDisplay $ChordsToDisplay 
        }
        for ($i = 0; $i -lt 4; $i++) {
            $FormattedRowParams = @{
                GridsToDisplay    = $GridsToDisplayCount
                ChordsToDisplay   = $ChordsToDisplay
                ChordToKeystrokes = $ChordToKeystrokes
                GridIndex         = $j
                RowIndex          = $i
            }
            Write-FormattedRow @FormattedRowParams
        }
        Write-BottomOfGrids $GridsToDisplayCount
    }
}