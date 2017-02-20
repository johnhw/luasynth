require "utils"
-- basic musical definitions (chords, scales, intervals, note names)

local chords = 
{
    ["+2"] = { 0, 2, },
    ["+3"] = { 0, 4, },
    ["+4"] = { 0, 6, },
    ["+b3"] = { 0, 3, },
    ["5"] = { 0, 7, },
    ["b5"] = { 0, 6, },
    ["6sus4(-5)"] = { 0, 6, 9, },
    ["aug"] = { 0, 4, 8, },
    ["dim"] = { 0, 3, 6, },
    ["dim5"] = { 0, 4, 6, },
    ["maj"] = { 0, 4, 7, },
    ["min"] = { 0, 3, 7, },
    ["sus2"] = { 0, 2, 7, },
    ["sus2sus4(-5)"] = { 0, 2, 6, },
    ["sus4"] = { 0, 6, 7, },
    ["6"] = { 0, 4, 7, 9, },
    ["6sus2"] = { 0, 2, 7, 9, },
    ["6sus4"] = { 0, 6, 7, 9, },
    ["7"] = { 0, 4, 7, 10, },
    ["7#5"] = { 0, 4, 8, 10, },
    ["7b5"] = { 0, 4, 6, 10, },
    ["7sus2"] = { 0, 2, 7, 10, },
    ["7sus4"] = { 0, 6, 7, 10, },
    ["add2"] = { 0, 2, 4, 7, },
    ["add4"] = { 0, 4, 6, 7, },
    ["add9"] = { 0, 4, 7, 14, },
    ["dim7"] = { 0, 3, 6, 9, },
    ["dim7susb13"] = { 0, 3, 9, 20, },
    ["madd2"] = { 0, 2, 3, 7, },
    ["madd4"] = { 0, 3, 6, 7, },
    ["madd9"] = { 0, 3, 7, 14, },
    ["mmaj7"] = { 0, 3, 7, 11, },
    ["m6"] = { 0, 3, 7, 9, },
    ["m7"] = { 0, 3, 7, 10, },
    ["m7#5"] = { 0, 3, 8, 10, },
    ["m7b5"] = { 0, 3, 6, 10, },
    ["maj7"] = { 0, 4, 7, 11, },
    ["maj7#5"] = { 0, 4, 8, 11, },
    ["maj7b5"] = { 0, 4, 6, 11, },
    ["maj7sus2"] = { 0, 2, 7, 11, },
    ["maj7sus4"] = { 0, 6, 7, 11, },
    ["sus2sus4"] = { 0, 2, 6, 7, },
    ["6/7"] = { 0, 4, 7, 9, 10, },
    ["6add9"] = { 0, 4, 7, 9, 14, },
    ["7#5b9"] = { 0, 4, 8, 10, 13, },
    ["7#9"] = { 0, 4, 7, 10, 15, },
    ["7#9b5"] = { 0, 4, 6, 10, 15, },
    ["7/11"] = { 0, 4, 7, 10, 18, },
    ["7/13"] = { 0, 4, 7, 10, 21, },
    ["7add4"] = { 0, 4, 6, 7, 10, },
    ["7b9"] = { 0, 4, 7, 10, 13, },
    ["7b9b5"] = { 0, 4, 6, 10, 13, },
    ["7sus4/13"] = { 0, 6, 7, 10, 21, },
    ["9"] = { 0, 4, 7, 10, 14, },
    ["9#5"] = { 0, 4, 8, 10, 14, },
    ["9b5"] = { 0, 4, 6, 10, 14, },
    ["9sus4"] = { 0, 7, 10, 14, 18, },
    ["m maj9"] = { 0, 3, 7, 11, 14, },
    ["m6/7"] = { 0, 3, 7, 9, 10, },
    ["m6/9"] = { 0, 3, 7, 9, 14, },
    ["m7/11"] = { 0, 3, 7, 10, 18, },
    ["m7add4"] = { 0, 3, 6, 7, 10, },
    ["m9"] = { 0, 3, 7, 10, 14, },
    ["m9/11"] = { 0, 3, 10, 14, 18, },
    ["m9b5"] = { 0, 3, 6, 10, 14, },
    ["maj6/7"] = { 0, 4, 7, 9, 11, },
    ["maj7/11"] = { 0, 4, 7, 11, 18, },
    ["maj7/13"] = { 0, 4, 7, 11, 21, },
    ["maj9"] = { 0, 4, 7, 11, 14, },
    ["maj9#5"] = { 0, 4, 8, 11, 14, },
}

