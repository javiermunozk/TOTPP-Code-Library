func = require "functions" 
civlua = require "civlua"
charSize={
[string.char(0)]=1,
[string.char(1)]=1,
[string.char(2)]=1,
[string.char(3)]=1,
[string.char(4)]=1,
[string.char(5)]=1,
[string.char(6)]=1,
[string.char(7)]=1,
[string.char(8)]=1,
[string.char(9)]=1,
[string.char(10)]=1,
[string.char(11)]=1,
[string.char(12)]=1,
[string.char(13)]=1,
[string.char(14)]=1,
[string.char(15)]=1,
[string.char(16)]=1,
[string.char(17)]=1,
[string.char(18)]=1,
[string.char(19)]=1,
[string.char(20)]=1,
[string.char(21)]=1,
[string.char(22)]=1,
[string.char(23)]=1,
[string.char(24)]=1,
[string.char(25)]=1,
[string.char(26)]=1,
[string.char(27)]=1,
[string.char(28)]=1,
[string.char(29)]=1,
[string.char(30)]=1,
[string.char(31)]=1,
[string.char(32)]=1,
[string.char(33)]=1,
[string.char(34)]=1,
[string.char(35)]=1,
[string.char(36)]=1,
[string.char(37)]=1,
[string.char(38)]=1,
[string.char(39)]=1,
[string.char(40)]=1,
[string.char(41)]=1,
[string.char(42)]=1,
[string.char(43)]=1,
[string.char(44)]=1,
[string.char(45)]=1,
[string.char(46)]=1,
[string.char(47)]=1,
[string.char(48)]=1,
[string.char(49)]=1,
[string.char(50)]=1,
[string.char(51)]=1,
[string.char(52)]=1,
[string.char(53)]=1,
[string.char(54)]=1,
[string.char(55)]=1,
[string.char(56)]=1,
[string.char(57)]=1,
[string.char(58)]=1,
[string.char(59)]=1,
[string.char(60)]=1,
[string.char(61)]=1,
[string.char(62)]=1,
[string.char(63)]=1,
[string.char(64)]=1,
[string.char(65)]=1,
[string.char(66)]=1,
[string.char(67)]=1,
[string.char(68)]=1,
[string.char(69)]=1,
[string.char(70)]=1,
[string.char(71)]=1,
[string.char(72)]=1,
[string.char(73)]=1,
[string.char(74)]=1,
[string.char(75)]=1,
[string.char(76)]=1,
[string.char(77)]=1,
[string.char(78)]=1,
[string.char(79)]=1,
[string.char(80)]=1,
[string.char(81)]=1,
[string.char(82)]=1,
[string.char(83)]=1,
[string.char(84)]=1,
[string.char(85)]=1,
[string.char(86)]=1,
[string.char(87)]=1,
[string.char(88)]=1,
[string.char(89)]=1,
[string.char(90)]=1,
[string.char(91)]=1,
[string.char(92)]=1,
[string.char(93)]=1,
[string.char(94)]=1,
[string.char(95)]=1,
[string.char(96)]=1,
[string.char(97)]=1,
[string.char(98)]=1,
[string.char(99)]=1,
[string.char(100)]=1,
[string.char(101)]=1,
[string.char(102)]=1,
[string.char(103)]=1,
[string.char(104)]=1,
[string.char(105)]=1,
[string.char(106)]=1,
[string.char(107)]=1,
[string.char(108)]=1,
[string.char(109)]=1,
[string.char(110)]=1,
[string.char(111)]=1,
[string.char(112)]=1,
[string.char(113)]=1,
[string.char(114)]=1,
[string.char(115)]=1,
[string.char(116)]=1,
[string.char(117)]=1,
[string.char(118)]=1,
[string.char(119)]=1,
[string.char(120)]=1,
[string.char(121)]=1,
[string.char(122)]=1,
[string.char(123)]=1,
[string.char(124)]=1,
[string.char(125)]=1,
[string.char(126)]=1,
[string.char(127)]=1,
[string.char(128)]=1,
[string.char(129)]=1,
[string.char(130)]=1,
[string.char(131)]=1,
[string.char(132)]=1,
[string.char(133)]=1,
[string.char(134)]=1,
[string.char(135)]=1,
[string.char(136)]=1,
[string.char(137)]=1,
[string.char(138)]=1,
[string.char(139)]=1,
[string.char(140)]=1,
[string.char(141)]=1,
[string.char(142)]=1,
[string.char(143)]=1,
[string.char(144)]=1,
[string.char(145)]=1,
[string.char(146)]=1,
[string.char(147)]=1,
[string.char(148)]=1,
[string.char(149)]=1,
[string.char(150)]=1,
[string.char(151)]=1,
[string.char(152)]=1,
[string.char(153)]=1,
[string.char(154)]=1,
[string.char(155)]=1,
[string.char(156)]=1,
[string.char(157)]=1,
[string.char(158)]=1,
[string.char(159)]=1,
[string.char(160)]=1,
[string.char(161)]=1,
[string.char(162)]=1,
[string.char(163)]=1,
[string.char(164)]=1,
[string.char(165)]=1,
[string.char(166)]=1,
[string.char(167)]=1,
[string.char(168)]=1,
[string.char(169)]=1,
[string.char(170)]=1,
[string.char(171)]=1,
[string.char(172)]=1,
[string.char(173)]=1,
[string.char(174)]=1,
[string.char(175)]=1,
[string.char(176)]=1,
[string.char(177)]=1,
[string.char(178)]=1,
[string.char(179)]=1,
[string.char(180)]=1,
[string.char(181)]=1,
[string.char(182)]=1,
[string.char(183)]=1,
[string.char(184)]=1,
[string.char(185)]=1,
[string.char(186)]=1,
[string.char(187)]=1,
[string.char(188)]=1,
[string.char(189)]=1,
[string.char(190)]=1,
[string.char(191)]=1,
[string.char(192)]=1,
[string.char(193)]=1,
[string.char(194)]=1,
[string.char(195)]=1,
[string.char(196)]=1,
[string.char(197)]=1,
[string.char(198)]=1,
[string.char(199)]=1,
[string.char(200)]=1,
[string.char(201)]=1,
[string.char(202)]=1,
[string.char(203)]=1,
[string.char(204)]=1,
[string.char(205)]=1,
[string.char(206)]=1,
[string.char(207)]=1,
[string.char(208)]=1,
[string.char(209)]=1,
[string.char(210)]=1,
[string.char(211)]=1,
[string.char(212)]=1,
[string.char(213)]=1,
[string.char(214)]=1,
[string.char(215)]=1,
[string.char(216)]=1,
[string.char(217)]=1,
[string.char(218)]=1,
[string.char(219)]=1,
[string.char(220)]=1,
[string.char(221)]=1,
[string.char(222)]=1,
[string.char(223)]=1,
[string.char(224)]=1,
[string.char(225)]=1,
[string.char(226)]=1,
[string.char(227)]=1,
[string.char(228)]=1,
[string.char(229)]=1,
[string.char(230)]=1,
[string.char(231)]=1,
[string.char(232)]=1,
[string.char(233)]=1,
[string.char(234)]=1,
[string.char(235)]=1,
[string.char(236)]=1,
[string.char(237)]=1,
[string.char(238)]=1,
[string.char(239)]=1,
[string.char(240)]=1,
[string.char(241)]=1,
[string.char(242)]=1,
[string.char(243)]=1,
[string.char(244)]=1,
[string.char(245)]=1,
[string.char(246)]=1,
[string.char(247)]=1,
[string.char(248)]=1,
[string.char(249)]=1,
[string.char(250)]=1,
[string.char(251)]=1,
[string.char(252)]=1,
[string.char(253)]=1,
[string.char(254)]=1,
[string.char(255)]=1,
["W"]=15,
["X"]=11,
["Y"]=11,
["Z"]=10,
["S"]=11,
["T"]=10,
["U"]=12,
["V"]=11,
["_"]=4,
["a"]=9,
["b"]=10,
["["]=5,
["]"]=5,
["G"]=12,
["H"]=12,
["I"]=4,
["J"]=9,
["C"]=12,
["D"]=12,
["E"]=11,
["F"]=10,
["O"]=12,
["P"]=11,
["Q"]=12,
["R"]=12,
["K"]=12,
["L"]=10,
["M"]=13,
["N"]=12,
[":"]=5,
["A"]=12,
["B"]=12,
[";"]=5,
["/"]=4,
[","]=4,
["-"]=5,
["."]=4,
[" "]=4,
["w"]=12,
["x"]=9,
["y"]=9,
["z"]=8,
["s"]=9,
["t"]=5,
["u"]=10,
["v"]=9,
["{"]=6,
["|"]=4,
["}"]=6,
["g"]=10,
["h"]=10,
["i"]=4,
["j"]=4,
["c"]=9,
["d"]=10,
["e"]=9,
["f"]=5,
["o"]=10,
["p"]=10,
["q"]=10,
["r"]=6,
["k"]=9,
["l"]=4,
["m"]=14,
["n"]=10,
["1"]=1,
["2"]=1,
["3"]=1,
["4"]=1,
["5"]=1,
["6"]=1,
["7"]=1,
["8"]=1,
["9"]=1,
["0"]=1,
["`"]=1,
["~"]=1,
["!"]=1,
["@"]=1,
["#"]=1,
["$"]=1,
["%"]=1,
["^"]=1,
["&"]=1,
["*"]=1,
["("]=1,
[")"]=1,
["+"]=1,
["="]=1,
["<"]=1,
[">"]=1,
[","]=1,
["."]=1,
["?"]=1,
["\\"]=1,
["\""]=1,
["\'"]=1,
}
numCharLength = {
  [1] = 14,
  [2] = 14,
  [3] = 14,
  [4] = 14,
  [5] = 14,
  [6] = 14,
  [7] = 14,
  [8] = 14,
  [9] = 14,
  [11] = 14,
  [12] = 14,
  [14] = 14,
  [15] = 14,
  [16] = 14,
  [17] = 14,
  [18] = 14,
  [19] = 14,
  [20] = 14,
  [21] = 14,
  [22] = 14,
  [23] = 14,
  [24] = 14,
  [25] = 14,
  [26] = 14,
  [27] = 14,
  [28] = 14,
  [29] = 14,
  [32] = 5,
  [33] = 5,
  [34] = 6,
  [35] = 10,
  [36] = 10,
  [37] = 16,
  [39] = 3,
  [40] = 6,
  [41] = 6,
  [42] = 7,
  [43] = 11,
  [44] = 5,
  [45] = 6,
  [46] = 5,
  [47] = 5,
  [48] = 10,
  [49] = 10,
  [50] = 10,
  [51] = 10,
  [52] = 10,
  [53] = 10,
  [54] = 10,
  [55] = 10,
  [56] = 10,
  [57] = 10,
  [58] = 5,
  [59] = 5,
  [60] = 11,
  [61] = 11,
  [62] = 11,
  [63] = 10,
  [64] = 18,
  [65] = 12,
  [66] = 12,
  [67] = 13,
  [68] = 13,
  [69] = 12,
  [70] = 11,
  [71] = 14,
  [72] = 13,
  [73] = 5,
  [74] = 9,
  [75] = 12,
  [76] = 10,
  [77] = 15,
  [78] = 13,
  [79] = 14,
  [80] = 12,
  [81] = 14,
  [82] = 13,
  [83] = 12,
  [84] = 11,
  [85] = 13,
  [86] = 12,
  [87] = 17,
  [88] = 12,
  [89] = 12,
  [90] = 11,
  [91] = 5,
  [92] = 5,
  [93] = 5,
  [94] = 8,
  [95] = 5,
  [96] = 6,
  [97] = 10,
  [98] = 10,
  [99] = 9,
  [100] = 10,
  [101] = 10,
  [102] = 5,
  [103] = 10,
  [104] = 10,
  [105] = 4,
  [106] = 4,
  [107] = 9,
  [108] = 4,
  [109] = 15,
  [110] = 10,
  [111] = 10,
  [112] = 10,
  [113] = 10,
  [114] = 6,
  [115] = 9,
  [116] = 5,
  [117] = 10,
  [118] = 9,
  [119] = 13,
  [120] = 9,
  [121] = 9,
  [122] = 9,
  [123] = 6,
  [124] = 5,
  [125] = 6,
  [126] = 11,
  [127] = 14,
  [128] = 10,
  [129] = 14,
  [130] = 4,
  [131] = 10,
  [132] = 6,
  [133] = 18,
  [134] = 10,
  [135] = 10,
  [136] = 6,
  [137] = 18,
  [138] = 12,
  [139] = 6,
  [140] = 18,
  [141] = 14,
  [142] = 11,
  [143] = 14,
  [144] = 14,
  [145] = 4,
  [146] = 4,
  [147] = 6,
  [148] = 6,
  [149] = 6,
  [150] = 10,
  [151] = 18,
  [152] = 6,
  [153] = 18,
  [154] = 9,
  [155] = 6,
  [156] = 17,
  [157] = 14,
  [158] = 9,
  [159] = 12,
  [160] = 5,
  [161] = 6,
  [162] = 10,
  [163] = 10,
  [164] = 10,
  [165] = 10,
  [166] = 5,
  [167] = 10,
  [168] = 6,
  [169] = 13,
  [170] = 7,
  [171] = 10,
  [172] = 11,
  [173] = 6,
  [174] = 13,
  [175] = 10,
  [176] = 7,
  [177] = 10,
  [178] = 6,
  [179] = 6,
  [180] = 6,
  [181] = 10,
  [182] = 10,
  [183] = 5,
  [184] = 6,
  [185] = 6,
  [186] = 7,
  [187] = 10,
  [188] = 15,
  [189] = 15,
  [190] = 15,
  [191] = 11,
  [192] = 12,
  [193] = 12,
  [194] = 12,
  [195] = 12,
  [196] = 12,
  [197] = 12,
  [198] = 18,
  [199] = 13,
  [200] = 12,
  [201] = 12,
  [202] = 12,
  [203] = 12,
  [204] = 5,
  [205] = 5,
  [206] = 5,
  [207] = 5,
  [208] = 13,
  [209] = 13,
  [210] = 14,
  [211] = 14,
  [212] = 14,
  [213] = 14,
  [214] = 14,
  [215] = 11,
  [216] = 14,
  [217] = 13,
  [218] = 13,
  [219] = 13,
  [220] = 13,
  [221] = 12,
  [222] = 12,
  [223] = 11,
  [224] = 10,
  [225] = 10,
  [226] = 10,
  [227] = 10,
  [228] = 10,
  [229] = 10,
  [230] = 16,
  [231] = 9,
  [232] = 10,
  [233] = 10,
  [234] = 10,
  [235] = 10,
  [236] = 5,
  [237] = 5,
  [238] = 5,
  [239] = 5,
  [240] = 10,
  [241] = 10,
  [242] = 10,
  [243] = 10,
  [244] = 10,
  [245] = 10,
  [246] = 10,
  [247] = 10,
  [248] = 11,
  [249] = 10,
  [250] = 10,
  [251] = 10,
  [252] = 10,
  [253] = 9,
  [254] = 10,
  [255] = 9,--  [0] = 1,
}
function findOne()
    for key,value in pairs(numCharLength) do
        if value == 1 then
            return key
        end
    end
    return 60
