Import-Module .\TwiddlerLayoutPrinter.psm1

Describe Get-SpecialKeys {
    It "Should return a hashtable" {
        Get-SpecialKeys | Should -BeOfType "Hashtable"
    }
    It "Should not have any symbols longer than three characters" {
        (Get-SpecialKeys).values | Where-Object length -gt 3 | Should -BeNullOrEmpty
    }
}

Describe Get-AllPossibleChords {
    It "Should have 256 unique values" {
        (Get-AllPossibleChords | Get-Unique).Count | Should -Be 256
    }
    It "All should match the pattern ^(O|L|M|R){4}$" {
        Get-AllPossibleChords | Where-Object { $_ -match "^(O|L|M|R){4}$" } | 
            Measure-Object | Select-Object -ExpandProperty Count | Should -Be 256
    }
}

Describe Get-LayoutFromCSV {
    BeforeAll {
        @"
        "Chord","Key Strokes"
        "   N OOOL","<Left GUI>s</Left GUI>"
        "   O ORMM","``"
        "   O OLMM","\"
        "   O OMMM",";"
        "   N OROO","<Left GUI>r</Left GUI>"
        "   O ROOO","o"
        "   O MOOO","i"
        "   O LOOO","e"
        "   O OROO","r"
        "   O RROO","or"
"@ | Out-File TestDrive:\Layout.csv
    }
    It "Loads chords from a Twiddler tuner export, ignoring chords with modifiers, adding number of keys pressed and type" {
        $Layout = Get-LayoutFromCSV TestDrive:\Layout.csv
        $Layout | Should -HaveCount 8
        $Layout.KeyStrokes | Should -Be "``", "\", ";", "o", "i", "e", "r", "or"
        $Layout.KeysCount | Should -Be 3, 3, 3, 1, 1, 1, 1, 2
        $Layout.Type[0..($Layout.Length - 2)] | Select-Object -Unique | Should -Be "Letter"
        $Layout.Type[-1] | Should -Be "Multicharacter"
    }
}

Describe Get-KeystrokeType {
    BeforeAll {
        $script:SpecialKeys = Get-SpecialKeys
    }
    It "Should return 'Unassigned' when passed a null value" {
        Get-KeystrokeType -SpecialKeys $SpecialKeys | Should -Be "Unassigned"
    }    
    It "Should return 'Special' when passed a special key" {
        Get-KeystrokeType "<TAB>" -SpecialKeys $SpecialKeys | Should -Be "Special"
    }    
    It "Should return 'MultiCharacter' when passed a multicharacter string" {
        Get-KeystrokeType "the" -SpecialKeys $SpecialKeys | Should -Be "MultiCharacter"
    }    
    It "Should return 'Number' in all other cases" {
        Get-KeystrokeType "1" -SpecialKeys $SpecialKeys | Should -Be "Number"
    }
    It "Should return 'Letter' in all other cases" {
        Get-KeystrokeType "l" -SpecialKeys $SpecialKeys | Should -Be "Letter"
    }    
}