local common_chords = 
{
    ["aug"] = { 0, 4, 8, },
    ["dim"] = { 0, 3, 6, },
    ["dim5"] = { 0, 4, 6, },
    ["maj"] = { 0, 4, 7, },
    ["min"] = { 0, 3, 7, },
    ["sus2"] = { 0, 2, 7, },
    ["sus4"] = { 0, 6, 7, },
    ["6"] = { 0, 4, 7, 9, },
    ["7"] = { 0, 4, 7, 10, },
    ["7sus2"] = { 0, 2, 7, 10, },
    ["7sus4"] = { 0, 6, 7, 10, },
    ["add2"] = { 0, 2, 4, 7, },
    ["add4"] = { 0, 4, 6, 7, },
    ["add9"] = { 0, 4, 7, 14, },
    ["dim7"] = { 0, 3, 6, 9, },
    ["madd9"] = { 0, 3, 7, 14, },
    ["mmaj7"] = { 0, 3, 7, 11, },
    ["m6"] = { 0, 3, 7, 9, },
    ["m7"] = { 0, 3, 7, 10, },
    ["m7#5"] = { 0, 3, 8, 10, },
    ["m7b5"] = { 0, 3, 6, 10, },
    ["maj7"] = { 0, 4, 7, 11, },
    ["maj7#5"] = { 0, 4, 8, 11, },
    ["maj7b5"] = { 0, 4, 6, 11, },
    ["9"] = { 0, 4, 7, 10, 14, },
    ["mmaj9"] = { 0, 3, 7, 11, 14, },
    ["m6/7"] = { 0, 3, 7, 9, 10, },
    ["m6/9"] = { 0, 3, 7, 9, 14, },
    ["m7/11"] = { 0, 3, 7, 10, 18, },
    ["m7add4"] = { 0, 3, 6, 7, 10, },
    ["m9"] = { 0, 3, 7, 10, 14, },
    ["m9/11"] = { 0, 3, 10, 14, 18, },
    ["m9b5"] = { 0, 3, 6, 10, 14, },
    ["maj9"] = { 0, 4, 7, 11, 14, },
    }

local dim_interval = 
{
    unison =-1,
    minor_second=0,
    major_second=1,
    minor_third=2,
    major_third=3,
    perfect_fourth=4,
    tritone=5,
    fifth=6,
    minor_sixth=7,
    major_sixth=8,
    minor_seventh=9,
    major_seventh=10,
    octave=11,
}


local aug_interval = 
{
    unison =1,
    minor_second=2,
    major_second=3,
    minor_third=4,
    major_third=5,
    perfect_fourth=6,
    tritone=7,
    fifth=8,
    minor_sixth=9,
    major_sixth=10,
    minor_seventh=11,
    major_seventh=12,
    octave=13,
}

local interval = 
{
    unison =0,
    minor_second=1,
    major_second=2,
    minor_third=3,
    major_third=4,
    fourth=5,
    tritone=6,
    fifth=7,
    minor_sixth=8,
    major_sixth=9,
    minor_seventh=10,
    major_seventh=11,
    octave=12
}

--some basic scales, and some wacky ones too


function construct_mode(offset)
    local note = 0
    local modeIncrements = {2,2,1,2,2,2,1}
    local notes = {}
    
    notes[1] = 0
    for i=1,7 do 
        index = ((offset+(i-1))%7)+1
        note = note + modeIncrements[index]        
        notes[i+1] = note
    end
    return notes
end

--construct the modes, using the offset from ionian
local modes = {
    ionian = construct_mode(0),
    dorian = construct_mode(1),
    phyrgian = construct_mode(2),
    lydian = construct_mode(3),
    mixolydian = construct_mode(4),
    aeolian = construct_mode(5),
    locrian = construct_mode(6),
}