end

function printNumCharLength()
    print(civlua.serialize(numCharLength))
end

function cs(charNum,size)
    if charNum > 300 then
        return
    end
    if not size then
        return cs(charNum+1,numCharLength[charNum+1])
    end
    local char = string.char(charNum)
    local window = civ.ui.createDialog()
    local spaceString = "\n^|"
    for i=1,size do
        spaceString = spaceString.." "
    end
    spaceString = spaceString.."|"
    local charString = "\n^|"
    for i=1,numCharLength[32] do
        charString = charString..char
    end
    charString=charString.."|"
    window.title=tostring(charNum)
    window:addText(func.splitlines(spaceString))
    window:addText(func.splitlines(charString))
    window:addOption("Correct",2)
   -- window:addOption("Divide4",9)
    --window:addOption("BIGGER",1)
    window:addOption("Bigger",6)
    window:addOption("bigger",7)
    window:addOption("SMALLER",8)
    window:addOption("Smaller",3)
    window:addOption("box",10)
    window:addOption("Finish",4)
    choice = window:show()
    if choice == 1 then
        return cs(charNum,size+8)
    elseif choice == 6 then
        return cs(charNum,size+3)
    elseif choice == 7 then
        return cs(charNum,size+1)
    elseif choice == 2 then
        numCharLength[charNum]=size
        return cs(charNum+1,numCharLength[charNum+1])
    elseif choice == 3 then
        return cs(charNum,size-1)
    elseif choice == 8 then
        return cs(charNum,size-3)
    elseif choice == 4 then
        return printNumCharLength()
    elseif choice == 5 then
        return cs(charNum,size*14)
    elseif choice == 9 then
        return cs(charNum,size//4)
    elseif choice == 10 then
        return cs(charNum,14)
    end
end