Describe Get-ForegroundColorFromType  {
    $TypesAndColours = @(
        @{ Type = "Unassigned";     Color = "Magenta" }
        @{ Type = "Special";        Color = "Cyan"    }
        @{ Type = "MultiCharacter"; Color = "Green"   }
        @{ Type = "Number";         Color = "Yellow"  }
        @{ Type = "Letter";         Color = "White"   }
    )
    It "When passed the type '<Type>', it returns the colour <Color>." -ForEach $TypesAndColours {
        Get-ForegroundColorFromType -Type $Type | Should -Be $Color
    }

}
Describe Get-RowWithOneKeyPressed  {
    $ButtonsAndDisplayedRows = @(
        @{ Button = "L"; DisplayedRow = " *          " }
        @{ Button = "M"; DisplayedRow = "     *      " }
        @{ Button = "R"; DisplayedRow = "         *  " }
    )
    It "When '<Button>' is pressed, the displayed row is |$DisplayedRow|" -ForEach $ButtonsAndDisplayedRows {
        Get-RowWithOneKeyPressed -Key $Button | Should -Be $DisplayedRow
    }
}
Describe Get-DisplayedKeystrokes {
    BeforeAll {
        $script:SpecialKeys = Get-SpecialKeys
    }
    It "Returns '[]' when the type is 'Unassigned'" {
        Get-DisplayedKeystrokes -Type "Unassigned" -SpecialKeys $SpecialKeys | Should -Be "[]  "
    }
    It "Returns a special display character when the type is 'Special'" {
        Get-DisplayedKeystrokes -Type "Special" -Keystrokes "<Escape>" -SpecialKeys $SpecialKeys | Should -Be "ESC "
    }
    It "Returns the keystrokes when the type is 'Default'" {
        Get-DisplayedKeystrokes -Type "Default" -Keystrokes "a" -SpecialKeys $SpecialKeys | Should -Be " a  "
    }
    It "Uses appropriate padding when the keystrokes contain two characters" {
        Get-DisplayedKeystrokes -Type "Default" -Keystrokes "aa" -SpecialKeys $SpecialKeys | Should -Be "aa  "
    }
}
Describe Get-CellContents  {
    It "Returns the expected cell contents based on sample data" {
        $ChordToKeystrokes = @{"LROO" = "er"; "LMOO" = "me"; "LLOO" = "he"; "LORO" = "ea"}
        Get-CellContents -ChordToKeystrokes $ChordToKeystrokes -PartialChord "LOOO" |
            Should -Be "he", "me", "er", "ea"
    }
}
Describe Get-ChordsWithoutDuplicatedKeystrokes  {
    It "Gives the expected result based on sample data" {
        $Layout = @"
        "Chord", "KeyStrokes",                         "KeysCount", "Type"
        "MMRO",  "<Delete>",                           "3",         "Special"
        "MLMO",  "<Left Ctrl><Backspace></Left Ctrl>", "3",         "Special"
        "ROOO",  "o",                                  "1",         "Letter"
        "MOOO",  "i",                                  "1",         "Letter"
        "LOOO",  "e",                                  "1",         "Letter"
        "OROO",  "r",                                  "1",         "Letter"
        "RROO",  "or",                                 "2",         "MultiCharacter"
        "MROO",  "ri",                                 "2",         "MultiCharacter"
        "LROO",  "er",                                 "2",         "MultiCharacter"
        "OMOO",  "m",                                  "1",         "Letter"
"@ | ConvertFrom-CSV
        $ChordToKeystrokes = Get-ChordToKeystrokesHashtable $Layout
        Get-ChordsWithoutDuplicatedKeystrokes (Get-ChordToKeystrokesHashtable $Layout) |
            Should -Be "OOOO","LOOO","MOOO","ROOO","MLOO","MMOO"
    }
}
Describe Write-FormattedRowContents  {
    It "Calls Get-RowWithOneKeyPressed if a key is pressed" {
        Mock Get-RowWithOneKeyPressed -ModuleName TwiddlerLayoutPrinter {}
        Write-FormattedRowContents -Row 0 -PartialChord "LOOO" -ChordToKeyStrokes @{} |
            Should -Invoke Get-RowWithOneKeyPressed -ModuleName TwiddlerLayoutPrinter -Exactly 1
    }
    It "Prints the keystrokes for buttons on row 1 when the L button of row 0 is pressed" {
        $ChordToKeystrokes = @{"LROO" = "er"; "LMOO" = "me"; "LLOO" = "he"}
        Mock Write-Host -ModuleName TwiddlerLayoutPrinter {}
        Write-FormattedRowContents -Row 1 -PartialChord "LOOO" -ChordToKeyStrokes $ChordToKeystrokes | 
            Should -Invoke Write-Host -Times 3 -Exactly -ModuleName TwiddlerLayoutPrinter -ParameterFilter {
                $NoNewLine -and $ForegroundColor -eq "Green"
            }
    }
}
Describe Get-ChordToKeystrokesHashtable  {

}
Describe Write-TopOfGrids {
    It "Writes two grid tops and a newline when passed 2" {
        Mock Write-Host {} -ModuleName TwiddlerLayoutPrinter
        Write-TopOfGrids -GridsToDisplay 2
        Assert-MockCalled Write-Host -Exactly 2 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -eq "┌─────────────┐" -and $NoNewLine
        } 
        Assert-MockCalled Write-Host -Exactly 1 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -eq $null -and -not $NoNewLine 
        }
    }
}

Describe Write-BottomOfGrids {
    It "Writes two grid tops and a newline when passed 2" {
        Mock Write-Host {} -ModuleName TwiddlerLayoutPrinter
        Write-BottomOfGrids -GridsToDisplay 2
        Assert-MockCalled Write-Host -Exactly 2 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -eq "└─────────────┘" -and $NoNewLine
        } 
        Assert-MockCalled Write-Host -Exactly 1 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -eq $null -and -not $NoNewLine 
        }
    }
}