local scales = 
{
    majorPentatonic = {0, 2, 3, 7, 9},
    newPentatonic = {0, 2, 3, 6, 9},
    japanese_pentatonic = {0, 1, 5, 7, 8},
    balinese_pentatonic = {0, 1, 5, 6, 8},
    pelog_pentatonic = {0, 1, 3, 7, 10},
    hemitonic_pentatonic = {0, 2, 3, 7, 11},
    variation_pentatonic = {0, 4, 7, 9, 10},
    harmonic_minor = {0, 2, 3, 5, 7, 8, 11},
    melodic_minor = {0, 2, 3, 5, 7, 9, 11},
    whole_tone = {0, 2, 4, 6, 8, 10}, 
    augmented = {0, 3, 4, 6, 8, 11},
    diminished = {0, 2, 3, 5, 6, 8, 9, 11} ,
    enigmatic = {0, 1, 4, 6, 8, 10, 11}, 
    byzantine = {0, 1, 4, 5, 7, 8, 11},
    locrian = {0, 2, 4, 5, 6, 8, 10},
    persian = {0, 1, 4, 5, 7, 10, 11},
    spanish = {0, 1, 3, 4, 5, 6, 8, 10}, 
    hungarian = {0, 2, 3, 6, 7, 8, 10},
    nativeamerican = {0, 2, 4, 6, 9, 11},
    bebop = {0, 2, 4, 5, 7, 8, 9, 11},
    barbershop1  = {0, 2, 4, 5, 7, 11, 14, 17, 19, 23},
    barbershop2 = {0, 7, 12, 16, 19, 23},
    rain = {10, 14, 16, 18, 20, 24, 26, 30, 32},
    crystalline = {0, 7, 11, 15, 19, 26, 27, 34, 38, 42, 46, 53, 54, 61, 65, 69},
    popular_blues ={0, 3, 5, 6, 7, 10},
    blues = {0, 3, 4, 7, 8, 15, 19},
    disharmony = {0, 1, 4, 5, 7, 8, 11, 12, 14, 15, 18, 19, 21, 22, 25, 26},
    gracemajor = {0, 5, 8, 13, 17, 19, 25, 30},
    eblues = {0, 2, 4, 7, 8, 6, 13, 17},
    ionian = construct_mode(0),
    dorian = construct_mode(1),
    phyrgian = construct_mode(2),
    lydian = construct_mode(3),
    mixolydian = construct_mode(4),
    aeolian = construct_mode(5),
    locrian = construct_mode(6),
 }
 
 

local note_names = {
        ['C-']=0, ['B#']=0, 
        ['C#']=1, ['Db']=1,
        ['D-']=2, 
        ['D#']=3, ['Eb']=3,
        ['E-']=4, ['Fb']=4,
        ['F-']=5, ['E#']=5,
        ['F#']=6, ['Gb']=6,
        ['G-']=7,
        ['G#']=8, ['Ab']=8,
        ['A-']=9, 
        ['A#']=10, ['Bb']=10,
        ['B-']=11, ['Cb']=11
        
}

plain_note_names = {
        ['C']=0, 
        ['C#']=1,
        ['D']=2, 
        ['D#']=3,
        ['E']=4, 
        ['F']=5, 
        ['F#']=6, 
        ['G']=7,
        ['G#']=8, 
        ['A']=9, 
        ['A#']=10, 
        ['B']=11,
}

plain_note_numbers = invert_table(plain_note_names)



note_numbers = { 
        [0]='C-', 
         [1]='C#',
         [2]='D-',
         [3]='D#',
         [4]='E-',
         [5]='F-',
         [6]='F#',
         [7]='G-',
         [8]='G#',
         [9]='A-',
         [10]='A#',
         [11]='B-'}



--Convert a notespec of the form C-4 to a midi note number.  The last digit is the octave.
--Naturals are of the form C-4, sharps C#4, flats Cb4. Octave can be 0--9
function note_to_number(note)    
    local name = string.upper(string.sub(note, 1, 2))
    local octave = string.sub(note,3,3)
    local note = note_names[name] + octave*12
    return note
end

-- Only ever returns natural or sharps -- never flats
function number_to_note(number)
    local octave = math.floor(number / 12)
    local note = number % 12
    return note_numbers[note]..octave
end


return {chords=chords, common_chords=common_chords, dim_interval=dim_interval, aug_interval=aug_interval, interval=interval,
    modes=modes, scales=scales, note_numbers=note_numbers, note_names=note_names, plain_note_names=plain_note_names,
    plain_note_numbers=plain_note_numbers,
    note_to_number=note_to_number,
    number_to_note=number_to_note
}