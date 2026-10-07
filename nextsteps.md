# Next steps

yanaaaomg - design:

!! Uvedené dimenze/velikosti v px jsou **finální** - pokud bude potřebná další manipulace se spritem pro jiné účely, bude se muset upscalovat. pojďme se tomu vyvarovat. drž se rozsahu (např pro uvedenou hodnotu: 32x32 = 1024x1024) - pozor na detaily, aby byly při zmenšení vidět. - Pro soubory v gfx>ui>upgrader udělej 2 verze: .anm2 soubor obsahuje přesné dimenze korespondujícího .png souboru. Pokud budeš chtít některou velikost souboru png s anm2 změnit, napiš do anm2_zmeny.md

* Logo active/pocket itemu (32x32, gfx/items/collectibles/upgrader.png)
* Text "Choose your destiny, bez pozadí (222x12, banner_destiny.png)
* Rámeček chlívečku - normální stav (128x56, slot_frame_empty.png)
* Rámeček chlívečku - vybraný stav (128x56, slot_frame_selected.png), červený (r.i.p wildcard)
* Ikony kvality 0-4 ve stylu EID, 5 ikon vedle sebe v jednom souboru (60x12, každá 12x12, quality_icons.png)
* Kurzor/rámeček kolem vybraného itemu (36x36, item_cursor.png), uprostřed průhledný - item 32x32 je pod ním
* Kolo rulety - rámeček (128x128, wheel_frame.png): vnější obrys, průhledný prstenec mezi poloměrem 46 a 60 px (tam kód kreslí zelenou/červenou výseč šance), uprostřed místo pro text šance
* Kolo rulety - ukazatel (14x14, wheel_pointer.png), míří dolů do prstence a otáčí se kolem středu kola
* Text "Choose an item to bet", bez pozadí (výška 12, šířka podle textu)
* Text "Upgrade" (nadpis obrazovky s kolem), bez pozadí (výška 12, šířka podle textu)
* Texty "You win!" a "You lose...", bez pozadí (výška 12, šířka podle textu)
* (volitelně) Pozadí obrazovek místo zčernání (480x270), např. místnost jako v mockupu
* Preview/thumbnail pro Steam Workshop (1280x720)
* Description header banner (600x150)
* Section headery/dividéry (600x40) - dividér v popisu modu.
* Ikony, bullet-pointy, odkazy, credits.. (64x64)
* Screenshoty ze hry, trailer.. (1920x1080)

Pro výměnu placeholderů: hotový PNG stačí uložit pod stejným názvem do `resources/gfx/ui/upgrader/` (slot_frame_empty.png, slot_frame_selected.png, quality_icons.png, item_cursor.png, banner_destiny.png, wheel_frame.png, wheel_pointer.png). Pokud se změní rozměr, je potřeba upravit i odpovídající .anm2 soubor. Texty bez souboru se zatím píšou herním fontem, barevná výseč kola se skládá z obdélníků (white.png) - po dodání grafiky se napojí v kódu.