Describe Write-ChordName  {
    It "Writes two chord names in gray surrounded by pipes when passed 2" {
        Mock Write-Host {} -ModuleName TwiddlerLayoutPrinter
        Write-ChordName -GridsToDisplay 2 -ChordsToDisplay "OOOO", "LLLL"
        Assert-MockCalled Write-Host -Exactly 2 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -match "    (OOOO|LLLL)     " -and $NoNewLine -and $ForegroundColor -eq "DarkGray"
        } 
        Assert-MockCalled Write-Host -Exactly 4 -ModuleName TwiddlerLayoutPrinter -ParameterFilter {
            $Object -eq "│" -and $NoNewLine
        }
        Assert-MockCalled Write-Host -Exactly 1 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -eq $null -and -not $NoNewLine 
        }
    }
}
Describe Write-FormattedRow  {
    It "Calls Write-FormattedRowContents with appropriate parameters" {
        $ChordToKeystrokesParam = @{"LLLO" = "the"; "MRMM" = "5"; "MOLO" = "ti"}
        $FormattedRowParams = @{
            GridsToDisplay    = 2
            ChordsToDisplay   = "OOOO", "OOMO"
            ChordToKeystrokes = $ChordToKeystrokesParam
            GridIndex         = 0
            RowIndex          = 1
        }
        Mock Write-Host {} -ModuleName TwiddlerLayoutPrinter
        Mock Write-FormattedRowContents {} -ModuleName TwiddlerLayoutPrinter
        Write-FormattedRow @FormattedRowParams
        Assert-MockCalled Write-FormattedRowContents -Exactly 2 -ModuleName TwiddlerLayoutPrinter -ParameterFilter {
            $Row -eq 1 -and 
            $ChordToKeystrokes -eq $ChordToKeystrokesParam -and
            $PartialChord -match "(OOOO|OOMO)"
        }
    }
}

Describe Format-Layout {
    BeforeAll {
        Mock Write-Host {} -ModuleName TwiddlerLayoutPrinter
        @"
        "Chord","Key Strokes"
        "   N OOOL","<Left GUI>s</Left GUI>"
        "   O ORMM","``"
        "   O OLMM","\"
        "   O OMMM",";"
        "   N OROO","<Left GUI>r</Left GUI>"
        "   O ROOO","o"
        "   O MOOO","i"
        "   O LOOO","e"
        "   O OROO","r"
        "   O RROO","or"
"@ | Out-File TestDrive:\Layout.csv
        Mock Write-TopOfGrids {} -ModuleName TwiddlerLayoutPrinter
        Mock Write-ChordName {} -ModuleName TwiddlerLayoutPrinter
        Mock Write-FormattedRow {} -ModuleName TwiddlerLayoutPrinter
        Mock Write-BottomOfGrids {} -ModuleName TwiddlerLayoutPrinter

    }
    It "Formats Layouts" {
        Format-Layout (Get-LayoutFromCSV TestDrive:\Layout.csv) -GridsPerRow 10
        Assert-MockCalled Write-TopOfGrids -Exactly 18 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -eq $null -and -not $NoNewLine 
        }

        Assert-MockCalled Write-FormattedRow -Exactly 72 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -eq $null -and -not $NoNewLine 
        }

        Assert-MockCalled Write-BottomOfGrids -Exactly 18 -ModuleName TwiddlerLayoutPrinter -ParameterFilter { 
            $Object -eq $null -and -not $NoNewLine 
        }
    }
    It "Calls Get-ChordsWithoutDuplicatedKeystrokes when the -ReduceDuplicates switch is used" {
        Mock Get-ChordsWithoutDuplicatedKeystrokes {} -ModuleName TwiddlerLayoutPrinter
        Format-Layout (Get-LayoutFromCSV TestDrive:\Layout.csv) -GridsPerRow 10 -ReduceDuplicates |
            Should -Invoke Get-ChordsWithoutDuplicatedKeystrokes -ModuleName TwiddlerLayoutPrinter
    }
    It "Calls Write-ChordName when the -ChordHeader switch is used" {
        Mock Write-ChordName {} -ModuleName TwiddlerLayoutPrinter
        Format-Layout (Get-LayoutFromCSV TestDrive:\Layout.csv) -GridsPerRow 10 -ChordHeader |
            Should -Invoke Write-ChordName -ModuleName TwiddlerLayoutPrinter
    }
}