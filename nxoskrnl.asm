;Doors NX kernel Made by David Badiei
use32
org 30000h

apiVector:
jmp sys_main
jmp sys_plotpixel
jmp sys_setupScreen
jmp sys_drawbox
jmp sys_printString
jmp sys_getpixel
jmp sys_dispsprite
jmp sys_singleLineEntry
jmp sys_loadfile
buttonornot db 0
entrysuccess db 0
loadsuccess db 0
state db 0
X dw 0
Y dw 0
Color dw 0
mouseX dw 0
mouseY dw 0
jmp sys_getoldlocation
ioornot db 0
jmp sys_term_setupScreen
jmp sys_term_redrawbuffer
jmp sys_term_movecursor
jmp sys_term_printChar
jmp sys_term_getcursor
keydata db 0
jmp sys_term_getkey
jmp sys_term_printString
jmp sys_term_getString
jmp sys_printChar
jmp sys_getrootdirectory
jmp sys_deletefile
jmp sys_renamefile
jmp sys_charforward
jmp sys_charbackward
jmp sys_createfile
jmp sys_writefile
jmp sys_makefnfat12
jmp sys_windowloop
jmp sys_nobgtasks
mouseaddress dd 0
keybaddress dd 0
bgtaskaddress dd 0
keyormouse db 0
jmp sys_mouseemuenable
jmp sys_mouseemudisable
jmp sys_overwrite
jmp sys_genrandnumber
jmp sys_returnnumberofdrives
jmp sys_displayfatfn
jmp sys_numoffatfn
numOfSectors dd 0
directoryCluster dd 19
jmp sys_reloadfolder
saveataddress db 0
jmp sys_createfolder

sys_main:
mov dword [vidmem],eax

mov byte [keyormouse],dl

mov al,byte [201d2h+3]
mov byte [bootdev],al
mov ax,word [201c9h+3]
mov word [SectorsPerTrack],ax
mov ax,word [201cbh+3]
mov word [Sides],ax
mov al,byte [201fch]
mov byte [picmaster],al
mov al,byte [201fdh]
mov byte [picslave],al
mov al,byte [201feh]
mov byte [pciusable],al
mov al,byte [201ffh]
mov byte [floppyavail],al

sgdt [gdtloc]
sidt [idtloc]

mov edi,idt 
mov cx,45
idtloop:
mov ebx,unhandled
mov [edi],bx
shr ebx,16
mov [edi+6],bx
add edi,8
loop idtloop

mov ebx,pithandler
mov [idt31+8],bx
shr ebx,16
mov [idt31+14],bx

mov ebx,kbhandler
mov [idt32+8],bx
shr ebx,16
mov [idt32+14],bx

mov ebx,mousehandler
mov [idt31+104],bx
shr ebx,16
mov [idt31+110],bx

mov ebx,fdchandler
mov [idt31+56],bx
shr ebx,16
mov [idt31+62],bx

call pic32
lidt [idtptr]
cmp byte [keyormouse],0
je skipmousedrv
call initmouse
skipmousedrv:
call initKeyboard
mov ebx,100
call initPIT
mov ecx,32
readyforirq:
mov al,0x20
out 0x20,al
out 0xa0,al
loop readyforirq
cmp byte [keyormouse],1
jne skippicenable
mov byte [picslave],0xef
jmp skippicdisable
skippicenable:
mov byte [picslave],0xff
skippicdisable:
sti

mov al,0xb8
out 0x21,al
mov al,byte [picslave]
out 0xa1,al

call fdcdetect

call patadetect
cmp byte [pciusable],1
je skipahci
cli
call ahcidetect
sti
skipahci:

cmp byte [pciusable],1
je skipusb
call usbdetect
skipusb:

mov esi,titleString
call sys_setupScreen

call drawWidgets

mov word [mouseX],320
mov word [mouseY],240
mov word [Color],0
call drawcursor

mov eax,dword [tdlocation]
add eax,4
mov dword [eax],0
mov ebx,100
call initPIT
mov byte [usbhidenabled],1
mov byte [autoornot],1
mov esi,autoFN
mov edi,program
jmp doneautoex ;LOADFILE currently crashes OS
call sys_loadfile
cmp byte [loadsuccess],1
je doneautoex
mov esi,program
mov edi,autoFN
mov ecx,13
repe movsb
mov esi,autoFN
mov edi,program
call sys_loadfile
jmp otherprogramcontinue
doneautoex:

osstart:
mov dword [mouseaddress],lbuttonclick
mov dword [keybaddress],sys_windowloop
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop

jmp $

titleString db 'Doors NX 2.0 BETA Copyright (C) 2022 David Badiei',0
table db 0x01,"1234567890-=",0X0E,0x0F,'qwertyuiop[]',0x1C,0,"asdfghjkl;'",0,0,0,"zxcvbnm,./",0,0,0," ",0
tableCaps db 0x01,"1234567890-=",0X0E,0x0F,'QWERTYUIOP[]',0x1C,0,"ASDFGHJKL;'",0,0,0,"ZXCVBNM,./",0,0,0," ",0
tableShift db 0x01,"!@#$%^&*()_+",0X0E,0x0F,'QWERTYUIOP{}',0x1C,0,"ASDFGHJKL:",0x22,0,0,0,"ZXCVBNM<>?",0,0,0," ",0
msoldloc times 8 dw 0xffff
driveletter times 26 dw 0xffff
usbcontrollers times 55 db 0
usbcontrollercounter db 0
prevmouseX dw 320
prevmouseY dw 240
prevColor dw 0
bootdev db 0
tableNum db '789-456+1230.',0
testbyte2 db 0
vidmem dd 0
autoornot db 0
mouseemutoggle db 0
drivecounter db 0
pciusable db 0
floppyavail db 0
usbhidenabled db 0

fontlocation:
incbin 'fontdata.bin'

sys_plotpixel:
pusha
movzx ecx,word [Color]
movzx eax,word [X]
movzx ebx,word [Y]
imul eax,2
imul ebx,1280
add eax,ebx
mov edi,dword [vidmem]
add edi,eax
mov ax,cx
stosw
popa
ret

sys_getpixel:
push ebx
movzx eax,word [X]
movzx ebx,word [Y]
imul eax,2
imul ebx,1280
add eax,ebx
mov esi,dword [vidmem]
add esi,eax
pop ebx
lodsw
ret

sys_drawbox:
pusha
push word [X]
push word [Y]
push ax
mov al,0xba
out 0x21,al
mov al,0xff
out 0xa1,al
pop ax
mov word [X],ax
mov word [Y],bx
cmp byte [buttonornot],0
jne drawbutton1
mov word [Color],0xBDF7
drawbutton1:
call sys_plotpixel
inc word [X]
cmp word [X],cx
jne drawbutton1
mov word [X],ax
inc word [Y]
cmp word [Y],dx
jne drawbutton1
push ax
mov al,0xb8
out 0x21,al
mov al,byte [picslave]
out 0xa1,al
pop ax
pop word [Y]
pop word [X]
popa
ret

sys_setupScreen:
cli
push ax
mov al,0xba
out 0x21,al
mov al,0xff
out 0xa1,al
pop ax
;Draw background
mov ax,0xffff
mov edi,dword [vidmem]
mov ecx,0xfffff
repe stosw
;Draw titlebar
mov ax,0x0057
mov edi,dword [vidmem]
mov cx,8320
repe stosw
;Write title string
mov word [X],1
mov word [Y],3
mov word [Color],0xffff
call sys_printString
;Draw Close Button
mov byte [buttonornot],1
mov ax,621
mov bx,2
mov cx,636
mov dx,11
mov word [Color],0xF800
call sys_drawbox
mov byte [buttonornot],0
mov word [X],626
mov word [Y],3
xor dh,dh
mov dl,'X'
mov word [Color],0xffff
call sys_printChar
push ax
mov al,0xb8
out 0x21,al
mov al,byte [picslave]
out 0xa1,al
pop ax
sti
ret

sys_printString:
push ax
mov al,0xba
out 0x21,al
mov al,0xff
out 0xa1,al
pop ax
xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx
push word [X]
loopprint:
cmp word [Y],480
jg donestr
lodsb
mov dl,al
test al,al
jz donestr
cmp al,0ah
je newline
cmp word [X],635
jge endofline
cmp byte [cutter],1
je continueprint
call sys_printChar
continueprint:
jmp loopprint
newline:
mov byte [cutter],0
pop word [X]
add word [Y],8
push word [X]
jmp continueprint
donestr:
pop word [X]
push ax
mov al,0xb8
out 0x21,al
mov al,byte [picslave]
out 0xa1,al
pop ax
ret
endofline:
mov byte [cutter],1
jmp loopprint
cutter db 0

sys_charforward:
pusha
push esi
findendoftextblock:
lodsb
test al,al
jz foundendoftext
jmp findendoftextblock
foundendoftext:
pop edi
loopforward:
mov al,byte [esi]
mov byte [esi+1],al
dec esi
cmp esi,edi
jl doneforward
jmp loopforward
doneforward:
inc dword [ebx]
inc dword [ecx]
popa
ret

sys_charbackward:
pusha
dec esi
loopbackward:
mov al,byte [esi+1]
mov byte [esi],al
inc esi
cmp byte [esi],0
jne loopbackward
dec dword [ebx]
dec dword [ecx]
popa
ret

sys_singleLineEntry:
mov byte [state],9
mov byte [entrysuccess],0
mov dword [edival],edi
pusha
mov byte [maxval],al
push esi
mov ax,150
mov bx,200
mov cx,500
mov dx,268
call sys_drawbox
mov byte [buttonornot],1
mov ax,175
mov bx,220
mov cx,475
mov dx,232
mov word [Color],0xffff
call sys_drawbox
mov ax,284
mov bx,240
mov cx,354
mov dx,260
mov word [Color],0xFFFF
call sys_drawbox
mov byte [buttonornot],0
mov word [X],301
mov word [Y],245
mov word [Color],0
mov esi,cancel
call sys_printString
pop esi
mov word [X],152
mov word [Y],202
mov word [Color],0
call sys_printString
call sys_getoldlocation
cmp byte [otherprog],1
je doneentry
mov dword [mouseaddress],lbuttonclick4
mov dword [keybaddress],getinput
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop
doneentry:
popa
mov word [counterdel],0
mov word [lineX],175
mov word [lineY],222
mov byte [otherprog],0
ret

sys_getrootdirectory:
pushad
mov eax,19
mov edi,disk_buffer
mov ecx,14
mov dx,0
mov byte [selecteddrive],0
call readwritesectors
popad
ret

sys_term_setupScreen:
mov esi,filename
call sys_setupScreen
mov ax,0
mov bx,0
call sys_term_movecursor
call sys_getoldlocation
mov ecx,5985
mov edi,terminalbuffer
mov al,0
repe stosb
ret

sys_term_redrawbuffer:
mov esi,terminalbuffer
mov word [X],0
mov word [Y],14
call sys_printString
ret

sys_term_movecursor:
pusha
and ecx,0xffff
and edx,0xffff
mov byte [termX],ah
mov byte [termY],bh
mov word [Color],0xffff
call drawcaret
mov byte [termX],al
mov byte [termY],bl
mov word [Color],0
call drawcaret
popa
ret

sys_term_getcursor:
mov al,byte [termX]
mov bl,byte [termY]
ret

sys_term_printChar:
pusha
push ax
cmp al,0x0d
je termnewline1
cmp al,0
je donemove
cmp byte [termX],105
je termnewline2
continuetoprint:
movzx eax,byte [termX]
mov dx,6
mul dx
inc ax
mov word [X],ax
movzx eax,byte [termY]
mov dx,8
mul dx
add ax,15
mov word [Y],ax
push word [X]
push word [Y]
pusha
mov byte [buttonornot],1
mov ax,word [X]
mov bx,word [Y]
mov cx,ax
add cx,5
mov dx,bx
add dx,7
mov word [Color],0xffff
call sys_drawbox
mov byte [buttonornot],0
popa
pop word [Y]
pop word [X]
pop ax
movzx dx,al
push ax
mov word [Color],0
call sys_printChar
mov cl,1
continuetomove:
mov ah,byte [termX]
inc byte [termX]
mov al,byte [termX]
mov bh,byte [termY]
mov bl,byte [termY]
call sys_term_movecursor
pop ax
inc word [termpos]
mov edi,terminalbuffer
add di,word [termpos]
mov byte [edi],al
skipstosb:
popa
ret
termnewline1:
mov cl,0
cmp byte [termY],57
je scrolltermdown
continuenewline1:
mov word [Color],0xffff
call drawcaret
mov byte [termX],-1
inc byte [termY]
pop ax
mov al,0x0a
push ax
mov cl,0
jmp continuetomove
termnewline2:
mov word [Color],0xffff
call drawcaret
mov byte [termX],0
inc byte [termY]
pop ax
mov al,0x0a
push ax
jmp continuetoprint
donemove:
pop ax
popa
ret
scrolltermdown:
pusha
mov word [Color],0xffff
push edi
mov edi,dword [vidmem]
add edi,19200
mov ecx,297600
mov ax,0xffff
repe stosw
pop edi
mov esi,terminalbuffer
inc esi
mov word [X],1
mov word [Y],15
call sys_printString
mov esi,terminalbuffer
mov cx,0
inc esi
findnewline:
lodsb
inc cx
cmp al,10
jne findnewline
sub word [termpos],cx
movzx ecx,word [termpos]
mov edi,terminalbuffer
inc edi
repe movsb
mov al,0
stosb
stosb
mov esi,terminalbuffer
inc esi
skipclear:
mov word [Color],0
mov word [X],1
mov word [Y],15
call sys_printString
push esi
mov byte [buttonornot],1
mov ax,0
mov bx,471
mov cx,640
mov dx,480
mov word [Color],0xffff
call sys_drawbox
mov byte [buttonornot],0
call sys_term_getcursor
mov ah,al
mov bh,bl
mov bl,56
call sys_term_movecursor
pop esi
push edi
mov edi,esi
mov al,0
stosb
pop edi
popa
cmp cl,0
je continuenewline1

terminalbuffer equ 10000h
termX db 0
termY db 0
termpos dw 0

sys_term_getkey:
hlt
cmp byte [state],9
je lbuttonclick6
cmp byte [ioornot],1
je sys_term_getkey
ret
jmp sys_term_getkey

lbuttonclick6:
cmp word [mouseX],619
jle s61
cmp word [mouseX],636
jg s61
cmp word [mouseY],1
jle s61
cmp word [mouseY],13
jg s61
mov esp,0xffc
ret
s61:
jmp sys_term_getkey

sys_term_printString:
pusha
loop1:
lodsb
test al,al
jz donetermprintstring
call sys_term_printChar
jmp loop1
donetermprintstring:
popa
ret

sys_term_getString:
pusha
mov byte [loc],0
mov byte [maxstrlength],al
getStringloop:
call sys_term_getkey
mov al,byte [keydata]
cmp al,0x0d
je enterpress1
cmp al,0x08
je backspace2
cmp al,0
je getStringloop
mov bl,byte [maxstrlength]
cmp byte [loc],bl
je getStringloop
stosb
call sys_term_printChar
inc byte [loc]
jmp getStringloop
enterpress1:
call sys_term_printChar
mov byte [loc],0
popa
ret
backspace2:
cmp byte [loc],0
je getStringloop
call sys_term_getcursor
mov cl,0
cmp al,0
jle reducey
continuebackspace:
call sys_term_getcursor
mov ah,al
dec al
mov bh,bl
call sys_term_movecursor
mov al,' '
call sys_term_printChar
call sys_term_getcursor
mov cl,1
cmp al,0
je reducey
continuebackspace2:
call sys_term_getcursor
mov ah,al
dec al
mov bh,bl
call sys_term_movecursor
dec edi
mov byte [edi],0
dec byte [loc]
pushad
dec word [termpos]
mov edi,terminalbuffer
add di,word [termpos]
mov byte [edi],0
dec word [termpos]
popad
jmp getStringloop
reducey:
mov bh,bl
dec bl
mov ah,al
mov al,105
call sys_term_movecursor
cmp cl,0
je continuebackspace
cmp cl,1
je continuebackspace2
maxstrlength db 0
loc db 0

drawcaret:
pusha
movzx eax,byte [termX]
mov dx,6
mul dx
mov word [X],ax
movzx eax,byte [termY]
mov dx,8
mul dx
add ax,15
mov word [Y],ax
mov cx,7
caretLoop:
call sys_plotpixel
inc word [Y]
loop caretLoop
popa
ret

createsfnfromlfn:
pushad
mov edi,fat12fn
call skipspace
call skipspace
startwithnumberofsfn:
mov al,'~'
stosb
mov byte [fat12fn+3],0
push esi
mov esi,fat12fn
call makeCaps
mov ax,word [fat12fn]
mov esi,disk_buffer
mov ecx,dword [folderSize]
shr ecx,5
mov bx,0
loopfindnumofsfns:
cmp word [esi],ax
jne skipfoundsimilarone
inc bx
skipfoundsimilarone:
add esi,32
loop loopfindnumofsfns
pop esi
call savefourdigitnum
mov ebx,esi
loopfindend:
lodsb
cmp al,0
je loopfinddot
jmp loopfindend
loopfinddot:
mov al,byte [esi]
cmp al,'.'
je founddot
cmp esi,ebx
jle didntfinddot
dec esi
jmp loopfinddot
didntfinddot:
mov al,' '
stosb
stosb
stosb
founddot:
inc esi
mov ecx,3
repe movsb
sub edi,3
mov esi,edi
call makeCaps
call generatefatchecksum
popad
ret

generatefatchecksum:
mov esi,fat12fn
mov ecx,11
mov al,0
loopcalculatechecksum:
mov bl,al
and al,1
shl al,7
and bl,0xfe
shr bl,1
or bl,al
lodsb
add bl,al
mov al,bl
mov byte [fatsfnchecksum],bl
loop loopcalculatechecksum
ret
fatsfnchecksum db 0

savefourdigitnum:
mov ax,bx
mov cx,10000
loopsavedigit:
mov edx,0
div cx
add al,30h
stosb
mov ax,cx
mov edx,0
mov cx,10
div cx
mov cx,ax
mov ax,bx
cmp cx,0
jne loopsavedigit
ret

skipspace:
lodsb
cmp al,' '
je skipspace
cmp al,'.'
je hitendoffilename
stosb
ret
hitendoffilename:
add esp,4
jmp startwithnumberofsfn

filllfn:
pusha
pusha
mov ecx,32
mov al,0
repe stosb
popa
mov dl,bl
cmp cl,bl
jne skipterminatebit
or dl,40h
skipterminatebit:
mov byte [edi],dl
inc edi
mov dl,0
mov ecx,5
call filloutlfnchars
mov byte [edi],0x0f
add edi,2
mov al,byte [fatsfnchecksum]
stosb
mov ecx,6
call filloutlfnchars
add edi,2
mov ecx,2
call filloutlfnchars
popa
add esi,13
ret

filloutlfnchars:
lodsb
cmp al,0
jne skipnullvalue
cmp dl,1
je endoffilename
mov ax,0
stosw
mov dl,1
dec ecx
cmp ecx,0
je skipoutputnull
endoffilename:
mov ax,0xffff
stosw
loop endoffilename
skipoutputnull:
dec esi
ret
skipnullvalue:
mov ah,0
stosw
loop filloutlfnchars
ret

getinput:
push ax
mov ax,word [X]
mov bx,word [Y]
mov cx,word [lineX]
mov dx,word [lineY]
mov word [X],cx
mov word [Y],dx
pop ax
cmp byte [keydata],0
je windowloop
cmp al,0dh
je enterpress
cmp al,08h
je backspace1
cmp word [lineX],469
je shiftsinglelineright
continueaftershiftright:
movzx bx,byte [maxval]
cmp word [counterdel],bx
je windowloop
add word [X],6
add word [lineX],6
mov byte [bslast],0	
drawchar:
push dx
push di
continueinput:
add di,word [counterdel]
mov ax, word [keydata]
stosb
movzx dx,byte [keydata]
call sys_printChar
inc word [counterdel]
pop di
pop dx
mov cx,word [X]
sub cx,6
mov word [lineX],cx
mov word [X],ax
mov word [Y],bx
jmp windowloop
backspace1:
cmp dword [edival],edi
jne shiftsinglelineleft
continueaftershiftleft:
cmp word [counterdel],0
je resetlinextozero
pusha
mov byte [buttonornot],1
mov ax,cx
mov bx,word [Y]
add cx,5
add dx,7
mov word [Color],0ffffh
call sys_drawbox
mov byte [buttonornot],0
popa
push di
add di,word [counterdel]
mov byte [edi],0
pop di
mov word [Color],0
dec word [counterdel]
sub word [lineX],6
mov byte [bslast],1
jmp windowloop
enterpress:
jmp doneentry
lineX dw 175
lineY dw 222
counterdel dw 0
bslast db 0
maxval db 0
shiftsinglelineleft:
pushad
dec word [counterdel]
push di
add di,word [counterdel]
mov byte [edi],0
pop di
inc word [counterdel]
push word [X]
push word [Y]
mov esi,dword [edival]
mov word [X],181
mov word [Y],222
mov word [Color],0xffff
call sys_printString
dec dword [edival]
mov esi,dword [edival]
mov word [X],181
mov word [Y],222
mov word [Color],0
call sys_printString
pop word [Y]
pop word [X]
mov word [lineX],469
mov word [X],469
popad
mov cx,word [X]
jmp continueaftershiftleft
shiftsinglelineright:
pushad
push word [X]
push word [Y]
mov esi,dword [edival]
mov word [X],181
mov word [Y],222
mov word [Color],0xffff
call sys_printString
inc dword [edival]
mov esi,dword [edival]
mov word [X],181
mov word [Y],222
mov word [Color],0
call sys_printString
pop word [Y]
pop word [X]
sub word [X],6
sub word [lineX],6
popad
jmp continueaftershiftright
resetlinextozero:
push edi
mov edi,dword [edival]
mov byte [edi],0
pop edi
mov word [lineX],175
jmp windowloop

lbuttonclick4:
cmp word [mouseX],283
jle s41
cmp word [mouseX],354
jg s41
cmp word [mouseY],239
jle s41
cmp word [mouseY],260
jg s41
cli
mov word [counterdel],0
mov word [lineX],175
mov word [lineY],222
mov esi,titleString
call sys_setupScreen
call drawWidgets
call sys_getoldlocation
sti
mov byte [entrysuccess],1
jmp doneentry
s41:
jmp windowloop

sys_printChar:
pusha
cmp dx,0
je exitchar
mov ax,7
mul dx
mov bx,ax
mov cx,0
printLine:
cmp cx,7
je discharend
inc cx
mov esi,fontlocation
add esi,ebx
lodsb
inc bx
push ax
and al,128
cmp al,128
jne nxtprint
call sys_plotpixel
nxtprint:
pop ax
inc word [X]
push ax
and al,64
cmp al,64
jne nxtprintB
call sys_plotpixel
nxtprintB:
pop ax
inc word [X]
push ax
and al,32
cmp al,32
jne nxtprintC
call sys_plotpixel
nxtprintC:
pop ax
inc word [X]
push ax
and al,16
cmp al,16
jne nxtprintD
call sys_plotpixel
nxtprintD:
pop ax
inc word [X]
push ax
and al,8
cmp al,8
jne dislineend
call sys_plotpixel
dislineend:
pop ax
inc word [Y]
sub word [X],4
jmp printLine
discharend:
popa
sub word [Y],7
add word [X],6
ret
exitchar:
popa
sub word [Y],7
ret

sys_windowloop:
windowloop:
mov byte [keydata],0
call dword [bgtaskaddress]
hlt
cmp byte [state],9
je lbuttonloopclick
cmp byte [ioornot],1
je windowloop
cmp byte [keyormouse],0
je mouseemu
mov al,byte [keydata]
jmp dword [keybaddress]
jmp windowloop
lbuttonloopclick:
cmp byte [keyormouse],0
je resetstate
and byte [state],0xfe
jmp dword [mouseaddress]
resetstate:
mov byte [state],0
jmp windowloop

sys_mouseemuenable:
mov byte [mouseemutoggle],0
ret

sys_mouseemudisable:
mov byte [mouseemutoggle],1
ret

mouseemu:
cmp byte [mouseemutoggle],1
je donemouseemu
cmp byte [keydata],1
je moveup
cmp byte [keydata],2
je movedown
cmp byte [keydata],3
je moveleft
cmp byte [keydata],4
je moveright
cmp byte [keydata],6
je setstate
donemouseemu:
jmp dword [keybaddress]
moveup:
cmp word [mouseY],4
jle windowloop
call printoldlocation
sub word [mouseY],7
call sys_getoldlocation
mov word [Color],0
call drawcursor
jmp windowloop
movedown:
cmp word [mouseY],476
jge windowloop
call printoldlocation
add word [mouseY],7
call sys_getoldlocation
mov word [Color],0
call drawcursor
jmp windowloop
moveleft:
cmp word [mouseX],4
jle windowloop
call printoldlocation
sub word [mouseX],7
call sys_getoldlocation
mov word [Color],0
call drawcursor
jmp windowloop
moveright:
cmp word [mouseX],636
jge windowloop
call printoldlocation
add word [mouseX],7
call sys_getoldlocation
mov word [Color],0
call drawcursor
jmp windowloop
setstate:
jmp dword [mouseaddress]

sys_nobgtasks:
ret

kbhandler:
;cli
mov byte [ioornot],0
pushad
loop:
in al,0x64
and al,0001b
jz invalid
cmp byte [shiftornot],1
je shiftpress
in al,60h
cmp al,0x3b
je f1pressed
cmp al,0x3c
je f2pressed
cmp al,0x48
je uparrow
cmp al,0x50
je downarrow
cmp al,0x4b
je leftarrow
cmp al,0x4d
je rightarrow
cmp al,0x53
je deletepressed
cmp al,0x0e
je backspacepressed
cmp al,0x1c
je enterpressed
cmp al,0x2a
je shiftpress
cmp al,0x36
je shiftpress
cmp al,0x37
je numshiftpressed
cmp al,0x47
jge numpadpressed
cmp al,0x29
je tickpress
cmp al,0x2b
je backslashpress
goback:
test al,80h
jnz loop
cmp al,0x3a
je capsLockpress
startforusb:
and al,0x7f
cmp byte [capsornot],0
jne caps
mov esi,table
jmp continueon
caps:
mov esi,tableCaps
continueon:
dec al
xor ah,ah
add si,ax
mov al,byte [esi]
mov byte [keydata],al
cmp byte [kbhctype],1
je donekbhandleuhci
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
sti
iret
shiftpress:
loop2:
mov byte [shiftornot],1
in al,64h
test al,1
jz invalid
in al,60h
mov byte [ioornot],0
cmp al,0xaa
je shiftreleased
cmp al,0xb6
je shiftreleased
cmp al,0x29
je tickpress
cmp al,0x2b
je backslashpress
test al,80h
jnz loop2
and al,0x7f
mov esi,tableShift
jmp continueon
shiftreleased:
mov byte [shiftornot],0
jmp loop
backslashpress:
cmp byte [shiftornot],0
jne shiftbackslash
mov byte [keydata],0x5c
jmp setkey
shiftbackslash:
mov byte [keydata],'|'
jmp setkey
tickpress:
cmp byte [shiftornot],0
jne shifttick
mov byte [keydata],0x60
jmp setkey
shifttick:
mov byte [keydata],'~'
setkey:
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
sti
iret
numpadpressed:
cmp al,0x57
jg goback
sub al,0x47
mov esi,tableNum
xor ah,ah
add si,ax
mov al,byte [esi]
mov byte [keydata],al
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
sti
iret
numshiftpressed:
mov byte [keydata],'*'
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
sti
iret
backspacepressed:
mov byte [keydata],0x08
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
sti
iret
enterpressed:
mov byte [keydata],0x0d
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
sti
iret
capsLockpress:
cmp byte [capsornot],1
je disableCaps
enableCaps:
mov byte [capsornot],1
or  byte [ledstate],0000000100b
mov al,byte [ledstate]
call setLEDs
mov byte [keydata],0
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
sti
iret
disableCaps:
mov byte [capsornot],0
and byte [ledstate],0000000000b
mov al,byte [ledstate]
call setLEDs
mov byte [keydata],0
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
sti
iret
setLEDs:
mov al,0xed
out 0x60,al
call waitforack
mov al,byte [ledstate]
out 0x60,al
call waitforack
ret
waitforack:
in al,0x64
test al,0x02
jne waitforack
ret
invalid:
mov byte [keydata],0
mov al,0x20
out 0x20,al
popad
sti
iret
arrowkeys:
in al,60h
uparrow:
cmp al,0x48
jne downarrow
mov byte [keydata],1
jmp donearrow
downarrow:
cmp al,0x50
jne leftarrow
mov byte [keydata],2
jmp donearrow
leftarrow:
cmp al,0x4b
jne rightarrow
mov byte [keydata],3
jmp donearrow
rightarrow:
cmp al,0x4d
jne invalid
mov byte [keydata],4
donearrow:
popad
mov al,0x20
out 0x20,al
mov al,byte [keydata]
mov byte [ioornot],0
sti
iret
deletepressed:
mov byte [keydata],5
jmp donearrow
f1pressed:
mov byte [keydata],6
jmp donearrow
f2pressed:
mov byte [keydata],7
jmp donearrow
capsornot db 0
ledstate db 0
shiftornot db 0
initmouse:
pushad
mov bl,0xa8
call kbcmd
call kbread
mov bl,0x20
call kbcmd
call kbread
or al,3
mov byte [ccbyte],al
mov bl,0x60
push eax
call kbcmd
pop eax
call kbwrite
mov bl,0xd4
call kbcmd
mov al,0xf4
call kbwrite
call kbread
donemouseinit:
popad
ret

kbread:
push ecx
push edx
mov ecx,0xffff
krloop:
in al,0x64
test al,1
jnz krready
loop krloop
mov ah,1
jmp krexit
krready:
push ecx
mov ecx,32
krdelay:
loop krdelay
pop ecx
in al,0x60
xor ah,ah
krexit:
pop edx
pop ecx
ret

kbwrite:
push ecx
push edx
mov dl,al
mov ecx,0xffff
kwloop1:
in al,0x64
test al,0x20
jz kwok1
loop kwloop1
mov ah,1
jmp kwexit
kwok1:
in al,0x60
mov ecx,0xffff
kwloop:
in al,0x64
test al,2
jz kwok
loop kwloop
mov ah,1
jmp kwexit
kwok:
mov al,dl
out 0x60,al
mov ecx,0xffff
kwloop3:
in al,0x64
test al,2
jz kwok3
loop kwloop3
mov ah,1
jmp kwexit
kwok3:
mov ah,8
kwloop4:
mov ecx,0xffff
kwloop5:
in al,0x64
test al,1
jnz kwok4
loop kwloop5
dec ah
jnz kwloop4
kwok4:
xor ah,ah
kwexit:
pop edx
pop ecx
ret

kbcmd:
mov cx,0xffff
cwait:
in al,0x64
test al,2
jz csend
loop cwait
jmp cerror
csend:
mov al,bl
out 0x64,al
mov ecx,0xffff
caccept:
in al,0x64
test al,2
jz cok
loop caccept
cerror:
mov ah,1
jmp cexit
cok:
xor ah,ah
cexit:
ret

picallowirq:
push eax
push ebx
push ecx
mov ecx,eax
mov ebx,1
inc ecx
cmp ecx,0x8
jg pic2
pic1:
shl ebx,1
loop pic1
shr ebx,1
not ebx
in al,0x21
and al,bl
out 0x21,al
jmp endallowirq
pic2:
sub ecx,0x8
picloop2:
shl ebx,1
loop picloop2
shr ebx,1
not ebx
in al,0xa1
and al,bl
out 0xa1,al
jmp endallowirq
endallowirq:
pop ecx
pop ebx
pop eax
ret

picdelay:
jmp donepicdelay
donepicdelay:
ret

idt:
%rep 0x1f
dw 0
dw 0x08
db 0
db 8Eh
dw 0
%endrep
idt31:
dw 0
dw 0x08
db 0
db 8Eh
dw 0
idt32:
dw 0
dw 0x08
db 0
db 8Eh
dw 0
%rep 14
dw 0
dw 0x08
db 0
db 8Eh
dw 0
%endrep
idtend:
idtptr:
dw idtend-idt-1
dd idt

pithandler:
;cli
pusha
push eax
push ebx
push ecx
mov eax,[irq0fractions]
mov ebx,[irq0ms]
add [systimerfractions],eax
adc [systimerms],ebx
add dword [counterms],1
cmp byte [skipioornot],1
je skipthisioornot
mov byte [ioornot],1
skipthisioornot:
cmp byte [usbhidenabled],1
jne skipusbhid
cmp byte [usbmousecounter],3
jl skipusbms
call usbmshandler
mov byte [usbmousecounter],0
skipusbms:
inc byte [usbmousecounter]
cmp byte [usbkeyboardcounter],10
jl skipusbkb
call usbkbhandler
mov byte [usbkeyboardcounter],0
skipusbkb:
inc byte [usbkeyboardcounter]
skipusbhid:
push ax
mov al,byte [uhcihidcurrentvals]
cmp byte [uhcihidvals],al
jne skipresetuhcihidvals
mov byte [uhcihidcurrentvals],0
skipresetuhcihidvals:
pop ax
mov al,0x20
out 0x20,al
pop ecx
pop ebx
pop eax
popa
;sti
iret
usbkeyboardcounter db 30
usbmousecounter db 0
skipioornot db 0

irq0fractions dd 0
irq0ms dd 0
systimerfractions dd 0
systimerms dd 0
pitreloadvalue dw 0
irq0freq dd 0
counterms dd 0

mousehandler:
pushad
push eax
mov byte [ioornot],1
cmp byte [mouseStep],0
je statePacket
cmp byte [mouseStep],1
je xmovPacket
cmp byte [mouseStep],2
je ymovPacket
statePacket:
in al,0x64
and al,0001b
jz donemouse
call printoldlocation
in al,0x60
test al,0xc0
jnz donemouse
mov byte [state],al
inc byte [mouseStep]
jmp donemouse
xmovPacket:
in al,0x64
and al,0001b
jz donemouse
in al,0x60
mov byte [xmovement],al
inc byte [mouseStep]
jmp donemouse
ymovPacket:
in al,0x64
and al,0001b
jz donemouse
in al,0x60
mov byte [ymovement],al
mov byte [mouseStep],0
endmouse:
mov al,byte [state]
cmp byte [xmovement],0
je checky
movzx bx,byte [xmovement]
test al,00010000b
jz rightmovement
xor bx,0xff
sub word [mouseX],bx
jmp checky	
rightmovement:
add word [mouseX],bx
checky:
cmp byte [ymovement],0
je donemovement
mov al,byte [state]
movzx bx,byte [ymovement]
neg bx
test al,00100000b
jz downmovement
xor bx,0xff
sub word [mouseY],bx
jmp donemovement
downmovement:
add word [mouseY],bx
donemovement:
cmp word [mouseX],636
jge stopmovement1
cmp word [mouseX],0
jle stopmovement2
cmp word [mouseY],476
jge stopmovement3
cmp word [mouseY],0
jle stopmovement4
continuemouse:
cmp byte [state],9
je donemouse
call sys_getoldlocation
cmp byte [state],0
je donemouse
mov word [Color],0
call drawcursor
donemouse:
mov al,0x20
out 0x20,al
out 0xa0,al
pop eax
popad
iret
mouseStep db 0
xmovement db 0
ymovement db 0
stopmovement1:
mov word [mouseX],636
jmp continuemouse
stopmovement2:
mov word [mouseX],0
jmp continuemouse
stopmovement3:
mov word [mouseY],476
jmp continuemouse
stopmovement4:
mov word [mouseY],0
jmp continuemouse

inttostr:
pushad
mov ecx,0
mov ebx,10
pushit:
xor edx,edx
div ebx
inc ecx
push edx
test eax,eax
jnz pushit
popit:
pop edx
add dl,30h
pusha
mov dh,0
call sys_printChar
popa
inc edi
dec ecx
jnz popit
popad
ret

initPIT:
pushad
mov eax,0x10000
cmp ebx,18
jbe gotReloadValue
mov eax,1
cmp ebx,1193181
jae gotReloadValue
mov eax,3579545
mov edx,0
div ebx
cmp edx,3579545 / 2
jb l1
inc eax
l1:
mov ebx,3
mov edx,0
div ebx
cmp edx,3 / 2
jb l2
inc eax
l2:
gotReloadValue:
push eax
mov [pitreloadvalue],ax
mov ebx,eax
mov eax,3579545
mov edx,0
div ebx
cmp edx,3579545 / 2
jb l3
inc eax
l3:
mov ebx,3
mov edx,0
div ebx
cmp edx,3 / 2
jb l4
inc eax
l4:
mov [irq0freq],eax
pop ebx
mov eax,0xDBB3A062
mul ebx
shrd eax,edx,10
shr edx,10
mov [irq0ms],edx
mov [irq0fractions],eax
pushfd
cli
mov al,00110100b
out 0x43,al
mov ax,[pitreloadvalue]
out 0x40,al
mov al,ah
out 0x40,al
popfd
popad
ret

unhandled:
push eax
mov byte [ioornot],1
mov al,0x20
out 0x20,al
pop eax
iret

installisr:
push eax
push ebp
mov ebp,eax
mov eax,esi
mov word [idt+ebp*8],ax
shr eax,16
mov word [idt+ebp*8+6],ax
pop ebp
pop eax
ret


initKeyboard:
push eax
mov al,0xed
call ps2write
out 0x60,al
call ps2read
in al,0x60
mov al,000b
call ps2write
out 0x60,al
call ps2read
in al,0x60
mov al,0xf3
call ps2write
out 0x60,al
call ps2read
in al,0x60
mov al,0
call ps2write
out 0x60,al
call ps2read
in al,0x60
end:
pop eax
ret

ps2write:
push eax
waitloop:
in al,0x64
bt ax,1
jnc donewrite
jmp waitloop
donewrite:
pop eax
ret

ps2read:
push eax
waitloop2:
in al,0x64
bt ax,0
jc doneread
jmp waitloop2
doneread:
pop eax
ret

drawcursor:
push word [X]
push word [Y]
mov ax,word [mouseX]
mov word [X],ax
mov ax,word [mouseY]
mov word [Y],ax
call sys_plotpixel
inc word [X]
call sys_plotpixel
inc word [X]
call sys_plotpixel
sub word [X],2
inc word [Y]
call sys_plotpixel
inc word [Y]
call sys_plotpixel
sub word [Y],2
inc word [X]
inc word [Y]
call sys_plotpixel
inc word [X]
inc word [Y]
call sys_plotpixel
inc word [X]
inc word [Y]
call sys_plotpixel
pop word [Y]
pop word [X]
ret

sys_getoldlocation:
pusha
push word [X]
push word [Y]
push ax
mov al,0xff
out 0x21,al
pop ax
mov ax,word [mouseX]
mov word [prevmouseX],ax
mov word [X],ax
mov ax,word [mouseY]
mov word [prevmouseY],ax
mov word [Y],ax
call sys_getpixel
;mov ax,word [prevColor]
mov word [msoldloc],ax
inc word [X]
call sys_getpixel
;mov ax,word [prevColor]
mov word [msoldloc+2],ax
inc word [X]
call sys_getpixel
;mov ax,word [prevColor]
mov word [msoldloc+4],ax
sub word [X],2
inc word [Y]
call sys_getpixel
;mov ax,word [prevColor]
mov word [msoldloc+6],ax
inc word [Y]
call sys_getpixel
;mov ax,word [prevColor]
mov word [msoldloc+8],ax
sub word [Y],2
inc word [X]
inc word [Y]
call sys_getpixel
;mov ax,word [prevColor]
mov word [msoldloc+10],ax
inc word [X]
inc word [Y]
call sys_getpixel
;mov ax,word [prevColor]
mov word [msoldloc+12],ax
inc word [X]
inc word [Y]
call sys_getpixel
;mov ax,word [prevColor]
mov word [msoldloc+14],ax
push ax
mov al,0xb8
out 0x21,al
pop ax
pop word [Y]
pop word [X]
popa
ret

printoldlocation:
pusha
push word [X]
push word [Y]
mov ax,word [prevmouseX]
mov word [X],ax
mov ax,word [prevmouseY]
mov word [Y],ax
mov ax,word [msoldloc]
mov word [Color],ax
call sys_plotpixel
inc word [X]
mov ax,word [msoldloc+2]
mov word [Color],ax
call sys_plotpixel
inc word [X]
mov ax,word [msoldloc+4]
mov word [Color],ax
call sys_plotpixel
sub word [X],2
inc word [Y]
mov ax,word [msoldloc+6]
mov word [Color],ax
call sys_plotpixel
inc word [Y]
mov ax,word [msoldloc+8]
mov word [Color],ax
call sys_plotpixel
sub word [Y],2
inc word [X]
inc word [Y]
mov ax,word [msoldloc+10]
mov word [Color],ax
call sys_plotpixel
inc word [X]
inc word [Y]
mov ax,word [msoldloc+12]
mov word [Color],ax
call sys_plotpixel
inc word [X]
inc word [Y]
mov ax,word [msoldloc+14]
mov word [Color],ax
call sys_plotpixel
pop word [Y]
pop word [X]
popa
ret

lbuttonclick:
cmp word [mouseX],619
jle s1
cmp word [mouseX],636
jg s1
cmp word [mouseY],1
jle s1
cmp word [mouseY],13
jg s1
jmp poweroptions
s1:
cmp word [mouseX],99
jle s2
cmp word [mouseX],150
jg s2
cmp word [mouseY],99
jle s2
cmp word [mouseY],150
jg s2
jmp distimedate
s2:
cmp word [mouseX],279
jle s3
cmp word [mouseX],330
jg s3
cmp word [mouseY],99
jle s3
cmp word [mouseY],150
jg s3
s3:
cmp word [mouseX],189
jle s4
cmp word [mouseX],240
jg s4
cmp word [mouseY],199
jle s4
cmp word [mouseY],250
jg s4
jmp loadprogram
s4:
cmp word [mouseX],369
jle s5
cmp word [mouseX],420
jg s5
cmp word [mouseY],199
jle s5
cmp word [mouseY],250
jg s5
mov byte [otherprog],1
call sys_singleLineEntry
mov esi,titleString
call sys_setupScreen
call drawWidgets
mov esi,calcFN
mov edi,program
call sys_loadfile
jmp otherprogramcontinue
mov byte [state],0
jmp osstart
s5:
cmp word [mouseX],279
jle s6
cmp word [mouseX],330
jg s6
cmp word [mouseY],99
jle s6
cmp word [mouseY],150
jg s6
mov byte [otherprog],1
call sys_singleLineEntry
mov esi,titleString
call sys_setupScreen
call drawWidgets
mov esi,fileFN
mov edi,program
call sys_loadfile
jmp otherprogramcontinue
mov byte [state],0
jmp osstart
s6:
cmp word [mouseX],459
jle s7
cmp word [mouseX],510
jg s7
cmp word [mouseY],99
jle s7
cmp word [mouseY],150
jg s7
mov byte [otherprog],1
call sys_singleLineEntry
mov esi,titleString
call sys_setupScreen
call drawWidgets
mov esi,editFN
mov edi,program
call sys_loadfile
jmp otherprogramcontinue
mov byte [state],0
jmp osstart
s7:
jmp osstart
otherprog db 0
calcFN db 'NXCALC.EXE',0
fileFN db 'NXFILE.EXE',0
editFN db 'NXEDIT.EXE',0
autoFN db 'AUTOEX.CFG',0

loadprogram:
mov esi,filenamestr
mov edi,filename
mov al,13
call sys_singleLineEntry
cli
mov esi,titleString
call sys_setupScreen
call drawWidgets
call sys_getoldlocation
sti
cmp byte [entrysuccess],1
je skipload
mov esi,filename
mov edi,program
call sys_loadfile
otherprogramcontinue:
mov esi,titleString
call sys_setupScreen
call drawWidgets
call sys_getoldlocation
cmp byte [loadsuccess],1
je osstart
mov dl,byte [bootdev]
call program
mov dword [directoryCluster],19
mov esi,titleString
call sys_setupScreen
call drawWidgets
call sys_getoldlocation
mov byte [state],0
call sys_mouseemuenable
jmp osstart
skipload:
jmp osstart

filenamestr db 'Enter file name:',0
filename times 13 db 0
fat12fn times 13 db 0
Sides dw 0
fileSize dd 0
cluster dw 0
SectorsPerTrack dw 18
program equ 50000h
disk_buffer equ 40000h
fat equ 0ac00h

sys_reloadfolder:
cmp ax,19
je reloadroot
sub ax,31
push edi
jmp reloadfolderhere
reloadroot:
call sys_getrootdirectory
mov esi,disk_buffer
mov ecx,1c00h
repe movsb
mov dword [numOfSectors],14
ret

sys_loadfile:
mov byte [loadsuccess],0
mov dword [numOfSectors],0
push edi
mov edi,fat12fn
call sys_makefnfat12
pop edi
push edi
mov eax,dword [directoryCluster]
mov edi,102c0h
call sys_reloadfolder
mov esi,102c0h
mov ecx,dword [numOfSectors]
imul ecx,200h
mov dword [folderSize],ecx
mov edi,disk_buffer
repe movsb
mov edi,disk_buffer
mov esi,fat12fn
mov bx,0
mov ax,0
findfn1:
mov ecx,11
cld
repe cmpsb
je foundfn1
inc bx
add ax,32
mov esi,fat12fn
mov edi,disk_buffer
and eax,0xffff
add edi,eax
cmp bx,224
jle findfn1
cmp bx,224
jae filenotfound
foundfn1:
mov ax,32
mul bx
mov edi,disk_buffer
and eax,0xffff
add edi,eax
push eax
mov eax,dword [edi+1ch]
mov dword [fileSize],eax
pop eax
mov ax,word [edi+1Ah]
reloadfolderhere:
mov word [cluster],ax
add word [cluster],31
push ax
mov eax,1
mov edi,disk_buffer
mov ecx,9
mov dx,0
mov byte [selecteddrive],0
call readwritesectors
pop ax
pop edi
;mov ebx,edi
push edi
movzx eax,word [cluster]
mov ecx,1
mov dx,0
cmp byte [saveinsteadofload],0
je skipincrementdx2
inc dx
skipincrementdx2:
mov byte [selecteddrive],0
call readwritesectors
inc dword [numOfSectors]
sub dword [cluster],31
pop edi
;mov ebp,0
mov ax,word [cluster]
loadnextclust:
movzx ecx,ax
movzx edx,ax
shr edx,1
add ecx,edx
mov ebx,disk_buffer
add ebx,ecx
mov dx,word [ebx]
test ax,1
jnz odd1
even1:
and dx,0fffh
jmp endload
odd1:
shr dx,4
endload:
mov ax,dx
mov word [cluster],dx
add edi,512
add word [cluster],31
movzx eax,word [cluster]
mov ecx,1
mov dx,0
cmp byte [saveinsteadofload],0
je skipincrementdx
inc dx
skipincrementdx:
push edi
mov byte [selecteddrive],0
call readwritesectors
pop edi
jc donereadsectorfat12
inc dword [numOfSectors]
sub word [cluster],31
mov dx,word [cluster]
mov ax,dx
cmp dx,0ff0h
jb loadnextclust
donereadsectorfat12:
clc
mov byte [saveinsteadofload],0
mov eax,dword [fileSize]
;mov dword [directoryCluster],19
ret

sys_overwrite:
push esi
push ebx
push eax
call sys_deletefile
pop eax
pop ebx
pop esi	
call sys_writefile
mov byte [state],0
mov al,byte [ccbyte]
mov bl,0x20
call kbcmd
call kbread
donewritw2:
ret

loaddirectory:
pushad
mov eax,dword [directoryCluster]
mov edi,102c0h
call sys_reloadfolder
mov esi,102c0h
mov ecx,dword [numOfSectors]
imul ecx,200h
mov dword [folderSize],ecx
mov edi,disk_buffer
repe movsb
mov dword [edi],0
popad
ret

sys_writefile:
mov dword [numOfSectors],0
mov dword [fileSize],eax
push ebx
push esi
call loaddirectory
pop esi
call sys_createfile
pop ebx
mov dword [location],ebx
mov edi,freeclusts
mov ecx,1024
cleanroutine:
mov word [edi],0
add edi,2
loop cleanroutine
getclustamount:
mov ecx,dword [fileSize]
mov eax,ecx
mov edx,0
mov ebx,512
div ebx
cmp edx,0
jg addaclust
jmp createentry
addaclust:
inc eax
createentry:
mov word [clustersneeded],ax
mov ebx,dword [fileSize]
cmp ebx,0
je finishwrite
pushad
mov eax,1
mov edi,disk_buffer
mov ecx,9
mov dx,0
mov byte [selecteddrive],0
call readwritesectors
popad
movzx ecx,word [clustersneeded]
call findavailableclusters
chainloop:
movzx eax,word [count]
cmp ax,word [clustersneeded]
je lastcluster
mov edi,freeclusts
add edi,ecx
movzx ebx,word [edi]
mov ax,bx
mov edx,0
mov bx,3
mul bx
mov bx,2
div bx
mov esi,disk_buffer
add esi,eax
mov ax,word [esi]
or dx,dx
jz even2
odd2:
and ax,000fh
mov edi,freeclusts
add edi,ecx
mov bx,word [edi+2]
shl bx,4
add ax,bx
mov word [esi],ax
inc word [count]
add cx,2
jmp chainloop
even2:
and ax,0f000h
mov edi,freeclusts
add edi,ecx
mov bx,word [edi+2]
add ax,bx
mov word [esi],ax
inc word [count]
add cx,2
jmp chainloop
lastcluster:
mov edi,freeclusts
add edi,ecx
movzx ebx,word [edi]
mov eax,ebx
mov edx,0
mov bx,3
mul bx
mov bx,2
div bx
mov esi,disk_buffer
add esi,eax
movzx eax,word [esi]
or dx,dx
jz evenlast
oddlast:
and ax,000fh
add ax,0ff80h
jmp writefat
evenlast:
and ax,0f000h
add ax,0ff8h
writefat:
mov word [esi],ax
pushad
mov eax,1
mov edi,disk_buffer
mov ecx,9
mov dx,1
mov byte [selecteddrive],0
call readwritesectors
popad
mov ecx,0
saveloop:
mov edi,freeclusts
add edi,ecx
mov ax,word [edi]
cmp ax,0
je writerootentry
pushad
movzx eax,ax
add eax,31
mov edi,dword [location]
mov ecx,1
mov dx,1
mov byte [selecteddrive],0
call readwritesectors
popad
add dword [location],512
inc cx
inc cx
jmp saveloop
writerootentry:
call loaddirectory
mov edi,disk_buffer
mov esi,fat12fn
mov bx,0
mov ax,0
findfn4:
mov ecx,11
cld
repe cmpsb
je foundfn4
inc bx
add ax,32
mov esi,fat12fn
mov edi,disk_buffer
and eax,0xffff
add edi,eax
cmp bx,224
jle findfn4
push edi
foundfn4:
mov ax,32
mul bx
mov edi,disk_buffer
and eax,0xffff
add edi,eax
mov ax,word [freeclusts]
mov word [edi+26],ax
mov dword ecx,[fileSize]
mov dword [edi+28],ecx
call sys_overwritefolder
finishwrite:
ret
location dd 0
freeclusts times 1024 dw 0
clustersneeded dd 0
count dw 0

sys_createfile:
push esi
call getStringLength
pop esi
call lookforspaceinstring
jc startlfncreate
cmp edx,12
jle skiplfncreate
startlfncreate:
pusha
mov eax,edx
mov edx,0
mov ebx,13
div ebx
cmp edx,0
je skipaddonedirectoryentry
inc eax
skipaddonedirectoryentry:
mov edi,disk_buffer ;subtract difference between old and new edi value to get new file size, then use that to determine if we need a new cluster.
mov ecx,0xffff
findemptyrootentry2:
mov byte bl,[edi]
cmp bl,0
je foundempty2
cmp bl,0e5h
je foundempty2
failfindemptyrootentry2:
add edi,32
loop findemptyrootentry2
foundempty2:
mov ecx,eax
push edi
loopcheckifdirentryisavailable:
sub edi,32
cmp byte [edi],0
je direntryavailable
cmp byte [edi],0xe5
je direntryavailable
gotonextemptyrootdir2:
pop edi
jmp failfindemptyrootentry2
direntryavailable:
cmp edi,disk_buffer
jl gotonextemptyrootdir2
loop loopcheckifdirentryisavailable
pop edi
call createsfnfromlfn
push edi
mov ecx,eax
mov ebx,1
loopfilllfn:
sub edi,32
call filllfn
inc ebx
cmp ebx,ecx
jle loopfilllfn
pop edi
mov dword [102c0h],edi
popa
mov edi,dword [102c0h]
jmp foundempty
skiplfncreate:
mov edi,fat12fn
pushad
mov ecx,11
mov al,0
repe stosb
popad
call sys_makefnfat12
mov edi,disk_buffer ;subtract difference between old and new edi value to get new file size, then use that to determine if we need a new cluster.
mov ecx,0xffff
findemptyrootentry:
mov byte al,[edi]
cmp al,0
je foundempty
cmp al,0e5h
je foundempty
add edi,32
loop findemptyrootentry
foundempty:
cmp dword [directoryCluster],19
je skipaddnewcluster
push edi
sub edi,disk_buffer
cmp edi,dword [folderSize]
jl doneaddnewcluster
mov eax,edi
mov edx,0
mov edi,200h
div edi
mov ecx,eax
push ecx
call addadditionalcluster
call loaddirectory
mov eax,0
mov edi,disk_buffer
sub dword [folderSize],200h
mov ecx,dword [folderSize]
add edi,ecx
sub edi,200h
pop ecx
imul ecx,200h
repe stosb
doneaddnewcluster:
pop edi
skipaddnewcluster:
mov esi,fat12fn
mov ecx,11
cld
repe movsb
sub edi,11
mov byte [edi+11],0
mov byte [edi+12],0
mov byte [edi+13],0
mov byte [edi+14],0c6h
mov byte [edi+15],07eh
mov byte [edi+16],0
mov byte [edi+17],0
mov byte [edi+18],0
mov byte [edi+19],0
mov byte [edi+20],0
mov byte [edi+21],0
mov byte [edi+22],0c6h
mov byte [edi+23],07eh
mov byte [edi+24],0
mov byte [edi+25],0
mov byte [edi+26],0
mov byte [edi+27],0
mov byte [edi+28],0
mov byte [edi+29],0
mov byte [edi+30],0
mov byte [edi+31],0
pushad
call sys_overwritefolder
popad
ret

sys_createfolder:
call sys_createfile
pushad
call loaddirectory
popad
mov byte [edi+0bh],10h
pushad
call sys_overwritefolder
popad
ret

sys_deletefile:
mov dword [numOfSectors],0
mov byte [loadsuccess],0
mov edi,fat12fn
call sys_makefnfat12
mov eax,dword [directoryCluster]
mov edi,102c0h
call sys_reloadfolder
mov esi,102c0h
mov ecx,dword [numOfSectors]
imul ecx,200h
mov dword [folderSize],ecx
mov edi,disk_buffer
repe movsb
mov edi,disk_buffer
mov esi,fat12fn
mov bx,0
mov ax,0
findfn2:
mov ecx,11
cld
repe cmpsb
je foundfn2
inc bx
add ax,32
mov esi,fat12fn
mov edi,disk_buffer
and eax,0xffff
add edi,eax
cmp bx,224
jle findfn2
push edi
cmp bx,224
jae filenotfound
foundfn2:
mov ax,32
mul bx
mov edi,disk_buffer
and eax,0xffff
add edi,eax
mov byte [edi],229
push edi
sub edi,15h
loopclearlfn:
cmp byte [edi],0x0f
jne doneloopclearlfn
mov byte [edi-0bh],229
sub edi,20h
jmp loopclearlfn
doneloopclearlfn:
pop edi
pusha
call sys_overwritefolder
mov edi,disk_buffer
mov esi,102c0h
mov ecx,dword [folderSize]
repe movsb
popa
mov ax,word [edi+26]
cmp ax,0
je zerosectors
mov word [tmpcluster],ax
push ax
mov eax,1
mov edi,disk_buffer
mov ecx,9
mov dx,0
mov byte [selecteddrive],0
call readwritesectors
pop ax
and eax,0xffff
and ebx,0xffff
moreCluster:
mov bx,3
mul bx
mov bx,2
div bx
mov esi,disk_buffer
add esi,eax
mov ax, word [esi]
test dx,dx
jz even
odd:
push ax
and ax,0x000F
mov word [esi],ax
pop ax
shr ax,4
jmp calcclustcount
even:
push ax
and ax,0xF000
mov word [esi],ax
pop ax
and ax,0x0fff
calcclustcount:
mov word [tmpcluster],ax
cmp ax,0ff8h
jae donefat
jmp moreCluster
donefat:
mov ax,1
call twelvehts2
mov eax,1
mov edi,disk_buffer
mov ecx,9
mov dx,1
mov byte [selecteddrive],0
call readwritesectors
zerosectors:
mov edi,fat12fn
mov ecx,13
mov al,0
repe stosb
ret

tmpcluster dw 0
folderSize dd 0

sys_overwritefolder:
cmp dword [directoryCluster],19
je overwriteroot 
mov byte [saveinsteadofload],1
mov edi,102c0h
mov esi,disk_buffer
mov ecx,dword [folderSize]
repe movsb
mov edi,102c0h
push edi
mov eax,dword [directoryCluster]
sub eax,31
jmp reloadfolderhere
overwriteroot:
pusha
mov eax,19
mov edi,disk_buffer
mov ecx,14
mov dx,1
mov byte [selecteddrive],0
call readwritesectors
popa
ret
saveinsteadofload db 0

sys_renamefile:
push esi
push edi
mov byte [loadsuccess],0
mov edi,fat12fn
call sys_makefnfat12
pusha
call loaddirectory
popa
mov edi,disk_buffer
mov esi,fat12fn
mov bx,0
mov ax,0
findfn3:
mov ecx,11
cld
repe cmpsb
je foundfn3
inc bx
add ax,32
mov esi,fat12fn
mov edi,disk_buffer
and eax,0xffff
add edi,eax
cmp bx,224
jle findfn3
pop edi
pop esi
push edi
cmp bx,224
jae filenotfound
foundfn3:
mov ax,32
mul bx
mov edi,disk_buffer
and eax,0xffff
add edi,eax
mov eax,edi
pop edi
pop esi
mov esi,edi
pusha
mov bx,word [eax+26]
mov word [startingCluster],bx
mov bx,word [eax+20]
mov word [startingCluster+2],bx
mov ebx,dword [eax+28]
mov dword [fileSize],ebx
mov bl,byte [eax+0bh]
cmp bl,10h
je skipfilerename
cmp bl,16h
je skipfilerename
call sys_createfile
jmp skipfolderrename
skipfilerename:
call sys_createfolder
skipfolderrename:
pusha
call loaddirectory
popa
mov bx,word [startingCluster]
mov word [edi+26],bx
mov bx,word [startingCluster+2]
mov word [edi+20],bx
mov ebx,dword [fileSize]
mov dword [edi+28],ebx
popa
mov edi,eax
mov byte [edi],229
push edi
sub edi,15h
loopclearlfn2:
cmp byte [edi],0x0f
jne doneloopclearlfn2
mov byte [edi],0xff
mov byte [edi-0bh],229
sub edi,20h
jmp loopclearlfn2
doneloopclearlfn2:
pop edi
call sys_overwritefolder
mov edi,disk_buffer
mov esi,102c0h
mov ecx,dword [folderSize]
repe movsb
ret
startingCluster dd 0

fat12fn2 times 13 db 0

filenotfound:
mov dword [directoryCluster],19
cmp byte [autoornot],1
je donefnf
mov ax,150
mov bx,200
mov cx,500
mov dx,250
call sys_drawbox
mov byte [buttonornot],1
mov ax,290
mov bx,227
mov cx,338
mov dx,241
mov word [Color],0xffff
call sys_drawbox
mov byte [buttonornot],0
mov word [Color],0
mov word [X],200
mov word [Y],210
mov esi,fnfspr
call sys_dispsprite
mov word [X],306
mov word [Y],229
mov esi,ok
call sys_printString
mov word [X],247
mov word [Y],210
mov esi,errorfnf
call sys_printString
call sys_getoldlocation
mov dword [mouseaddress],lbuttonclick5
mov dword [keybaddress],sys_windowloop
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop
ok db 'OK',0
errorfnf db 'Error: File not found!',0

lbuttonclick5:
cmp word [mouseX],289
jle s51
cmp word [mouseX],337
jg s51
cmp word [mouseY],226
jle s51
cmp word [mouseY],241
jg s51
donefnf:
pop edi
mov byte [loadsuccess],1
mov byte [autoornot],0
ret
s51:
jmp windowloop

readwritesectors:
pushad
mov byte [usbhidenabled],0
push ax
mov al,0xba
out 0x21,al
mov al,0xff
out 0xa1,al
pop ax
shl byte [selecteddrive],1
mov esi,driveletter
push eax
movzx eax,byte [selecteddrive]
add esi,eax
pop eax
cmp byte [esi],0
jne skipfloppy
cmp byte [esi+1],0
je skipdisktwo
mov dh,1
skipdisktwo:
call fdcreadwrite
jmp donereadwritesectors
skipfloppy:
cmp byte [esi],1
jne skippata
mov ebx,eax
mov al,byte [esi+1]
and al,0xf0
shr al,4
dec al
mov esi,ebx
call patareadwritesector
jmp donereadwritesectors
skippata:
cmp byte [esi],2
jne skipahcireadwrite
shl edx,8
mov bl,byte [esi+1]
and bl,0xf0
shr bl,4
dec bl
or dl,bl
call ahcireadwritesector
jmp donereadwritesectors
skipahcireadwrite:
mov bl,byte [esi]
and bl,0xf0
cmp bl,30h
jne skipusbmsdreadwrite
mov dword [eaxval],eax
mov dword [ecxval],ecx
cmp dl,1
jne skipmsdwrite2
mov byte [msdreadorwrite],1
skipmsdwrite2:
cmp dl,0
jne skipmsdread2
mov byte [msdreadorwrite],0
skipmsdread2:
mov bl,byte [esi]
and bl,0x0f
push esi
mov esi,usbcontrollers
movzx ebx,bl
imul ebx,5
add esi,ebx
mov bl,byte [esi]
dec bl
mov byte [usbcontrollertype],bl
cmp byte [usbcontrollertype],2
jne skipehcimsdsetup
inc esi
mov edx,dword [esi]
mov dword [ehcioperbase],edx
mov eax,dword [edx+14h]
mov dword [uhciframelist],eax
sub eax,3000h
imul eax,5
add eax,1100h
mov dword [asyncval],eax
add eax,102h
mov dword [prevqh],eax
mov eax,dword [edx+14h]
sub eax,3000h
mov edx,0
mov ecx,10h
div ecx
add eax,eax
mov dword [tdval],20000h
sub dword [tdval],eax
mov edx,dword [tdval]
mov dword [tdlocation],edx
skipehcimsdsetup:
pop esi
mov bl,byte [esi+1]
and bl,0xf0
shr bl,4
dec bl
movzx edx,bl ;get endpoints from before
mov esi,msdendp
movzx ebx,byte [msdendpcounter]
add esi,edx
mov bl,byte [esi]
mov byte [endp1],bl
mov bl,byte [esi+1]
mov byte [endp2],bl
mov esi,msdframelists
movzx ebx,byte [msdendpcounter]
shl edx,2
add esi,edx
mov ebx,dword [esi]
mov dword [uhciframelist],ebx
shr edx,2
mov esi,msdtoggle
add esi,edx
mov bl,byte [esi]
mov byte [msdbulkouttoggle],bl
mov bl,byte [esi+1]
mov byte [msdbulkintoggle],bl
mov ecx,dword [ecxval]
mov eax,dword [eaxval]
call msdreadwritesector
skipusbmsdreadwrite:
donereadwritesectors:
mov byte [usbhidenabled],1
push ax
mov al,0xb8
out 0x21,al
mov al,byte [picslave]
out 0xa1,al
pop ax
popad
ret
selecteddrive db 0

alreg db 0
cxreg dw 0
dxreg dw 0
edireg dd 0 
espreg dd 0
ebpreg dd 0
ccbyte db 0

go32:
use16
cli
pop bp
and ebp,0x0000ffff
mov eax,cs
shl eax,4
mov ebx,eax
lgdt [gdtloc]
mov eax,cr0
or eax,1
mov cr0,eax
add ebx,ebp
push 0x08
push ebx
mov bp,sp
jmp dword far [bp]
retf
use32

gdtloc times 6 db 0
idtloc times 6 db 0

pic32:
mov al,0x11
out 0x20,al
call picdelay
out 0xA0,al
call picdelay
mov al,0x20
out 0x21,al
call picdelay
mov al,0x28
out 0xA1,al
call picdelay
mov al,0x04
out 0x21,al
call picdelay
mov al,0x02
out 0xA1,al
call picdelay
mov al,0x01
out 0x21,al
call picdelay
out 0xA1,al
call picdelay
mov al,0xff
out 0x21,al
call picdelay
out 0xa1,al
call picdelay
ret

sys_makefnfat12:
call getStringLength
push esi
sub esi,edx
cmp dword [esi],538979886
je justcopyfn
cmp dword [esi],538976302
je justcopyfn
pop esi
xor dh,dh
movzx edx,dx
sub esi,edx
call makeCaps
sub esi,edx
mov cx,0
mov ebx,edi
copytonewstr:
lodsb
cmp al,'.'
je extfound
cmp cx,8
je justskipext
cmp al,0
jne skipusespaceinstead
mov al,' '
skipusespaceinstead:
stosb
inc cx
jmp copytonewstr
justskipext:
mov al,' '
stosb
stosb
stosb
ret
extfound:
cmp cx,8
je addext
addspaces:
mov byte [edi],' '
inc edi
inc cx
cmp cx,8
jl addspaces
addext:
lodsb
stosb
lodsb
stosb
lodsb
stosb
pusha
add cx,3
and ecx,0xffff
sub edi,ecx
mov esi,edi
call getStringLength
movzx edx,dl
sub esi,edx
checkifspaceneeded:
cmp edx,11
jle addspace
popa
mov al,0
stosb
ret
addspace:
add esi,edx
mov byte [esi],' '
sub esi,edx
inc edx
jmp checkifspaceneeded
justcopyfn:
pop esi
sub esi,edx
mov ecx,8
repe movsb
jmp justskipext

addadditionalcluster:
pushad
mov eax,1
mov edi,disk_buffer
mov ecx,9
mov dx,0
mov byte [selecteddrive],0
call readwritesectors
popad
push ecx
call findavailableclusters
movzx eax,word [directoryCluster]
sub eax,31
gotolastclust:
mov dword [oldcluster],eax
mov ecx,eax
mov edx,eax
shr edx,1
add ecx,edx
mov ebx,disk_buffer
add ebx,ecx
mov dx,word [ebx]
test ax,1
jnz odd3
even3:
and dx,0fffh
jmp endload2
odd3:
shr dx,4
endload2:
mov ax,dx
mov word [cluster],dx
mov dx,word [cluster]
mov ax,dx
cmp dx,0ff0h
jb gotolastclust
pop ecx
loopsavecluster:
mov ebx,freeclusts
add bx,word [clustercount]
movzx ebx,word [ebx]
startsavecluster:
push ebx
mov eax,dword [oldcluster]
mov ebx,2
mov edx,0
div ebx
pop ebx
mov eax,dword [oldcluster]
mov esi,disk_buffer
push ecx
push edx
mov ecx,eax
mov edx,eax
shr edx,1
add esi,ecx
add esi,edx
pop edx
pop ecx
movzx edi,word [esi]
cmp edx,1
je odd4
and edi,0xf000
mov eax,ebx
and eax,0xfff
or edi,eax
mov word [esi],di
jmp skipodd5
odd4:
and edi,0x0f
mov eax,ebx
shl eax,4
or edi,eax
mov word [esi],di
skipodd5:
mov eax,freeclusts
add ax,word [clustercount]
movzx eax,word [eax]
mov dword [oldcluster],eax
inc word [clustercount]
dec ecx
cmp ecx,0
jg loopsavecluster
cmp ebx,0xff0
je donesavecluster
mov word [clustercount],0
mov ebx,0xff0
jmp startsavecluster
donesavecluster:
pushad
mov eax,1
mov edi,disk_buffer
mov ecx,9
mov dx,1
mov byte [selecteddrive],0
call readwritesectors
popad
ret
clustercount dw 0
oldcluster dd 0

findavailableclusters:
mov esi,disk_buffer+3
mov ebx,2
mov edx,0
findcluster:
lodsw
and ax,0fffh
jz foundeven
moreodd:
inc bx
dec esi
lodsw
shr ax,4
or ax,ax
jz foundodd
moreeven:
inc bx
jmp findcluster
foundeven:
push esi
mov esi,freeclusts
add esi,edx
mov word [esi],bx
pop esi
dec ecx
cmp ecx,0
je donefind
inc dx
inc dx
jmp moreodd
foundodd:
push esi
mov esi,freeclusts
add esi,edx
mov word [esi],bx
pop esi
dec ecx
cmp ecx,0
je donefind
inc dx
inc dx
jmp moreeven
donefind:
mov ecx,0
mov word [count],1
ret

twelvehts:
add ax,31
twelvehts2:
push bx
push ax
mov bx,ax
mov dx,0
div word [SectorsPerTrack]
add dl,01h
mov cl,dl
mov ax,bx
mov dx,0
div word [SectorsPerTrack]
mov dx,0
div word [Sides]
mov dh,dl
mov ch,al
pop ax
pop bx
mov dl,byte [bootdev]
ret

lookforspaceinstring:
pushad
clc
looplookforspace:
lodsb
cmp al,' '
je foundspace
cmp al,0
je didntfindspace
jmp looplookforspace
foundspace:
stc
didntfindspace:
popad
ret

getStringLength:
mov edx,0
loopstrlength:
cmp byte [esi],0
jne inccounter
cmp byte [esi],0
je donestrlength
jmp loopstrlength
inccounter:
inc edx
inc esi
jmp loopstrlength
donestrlength:
ret

makeCaps:
cmp byte [esi],0
je doneCaps
cmp byte [esi],61h
jl notatoz
cmp byte [esi],7ah
jg notatoz
sub byte [esi],20h
notatoz:
inc esi
jmp makeCaps
doneCaps:
ret


distimedate:
cli
mov byte [buttonornot],1
mov ax,223
mov bx,200
mov cx,423
mov dx,300
mov word [Color],0xBDF7
call sys_drawbox
mov ax,289
mov bx,255
mov cx,359
mov dx,275
mov word [Color],0xFFFF
call sys_drawbox
mov byte [buttonornot],0
mov word [X],306
mov word [Y],260
mov word [Color],0
mov esi,cancel
call sys_printString
mov word [X],265
mov word [Y],210
mov esi,time
call sys_printString
mov word [X],265
mov word [Y],225
mov esi,date
call sys_printString
sti
mov dword [mouseaddress],lbuttonclick3
mov dword [keybaddress],sys_windowloop
mov dword [bgtaskaddress],rtchandler
jmp sys_windowloop
time db 'Time:',0
date db 'Date:',0
status db 0
bcdtest db 0
timedstruct times 8 db 0


rtchandler:
pusha
cli
mov byte [ioornot],1
mov edi,timedstruct
mov al,0
out 0x70,al
in al,0x71
stosb
mov al,0x02
out 0x70,al
in al,0x71
stosb
mov al,0x04
out 0x70,al
in al,0x71
stosb
mov al,0x06
out 0x70,al
in al,0x71
stosb
mov al,0x07
out 0x70,al
in al,0x71
stosb
mov al,0x08
out 0x70,al
in al,0x71
stosb
mov al,0x09
out 0x70,al
in al,0x71
stosb
mov al,0x32
out 0x70,al
in al,0x71
stosb
mov al,0x0b
out 0x70,al
in al,0x71
test al,4
jnz notit
mov esi,timedstruct
mov ecx,8
bcdloop:
lodsb
push cx
push ax
and al,11110000b
shr al,4
mov cl,10
mul cl
pop cx
and cl,00001111b
add al,cl
pop cx
loop bcdloop
notit:
mov byte [buttonornot],1
mov ax,300
mov bx,200
mov cx,423
mov dx,240
mov word [Color],0xBDF7
call sys_drawbox
mov byte [buttonornot],0
mov esi,timedstruct
lodsb
xor ah,ah
mov word [X],335
mov word [Y],210
mov word [Color],0
call printtimed
mov word [X],330
mov word [Y],210
mov dx,':'
call sys_printChar
lodsb
xor ah,ah
mov word [X],318
mov word [Y],210
call printtimed
lodsb
mov word [X],300
mov word [Y],210
call printtimed
mov word [X],312
mov word [Y],210
mov dx,':'
call sys_printChar
lodsb
lodsb
mov word [X],300
mov word [Y],225
call printtimed
mov word [X],312
mov word [Y],225
mov dx,'/'
call sys_printChar
lodsb
mov word [X],318
mov word [Y],225
call printtimed
mov word [X],330
mov word [Y],225
mov dx,'/'
call sys_printChar
lodsb
mov word [X],347
mov word [Y],225
call printtimed
lodsb
mov word [X],335
mov word [Y],225
call printtimed
sti
popa
ret
printtimed:
pusha
mov bl,al
and al,00001111b
mov esi,hexvalue
mov edi,finalvalue+1
movzx eax,al
add esi,eax
movsb
mov al,bl
and al,11110000b
shr al,4
mov esi,hexvalue
mov edi,finalvalue
movzx eax,al
add esi,eax
movsb
mov esi,finalvalue
call sys_printString
popa
ret

hexvalue db '0123456789ABCDEF',0
finalvalue times 2 db 0
db 0

poweroptions:
cli
mov byte [buttonornot],1
mov ax,100
mov bx,100
mov cx,540
mov dx,350
mov word [Color],0xBDF7
call sys_drawbox
mov byte [buttonornot],0
mov esi,poweroptionsstr
mov word [Color],0
mov word [X],278
mov word [Y],110
call sys_printString
mov byte [buttonornot],1
mov ax,150
mov bx,150
mov cx,250
mov dx,250
mov word [Color],0xE73C
call sys_drawbox
mov ax,390
mov bx,150
mov cx,490
mov dx,250
mov word [Color],0xE73C
call sys_drawbox
mov ax,288
mov bx,310
mov cx,358
mov dx,330
mov word [Color],0xFFFF
call sys_drawbox
mov byte [buttonornot],0
mov word [Color],0
mov word [X],172
mov word [Y],260
mov esi,shutdown
call sys_printString
mov word [X],417
mov word [Y],260
mov esi,reboot
call sys_printString
mov word [X],305
mov word [Y],315
mov esi,cancel
call sys_printString
mov word [X],191
mov word [Y],193
mov esi,sdspr
call sys_dispsprite
mov word [X],431
mov word [Y],193
mov esi,respr
call sys_dispsprite
sti
mov dword [mouseaddress],lbuttonclick2
mov dword [keybaddress],sys_windowloop
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop
poweroptionsstr db 'Power options:',0
shutdown db 'Shut Down',0
reboot db 'Restart',0
cancel db 'Cancel',0

lbuttonclick2:
cmp word [mouseX],287
jle s21
cmp word [mouseX],358
jg s21
cmp word [mouseY],309
jle s21
cmp word [mouseY],330
jg s21
cli
mov esi,titleString
call sys_setupScreen
call drawWidgets
call sys_getoldlocation
sti
jmp osstart
s21:
cmp word [mouseX],389
jle s22
cmp word [mouseX],490
jg s22
cmp word [mouseY],149
jle s22
cmp word [mouseY],250
jg s22
mov al,0xfe
out 0x64,al
jmp 0xffff:0000h
s22:
cmp word [mouseX],149
jle s23
cmp word [mouseX],250
jg s23
cmp word [mouseY],149
jle s23
cmp word [mouseY],250
jg s23
call shutdownpc
s23:
jmp windowloop

lbuttonclick3:
cmp word [mouseX],288
jle s31
cmp word [mouseX],359
jg s31
cmp word [mouseY],254
jle s31
cmp word [mouseY],275
jg s31
cli
mov esi,titleString
call sys_setupScreen
call drawWidgets
call sys_getoldlocation
sti
jmp osstart
s31:
jmp windowloop

shutdownpc:
call acpishutdown
call go16
db 0xB8, 0x00, 0x53, 0xBB, 0x00, 0x00, 0xCD, 0x15, 0xB8, 0x01, 0x53, 0xBB, 0x00, 0x00, 0xCD, 0x15, 0xB8, 0x0E, 0x53, 0xBB
db 0x00, 0x00, 0xB9, 0x02, 0x01, 0xCD, 0x15, 0xB8, 0x07, 0x53, 0xB9, 0x03, 0x00, 0xBB, 0x01, 0x00, 0xCD, 0x15, 0xF4, 0xEB, 0xFE

acpishutdown:
mov edi,0xe0000
mov esi,rsdp
mov ecx,8
findrsdp:
pusha
rep cmpsb
popa
jne couldntfindrsdp
jmp foundrsdp
doneacpi:
ret
couldntfindrsdp:
cmp edi,0xfffff
jge doneacpi
add edi,8
mov esi,rsdp
mov ecx,8
jmp findrsdp
foundrsdp:
mov eax,dword [edi+16]
mov esi,eax
mov ecx,[esi+4]
sub ecx,36
shr ecx,2
findfacp:
add esi,36
mov ebx,[esi]
mov eax,[ebx]
cmp eax,'FACP'
je foundfacp
add esi,4
dec cx
cmp cx,0
jne findfacp
jmp doneacpi
foundfacp:
mov esi,ebx
mov eax,[esi+64]
mov [oneacontrolblock],eax
mov eax,[esi+68]
mov [onebcontrolblock],eax
mov esi,[esi+40]
sub esi,10000h
mov edx,[esi+4]
mov eax,0dfh
mul edx
xchg eax,edx
mov edi,'_S5_'
mov ecx,4
s5check:
cmp edi,[esi]
je founds5
inc esi
dec edx
cmp edx,0
jne s5check
jmp doneacpi
founds5:
mov eax,esi
add esi,5
mov al,[esi]
and al,0c0h
shr al,6
add al,2
movzx eax,al
add esi,eax
a32 lodsb
cmp al,0ah
jne byteprefix1
a32 lodsb
byteprefix1:
movzx ax,al
shl ax,10
mov [sla],ax
a32 lodsb
cmp al,0ah
jna byteprefix2
a32 lodsb
byteprefix2:
movzx ax,al
shl ax,10
mov [slb],ax
cli
mov dx,[oneacontrolblock]
mov ax,[sla]
or ax,2000h
out dx,ax
mov dx,[onebcontrolblock]
mov ax,[slb]
or ax,2000h
out dx,ax
sti
ret

rsdp db 'RSD PTR '
oneacontrolblock dw 0
onebcontrolblock dw 0
sla dw 0
slb dw 0

go16:
cli
pop edx
lidt [idtloc]
mov al,0x11
out 0x20,al
call picdelay
out 0xA0,al
call picdelay
mov al,0x08
out 0x21,al
call picdelay
mov al,0x70
out 0xA1,al
call picdelay
mov al,0x04
out 0x21,al
call picdelay
mov al,0x02
out 0xA1,al
call picdelay
mov al,0x01
out 0x21,al
call picdelay
out 0xA1,al
call picdelay
mov al,0xff
out 0x21,al
call picdelay
mov al,0xff
out 0xa1,al
call picdelay
mov al,byte [picmaster]
out 0x21,al
mov al,byte [picslave]
out 0xa1,al
mov esi,pm16
mov edi,0x5021
mov eax,0
mov ecx,0
looptransfer:
lodsw
stosw
inc ecx
cmp ecx,sixteendata
jne looptransfer
;NOTE TO SELF: TRY COPYING THE 16 BIT SHIT TO THAT MEMORY ADDRESS!!
push dword 0x18
push 0x5021
retf
use16
pm16:
mov ax,0x20
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ss,ax
mov eax,cr0
and eax,0xfe
mov cr0,eax
jmp 3000h:rmode
rmode:
mov ax, 3000h
mov ds, ax
mov es, ax
mov ss, ax    
mov sp, 0
sti
push 3000h
push dx
retf

use32

sixteendata equ $-pm16

picmaster db 0
picslave db 0

drawWidgets:
mov word [X],230
mov word [Y],50
mov word [Color],0
mov esi,options
call sys_printString
mov ax,100
mov bx,100
mov cx,150
mov dx,150
call sys_drawbox
mov word [X],115
mov word [Y],115
mov esi,tispr
call sys_dispsprite
mov esi,timedstr
mov word [X],94
mov word [Y],160
mov word [Color],0
call sys_printString
mov ax,280
mov bx,100
mov cx,330
mov dx,150
call sys_drawbox
mov word [X],295
mov word [Y],115
mov esi,fmspr
call sys_dispsprite
mov word [X],271
mov word [Y],160
mov word [Color],0
mov esi,fmstr
call sys_printString
mov ax,460
mov bx,100
mov cx,510
mov dx,150
call sys_drawbox
mov word [X],475
mov word [Y],115
mov esi,tespr
call sys_dispsprite
mov word [X],453
mov word [Y],160
mov esi,testr
mov word [Color],0
call sys_printString
mov ax,190
mov bx,200
mov cx,240
mov dx,250
call sys_drawbox
mov word [X],205
mov word [Y],215
mov esi,progspr
call sys_dispsprite
mov word [X],181
mov word [Y],260
mov word [Color],0
mov esi,progstr
call sys_printString
mov ax,370
mov bx,200
mov cx,420
mov dx,250
call sys_drawbox
mov word [X],385
mov word [Y],215
mov esi,calcspr
call sys_dispsprite
mov word [X],367
mov word [Y],260
mov word [Color],0
mov esi,calcstr
call sys_printString
ret
options db 'Please choose an option below:',0
timedstr db 'Date & time',0
fmstr db 'File manager',0
testr db 'Text editor',0
progstr db 'Load program',0
calcstr db 'Calculator',0

sys_genrandnumber:
pusha
push eax
push ebx
mov ecx,dword [systimerms]
mov eax,1103515245
mul ecx
add eax,12345
mov edx,0
mov ecx,65535
div ecx
mov edx,0
pop ebx
mov ecx,ebx
pop ebx
sub ecx,ebx
inc ecx
div ecx
mov dword [edireg],edx
popa
mov edx,dword [edireg]
cmp edx,0
jne skipaddition
cmp eax,0
je skipaddition
add edx,eax
skipaddition:
ret

sys_dispsprite:
pusha
loopsprite:
lodsb
cmp al,0
je skipahead
cmp al,1
je printonesprite
cmp al,2
je nextline
cmp al,3
je lastline
donesprite:
popa
mov byte [lastlinebyte],0
ret
skipahead:
inc word [X]
cmp bl,1
je loopsprite
inc word [X]
jmp loopsprite
printonesprite:
mov word [Color],00h
call sys_plotpixel
inc word [X]
cmp bl,1
je loopsprite
mov word [Color],00h
call sys_plotpixel
inc word [X]
jmp loopsprite
nextline:
sub word [X],10
inc word [Y]
cmp bl,1
je loopsprite
sub word [X],10
cmp byte [spriteswitch],0
je doagain
mov byte [spriteswitch],0
jmp loopsprite
doagain:
sub esi,11
mov byte [spriteswitch],1
jmp loopsprite
lastline:
cmp bl,1
je donesprite
cmp byte [lastlinebyte],1
je donesprite
sub esi,11
sub word [X],20
inc word [Y]
mov byte [lastlinebyte],1
jmp loopsprite

spriteswitch db 0
lastlinebyte db 0

sys_returnnumberofdrives:
mov al,byte [drivecounter]
ret

sys_displayfatfn:
pushad
push ax
mov al,0xff
out 0x21,al
pop ax
mov esi,disk_buffer
mov ebx,0bh
add edx,disk_buffer
loopfindfn:
cmp esi,edx
je nolfnfound
cmp byte [esi+ebx],0x0f
je foundpossiblelfn
cmp byte [esi+ebx],0x0f
jne foundpossiblesfn2
nextrootentry:
add esi,32
jmp loopfindfn
foundpossiblelfn:
mov al,byte [esi]
and al,0x0f
cmp al,1
jne nextrootentry
cmp al,0xe5
je nextrootentry
cmp byte [esi+2bh],0x0f
je nextrootentry
dec ecx
cmp ecx,0xffffffff
jne nextrootentry
mov dword [esival],esi
readalfnentry:
inc esi
mov ecx,5
call displaylfnsection
add esi,13
mov ecx,6
call displaylfnsection
add esi,14
mov ecx,2
call displaylfnsection
sub esi,28
mov al,byte [esi]
sub esi,32
test al,40h
jz readalfnentry
nolfnfound:
cmp byte [saveataddress],1
jne skipsaveataddr7
mov byte [edi],0
skipsaveataddr7:
inc edi
mov dword [edival],edi
popad
mov edi,dword [edival]
push ax
mov al,0xb8
out 0x21,al
pop ax
mov esi,dword [esival]
mov al,1
ret
displaylfnsection:
push esi
loopreadfivechars:
lodsb
movzx dx,al
cmp dx,0
je notvalidchar
cmp dx,0xff
je notvalidchar
cmp word [X],600
jg printdots
call sys_printChar
cmp byte [saveataddress],1
jne skipsaveataddr
mov byte [edi],dl
inc edi
skipsaveataddr:
jmp notvalidchar
notvalidchar:
inc esi
loop loopreadfivechars
pop esi
ret
printdots:
mov dx,'.'
cmp byte [saveataddress],1
jne skipsaveataddr2
mov byte [edi],dl
mov byte [edi+1],dl
mov byte [edi+2],dl
add edi,3
skipsaveataddr2:
call sys_printChar
call sys_printChar
call sys_printChar
pop esi
add esp,4
jmp nolfnfound
foundpossiblesfn2:
mov al,byte [esi-21]
cmp al,0x0f
je checkiflfnisdeleted
lfnisdeleted:
mov al,byte [esi]
cmp al,0xe5
je nextrootentry
cmp dword [esi],538979886
je nextrootentry
cmp dword [esi],538976302
je nextrootentry
dec ecx
cmp ecx,0xffffffff
jne nextrootentry
mov dword [esival],esi
mov ecx,8
loopdispsfn:
lodsb
cmp al,' '
je doneloopdispsfn
movzx dx,al
cmp byte [saveataddress],1
jne skipsaveataddr3
mov byte [edi],dl
inc edi
skipsaveataddr3:
call sys_printChar
loop loopdispsfn
doneloopdispsfn:
mov esi,dword [esival]
cmp byte [esi+0bh],10h
je nosfnfound
cmp byte [esi+0bh],16h
je nosfnfound
add esi,8
mov dx,'.'
cmp byte [saveataddress],1
jne skipsaveataddr4
mov byte [edi],dl
inc edi
skipsaveataddr4:
call sys_printChar
mov ecx,3
loopdispsfnext:
lodsb
movzx dx,al
cmp byte [saveataddress],1
jne skipsaveataddr5
mov byte [edi],dl
inc edi
skipsaveataddr5:
call sys_printChar
loop loopdispsfnext
nosfnfound:
cmp byte [saveataddress],1
jne skipsaveataddr6
mov byte [edi],0
skipsaveataddr6:
inc edi
mov dword [edival],edi
popad
mov edi,dword [edival]
push ax
mov al,0xb8
out 0x21,al
pop ax
mov esi,dword [esival]
mov al,0
ret
checkiflfnisdeleted:
mov al,byte [esi-20h]
cmp al,0xe5
jne nextrootentry
jmp lfnisdeleted

sys_numoffatfn:
pushad
push ax
mov al,0xff
out 0x21,al
pop ax
mov edx,ecx
add edx,esi
mov ebx,0bh
mov ecx,0
loopfindfn2:
cmp esi,edx
je donenumoffatfn
cmp byte [esi+ebx],0x0f
je foundpossiblelfn2
cmp byte [esi],0
je donenumoffatfn
cmp byte [esi+ebx],0x0f
jne foundpossiblesfn
nextrootentry2:
add esi,32
jmp loopfindfn2
donenumoffatfn:
mov dword [ecxval],ecx
push ax
mov al,0xb8
out 0x21,al
pop ax
popad
mov ecx,dword [ecxval]
ret
foundpossiblelfn2:
mov al,byte [esi]
and al,0x0f
cmp al,1
jne nextrootentry2
cmp al,0xe5
je nextrootentry2
cmp byte [esi+2bh],0x0f
je nextrootentry2
inc ecx
jmp nextrootentry2
foundpossiblesfn:
mov al,byte [esi-21]
cmp al,0x0f
je checkiflfnisdeleted2
lfnisdeleted2:
mov al,byte [esi]
cmp al,0xe5
je nextrootentry2
cmp dword [esi],538979886
je nextrootentry2
cmp dword [esi],538976302
je nextrootentry2
inc ecx
jmp nextrootentry2
checkiflfnisdeleted2:
mov al,byte [esi-20h]
cmp al,0xe5
jne nextrootentry2
jmp lfnisdeleted2


fdcdetect:
cmp byte [floppyavail],1
jne donefdcdetect
mov al,0x10
out 0x70,al
in al,0x71
cmp al,0
je donefdcdetect
mov bl,al
and al,0xf0
and bl,0x0f
cmp al,0x40
jge addmasterfloppy
checkslave:
cmp bl,0x04
jge addslavefloppy
initfdc:
call fddreset
call fddrecalibrate
donefdcdetect:
ret
addmasterfloppy:
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov byte [esi],0
mov byte [esi+1],0
add byte [drivecounter],2
jmp checkslave
addslavefloppy:
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov byte [esi],0
mov byte [esi+1],1
add byte [drivecounter],2
jmp initfdc

fdcreadwrite:
pushad
push word [SectorsPerTrack]
push word [Sides]
mov word [SectorsPerTrack],18
mov word [Sides],2
push edi
push ecx
push dx
mov ebx,700
call initPIT
mov byte [fdcdrivenum],dh
cmp eax,2880
jg didntfinishfdcreadwrite
call twelvehts2
mov byte [fdcsector],cl
mov byte [fdchead],dh
mov byte [fdctrack],ch
cmp byte [fdcmotor],1
je skipenablefdcmotor2
call fdcmotoron
skipenablefdcmotor2:
mov dx,0x3f7
mov al,0
out dx,al
mov ecx,3
loopfdcseek:
call fdcseek
loop loopfdcseek
mov dx,0x3f4
in al,dx
pop dx
pop ecx
pop edi
test al,20h
jnz donefdcreadwrite
mov byte [fdcdone],0
call fdcdmatransfer
cmp dl,0
jne skipfdcread2
mov al,0xe6
call fdcsendbyte
jmp skipfdcwrite2
skipfdcread2:
mov al,0xc5
call fdcsendbyte
skipfdcwrite2:
mov al,byte [fdchead]
shl al,2
or al,byte [fdcdrivenum]
call fdcsendbyte
mov al,byte [fdctrack]
call fdcsendbyte
mov al,byte [fdchead]
call fdcsendbyte
mov al,byte [fdcsector]
call fdcsendbyte
mov al,2
call fdcsendbyte
mov al,12h
call fdcsendbyte
mov al,1bh
call fdcsendbyte
mov al,0xff
call fdcsendbyte
call fdcwaitforirq
call fdcgetbyte
call fdcgetbyte
call fdcgetbyte
call fdcgetbyte
mov	 [fdccurrenttrack],al 	
call fdcgetbyte
call fdcgetbyte
mov byte [resultR],al
call fdcgetbyte
donefdcreadwrite:
mov ebx,100
call initPIT
pop word [Sides]
pop word [SectorsPerTrack]
popad
mov al,byte [resultR]
ret
didntfinishfdcreadwrite:
pop dx
pop ecx
pop edi
mov ebx,100
call initPIT
pop word [Sides]
pop word [SectorsPerTrack]
popad
mov al,byte [resultR]
stc
ret

fdcdmatransfer:
pushad
cli
mov al,6
out 0x0a,al
mov al,0
out 0x0c,al
cmp dl,0
jne skipfdcread
mov al,46h
jmp skipfdcwrite
skipfdcread:
mov al,4ah
skipfdcwrite:
out 0x0b,al
mov eax,edi
out 0x04,al
mov al,ah
out 0x04,al
mov eax,edi
shr eax,16
out 0x81,al
mov eax,200h
mul ecx
dec eax
out 0x05,al
mov al,ah
out 0x05,al
mov al,2
out 0x0a,al
sti
popad
ret

fdcseek:
pushad
mov byte [fdcdone],0
mov al,byte [fdccurrenttrack]
;cmp byte [fdctrack],al
;je donefdcseek
mov al,15
call fdcsendbyte
mov al,byte [fdchead]
shl al,2
or al,byte [fdcdrivenum]
call fdcsendbyte
mov al,byte [fdctrack]
mov byte [fdccurrenttrack],al
call fdcsendbyte
call fdcwaitforirq
mov al,8
call fdcsendbyte
call fdcgetbyte
mov ah,al
call fdcgetbyte
donefdcseek:
popad
ret

fdchandler:
pushad
mov byte [fdcdone],1
mov al,0x20
out 0x20,al
popad
iret
fdcdone db 0
fdcmotor db 0
fdchead db 0
fdctrack db 0
fdcsector db 0
fdccurrenttrack db 0
fdcdrivenum db 0
resultR db 0

fddrecalibrate:
pushad
mov byte [fdcdone],0
cmp byte [fdcmotor],1
je skipenablefdcmotor
call fdcmotoron
skipenablefdcmotor:
mov al,7
call fdcsendbyte
mov al,0
call fdcsendbyte
mov byte [fdccurrenttrack],0
call fdcwaitforirq
mov al,8
call fdcsendbyte
call fdcgetbyte
mov ah,al
test al,20h
jz resetpc
call fdcgetbyte
popad
ret

fdcmotoron:
pushad
mov dx,0x3f2
mov al,0x1c
out dx,al
mov eax,10
call pitdelay
mov byte [fdcmotor],1
popad
ret

fdcmotoroff:
pushad
mov dx,0x3f2
mov al,0x0c
out dx,al
mov eax,10
call pitdelay
mov byte [fdcmotor],0
popad
ret

fddreset:
pushad
mov byte [fdcdone],0
mov dx,0x3f2
mov al,8
out dx,al
mov eax,10
call pitdelay
mov dx,0x3f7
mov al,0
out dx,al
mov dx,0x3f2
mov al,0x0c
out dx,al
call fdcwaitforirq
mov ecx,4
loopclearreset:
mov al,8
call fdcsendbyte
call fdcgetbyte
call fdcgetbyte
loop loopclearreset
mov al,3
call fdcsendbyte
mov al,0xdf
call fdcsendbyte
mov al,2
call fdcsendbyte
popad
ret

fdcwaitforirq:
mov ecx,1000000
loopfdcwait:
mov eax,1
call pitdelay
dec ecx
cmp ecx,0
je resetpc
cmp byte [fdcdone],0
je loopfdcwait
donefdcwait:
ret

fdcgetbyte:
push edx
mov eax,1
call pitdelay
waitforokread:
mov dx,0x3f4
in al,dx
and al,0xd0
cmp al,0xd0
jnz waitforokread
mov dx,0x3f5
in al,dx
pop edx
ret

fdcsendbyte:
pushad
push eax
mov eax,1
call pitdelay
waitforokwrite:
mov dx,0x3f4
in al,dx
and al,0xc0
cmp al,80h
jnz waitforokwrite
pop eax
mov dx,0x3f5
out dx,al
popad
ret

patadetect:
mov dx,0x1f6
mov al,0xa0
out dx,al
mov dx,0x1f3
mov al,0x04
out dx,al
in al,dx
cmp al,0x04
jne notdriveone
mov dx,0x1f6
mov al,0xa0
out dx,al
mov dx,0x3f6
in al,dx
in al,dx
in al,dx
in al,dx
mov dx,0x1f4
in al,dx
mov bl,al
mov dx,0x1f5
in al,dx
cmp al,0xeb
je notdriveone
mov al,0
mov esi,1
mov cl,34
mov edi,disk_buffer
mov edx,0
call patareadwritesector
mov esi,disk_buffer
mov edi,efipart
mov ecx,8
repe cmpsb
jne notdriveone
mov byte [idedriveid],1
call findandaddpatapartitions
notdriveone:
mov dx,0x1f6
mov al,0xb0
out dx,al
mov dx,0x1f3
mov al,0x04
out dx,al
in al,dx
cmp al,0x04
jne notdrivetwo
mov dx,0x1f6
mov al,0xb0
out dx,al
mov dx,0x3f6
in al,dx
in al,dx
in al,dx
in al,dx
mov dx,0x1f4
in al,dx
mov bl,al
mov dx,0x1f5
in al,dx
cmp al,0xeb
je notdrivetwo
mov dx,0x1f7
mov al,0xec
out dx,al
in al,dx
push ax
mov dx,0x3f6
mov al,0x04
out dx,al
mov dx,0x1f7
in al,dx
in al,dx
in al,dx
in al,dx
in al,dx
mov dx,0x3f6
mov al,0
out dx,al
pop ax
cmp al,0
je notdrivetwo
and al,00000001b
cmp al,0
jne notdrivetwo
mov al,1
mov esi,1
mov cl,34
mov edi,disk_buffer
mov edx,0
call patareadwritesector
mov esi,disk_buffer
mov edi,efipart
mov ecx,8
repe cmpsb
jne notdrivetwo
mov byte [idedriveid],2
call findandaddpatapartitions
notdrivetwo:
mov dx,0x176
mov al,0xa0
out dx,al
mov dx,0x173
mov al,0x04
out dx,al
in al,dx
cmp al,0x04
jne notdrivethree
mov dx,0x176
mov al,0xa0
out dx,al
mov dx,0x376
in al,dx
in al,dx
in al,dx
in al,dx
mov dx,0x174
in al,dx
mov bl,al
mov dx,0x175
in al,dx
cmp al,0xeb
je notdrivethree
mov dx,0x177
mov al,0xec
out dx,al
in al,dx
push ax
mov dx,0x376
mov al,0x04
out dx,al
mov dx,0x177
in al,dx
in al,dx
in al,dx
in al,dx
in al,dx
mov dx,0x376
mov al,0
out dx,al
pop ax
cmp al,0
je notdrivethree
and al,00000001b
cmp al,0
jne notdrivethree
mov al,2
mov esi,1
mov cl,34
mov edi,disk_buffer
mov edx,0
call patareadwritesector
mov esi,disk_buffer
mov edi,efipart
mov ecx,8
repe cmpsb
jne notdrivethree
mov byte [idedriveid],3
call findandaddpatapartitions
notdrivethree:
mov dx,0x176
mov al,0xb0
out dx,al
mov dx,0x173
mov al,0x04
out dx,al
in al,dx
cmp al,0x04
jne notdrivefour
mov dx,0x176
mov al,0xb0
out dx,al
mov dx,0x376
in al,dx
in al,dx
in al,dx
in al,dx
mov dx,0x174
in al,dx
mov bl,al
mov dx,0x175
in al,dx
cmp al,0xeb
je notdrivefour
mov dx,0x177
mov al,0xec
out dx,al
in al,dx
push ax
mov dx,0x376
mov al,0x04
out dx,al
mov dx,0x177
in al,dx
in al,dx
in al,dx
in al,dx
in al,dx
mov dx,0x376
mov al,0
out dx,al
pop ax
cmp al,0
je notdrivefour
and al,00000001b
cmp al,0
jne notdrivefour
mov al,3
mov esi,1
mov cl,34
mov edi,disk_buffer
mov edx,0
call patareadwritesector
mov esi,disk_buffer
mov edi,efipart
mov ecx,8
repe cmpsb
jne notdrivefour
mov byte [idedriveid],4
call findandaddpatapartitions
notdrivefour:
ret

efipart db 'EFI PART',0
idedriveid db 0
guidpart db 0xA2, 0xA0, 0xD0, 0xEB, 0xE5, 0xB9, 0x33, 0x44, 0x87, 0xC0, 0x68, 0xB6, 0xB7, 0x26, 0x99, 0xC7
fat12str db 'FAT12'
fat16str db 'FAT16'
fat32str db 'FAT32'

findandaddpatapartitions:
mov esi,disk_buffer
add esi,512
mov bx,0
partitiondetectone:
cmp bx,4
je donelooking
mov edi,guidpart
mov ecx,16
repe cmpsb
jne donepartitiondetectone
push esi
push edi
push bx
mov al,byte [idedriveid]
dec al
add esi,10h
mov esi,dword [esi]
mov cl,1
mov edi,disk_buffer
mov edx,0
call patareadwritesector
detectfs:
mov esi,disk_buffer
add esi,36h
mov ecx,5
mov edi,fat12str
repe cmpsb
jne notfat12
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov byte [esi],1
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
notfat12:
mov esi,disk_buffer
add esi,36h
mov ecx,5
mov edi,fat16str
repe cmpsb
jne notfat16
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov byte [esi],1
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
notfat16:
mov esi,disk_buffer
add esi,52h
mov ecx,5
mov edi,fat32str
repe cmpsb
jne notfat32
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov byte [esi],1
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
notfat32:
pop bx
pop edi
pop esi
donepartitiondetectone:
add esi,127
sub edi,16
inc bx
jmp partitiondetectone
donelooking:
ret

patareadwritesector:
pushad
mov dword [edxval],edx
cmp al,2
jge secondaryide
mov dx,0x1f0
jmp doneidecheck
secondaryide:
mov dx,0x170
sub al,2
doneidecheck:
add dx,6
mov ebx,esi
shr ebx,24
or bl,11100000b
cmp al,0
jne secondpatadrive
and bl,11101111b
jmp doneidecheck2
secondpatadrive:
or bl,00010000b
doneidecheck2:
mov al,bl
out dx,al
mov eax,esi
sub dx,4
mov al,cl
out dx,al
inc dx
mov eax,esi
out dx,al
inc dx
mov eax,esi
shr eax,8
out dx,al
inc dx
mov eax,esi
shr eax,16
out dx,al
add dx,2
cmp dword [edxval],0
jne skippataread
mov al,20h
jmp skippatawrite
skippataread:
mov al,30h
mov esi,edi
skippatawrite:
out dx,al
push edx
stillgoing:
in al,dx
test al,8
jz stillgoing
mov eax,256
xor bx,bx
mov bl,cl
mul bx
mov ecx,eax
pop edx
sub edx,7
cmp dword [edxval],0
jne skippataread2
rep insw
jmp skippatawrite2
skippataread2:
rep outsw
mov eax,50
call pitdelay
skippatawrite2:
popad
ret

ahcidetect:
mov eax,0
mov ebx,0
mov ecx,2
ahciprobe:
call pciread
shr edx,16
cmp dx,0x0106
je ahcifound
inc ebx
cmp ebx,256
je ahciprobenextbus
jmp ahciprobe
ahciprobenextbus:
mov ebx,0
inc eax
cmp eax,256
je notfound
jmp ahciprobe
ahcifound:
mov ecx,9
call pciread
mov dword [ahcibase],edx
mov esi,edx
mov eax,0
bts eax,31
mov [esi+0x04],eax
mov edx,[esi+0x0c]
mov ecx,0
ahciportsearch:
cmp ecx,4
je donelookingatports
bt edx,ecx
jnc ahciskipport
mov ebx,ecx
shl ebx,7
add ebx,128h
mov eax,[esi+ebx]
and al,0x0f
cmp al,0x03
jne ahciskipport
pusha
sub ebx,4
mov eax,[esi+ebx]
cmp eax,0xEB140101
je skipatapi
popa
bts dword [ahcipa],ecx
ahciskipport:
inc ecx
jmp ahciportsearch
skipatapi:
popa
inc ecx
jmp ahciportsearch
donelookingatports:
mov edx,[ahcipa]
mov ecx,0
checkactiveports:
cmp ecx,4
je donelookingahciports
bt edx,ecx
jnc ahciskipport2
mov edi,esi
add edi,100h
shl ecx,7
add edi,ecx
shr ecx,7
mov eax,[edi+18h]
btr eax,4
btr eax,0
mov [edi+18h],eax
mov eax,0
mov [edi+38h],eax
mov eax,dword [cmdlist]
shl ecx,10
add eax,ecx
shr ecx,10
stosd
mov eax,0
stosd
mov eax,dword [fis]
shl ecx,12
add eax,ecx
shr ecx,12
stosd
mov eax,0
stosd
stosd
stosd
ahciskipport2:
inc ecx
jmp checkactiveports
donelookingahciports:
mov ecx,0
detectahci:
mov edx,[ahcipa]
cmp ecx,4
je notfound
push ecx
bt edx,ecx
jnc nodrivedetected
mov eax,1
mov edx,ecx
mov ecx,34
mov edi,disk_buffer
call ahcireadwritesector
mov esi,disk_buffer
mov edi,efipart
mov ecx,8
repe cmpsb
jne nodrivedetected
pop ecx
push ecx
mov byte [idedriveid],cl
call detectahcipartitions
nodrivedetected:
pop ecx
inc ecx
jmp detectahci
notfound:
cli
ret
ahcibase dd 0
cmdlist dd 0x4000
fis dd 0x4800
cmdtable dd 0x6800
portnumber dd 0
ahcipa dd 0

detectahcipartitions:
mov esi,disk_buffer
add esi,512
mov bx,0
partitiondetectoneahci:
cmp bx,4
je donelookingahci
mov edi,guidpart
mov ecx,16
repe cmpsb
jne donepartitiondetectoneahci
push esi
push edi
push bx
movzx edx,byte [idedriveid]
add esi,10h
mov esi,dword [esi]
mov eax,esi
mov cl,1
mov edi,disk_buffer
call ahcireadwritesector
inc byte [idedriveid]
detectfsahci:
mov esi,disk_buffer
add esi,36h
mov ecx,5
mov edi,fat12str
repe cmpsb
jne notfat12ahci
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov byte [esi],2
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
notfat12ahci:
mov esi,disk_buffer
add esi,36h
mov ecx,5
mov edi,fat16str
repe cmpsb
jne notfat16ahci
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov byte [esi],2
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
notfat16ahci:
mov esi,disk_buffer
add esi,52h
mov ecx,5
mov edi,fat32str
repe cmpsb
jne notfat32ahci
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov byte [esi],2
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
notfat32ahci:
pop bx
pop edi
pop esi
donepartitiondetectoneahci:
add esi,127
sub edi,16
inc bx
jmp partitiondetectoneahci
donelookingahci:
ret

ahcireadwritesector:
pusha
push eax
push ebx
push ecx
push edx
push esi
push edi
push ecx
push edi
push eax
push eax
bt dword [ahcipa],edx
jnc readerror
mov dword [edxval],edx
and edx,0xff
and dword [edxval],0xff00
shr dword [edxval],8
mov dword [portnumber],edx
mov edi,dword [cmdlist]
shl edx,10
add edi,edx
shr edx,10
mov eax,0x10000
or eax,5
stosd
mov eax,0
stosd
mov eax,dword [cmdtable]
stosd
mov eax,0
stosd
stosd
stosd
stosd
stosd
mov edi,dword [cmdtable]
cmp dword [edxval],0
jne skipahciread
mov eax,0x00258027
jmp skipahciwrite
skipahciread:
mov eax,0x00358027
skipahciwrite:
stosd
pop eax
and eax,0x00ffffff
bts eax,30
stosd
pop eax
shr eax,24
stosd
mov eax,ecx
stosd
mov eax,0
stosd
mov edi,dword [cmdtable]
pop eax
mov dword [edi+0x80],eax
mov eax,0
mov dword [edi+0x80+4],eax
pop eax
shl eax,9
dec eax
mov dword [edi+0x8c],eax
mov ecx,dword [portnumber]
mov esi,dword [ahcibase]
add esi,100h
shl ecx,7
add esi,ecx
shr ecx,7
mov dword [edi+10h],0
mov eax,dword [esi+18h]
bts eax,4
bts eax,0
mov dword [esi+18h],eax
mov dword [esi+38h],1
readloop:
cmp dword [esi+38h],0
jne readloop
mov eax,dword [esi+18h]
btr eax,4
btr eax,0
mov dword [esi+18h],eax
doneahciread:
pop edi
pop esi
pop edx
pop ecx
pop ebx
pop eax
popa
ret
readerror:
pop eax
pop eax
pop edi
pop ecx
pop edi
pop esi
pop edx
pop ecx
pop ebx
pop eax
popa
ret

pciread:
push ebx
push ecx
push eax
shl eax,16
shl ebx,8
shl ecx,2
or eax,ebx
or eax,ecx
and eax,0x00ffffff
or eax,0x80000000
mov dx,0xcf8
out dx,eax
mov dx,0xcfc
in eax,dx
mov edx,eax
pop eax
pop ecx
pop ebx
ret

pciwrite:
push ebx
push ecx
push eax
push edx
shl eax,16
shl ebx,8
shl ecx,2
or eax,ebx
or eax,ecx
and eax,0x00ffffff
or eax,0x80000000
mov dx,0xcf8
out dx,eax
pop edx
mov eax,edx
mov dx,0xcfc
out dx,eax
pop eax
pop ecx
pop ebx
ret

pciwritebyte:
push ebx
push ecx
push eax
push edx
shl eax,16
shl ebx,8
shl ecx,2
or eax,ebx
or eax,ecx
;and eax,0x00ffffff
or eax,0x80000000
mov dx,0xcf8
out dx,eax
pop edx
mov eax,edx
mov dx,0xcfc
mov ebx,ecx
and ebx,0x03
add dx,bx
out dx,al
pop eax
pop ecx
pop ebx
ret


usbdetect:
call ehcidetect
call uhcidetect
call ohcidetect
ret

ehcidetect:
mov eax,0
mov ebx,0
ehciprobe:
mov ecx,2
call pciread
shr edx,16
cmp dx,0x0c03
je ehcifound
notehci:
inc ebx
cmp ebx,255
je ehciprobenextbus
jmp ehciprobe
ehciprobenextbus:
mov ebx,0
inc eax
cmp eax,255
je ehcinotfound
jmp ehciprobe
ehcifound:
pushad
call initehci
otherusbctrlr6:
popad
jmp notehci
ehcinotfound:
ret
otherusbctrlr5:
pop eax
jmp otherusbctrlr6
initehci:
mov ecx,2
call pciread
and edx,0xffff
shr edx,8
cmp edx,20h
jne otherusbctrlr5
mov ecx,1
call pciread
or edx,0x406
mov ecx,1
call pciwrite
mov ecx,4
call pciread
mov dword [eaxval],eax ;note to self try doin a port check before resetting shit
mov dword [ebxval],ebx
and edx,0xffffff00
mov dword [ehcimmio],edx
mov al,byte [edx]
and eax,0xff
add edx,eax
mov dword [ehcioperbase],edx
mov edx,dword [ehcimmio]
add edx,4
mov dword [ehcihcsparams],edx
pushad
mov edx,dword [ehcihcsparams]
mov edx,dword [edx]
and edx,0x0f
mov byte [ehcinumofports],dl
;call ehcidetectportsroothub
popad
add edx,4
mov dword [ehcihccparams],edx
mov edx,dword [ehcimmio]
mov eax,dword [edx+8]
shr eax,8
and eax,0xff
mov ebx,4
mov edx,0
div ebx
mov ecx,eax
;mov edx,dword [ehcioperbase]
;mov eax,dword [edx]
;and eax,0xfffffffe
;mov dword [edx],eax
;waitforehcihalt:
;test dword [edx+4],1000000000000b
;jz waitforehcihalt
mov edx,dword [ehcioperbase]
mov eax,dword [edx]
or eax,2
mov dword [edx],eax
ehciresetloop:
mov eax,dword [edx]
test eax,2
jnz ehciresetloop
mov ebx,dword [ebxval]
mov eax,dword [eaxval]
cmp ecx,10h
jl skipehcitakeoverfrombios
call pciread
or edx,0x1000000
call pciwrite
checktakeover:
call pciread
test edx,0x1000000
jz checktakeover
;inc ecx
;mov edx,0
;call pciwrite
skipehcitakeoverfrombios:
mov edx,dword [ehcihcsparams]
mov edx,dword [edx]
and edx,0x0f
mov byte [ehcinumofports],dl
mov eax,dword [asyncval]
mov dword [tdlocation],eax
mov edi,dword [tdlocation]
mov ecx,16
loopcreateasync:
mov eax,dword [tdlocation]
add eax,100h
or eax,2
stosd
mov eax,0
cmp ecx,16
jne skipreclamation
mov eax,1
shl eax,15
skipreclamation:
mov ebx,2
shl ebx,12
or eax,ebx
stosd
mov eax,1
shl eax,30
stosd
mov eax,3
stosd
stosd
add dword [tdlocation],100h
mov edi,dword [tdlocation]
loop loopcreateasync
sub dword [tdlocation],100h
mov eax,dword [asyncval]
add eax,2
mov edi,dword [tdlocation]
stosd
mov eax,0
mov ebx,2
shl ebx,12
or eax,ebx
stosd
mov eax,1
shl eax,30
stosd
mov eax,3
stosd
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edx,dword [ehcioperbase]
mov dword [edx],0
;mov eax,2000h ;initialize async last!!!!
;mov dword [edx+18h],eax
mov edi,dword [uhciframelist]
mov eax,1
mov ecx,1024
repe stosd
mov eax,dword [asyncval] ;initialize async last!!!!
mov dword [edx+18h],eax
mov edi,dword [uhciframelist]
mov dword [edx+10h],0
mov dword [edx+14h],edi
mov dword [edx+0Ch],0
mov dword [edx+08h],0
mov dword [edx+04h],3fh
mov eax,8
shl eax,16
mov ebx,1
or eax,ebx
mov dword [edx],eax
mov eax,10
call pitdelay
mov edx,dword [ehcioperbase]
or dword [edx+40h],1
mov edx,dword [ehcioperbase]
mov eax,dword [edx] ;initialize async list
or eax,30h
mov dword [edx],eax
waitforasyncstart:
mov edx,dword [ehcioperbase]
mov eax,dword [edx+4]
shr eax,15
and eax,1
cmp eax,1
jne waitforasyncstart
mov edx,dword [ehcihcsparams]
mov eax,1
shl eax,4
and eax,1
test dword [edx],eax
jz skipehcipower
movzx ecx,byte [ehcinumofports]
mov eax,44h
loopportpower:
mov edx,dword [ehcioperbase]
mov ebx,dword [edx+eax]
mov dword [edx+eax],1000h
add eax,4
loop loopportpower
mov eax,10
call pitdelay
skipehcipower:
loopreclamation:
mov edx,dword [ehcioperbase] ;check async pointer register
add edx,4
mov eax,dword [edx]
test eax,2000h
jnz loopreclamation
call ehcidetectportsroothub
skipehci:
add dword [uhciframelist],1000h
add dword [asyncval],5000h
add dword [prevqh],5000h
sub dword [tdval],200h
mov al,3
mov edx,dword [ehcioperbase]
call usbregister
ret
ehcihub:
mov bl,byte [ehcidevaddress]
mov byte [ehcihubaddress],bl
or bl,80h
mov dh,1
mov ch,0
mov eax,hubdescriptor
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov al,byte [102c2h]
mov byte [ehcinumberofhubports],al
mov eax,setconfiguration
mov bl,byte [ehcihubaddress]
mov dh,0
mov ch,0
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov byte [ehcicurrentport],1
ehcihubportreset: ;only 6 ports shown (not 8)
mov al,byte [ehcinumberofhubports]
cmp byte [ehcicurrentport],al
jg ehcidonehubport
mov eax,hubportpowerpacket
mov bl,byte [ehcicurrentport]
mov [eax+4],bl
mov bl,byte [ehcihubaddress]
mov ch,0
mov dh,0
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov eax,hubportresetpacket
mov bl,byte [ehcicurrentport]
mov [eax+4],bl
mov bl,byte [ehcihubaddress]
mov ch,0
mov dh,0
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
resetehcihubport:
mov eax,hubstatus
mov bl,byte [ehcicurrentport]
mov [eax+4],bl
mov bl,byte [ehcihubaddress]
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov eax,dword [102c0h]
mov eax,hubstatus
mov bl,byte [ehcicurrentport]
mov [eax+4],bl
mov bl,byte [ehcihubaddress]
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov eax,dword [102c0h]
test eax,0x0010
jnz resetehcihubport
test eax,1
jz ehcinexthubport
test eax,2
jnz ehcideviceconnectedtohub
ehcidonehubport:
popad
ret
ehcilowspeeddeviceconnectedtohub:
mov al,byte [ehcicurrentport]
mov byte [ehciportnumber],al
mov al,byte [ehcihubaddress]
mov byte [ehcihubnumber],al
mov eax,setup_packet
mov bl,0
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],8
mov byte [ehcieps],1
call ehcicreatetdchain
call ehcicreateqh
mov eax,setdevaddress
inc byte [ehcidevaddress]
movzx bx,byte [ehcidevaddress]
mov word [eax+2],bx
mov bl,0
mov dh,0
mov ch,0
call ehcicreatetdchain
call ehcicreateqh
mov edi,102c0h
mov ecx,32
mov eax,0
repe stosb
mov eax,setup_packet
mov bl,byte [ehcidevaddress]
or bl,80h
mov ch,0
mov dh,1
call ehcicreatetdchain
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
mov eax,7
stosw
pop eax
mov ch,0
;mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
movzx eax,byte [102c2h]
stosw
pop eax
mov ch,0
;mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
cmp byte [102ceh],3
je ehciinithid
jmp ehcinexthubport
ehcideviceconnectedtohub: ;check port val on dell
cmp eax,0x110303
je ehcilowspeeddeviceconnectedtohub
cmp eax,0x110103
je ehcinexthubport
mov byte [ehciportnumber],0
mov eax,setup_packet
mov bl,0
or bl,80h
mov ch,0
mov dh,1
call ehcicreatetdchain
call ehcicreateqh
mov eax,dword [tdlocation]
add eax,8
mov eax,dword [eax]
mov word [X],320
add word [Y],7
mov word [Color],0xffff
call inttostr
mov eax,setdevaddress
inc byte [ehcidevaddress]
movzx bx,byte [ehcidevaddress]
mov word [eax+2],bx
mov bl,0
mov dh,0
mov ch,0
call ehcicreatetdchain
call ehcicreateqh
mov edi,102c0h
mov ecx,32
mov eax,0
repe stosb
mov eax,setup_packet
mov bl,byte [ehcidevaddress]
or bl,80h
mov ch,0
mov dh,1
call ehcicreatetdchain
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
mov eax,7
stosw
pop eax
mov ch,0
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
movzx eax,byte [102c2h]
stosw
pop eax
mov ch,0
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov byte [ehcicomefromhub],1
cmp byte [102ceh],8
je ehciinitmsd
;jmp ehcidonehubport
ehcinexthubport:
mov byte [ehciportnumber],0
mov byte [ehcihubnumber],0
mov byte [ehcieps],2
inc byte [ehcicurrentport]
jmp ehcihubportreset
ehcihubaddress db 0
ehcinumberofhubports db 0
ehciportnumber db 0
ehcihubnumber db 0
ehcieps db 2

ehciinithid:
mov esi,102c0h
add esi,9
cmp byte [esi+7],1
je initehcikeyboard
cmp byte [esi+7],2
je initehcimouse
doneinithidehci:
jmp ehcinexthubport
initehcikeyboard:
call lookforendp
mov edi,kbendp
add esi,2
lodsb
movzx ebx,byte [kbendpcounter]
add edi,ebx
stosb
mov eax,setconfiguration
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,hidgetprotocol
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov eax,hidsetidle
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov eax,hidenablebootprotocol
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov byte [skipehciwaitbyte],0
mov edi,hidkbaddresses
movzx eax,byte [hidkbindex]
add edi,eax
mov al,byte [ehcidevaddress]
stosb
movzx eax,byte [usbcontrollercounter]
stosd
add byte [hidkbindex],2
mov edi,kbframelists
movzx eax,byte [kbendpcounter]
mov ebx,4
mul ebx
add edi,eax
mov eax,dword [uhciframelist]
stosd
mov edi,kbportnums
movzx eax,byte [kbportnumcounter]
mov ebx,2
mul ebx
add edi,eax
mov al,byte [ehciportnumber]
stosb
mov al,byte [ehcihubnumber]
stosb
inc byte [kbportnumcounter]
inc byte [kbendpcounter]
inc byte [uhcihidvals]
jmp doneinithidehci
initehcimouse:
call lookforendp
mov edi,msendp
add esi,2
lodsb
movzx ebx,byte [msendpcounter]
add edi,ebx
stosb
mov eax,setconfiguration
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,hidgetprotocol
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
;mov eax,hidsetidle
;mov bl,byte [ehcidevaddress]
;mov dh,0
;mov ch,0
;mov word [maxlen],8
;call ehcicreatetdchain
;call ehcicreateqh
mov eax,hidenablebootprotocol
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
;mov dword [tdlocation],20380h
;mov eax,usbmousedata
;mov bl,byte [ehcidevaddress] ;shit only executes when it detects user operation
;or bl,80h
;mov edx,ehcimousetoggle
;mov ch,byte [msendp]
;and ch,0x0f
;mov word [maxlen],4
;call ehcicreatetdinterrupt
;call ehcicreateqhinterrupt
;mov eax,10
;call pitdelay
;mov edi,dword [uhciframelist]
;mov eax,1
;mov ecx,1024
;repe stosd
;mov eax,dword [tdval]
;mov dword [tdlocation],eax
mov edi,hidmsaddresses
movzx eax,byte [hidmsindex]
add edi,eax
mov al,byte [ehcidevaddress]
stosb
movzx eax,byte [usbcontrollercounter]
stosd
add byte [hidmsindex],2
mov edi,msframelists
movzx eax,byte [msendpcounter]
mov ebx,4
mul ebx
add edi,eax
mov eax,dword [uhciframelist]
stosd
mov edi,msportnums
movzx eax,byte [msportnumcounter]
mov ebx,2
mul ebx
add edi,eax
mov al,byte [ehciportnumber]
stosb
mov al,byte [ehcihubnumber]
stosb
inc byte [msportnumcounter]
inc byte [msendpcounter]
inc byte [uhcihidvals]
jmp doneinithidehci
kbportnums times 4 dw 0
msportnums times 4 dw 0
kbportnumcounter db 0
msportnumcounter db 0

ehciinitport:
pushad
mov edi,102c0h
mov eax,0
mov ecx,1000
repe stosb
mov eax,dword [tdval] ;could be NULL packet or data toggle
mov dword [tdlocation],eax
mov eax,setup_packet
mov bl,0
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],64
mov word [ehcibytestransferred],18
call ehcicreatetdchain ;check to see if setup packet works
call ehcicreateqh
mov word [ehcibytestransferred],64
mov eax,dword [tdval]
mov dword [tdlocation],eax
mov eax,setdevaddress
inc byte [ehcidevaddress]
movzx bx,byte [ehcidevaddress]
mov word [eax+2],bx
mov bl,0
mov dh,0
mov ch,0
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov eax,dword [tdval]
mov dword [tdlocation],eax
mov edi,102c0h
mov eax,0
mov ecx,1000
repe stosb
mov eax,setup_packet
mov bl,byte [ehcidevaddress]
or bl,80h
mov ch,0
mov dh,1
call ehcicreatetdchain
call ehcicreateqh
cmp byte [102c4h],9
je ehcihub
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
mov eax,7
stosw
pop eax
mov ch,0
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
movzx eax,byte [102c2h]
stosw
pop eax
mov ch,0
mov word [maxlen],64
call ehcicreatetdchain
call ehcicreateqh
mov byte [ehcicomefromhub],0
cmp byte [102ceh],8
je ehciinitmsd
popad
ret

ehciinitmsd:
mov byte [msdbulkouttoggle],0
mov byte [msdbulkintoggle],0
mov bl,byte [ehcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
movzx eax,byte [102c2h]
stosw
pop eax
mov ch,0
mov word [maxlen],64
mov byte [needsixtds],1
call ehcicreatetdchain
call ehcicreateqh
mov eax,dword [tdval]
add eax,8
mov eax,dword [eax] ;try looking at qh
mov word [X],0
add word [Y],7
mov word [Color],0xffff
;call inttostr
mov byte [needsixtds],0
cmp byte [102c4h],1
jne failmsdehci
cmp byte [102ceh],8
jne failmsdehci
cmp byte [102cfh],6
jne failmsdehci
cmp byte [102d0h],50h
jne failmsdehci
mov esi,102d0h
mov ecx,7
mov al,7
call searchforval
mov al,byte [esi+2]
call saveendp
mov esi,102d8h
mov ecx,7
mov al,7
call searchforval
mov al,byte [esi+2]
call saveendp
cmp byte [endp1],0
jz failmsdehci
cmp byte [endp2],0
jz failmsdehci
mov al,byte [esi+2]
call saveendp
cmp byte [endp1],0
jz failmsdehci
cmp byte [endp2],0
jz failmsdehci

mov bl,byte [ehcidevaddress]
mov edi,msdaddresses
movzx ecx,byte [msdindex]
add edi,ecx
mov al,bl
stosb
mov eax,setconfiguration
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov eax,getmaxlun
mov bl,byte [ehcidevaddress]
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov eax,bulkreset
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov eax,bulkreset
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov eax,bulkreset
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov eax,bulkreset
mov bl,byte [ehcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
call ehcicreateqh
mov bl,byte [ehcidevaddress]
mov edx,msdbulkouttoggle
mov ch,byte [endp2]
mov eax,msdinquiry
mov word [maxlen],1fh
call ehcicreatetdio
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov edx,msdbulkintoggle
mov ch,byte [endp1]
and ch,0x0f
mov eax,102c0h
mov word [maxlen],36
call ehcicreatetdio
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov edx,msdbulkintoggle
mov ch,byte [endp1]
and ch,0x0f
mov eax,102c0h
mov word [maxlen],13
call ehcicreatetdio
call ehcicreateqh
mov byte [usbcontrollertype],2
mov bl,byte [ehcidevaddress]
mov byte [devaddress],bl
call msdtestunitready
mov bl,byte [ehcidevaddress]
mov edx,msdbulkouttoggle
mov ch,byte [endp2]
mov eax,requestsensecommand
mov word [maxlen],1fh
call ehcicreatetdio
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov edx,msdbulkintoggle
mov ch,byte [endp1]
and ch,0x0f
mov eax,102c0h
mov word [maxlen],18
call ehcicreatetdio
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov edx,msdbulkintoggle
mov ch,byte [endp1]
and ch,0x0f
mov eax,102c0h
mov word [maxlen],13
call ehcicreatetdio
call ehcicreateqh
mov byte [usbcontrollertype],2
mov bl,byte [ehcidevaddress]
mov byte [devaddress],bl
call msdtestunitready
mov bl,byte [ehcidevaddress]
mov edx,msdbulkouttoggle
mov ch,byte [endp2]
mov eax,msdreadcapacity
mov word [maxlen],1fh
call ehcicreatetdio
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov edx,msdbulkintoggle
mov ch,byte [endp1]
and ch,0x0f
mov eax,102c0h
mov word [maxlen],8
call ehcicreatetdio
call ehcicreateqh
mov bl,byte [ehcidevaddress]
or bl,80h
mov edx,msdbulkintoggle
mov ch,byte [endp1]
and ch,0x0f
mov eax,102c0h
mov word [maxlen],13
call ehcicreatetdio
call ehcicreateqh ;its most likely fullspeed
mov byte [usbcontrollertype],2
movzx edx,byte [msdindex]
mov eax,1
mov ecx,34
mov edi,disk_buffer
call msdreadwritesector
mov eax,dword [tdval]
add eax,8
mov eax,dword [disk_buffer]
mov word [X],0
add word [Y],7
mov word [Color],0xffff
call inttostr
mov esi,disk_buffer
mov edi,efipart
mov ecx,8
repe cmpsb
jne failmsdehci
mov byte [usbcontrollertype],2
mov al,byte [msdindex]
mov byte [idedriveid],al
inc byte [idedriveid]
call detectmsdpartitions
mov edi,msdtoggle
movzx ecx,byte [msdtogglecounter]
add edi,ecx
mov al,byte [msdbulkouttoggle]
stosb
mov al,byte [msdbulkintoggle]
stosb
add byte [msdtogglecounter],2
failmsdehci:
mov byte [fullspeed],0
cmp byte [ehcicomefromhub],1
je ehcinexthubport
popad
ret
ehcicomefromhub db 0

ehcimsdreadin: ;gotta create a td chain not seperate qhs
pushad
mov byte [msdreadinendpt],ch
mov ecx,dword [actrunamt]
loopehcimsdreadin:
push ecx
mov ch,byte [msdreadinendpt]
cmp byte [msdreadorwrite],0
jne skipmsdread5
mov edx,msdbulkintoggle
skipmsdread5:
cmp byte [msdreadorwrite],1
jne skipmsdwrite5
mov edx,msdbulkouttoggle
skipmsdwrite5:
mov eax,dword [edival]
call ehcicreatetdio
call ehcicreateqh
add dword [edival],200h
pop ecx
loop loopehcimsdreadin
popad
ret
msdreadinendpt db 0
tddistancefromqh dd 100h
msdbulkouttoggle db 0
msdbulkintoggle db 0

ehcicreateqh:
pushad
push ebx
add dword [tdlocation],100h
mov edi,dword [tdlocation]
mov eax,1
stosd
mov eax,8
shl eax,28
cmp byte [ehcieps],2
je skipnonhighspeed
mov ebx,1
shl ebx,27
or eax,ebx
skipnonhighspeed:
movzx ebx,word [maxlen]
shl ebx,16
or eax,ebx
mov ebx,1
shl ebx,14
or eax,ebx
movzx ebx,byte [ehcieps] ;fix this for low speed devices
shl ebx,12
or eax,ebx
movzx ebx,ch
shl ebx,8
or eax,ebx
pop ebx
and ebx,0x7f
or eax,ebx
stosd
mov eax,1
shl eax,30
movzx ebx,byte [ehciportnumber]
shl ebx,23
or eax,ebx
movzx ebx,byte [ehcihubnumber]
shl ebx,16
or eax,ebx
stosd
mov eax,dword [tdlocation]
sub eax,dword [tddistancefromqh]
stosd
stosd
mov edi,dword [tdlocation]
mov eax,dword [prevqh] ;FIX THIS FOR MULTIPLE HCs
stosd
mov eax,dword [tdlocation]
mov edi,dword [asyncval]
or eax,2
stosd
cmp dword [tddistancefromqh],100h
jne skipehciwait
sub dword [tdlocation],100h
mov ecx,50
loopehciwait:
cmp byte [skipehciwaitbyte],1
je skipehciwait2
pushad
mov eax,1
call pitdelay
popad
dec ecx
cmp ecx,0
je skipehciwait
skipehciwait2:
mov eax,dword [tdlocation]
mov eax,dword [eax+8]
mov edx,dword [ehcioperbase]
mov edx,dword [edx+4]
cmp al,80h
je loopehciwait
skipehciwait:
popad
ret
prevqh dd 1202h
skipehciwaitbyte db 0

ehcicreatetdinterrupt:
pushad
push eax
mov eax,dword [prevqh]
mov edi,dword [asyncval]
stosd
pop eax
test bl,80h
jnz notehciout4
mov byte [statustoken],0
mov byte [datatoken],0
jmp savedevaddress9
notehciout4:
mov byte [statustoken],1
mov byte [datatoken],1
savedevaddress9:
push eax
mov edi,dword [tdlocation]
mov eax,1
stosd
stosd
movzx eax,word [maxlen]
shl eax,16
movzx ebx,byte [statustoken]
shl ebx,8
or eax,ebx
movzx ebx,byte [edx]
shl ebx,31
or eax,ebx
or eax,80h
stosd
pop eax
stosd
mov eax,0
stosd
stosd
stosd
stosd
stosd
stosd
stosd
stosd
stosd
not byte [edx]
and byte [edx],1
popad
ret
ehcikeyboardtoggle db 0
ehcimousetoggle db 0

ehcicreateqhinterrupt:
pushad
push ebx
add dword [tdlocation],100h
mov edi,dword [tdlocation]
mov eax,1
stosd
mov eax,5
shl eax,28
movzx ebx,word [maxlen]
shl ebx,16
or eax,ebx
mov ebx,1
shl ebx,14
or eax,ebx
mov ebx,1
shl ebx,12
or eax,ebx
movzx ebx,ch
shl ebx,8
or eax,ebx
pop ebx
and ebx,0x7f
or eax,ebx
stosd
mov eax,3
shl eax,30
movzx ebx,byte [ehciportnumber]
shl ebx,23
or eax,ebx
movzx ebx,byte [ehcihubnumber]
shl ebx,16
or eax,ebx
mov ebx,0x1c
shl ebx,8
or eax,ebx
or eax,1
stosd
mov eax,dword [tdlocation]
sub eax,dword [tddistancefromqh]
stosd
stosd
mov eax,0
mov ecx,12
repe stosd
mov edi,dword [uhciframelist]
mov eax,dword [tdlocation]
or eax,2
push eax
mov eax,1024
movzx ecx,byte [uhcihidvals]
mov edx,0
div ecx
xchg eax,ecx
pop eax
loopframeehci:
stosd
sub edi,4
push eax
mov eax,4
movzx ebx,byte [uhcihidvals]
mul ebx
add edi,eax
pop eax
loop loopframeehci
sub dword [tdlocation],100h
popad
ret

ehcicreatetdio:
pushad
test bl,80h
jnz notehciout3
mov byte [statustoken],0
mov byte [datatoken],0
jmp savedevaddress8
notehciout3:
mov byte [statustoken],1
mov byte [datatoken],1
savedevaddress8:
push eax
mov edi,dword [tdlocation]
mov eax,1
stosd
stosd
movzx eax,word [maxlen]
shl eax,16
mov ebx,3
shl ebx,10
or eax,ebx
movzx ebx,byte [statustoken]
shl ebx,8
or eax,ebx
;and eax,0xfffff3ff
movzx ebx,byte [edx]
shl ebx,31
or eax,ebx
or eax,80h
stosd
pop eax
stosd
add eax,1000h
and eax,0xfffff3ff
stosd
add eax,1000h
stosd
add eax,1000h
stosd
add eax,1000h
stosd
mov eax,0
stosd
stosd
stosd
stosd
stosd
not byte [edx]
and byte [edx],1
popad
ret


ehcicreatetdchain:
pushad
test bl,80h
jnz notehciout2
mov byte [statustoken],0
mov byte [datatoken],0
jmp savedevaddress7
notehciout2:
mov byte [statustoken],1
mov byte [datatoken],1
savedevaddress7:
push eax
mov edi,dword [tdlocation]
mov eax,edi
add eax,64
stosd
mov eax,1
stosd
mov eax,8
shl eax,16
mov ebx,3
shl ebx,10
or eax,ebx
mov ebx,2
shl ebx,8
or eax,ebx
;and eax,0xfffff3ff
or eax,80h
stosd
pop eax
stosd
add eax,1000h
and eax,0xfffff000
stosd
add eax,1000h
stosd
add eax,1000h
stosd
add eax,1000h
stosd
mov eax,0
stosd
stosd
stosd
stosd
stosd
cmp dh,0
je ehciskipsecondtd
add edi,0ch ;Make EDI = 20040h
mov eax,dword [tdlocation]
add eax,80h
stosd
mov eax,1
stosd
movzx eax,word [ehcibytestransferred]
shl eax,16
mov ebx,3
shl ebx,10
or eax,ebx
movzx ebx,byte [statustoken]
shl ebx,8
or eax,ebx
mov ebx,1
shl ebx,31
or eax,ebx
;and eax,0xfffff3ff
or eax,80h
stosd
mov eax,102c0h
stosd
add eax,1000h
and eax,0xfffff000
stosd
add eax,1000h
stosd
add eax,1000h
stosd
add eax,1000h
stosd
mov eax,0
stosd
stosd
stosd
stosd
stosd
ehciskipsecondtd:
add edi,0ch
mov eax,1
stosd
stosd
mov eax,3
shl eax,10 ;change if dh=0
cmp dh,0
jne skipehcinullin
mov ebx,1
shl ebx,8
or eax,ebx
skipehcinullin:
mov ebx,1
shl ebx,31
or eax,ebx
or eax,80h
stosd
mov eax,0
stosd
add eax,1000h
and eax,0xfffff000
stosd
add eax,1000h
stosd
add eax,1000h
stosd
mov eax,0
stosd
stosd
stosd
stosd
stosd
skipallehci:
popad
ret

ehcidetectportsroothub: ;INCREMENT TDLOCATION AND OTHER CRAP FOR OTHER HC
call detectuhciorohci
jnc skipsetcompanion
mov byte [ehcihascompanions],1
skipsetcompanion:
movzx ecx,byte [ehcinumofports]
mov eax,44h
loopportreset:
mov edx,dword [ehcioperbase]
mov ebx,dword [edx+eax]
test ebx,1
jz skipstayonehciport
shr ebx,10
and ebx,3
test ebx,1
jz skippasstocompanion
setporttocompanion:
cmp byte [ehcihascompanions],0
je skippasstocompanion
mov dword [edx+eax],3000h
;call ehciinitport
jmp skipstayonehciport
skippasstocompanion:
mov ebx,dword [edx+eax]
or ebx,1000h
mov dword [edx+eax],ebx
and ebx,0xFFFFFFFB
or ebx,256
mov dword [edx+eax],ebx
pushad
mov eax,5
call pitdelay
popad
and ebx,0xFFFFFEFF
mov dword [edx+eax],ebx
;test dword [edx+eax],100b
;jz setporttocompanion
mov dword [edx+eax],1000h
pushad
mov eax,1
call pitdelay
popad
call displayvalport
call ehciinitport
skipstayonehciport:
add eax,4
dec ecx
cmp ecx,0
jne loopportreset
add word [Y],20
mov eax,10
call pitdelay
ret
ehcimmio dd 0
ehcioperbase dd 0
ehcihcsparams dd 0
ehcihccparams dd 0
ehcinumofports db 0
ehcidevaddress db 0
ehcihascompanions db 0
ehcicurrentport db 0
ehcibulktoggle db 0
ehcibytestransferred dw 32
asyncval dd 1100h
tdval dd 20000h

displayvalport:
pushad
mov edx,dword [ehcioperbase]
mov eax,dword [edx+eax]
mov word [X],0
add word [Y],7
mov word [Color],0xffff
call inttostr
popad
ret

detectuhciorohci:
mov eax,0
mov ebx,0
ohciprobe2:
mov ecx,2
call pciread
shr edx,16
cmp dx,0x0c03
je ohcifound2
notohci2:
inc ebx
cmp ebx,255
je ohciprobenextbus2
jmp ohciprobe2
ohciprobenextbus2:
mov ebx,0
inc eax
cmp eax,255
je ohcinotfound2
jmp ohciprobe2
ohcifound2:
mov ecx,2
call pciread
and edx,0xffff
shr edx,8
cmp edx,10h
jne notohci2
stc
ret
ohcinotfound2:
clc
mov eax,0
mov ebx,0
uhciprobe2:
mov ecx,2
call pciread
shr edx,16
cmp dx,0x0c03
je uhcifound2
notuhci6:
inc ebx
cmp ebx,255
je uhciprobenextbus2
jmp uhciprobe2
uhciprobenextbus2:
mov ebx,0
inc eax
cmp eax,255
je uhcinotfound2
jmp uhciprobe2
uhcifound2:
mov ecx,2
call pciread
and edx,0xffff
shr edx,8
cmp edx,0
jne notuhci6
stc
ret
uhcinotfound2:
clc
ret

ohcidetect:
mov eax,0
mov ebx,0
ohciprobe:
mov ecx,2
call pciread
shr edx,16
cmp dx,0x0c03
je ohcifound
notohci:
inc ebx
cmp ebx,255
je ohciprobenextbus
jmp ohciprobe
ohciprobenextbus:
mov ebx,0
inc eax
cmp eax,255
je ohcinotfound
jmp ohciprobe
ohcifound:
pushad
call initohci
otherusbctrlr4:
popad
jmp notohci
ohcinotfound:
ret
otherusbctrlr3:
pop eax
jmp otherusbctrlr4
initohci:
mov ecx,2
call pciread
and edx,0xffff
shr edx,8
cmp edx,10h
jne otherusbctrlr3
mov ecx,1
call pciread
or edx,0x406
mov ecx,1
call pciwrite
mov ecx,4
call pciread
mov dword [ohcimmio],edx
mov edi,edx
mov edx,dword [edi]
and edx,0xff
cmp edx,10h
jne failohci
mov edx,dword [ohcimmio]
mov dword [edx+8],8
mov eax,1
call pitdelay
mov edx,dword [ohcimmio]
mov eax,dword [edx+34h]
mov dword [frameinterval],eax
mov edx,dword [ohcimmio]
mov dword [edx+8],1
ohcireset:
mov edx,dword [ohcimmio]
test dword [edx+8],1
jnz ohcireset
mov dword [edx+14h],0xc000007f
mov dword [edx+0ch],0x0000007f
mov eax,dword [frameinterval]
cmp eax,0
je setdefaultinterval
mov dword [edx+34h],eax
setdefaultinterval:
mov eax,2edfh
mov edx,dword [ohcimmio]
mov dword [edx+34h],eax
mov edx,dword [ohcimmio]
mov eax,[edx+4]
and eax,0xffffff3f
or eax,80h
mov [edx+4],eax
mov eax,1
call pitdelay
mov edx,dword [ohcimmio]
mov eax,[edx+50h]
or eax,10000h
mov [edx+50h],eax
mov eax,1
call pitdelay
mov edx,dword [ohcimmio]
mov eax,dword [edx+48h]
and eax,0x0f
mov byte [numofports],al
mov byte [currentportohci],0
portloop:
mov al,byte [currentportohci]
cmp al,byte [numofports]
jge doneports
movzx edx,byte [currentportohci]
shl edx,2
add edx,54h
add edx,dword [ohcimmio]
or dword [edx],100h
mov eax,1
call pitdelay
or dword [edx],10h
portreset:
test dword [edx],10h
jnz portreset
or dword [edx],2
mov eax,1
call pitdelay
inc byte [currentportohci]
jmp portloop
doneports:
mov byte [currentportohci],0
portdetectdevices:
mov al,byte [currentportohci]
cmp al,byte [numofports]
jge doneportsdetect
mov edx,dword [ohcimmio]
add edx,54h
movzx eax,byte [currentportohci]
shl eax,2
add edx,eax
or dword [edx],100h
mov eax,1
call pitdelay
or dword [edx],10h
portreset2:
test dword [edx],10h
jnz portreset2
or dword [edx],2
mov eax,1
call pitdelay
mov edx,[edx]
mov dword [currentportstatusregister],edx
test edx,1
jz donedetectdevices
mov bl,0
or bl,80h
mov ch,0
mov dh,1
mov byte [fullspeed],0
mov eax,setup_packet
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
mov eax,setdevaddress
movzx bx,byte [ohcidevaddress]
mov word [eax+2],bx
mov bl,0
mov ch,0
mov dh,0
mov byte [fullspeed],0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
mov edi,102c0h
mov ecx,18
mov al,0
repe stosb
mov bl,byte [ohcidevaddress]
or bl,80h
mov ch,0
mov dh,1
mov byte [fullspeed],0
mov eax,setup_packet
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
cmp byte [102c4h],9
je ohcihub
call ohciinitmsd
inc byte [ohcidevaddress]
donedetectdevices:
inc byte [currentportohci]
jmp portdetectdevices
doneportsdetect:
mov al,2
mov edx,dword [ohcimmio]
call usbregister
ret
ohcihub:
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,0
mov eax,hubdescriptor
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
mov al,byte [102c2h]
mov byte [numberofhubports],al
mov eax,enablelocalpower
mov bl,byte [ohcidevaddress]
mov ch,0
mov dh,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
mov byte [currentport],1
ohcihubportreset:
mov al,byte [numberofhubports]
cmp byte [currentport],al
jg ohcidonehubport
mov eax,hubportresetpacket
mov bl,byte [currentport]
mov [eax+4],bl
mov bl,byte [ohcidevaddress]
mov ch,0
mov dh,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
resetohcihubport:
mov eax,hubstatus
mov bl,byte [currentport]
mov [eax+4],bl
mov bl,byte [ohcidevaddress]
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
mov eax,dword [102c0h]
mov eax,hubstatus
mov bl,byte [currentport]
mov [eax+4],bl
mov bl,byte [ohcidevaddress]
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
mov eax,dword [102c0h]
test eax,0x0010
jnz resetohcihubport
test eax,1
jz ohcinexthubport
test eax,2
jnz ohcideviceconnectedtohub
ohcidonehubport:
jmp donedetectdevices
ohcideviceconnectedtohub:
mov bl,0
or bl,80h
mov dh,1
mov ch,0
mov eax,setup_packet
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
mov eax,setdevaddress
inc byte [ohcidevaddress]
movzx bx,byte [ohcidevaddress]
mov word [eax+2],bx
mov bl,0
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc donedetectdevices
mov eax,1
call pitdelay
mov eax,dword [102c4h]
call ohciinitmsd
ohcinexthubport:
inc byte [currentport]
jmp ohcihubportreset
failohci:
ret

ohciinitmsd:
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
mov eax,7
stosw
pop eax
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc failmsdohci
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
movzx eax,byte [102c2h]
stosw
pop eax
mov ch,0
mov word [maxlen],7
mov byte [needsixtds],1
call ohcicreatetdchain
call ohcicreateedandsend
jc failmsdohci
cmp byte [102ceh],3
je ohciinithid
cmp byte [102c4h],1
jne failmsdohci
cmp byte [102ceh],8
jne failmsdohci
cmp byte [102cfh],6
jne failmsdohci
cmp byte [102d0h],50h
jne failmsdohci
mov esi,102d0h
mov ecx,7
mov al,7
call searchforval
mov al,byte [esi+2]
call saveendp
mov esi,102d8h
mov ecx,7
mov al,7
call searchforval
mov al,byte [esi+2]
call saveendp
cmp byte [endp1],0
jz failmsd
cmp byte [endp2],0
jz failmsd
mov al,byte [esi+2]
call saveendp
cmp byte [endp1],0
jz failmsdohci
cmp byte [endp2],0
jz failmsdohci
mov edi,msdendp
movzx ecx,byte [msdendpcounter]
add edi,ecx
and byte [endp1],0x0f
mov al,byte [endp1]
stosb
mov al,byte [endp2]
stosb
add byte [msdendpcounter],2
mov bl,byte [ohcidevaddress]
mov edi,msdaddresses
;movzx eax,byte [usbcontrollercounter]
;mov ecx,4
;mul ecx
;add edi,eax
movzx ecx,byte [msdindex]
add edi,ecx
mov al,bl
stosb
mov bl,byte [ohcidevaddress]
mov edi,msdaddresses
movzx ecx,byte [msdindex]
add edi,ecx
mov al,bl
stosb
mov eax,setconfiguration
mov bl,byte [ohcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
jc failmsdohci
mov bl,byte [ohcidevaddress]
mov dh,1
mov ch,byte [endp2]
mov byte [fullspeed],1
mov eax,msdinquiry
mov word [maxlen],1eh
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,byte [endp1]
mov byte [fullspeed],1
mov eax,102c0h
mov word [maxlen],36
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,byte [endp1]
mov byte [fullspeed],1
mov eax,102c0h
mov word [maxlen],13
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov byte [usbcontrollertype],1
mov bl,byte [ohcidevaddress]
mov byte [devaddress],bl
call msdtestunitready
mov bl,byte [ohcidevaddress]
mov dh,1
mov ch,byte [endp2]
mov byte [fullspeed],1
mov eax,requestsensecommand
mov word [maxlen],1eh
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,byte [endp1]
mov byte [fullspeed],1
mov eax,102c0h
mov word [maxlen],18
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,byte [endp1]
mov byte [fullspeed],1
mov eax,102c0h
mov word [maxlen],13
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov byte [usbcontrollertype],1
mov bl,byte [ohcidevaddress]
mov byte [devaddress],bl
call msdtestunitready
mov bl,byte [ohcidevaddress]
mov dh,1
mov ch,byte [endp2]
mov byte [fullspeed],1
mov eax,msdreadcapacity
mov word [maxlen],1eh
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,byte [endp1]
mov byte [fullspeed],1
mov eax,102c0h
mov word [maxlen],8
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,byte [endp1]
mov byte [fullspeed],1
mov eax,102c0h
mov word [maxlen],13
mov byte [bulkorcontrol],1
call ohcicreatetdio
call ohcicreateedandsend
jc failmsdohci
mov byte [usbcontrollertype],1
movzx edx,byte [msdindex]
mov eax,1
mov ecx,34
mov edi,disk_buffer
call msdreadwritesector
mov esi,disk_buffer
mov edi,efipart
mov ecx,8
repe cmpsb
jne failmsdohci
mov byte [usbcontrollertype],1
mov al,byte [msdindex]
mov byte [idedriveid],al
inc byte [idedriveid]
call detectmsdpartitions
mov edi,msdtoggle
movzx ecx,byte [msdtogglecounter]
add edi,ecx
mov al,byte [msdbulkouttoggle]
stosb
mov al,byte [msdbulkintoggle]
stosb
add byte [msdtogglecounter],2
failmsdohci:
ret
resetpc:
mov al,0xfe
out 0x64,al
jmp 0xffff:0000h

usbcontrollertype db 0
ohcimmio dd 0
frameinterval dd 0
numofports db 0
currentportohci db 0
ohcidevaddress db 1
bulkorcontrol db 0
listenable db 0
currentportstatusregister dd 0
ohcicounter dw 0
endpointdescriptorloc dd endpointdescriptor
align 16
endpointdescriptor times 4 dd 0
align 16
ohcihcca dd 0
align 256
hcca times 256 db 0

ohcicreatetdio:
test bl,80h
jnz notuhciout3
mov byte [statustoken],1
mov byte [datatoken],1
jmp savedevaddress4
notuhciout3:
mov byte [statustoken],2
mov byte [datatoken],2
savedevaddress4:
pushad
mov edi,td
push eax
movzx eax,byte [statustoken]
shl eax,19
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
mov ebx,7
shl ebx,21
or eax,ebx
stosd
pop eax
push eax
stosd
mov eax,0xf000000
stosd
pop eax
movzx ebx,word [maxlen]
add eax,ebx
stosd
mov eax,0
stosd
stosd
stosd
stosd
popad
ret

ohcicreateedandsend:
not byte [fullspeed]
and byte [fullspeed],1
mov edi,dword [endpointdescriptorloc]
and bl,7fh
movzx eax,bl
movzx ebx,ch
shl ebx,7
or eax,ebx
movzx ebx,byte [fullspeed]
shl ebx,13
or eax,ebx
movzx ebx,byte [maxlen]
inc ebx
shl ebx,16
or eax,ebx
stosd
mov eax,0xf000000
stosd
mov eax,td
stosd
mov eax,dword [ohcinextep]
stosd
skipedcreation:
mov edx,dword [ohcimmio]
mov eax,dword [edx+4]
and eax,0xffffffef
mov dword [edx+4],eax
mov dword [ohcihcca],hcca
mov edi,hcca
mov ecx,256
mov al,0
repe stosb
mov eax,dword [ohcihcca]
mov edx,dword [ohcimmio]
mov dword [edx+18h],eax
mov edx,dword [ohcimmio]
mov eax,dword [endpointdescriptorloc]
cmp byte [bulkorcontrol],1
je bulkregister
mov dword [edx+20h],eax
mov dword [edx+24h],0
jmp skipbulkregister
bulkregister:
mov dword [edx+28h],eax
mov dword [edx+2ch],0
skipbulkregister:
mov eax,dword [edx+8]
cmp byte [bulkorcontrol],1
je bulklist
or eax,10b
mov byte [listenable],10b
jmp skipbulklist
bulklist:
or eax,100b
mov byte [listenable],100b
skipbulklist:
mov dword [edx+8],eax
mov edx,dword [ohcimmio]
mov eax,dword [edx+4]
cmp byte [bulkorcontrol],1
je bulkenable
or eax,10000b
jmp skipbulkenable
bulkenable:
or eax,100000b
skipbulkenable:
and eax,0xffffff3f
or eax,80h
mov dword [edx+4],eax
mov word [ohcicounter],0
ohciwait:
cmp byte [skipdelay],1
je skipendpdescdelay
pushad
mov eax,1
call pitdelay
popad
skipendpdescdelay:
inc word [ohcicounter] ;NO LOOP DURING INTERRUPT!!!
cmp word [ohcicounter],4096
je errorohcisend
mov eax,dword [edx+8]
mov ebx,dword [edx+4]
cmp eax,ebx
je doneohcisend
mov edx,dword [ohcimmio]
mov eax,dword [edx+8]
movzx ebx,byte [listenable]
test eax,ebx
jz doneohcisend
;cmp byte [skipdelay],1
;je doneohcisend
jmp ohciwait
doneohcisend:
mov edx,dword [ohcimmio]
mov eax,dword [edx+4]
cmp byte [bulkorcontrol],1
je bulkclear
and eax,0xffffffef
jmp skipbulkclear
bulkclear:
and eax,0xffffffdf
skipbulkclear:
;mov dword [edx+4],eax
;mov dword [edx+0ch],7fh
cmp byte [skipdelay],1
je skipendpdescdelay2
mov eax,2
call pitdelay
skipendpdescdelay2:
clc
mov byte [bulkorcontrol],0
mov dword [endpointdescriptorloc],endpointdescriptor
mov byte [skipdelay],0
mov dword [ohcinextep],0
ret
errorohcisend:
mov edx,dword [ohcimmio]
mov eax,dword [edx+4]
cmp byte [bulkorcontrol],1
je bulkclear2
and eax,0xffffffef
jmp skipbulkclear2
bulkclear2:
and eax,0xffffffdf
skipbulkclear2:
mov dword [edx+4],eax
mov dword [edx+0ch],7fh
stc
mov byte [bulkorcontrol],0
mov dword [endpointdescriptorloc],endpointdescriptor
mov byte [skipdelay],0
ret
skipdelay db 0

ohcicreatetdchain:
pushad
test bl,80h
jnz notohciout2
mov byte [statustoken],1
mov byte [datatoken],1
jmp savedevaddress3
notohciout2:
mov byte [statustoken],2
mov byte [datatoken],2
savedevaddress3:
mov edi,td
push eax
mov eax,0
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
mov ebx,7
shl ebx,21
or eax,ebx
stosd
pop eax
push eax
stosd
mov eax,td2
stosd
pop eax
movzx ebx,word [maxlen]
add eax,ebx
stosd
mov eax,0
stosd
stosd
stosd
stosd
cmp dh,0
je ohcinodata
mov edi,td2
movzx eax,byte [statustoken]
shl eax,19
mov ebx,3
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
stosd
mov eax,bufferpointer
stosd
mov eax,td3
stosd
mov eax,bufferpointer
movzx ebx,word [maxlen]
add eax,ebx
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,td3
movzx eax,byte [statustoken]
shl eax,19
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
stosd
mov eax,bufferpointer
add eax,8
stosd
mov eax,td4
stosd
mov eax,bufferpointer
add eax,8
movzx ebx,word [maxlen]
add eax,ebx
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,td4
movzx eax,byte [statustoken]
shl eax,19
mov ebx,3
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
stosd
mov eax,bufferpointer
add eax,16
stosd
mov eax,td5
stosd
mov eax,bufferpointer
add eax,16
movzx ebx,word [maxlen]
add eax,ebx
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,td5
movzx eax,byte [statustoken]
shl eax,19
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
stosd
mov eax,bufferpointer
add eax,24
stosd
mov eax,td6
stosd
mov eax,bufferpointer
add eax,24
movzx ebx,word [maxlen]
add eax,ebx
stosd
mov eax,0
stosd
stosd
stosd
stosd
ohcinodata:
mov eax,2
shl eax,19
mov ebx,3
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
stosd
mov eax,0
stosd
mov eax,0xf000000
stosd
mov eax,0
stosd
stosd
stosd
stosd
stosd
popad
mov byte [td6offset],16
ret

ohcimsdreadin:
pushad
mov ecx,dword [actrunamt]
mov edi,dword [tdlocation]
ohcimsdreadinloop:
cmp byte [msdreadorwrite],0
jne skipmsdread8
mov eax,2
skipmsdread8:
cmp byte [msdreadorwrite],1
jne skipmsdwrite8
mov eax,1
skipmsdwrite8:
shl eax,19
mov ebx,14
shl ebx,28
or eax,ebx
mov ebx,7
shl ebx,21
or eax,ebx
stosd
mov eax,dword [edival]
stosd
cmp ecx,1
jne notfinalin
mov eax,0xf000000
jmp skipnotfinalin
notfinalin:
add dword [tdlocation],20h
mov eax,dword [tdlocation]
skipnotfinalin:
stosd
mov eax,dword [edival]
add eax,1ffh
stosd
mov eax,0
stosd
stosd
stosd
stosd
add dword [edival],200h
loop ohcimsdreadinloop
popad
mov dword [tdlocation],20000h
mov edi,dword [endpointdescriptorloc]
and bl,7fh
movzx eax,bl
movzx ebx,ch
shl ebx,7
or eax,ebx
mov ebx,32
shl ebx,16
or eax,ebx
stosd
mov eax,0xf000000
stosd
mov eax,20000h
stosd
mov eax,0
stosd
jmp skipedcreation

ohciinithid:
mov esi,102c0h
add esi,9
cmp byte [esi+7],1
je initohcikeyboard
cmp byte [esi+7],2
je initohcimouse
doneinithidohci:
ret
initohcimouse:
mov bl,byte [ohcidevaddress]
call ohcicreatehidconfigsetup
mov eax,102e0h
mov ecx,8
loopreadconfigdescmsohci:
push eax
push ecx
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdio
call ohcicreateedandsend
pop ecx
pop eax
add eax,8
loop loopreadconfigdescmsohci
call lookforendp
mov edi,msendp
add esi,2
lodsb
movzx ebx,byte [msendpcounter]
add edi,ebx
stosb
mov eax,setconfiguration
mov bl,byte [ohcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,setconfiguration
mov bl,byte [ohcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,hidgetprotocol
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,hidsetidle
mov bl,byte [ohcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,hidenablebootprotocol
mov bl,byte [ohcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,usbmousedata
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,0
mov ch,byte [msendp]
and ch,0x0f
mov word [maxlen],3
mov byte [fullspeed],0
mov byte [bulkorcontrol],1
call ohcicreatetdinterrupt
mov edi,hidmsaddresses
movzx eax,byte [hidmsindex]
add edi,eax
mov al,byte [ohcidevaddress]
stosb
movzx eax,byte [usbcontrollercounter]
stosd
add byte [hidmsindex],2
jmp doneinithidohci
initohcikeyboard:
mov bl,byte [ohcidevaddress]
call ohcicreatehidconfigsetup
mov eax,102e0h
mov ecx,8
loopreadconfigdesckeybohci:
push eax
push ecx
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdio
call ohcicreateedandsend
pop ecx
pop eax
add eax,8
loop loopreadconfigdesckeybohci
call lookforendp
mov edi,kbendp
add esi,2
lodsb
movzx ebx,byte [kbendpcounter]
add edi,ebx
stosb
mov eax,setconfiguration
mov bl,byte [ohcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,hidgetprotocol
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,1
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,hidsetidle
mov bl,byte [ohcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,hidenablebootprotocol
mov bl,byte [ohcidevaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call ohcicreatetdchain
call ohcicreateedandsend
mov eax,usbkeyboarddata
mov bl,byte [ohcidevaddress]
or bl,80h
mov dh,0
mov ch,byte [kbendp]
and ch,0x0f
mov word [maxlen],7
mov byte [fullspeed],0
mov byte [bulkorcontrol],1
call ohcicreatetdinterrupt
mov edi,hidkbaddresses
movzx eax,byte [hidkbindex]
add edi,eax
mov al,byte [ohcidevaddress]
stosb
movzx eax,byte [usbcontrollercounter]
stosd
add byte [hidkbindex],2
jmp doneinithidohci
ohcicreatehidconfigsetup:
mov word [maxlen],7
push ebx
mov edi,td
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
mov ebx,7
shl ebx,21
or eax,ebx
stosd
mov eax,getconfigdescriptor
stosd
mov eax,0xf000000
stosd
mov eax,getconfigdescriptor
add eax,7
stosd
mov eax,0
stosd
stosd
stosd
stosd
pop ebx
mov ch,0
mov byte [fullspeed],0
call ohcicreateedandsend
ret

ohcicreatetdinterrupt:
pushad
test bl,80h
jnz notohciout4
mov byte [statustoken],1
mov byte [datatoken],1
jmp savedevaddress6
notohciout4:
mov byte [statustoken],2
mov byte [datatoken],2
savedevaddress6:
mov edi,dword [tdlocation]
push eax
movzx eax,byte [statustoken]
shl eax,19
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
mov ebx,7
shl ebx,21
or eax,ebx
stosd
pop eax
push eax
stosd
mov eax,0xf000000
stosd
pop eax
movzx ebx,word [maxlen]
add eax,ebx
stosd
mov eax,0
stosd
stosd
stosd
stosd
popad
not byte [fullspeed]
and byte [fullspeed],1
mov edi,dword [endpointdescriptorloc]
and bl,7fh
movzx eax,bl
movzx ebx,ch
shl ebx,7
or eax,ebx
movzx ebx,byte [fullspeed]
shl ebx,13
or eax,ebx
movzx ebx,byte [maxlen]
inc ebx
shl ebx,16
or eax,ebx
stosd
mov eax,0xf000000
stosd
mov eax,dword [tdlocation]
stosd
mov eax,0
stosd
jmp skipedcreation

uhcidetect:
mov eax,0
mov ebx,0
uhciprobe:
mov ecx,2
call pciread
shr edx,16
cmp dx,0x0c03
je uhcifound
notuhci:
inc ebx
cmp ebx,255
je uhciprobenextbus
jmp uhciprobe
uhciprobenextbus:
mov ebx,0
inc eax
cmp eax,255
je uhcinotfound
jmp uhciprobe
uhcifound:
pushad
call inituhci
otherusbctrlr2:
popad
jmp notuhci
uhcinotfound:
ret
otherusbctrlr:
pop eax
jmp otherusbctrlr2
inituhci:
mov ecx,2
call pciread
and edx,0xffff
shr edx,8
cmp edx,0
jne otherusbctrlr
mov ecx,8
call pciread
and dx,0xfffc
mov word [uhcibase],dx
mov ecx,1
call pciread
or edx,0x5
mov ecx,1
call pciwrite
mov ax,4
mov dx,word [uhcibase]
out dx,ax
mov eax,5
call pitdelay
mov ax,2
mov dx,word [uhcibase]
out dx,ax
mov eax,5
call pitdelay
mov ax,0
mov dx,word [uhcibase]
out dx,ax
add dx,2
out dx,ax
add dx,2
out dx,ax
add dx,2
out dx,ax
mov edi,dword [uhciframelist]
mov ecx,1024
mov eax,1
repe stosd
mov dx,word [uhcibase]
add dx,8
mov eax,dword [uhciframelist]
out dx,eax
add dx,4
mov al,0x40
out dx,al
in al,dx
cmp al,40h
jne doneuhciinit
mov dx,word [uhcibase]
add dx,10h
in ax,dx
or ax,1000000000b
push ax
out dx,ax
mov eax,5
call pitdelay
pop ax
and ax,1111110111111111b
push ax
out dx,ax
mov eax,1
call pitdelay
pop ax
or ax,1110b
out dx,ax
mov eax,10
call pitdelay
mov dx,word [uhcibase]
add dx,10h
in ax,dx
mov dx,word [uhcibase]
add dx,12h
in ax,dx
or ax,1000000000b
push ax
out dx,ax
mov eax,5
call pitdelay
pop ax
and ax,1111110111111111b
push ax
out dx,ax
mov eax,1
call pitdelay
pop ax
or ax,1110b
out dx,ax
mov eax,5
call pitdelay
mov dx,word [uhcibase]
mov ax,1
out dx,ax
mov eax,5
call pitdelay
mov dx,word [uhcibase]
add dx,12h
in ax,dx
mov dx,word [uhcibase]
add dx,10h
in ax,dx
or ax,1000000000b
push ax
out dx,ax
mov eax,5
call pitdelay
pop ax
and ax,1111110111111111b
push ax
out dx,ax
mov eax,1
call pitdelay
pop ax
or ax,1110b
out dx,ax
mov eax,5
call pitdelay
mov dx,word [uhcibase]
add dx,10h
in ax,dx
mov byte [uhcicounter],1
looper:
mov edi,102c0h
mov eax,0
mov ecx,10
repe stosd
mov bl,0
or bl,80h
mov dh,1
mov ch,0
mov eax,setup_packet
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc timeout
mov eax,setdevaddress
movzx bx,byte [devaddress]
mov word [eax+2],bx
mov bl,0
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc timeout
cmp byte [uhcicounter],0
je skipportreset
mov dx,word [uhcibase]
add dx,12h
in ax,dx
or ax,1000000000b
push ax
out dx,ax
mov eax,5
call pitdelay
pop ax
and ax,1111110111111111b
push ax
out dx,ax
mov eax,1
call pitdelay
pop ax
or ax,1110b
out dx,ax
mov eax,5
call pitdelay
mov dx,word [uhcibase]
mov ax,1
out dx,ax
mov eax,5
call pitdelay
mov dx,word [uhcibase]
add dx,12h
in ax,dx
skipportreset:
cmp byte [102c4h],0
jne notmsd
;cmp byte [102c8h],40h
;jne notmsd
call initmsd
mov bl,byte [devaddress]
or bl,80h
mov dh,1
mov eax,setup_packet
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
notmsd:
cmp byte [102c4h],9
jne nothub
mov al,byte [devaddress]
mov byte [hubaddr],al
nothub:
timeout:
inc byte [devaddress]
dec byte [uhcicounter]
cmp byte [uhcicounter],0
je looper
hubdesc:
cmp byte [hubaddr],0
je doneuhciinit
mov bl,byte [hubaddr]
or bl,80h
mov dh,1
mov ch,0
mov eax,hubdescriptor
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
mov al,byte [102c2h]
mov byte [numberofhubports],al
mov eax,enablelocalpower
mov bl,byte [hubaddr]
mov ch,0
mov dh,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
mov byte [currentport],1
hubportreset:
mov al,byte [numberofhubports]
cmp byte [currentport],al
jg donehubport
mov eax,hubportresetpacket
mov bl,byte [currentport]
mov [eax+4],bl
mov bl,byte [hubaddr]
mov ch,0
mov dh,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
resetuhcihubport:
mov eax,hubstatus
mov bl,byte [currentport]
mov [eax+4],bl
mov bl,byte [hubaddr]
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
mov eax,dword [102c0h]
mov eax,hubstatus
mov bl,byte [currentport]
mov [eax+4],bl
mov bl,byte [hubaddr]
or bl,80h
mov ch,0
mov dh,1
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
mov eax,dword [102c0h]
test eax,0x0010
jnz resetuhcihubport
test eax,1
jz nexthubport
test eax,2
jnz deviceconnectedtohub
donehubport:
doneuhciinit:
mov al,1
movzx edx,word [uhcibase]
call usbregister
cld
mov edi,3000h
mov eax,1
mov ecx,15360
repe stosd
mov edi,uhciframelistarray
movzx eax,byte [uhciframelistcounter]
mov ebx,4
mul ebx
add edi,eax
mov eax,dword [uhciframelist]
stosd
inc byte [uhciframelistcounter]
add dword [uhciframelist],1000h
ret
deviceconnectedtohub:
mov bl,0
or bl,80h
mov dh,1
mov ch,0
mov eax,setup_packet
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
mov eax,setdevaddress
movzx bx,byte [devaddress]
mov word [eax+2],bx
mov bl,0
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
mov edi,dword [uhciframelist]
mov eax,1
mov ecx,1024
repe stosd
mov eax,1
call pitdelay
mov eax,dword [102c4h]
;cmp eax,40000000h
;jne nexthubport
call initmsd
inc byte [devaddress]
nexthubport:
inc byte [currentport]
jmp hubportreset

initmsd:
mov bl,byte [devaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
mov eax,7
stosw
pop eax
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov edi,dword [uhciframelist]
mov eax,1
mov ecx,1024
repe stosd
mov bl,byte [devaddress]
or bl,80h
mov dh,1
mov eax,getconfigdescriptor
push eax
mov edi,eax
add edi,6
movzx eax,byte [102c2h]
stosw
pop eax
mov ch,0
mov word [maxlen],7
mov byte [needsixtds],1
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
cmp byte [102ceh],3
je inithid
cmp byte [102c4h],1
jne failmsd
cmp byte [102ceh],8
jne failmsd
cmp byte [102cfh],6
jne failmsd
cmp byte [102d0h],50h
jne failmsd
mov esi,102d0h
mov ecx,7
mov al,7
call searchforval
mov al,byte [esi+2]
call saveendp
mov esi,102d8h
mov ecx,7
mov al,7
call searchforval
mov al,byte [esi+2]
call saveendp
cmp byte [endp1],0
jz failmsd
cmp byte [endp2],0
jz failmsd
mov edi,msdendp
movzx ecx,byte [msdendpcounter]
add edi,ecx
mov al,byte [endp1]
stosb
mov al,byte [endp2]
stosb
add byte [msdendpcounter],2
mov edi,msdframelists
movzx ecx,byte [msdframelistcounter]
add edi,ecx
mov eax,dword [uhciframelist]
stosd
add byte [msdframelistcounter],4
mov edi,dword [uhciframelist]
mov eax,1
mov ecx,1024
repe stosd
mov bl,byte [devaddress]
mov edi,msdaddresses
movzx ecx,byte [msdindex]
add edi,ecx
mov al,bl
stosb
mov eax,setconfiguration
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov bl,byte [devaddress]
mov dh,1
mov ch,byte [endp2]
mov byte [fullspeed],1
mov eax,msdinquiry
mov word [maxlen],1eh
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov bl,byte [devaddress]
or bl,80h
mov eax,102c0h
mov byte [fullspeed],1
mov byte [setupornot],1
mov ch,byte [endp1]
mov word [maxlen],36
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov bl,byte [devaddress]
or bl,80h
mov eax,102c0h
mov byte [fullspeed],1
mov byte [setupornot],1
mov ch,byte [endp1]
mov word [maxlen],13
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov byte [usbcontrollertype],0
call msdtestunitready
mov bl,byte [devaddress]
mov dh,1
mov ch,byte [endp2]
mov byte [fullspeed],1
mov eax,requestsensecommand
mov word [maxlen],1eh
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov bl,byte [devaddress]
or bl,80h
mov eax,102c0h
mov byte [fullspeed],1
mov byte [setupornot],1
mov ch,byte [endp1]
mov word [maxlen],18
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov bl,byte [devaddress]
or bl,80h
mov eax,102c0h
mov byte [fullspeed],1
mov byte [setupornot],1
mov ch,byte [endp1]
mov word [maxlen],13
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov byte [usbcontrollertype],0
call msdtestunitready
mov bl,byte [devaddress]
mov dh,1
mov ch,byte [endp2]
mov byte [fullspeed],1
mov eax,msdreadcapacity
mov word [maxlen],1eh
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov bl,byte [devaddress]
or bl,80h
mov eax,102c0h
mov byte [fullspeed],1
mov byte [setupornot],1
mov ch,byte [endp1]
mov word [maxlen],8
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov bl,byte [devaddress]
or bl,80h
mov eax,102c0h
mov byte [fullspeed],1
mov byte [setupornot],1
mov ch,byte [endp1]
mov word [maxlen],13
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
movzx edx,byte [msdindex]
mov eax,1
mov ecx,34
mov edi,disk_buffer
call msdreadwritesector
mov esi,disk_buffer
mov edi,efipart
mov ecx,8
repe cmpsb
jne failmsd
mov al,byte [msdindex]
mov byte [idedriveid],al
inc byte [idedriveid]
call detectmsdpartitions
failmsd:
ret

detectmsdpartitions:
mov esi,disk_buffer
add esi,512
mov bx,0
partitiondetectonemsd:
cmp bx,4
je donelookingmsd
mov edi,guidpart
mov ecx,16
repe cmpsb
jne donepartitiondetectonemsd
push esi
push edi
push bx
movzx edx,byte [usbcontrollertype]
push edx
movzx edx,byte [msdindex]
add esi,10h
mov esi,dword [esi]
mov eax,esi
mov cl,1
mov edi,disk_buffer
call msdreadwritesector
pop edx
mov byte [usbcontrollertype],dl
inc byte [msdindex]
detectfsmsd:
mov esi,disk_buffer
add esi,36h
mov ecx,5
mov edi,fat12str
repe cmpsb
jne notfat12msd
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov al,byte [usbcontrollercounter]
mov cl,5
div cl
or al,30h
mov byte [esi],al
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
call updatemsdendpointsandtoggle
notfat12msd:
mov esi,disk_buffer
add esi,36h
mov ecx,5
mov edi,fat16str
repe cmpsb
jne notfat16msd
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov al,byte [usbcontrollercounter]
mov cl,5
div cl
or al,30h
mov byte [esi],al
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
call updatemsdendpointsandtoggle
notfat16msd:
mov esi,disk_buffer
add esi,52h
mov ecx,5
mov edi,fat32str
repe cmpsb
jne notfat32msd
movzx edx,byte [drivecounter]
mov esi,driveletter
add esi,edx
mov al,byte [usbcontrollercounter]
mov cl,5
div cl
or al,30h
mov byte [esi],al
mov al,10h
mul byte [idedriveid]
pop bx
add bl,al
mov byte [esi+1],bl
sub bl,al
push bx
add byte [drivecounter],2
call updatemsdendpointsandtoggle
notfat32msd:
pop bx
pop edi
pop esi
donepartitiondetectonemsd:
add esi,127
sub edi,16
inc bx
jmp partitiondetectonemsd
donelookingmsd:
ret
updatemsdendpointsandtoggle:
mov edi,msdendp
movzx ecx,byte [msdendpcounter]
add edi,ecx
mov al,byte [endp1]
stosb
mov al,byte [endp2]
stosb
add byte [msdendpcounter],2
mov edi,msdtoggle
movzx ecx,byte [msdtogglecounter]
add edi,ecx
mov al,byte [msdbulkouttoggle]
stosb
mov al,byte [msdbulkintoggle]
stosb
add byte [msdtogglecounter],2
ret

msdreadwritesector:
pusha
mov esi,msdaddresses
add esi,edx
lodsb
mov byte [msdcurrentaddress],al
popa
mov dword [edxval],edx
mov dword [eaxval],eax
mov dword [ecxval],ecx
mov dword [edival],edi
msdreadwritesectorloop:
mov dword [ecxval],ecx
cmp dword [ecxval],4
jg toolargeforonerun
mov dword [actrunamt],ecx
jmp skipdefaultamt
toolargeforonerun:
mov dword [actrunamt],4
skipdefaultamt:
mov ecx,dword [actrunamt]
mov eax,512
mul ecx
push edx
cmp byte [msdreadorwrite],0
jne skipmsdread3
mov edx,msdread10
skipmsdread3:
cmp byte [msdreadorwrite],1
jne skipmsdwrite3
mov edx,msdwrite10
skipmsdwrite3:
mov [edx+8],eax
mov eax,dword [eaxval]
mov byte [edx+20],al
mov byte [edx+19],ah
shr eax,16
mov byte [edx+18],al
mov byte [edx+17],ah
mov byte [edx+22],ch
mov byte [edx+23],cl
pop edx
mov bl,byte [msdcurrentaddress]
mov dh,1
mov ch,byte [endp2]
mov byte [fullspeed],1
cmp byte [msdreadorwrite],0
jne skipmsdread
mov eax,msdread10
skipmsdread:
cmp byte [msdreadorwrite],1
jne skipmsdwrite
mov eax,msdwrite10
skipmsdwrite:
mov word [maxlen],1eh
mov byte [bulkorcontrol],1
cmp byte [usbcontrollertype],0
jne notuhci3
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
mov dh,0
call uhciwait
clc
jmp skipuhci3
notuhci3:
cmp byte [usbcontrollertype],1
jne notohci3
call ohcicreatetdio
call ohcicreateedandsend
jmp skipuhci3
notohci3:
mov word [maxlen],1fh ;Disable 4 sector limit for EHCI only needed for UHCI and OHCI
mov edx,msdbulkouttoggle
call ehcicreatetdio
call ehcicreateqh
mov eax,dword [tdval]
add eax,8
mov eax,dword [eax] ;try looking at qh
mov word [X],0
add word [Y],7
mov word [Color],0xffff
call inttostr
clc
skipuhci3:
cmp byte [usbcontrollertype],0
jne notuhci4
call msdreadin
mov edi,qh
mov eax,1
stosd
mov eax,20000h
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
mov dh,1
call uhciwait
clc
jmp skipuhci4
notuhci4:
cmp byte [usbcontrollertype],1
jne notohci4
mov byte [bulkorcontrol],1
mov bl,byte [msdcurrentaddress]
cmp byte [msdreadorwrite],0
jne skipmsdread9
mov ch,byte [endp1]
or bl,80h
skipmsdread9:
cmp byte [msdreadorwrite],1
jne skipmsdwrite9
mov ch,byte [endp2]
skipmsdwrite9:
mov dword [maxlen],1ffh
call ohcimsdreadin
jmp skipuhci4
notohci4:
cmp byte [msdreadorwrite],0
jne skipmsdread4
skipmsdread4:
cmp byte [msdreadorwrite],1
jne skipmsdwrite4
mov bl,byte [msdcurrentaddress]
mov ch,byte [endp2]
jmp readorwritemsdehci
skipmsdwrite4:
mov ch,byte [endp1]
and ch,0x0f
mov bl,byte [msdcurrentaddress]
or bl,80h
readorwritemsdehci:
mov word [maxlen],200h
call ehcimsdreadin ;add CSW for EHCI below
skipuhci4:
mov bl,byte [msdcurrentaddress]
or bl,80h
mov eax,102c0h
mov byte [fullspeed],1
mov byte [setupornot],1
mov ch,byte [endp1]
mov word [maxlen],13
mov byte [bulkorcontrol],1
cmp byte [usbcontrollertype],0
jne notuhci5
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
mov dh,0
call uhciwait
jmp skipohci5
notuhci5:
cmp byte [usbcontrollertype],1
jne notohci5
call ohcicreatetdio
call ohcicreateedandsend
jmp skipohci5
notohci5:
and ch,0x0f
mov edx,msdbulkintoggle
call ehcicreatetdio
call ehcicreateqh
clc
skipohci5:
mov eax,dword [actrunamt]
sub dword [ecxval],eax
add dword [eaxval],eax
mov eax,dword [eaxval]
mov ecx,dword [ecxval]
cmp dword [ecxval],0
jg msdreadwritesectorloop
failmsdreadwritesector:
mov byte [bulkorcontrol],0
mov byte [usbcontrollertype],0
ret
edxval dd 0
eaxval dd 0
ebxval dd 0
ecxval dd 0
edival dd 0
actrunamt dd 0
msdcurrentaddress db 0
msdreadorwrite db 0

msdreadin:
mov ecx,dword [actrunamt]
mov edi,dword [tdlocation]
msdreadinloop:
cmp ecx,1
jne notendofchain
mov eax,1
jmp endofchain
notendofchain:
add dword [tdlocation],20h
mov eax,dword [tdlocation]
endofchain:
stosd
mov eax,1
shl eax,23
stosd
mov eax,1ffh
shl eax,21
cmp byte [msdreadorwrite],0
jne skipmsdread6
movzx ebx,byte [endp1]
skipmsdread6:
cmp byte [msdreadorwrite],1
jne skipmsdwrite6
movzx ebx,byte [endp1]
skipmsdwrite6:
shl ebx,15
or eax,ebx
movzx ebx,byte [msdcurrentaddress]
shl ebx,8
or eax,ebx
cmp byte [msdreadorwrite],0
jne skipmsdread7
mov ebx,69h
skipmsdread7:
cmp byte [msdreadorwrite],1
jne skipmsdwrite7
mov ebx,0xe1
skipmsdwrite7:
or eax,ebx
stosd
mov eax,dword [edival]
stosd
mov eax,0
stosd
stosd
stosd
stosd
add dword [edival],200h
dec ecx
cmp ecx,0
jg msdreadinloop
mov dword [tdlocation],20000h
ret

msdtestunitready:
mov edi,102c0h
mov eax,0
mov ecx,5
repe stosd
mov bl,byte [devaddress]
mov dh,1
mov ch,byte [endp2]
mov byte [fullspeed],1
mov eax,testunitreadycommand
mov word [maxlen],1eh
mov byte [bulkorcontrol],1
cmp byte [usbcontrollertype],0
jne notuhci1
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
jmp skipuhci1
notuhci1:
cmp byte [usbcontrollertype],1
jne notohci1
call ohcicreatetdio
call ohcicreateedandsend
jmp skipuhci1
notohci1:
mov word [maxlen],1fh
mov edx,msdbulkouttoggle
call ehcicreatetdio
call ehcicreateqh
clc
skipuhci1:
mov bl,byte [devaddress]
or bl,80h
mov eax,102c0h
mov byte [fullspeed],1
mov byte [setupornot],1
mov ch,byte [endp1]
mov word [maxlen],13
mov byte [bulkorcontrol],1
cmp byte [usbcontrollertype],0
jne notuhci2
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
clc
jmp skipuhci2
notuhci2:
cmp byte [usbcontrollertype],1
jne notohci22
call ohcicreatetdio
call ohcicreateedandsend
jmp skipuhci2
notohci22:
and ch,0x0f
mov edx,msdbulkintoggle
call ehcicreatetdio
call ehcicreateqh
clc
skipuhci2:
mov byte [usbcontrollertype],0
mov byte [bulkorcontrol],0
ret

searchforval:
mov bl,al
loopsearch:
lodsb
cmp al,bl
je donesearch
loop loopsearch
donesearch:
dec esi
ret

saveendp:
test al,80h
jz outendp
;and al,0x0f
mov byte [endp1],al
jmp donesaveendp
outendp:
;and al,0x0f
mov byte [endp2],al
donesaveendp:
ret

uhciwait:
mov ecx,150
uhciloop:
mov eax,1
call pitdelay
mov esi,[td+4]
dec ecx
cmp ecx,0
je timeout2
test esi,100000000000000000000000b
jnz uhciloop
mov edi,dword [uhciframelist]
mov eax,1
mov ecx,1024
repe stosd
ret
timeout2:
stc
ret

createtdio:
test bl,80h
jnz notuhciout2
mov byte [statustoken],0xe1
mov byte [datatoken],0xe1
jmp savedevaddress2
notuhciout2:
cmp byte [setupbyte],1
je setupbytes
mov byte [statustoken],69h
mov byte [datatoken],69h
jmp savedevaddress2
setupbytes:
mov byte [statustoken],2dh
mov byte [datatoken],2dh
savedevaddress2:
mov cl,bl
mov dl,bl
and cl,7fh
push eax
mov edi,td
mov eax,1
stosd
mov eax,0
shl eax,27
mov ebx,1
shl ebx,23
or eax,ebx
cmp byte [fullspeed],0
jne skiplowspeed
mov ebx,1
shl ebx,26
or eax,ebx
skiplowspeed:
stosd
movzx eax,word [maxlen]
shl eax,21
movzx ebx,ch
shl ebx,15
or eax,ebx
movzx ebx,cl
shl ebx,8
or eax,ebx
movzx ebx,byte [statustoken]
or eax,ebx
stosd
pop eax
stosd
mov byte [fullspeed],0
ret

createtdchain:
test bl,80h
jnz notuhciout
mov byte [statustoken],0xe1
mov byte [datatoken],0xe1
jmp savedevaddress
notuhciout:
mov byte [statustoken],69h
mov byte [datatoken],69h
savedevaddress:
mov cl,bl
mov dl,bl
and cl,7fh
push eax
mov edi,td
cmp dh,0
je setstatustd
mov eax,td2
continuetd:
or eax,100b
stosd
mov eax,1
shl eax,23
cmp byte [fullspeed],0
jne skiplowdevice
mov ebx,1
shl ebx,26
or eax,ebx
skiplowdevice:
stosd
movzx eax,word [maxlen]
shl eax,21
mov ebx,0
shl ebx,19
or eax,ebx
movzx ebx,ch
or eax,ebx
movzx ebx,cl
shl ebx,8
or eax,ebx
cmp byte [setupornot],1
jne notin
mov ebx,69h
jmp skipsetup
notin:
cmp byte [setupornot],2
jne notout
mov ebx,0xe1
jmp skipsetup
notout:
mov ebx,2dh
skipsetup:
or eax,ebx
storethirddword:
stosd
pop eax
stosd
mov eax,0
stosd
stosd
stosd
stosd
cmp dh,0
je skiptostatus
mov edi,td2
mov eax,td3
or eax,100b
stosd
mov eax,1
shl eax,23
cmp byte [fullspeed],0
jne skiplowdevice3
mov ebx,1
shl ebx,26
or eax,ebx
skiplowdevice3:
stosd
movzx eax,word [maxlen]
shl eax,21
mov ebx,1
shl ebx,19
or eax,ebx
movzx ebx,ch
or eax,ebx
movzx ebx,cl
shl ebx,8
or eax,ebx
movzx ebx,byte [datatoken]
or eax,ebx
stosd
mov eax,0
test dl,80h
jz nooutput1
mov eax,bufferpointer
nooutput1:
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,td3
mov eax,td4
or eax,100b
stosd
mov eax,1
shl eax,23
cmp byte [fullspeed],0
jne skiplowdevice4
mov ebx,1
shl ebx,26
or eax,ebx
skiplowdevice4:
stosd
movzx eax,word [maxlen]
shl eax,21
mov ebx,0
shl ebx,19
or eax,ebx
movzx ebx,ch
or eax,ebx
movzx ebx,cl
shl ebx,8
or eax,ebx
movzx ebx,byte [statustoken]
or eax,ebx
stosd
mov eax,0
test dl,80h
jz nooutput2
mov eax,bufferpointer
add eax,8
nooutput2:
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,td4
cmp byte [needsixtds],1
jne td5next
mov eax,td6
jmp createtdagain
td5next:
mov eax,td5
createtdagain:
or eax,100b
stosd
mov eax,1
shl eax,23
cmp byte [fullspeed],0
jne skiplowdevice5
mov ebx,1
shl ebx,26
or eax,ebx
skiplowdevice5:
stosd
movzx eax,word [maxlen]
shl eax,21
mov ebx,1
shl ebx,19
or eax,ebx
movzx ebx,ch
or eax,ebx
movzx ebx,cl
shl ebx,8
or eax,ebx
movzx ebx,byte [datatoken]
or eax,ebx
stosd
mov eax,0
test dl,80h
jz nooutput3
mov eax,bufferpointer
movzx ebx,byte [td6offset]
add eax,ebx
nooutput3:
stosd
mov eax,0
stosd
stosd
stosd
stosd
cmp byte [needsixtds],1
je addsixthtd
skiptostatus:
mov edi,td5
mov eax,1
;or eax,100b
stosd
mov eax,3
shl eax,27
mov ebx,1
shl ebx,24
or eax,ebx
cmp byte [fullspeed],0
jne skiplowdevice2
mov ebx,1
shl ebx,26
or eax,ebx
skiplowdevice2:
mov ebx,1
shl ebx,23
or eax,ebx
mov ebx,80h
shl ebx,16
or eax,ebx
stosd
mov eax,7ffh
shl eax,21
mov ebx,1
shl ebx,19
or eax,ebx
movzx ebx,ch
or eax,ebx
movzx ebx,cl
shl ebx,8
or eax,ebx
cmp dh,0
je skipout
mov ebx,0e1h
jmp skipin
skipout:
mov ebx,69h
skipin:
or eax,ebx
storethirddword2:
stosd
mov eax,0
test dl,80h
jz nooutput4
mov eax,bufferpointer
cmp byte [td6offset],24
je fifthoffset
add eax,24
jmp nooutput4
fifthoffset:
add eax,32
nooutput4:
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov byte [td6offset],16
mov byte [setupornot],0
mov byte [fullspeed],0
ret
setstatustd:
mov eax,td5
jmp continuetd
addsixthtd:
mov edi,td6
mov eax,td5
mov byte [td6offset],24
mov byte [needsixtds],0
jmp createtdagain

inithid:
mov esi,102c0h
add esi,9
cmp byte [esi+7],1
je initusbkeyboard
cmp byte [esi+7],2
je initusbmouse
doneinithid:
ret
initusbkeyboard:
cmp byte [esi+6],1
jne doneinithid
mov bl,byte [devaddress]
call uhcicreatehidconfigsetup
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
mov eax,102e0h
mov ecx,8
loopreadconfigdesckeyb:
push eax
push ecx
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc doneinithid
pop ecx
pop eax
add eax,8
loop loopreadconfigdesckeyb
call lookforendp
mov edi,kbendp
add esi,2
lodsb
movzx ebx,byte [kbendpcounter]
add edi,ebx
stosb
mov eax,setconfiguration
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc doneinithid
mov bl,byte [devaddress]
or bl,80h
mov dh,1
mov eax,hidgetprotocol
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov eax,hidsetidle
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc doneinithid
mov eax,hidenablebootprotocol
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc doneinithid
mov eax,usbkeyboarddata
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,byte [kbendp]
mov word [maxlen],8
call uhcicreatetdinterrupt
mov edi,qh
mov eax,1
stosd
mov eax,dword [tdlocation]
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciinterruptwait
mov edi,hidkbaddresses
movzx eax,byte [hidkbindex]
add edi,eax
mov al,byte [devaddress]
stosb
movzx eax,byte [usbcontrollercounter]
stosd
add byte [hidkbindex],2
mov edi,kbframelists
movzx eax,byte [kbendpcounter]
mov ebx,4
mul ebx
add edi,eax
mov eax,dword [uhciframelist]
stosd
inc byte [kbendpcounter]
mov dx,word [uhcibase]
inc byte [uhcihidvals]
jmp doneinithid
initusbmouse:
cmp byte [esi+6],1
jne doneinithid
mov bl,byte [devaddress]
call uhcicreatehidconfigsetup
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
mov eax,102e0h
mov ecx,8
loopreadconfigdescms:
push eax
push ecx
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdio
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc doneinithid
pop ecx
pop eax
add eax,8
loop loopreadconfigdescms
call lookforendp
mov edi,msendp
add esi,2
lodsb
movzx ebx,byte [msendpcounter]
add edi,ebx
stosb
mov eax,setconfiguration
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc doneinithid
mov bl,byte [devaddress]
or bl,80h
mov dh,1
mov eax,hidgetprotocol
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc failmsd
mov eax,hidsetidle
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc doneinithid
mov eax,hidenablebootprotocol
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],7
call createtdchain
mov edi,qh
mov eax,1
stosd
mov eax,td
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciwait
jc doneinithid
mov eax,usbmousedata
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,byte [msendp]
mov word [maxlen],4
call uhcicreatetdinterrupt
mov edi,qh
mov eax,1
stosd
mov eax,dword [tdlocation]
stosd
mov edi,dword [uhciframelist]
mov eax,qh
or eax,2
mov ecx,1024
repe stosd
call uhciinterruptwait
mov edi,hidmsaddresses
movzx eax,byte [hidmsindex]
add edi,eax
mov al,byte [devaddress]
stosb
movzx eax,byte [usbcontrollercounter]
stosd
add byte [hidmsindex],2
mov edi,msframelists
movzx eax,byte [msendpcounter]
mov ebx,4
mul ebx
add edi,eax
mov eax,dword [uhciframelist]
stosd
mov edi,msportnums
movzx eax,byte [msportnumcounter]
mov ebx,2
mul ebx
add edi,eax
mov al,byte [ehciportnumber]
stosb
mov al,byte [ehcihubnumber]
stosb
inc byte [msportnumcounter]
inc byte [msendpcounter]
mov dx,word [uhcibase]
inc byte [uhcihidvals]
jmp doneinithid
uhcihidvals db 0
uhcihidcurrentvals db 0

lookforendp:
mov esi,102bfh
looplook:
lodsw
cmp ax,0507h
je foundendp
jmp looplook
foundendp:
sub esi,2
ret

uhcicreatehidconfigsetup:
push ebx
mov edi,td
mov eax,1
stosd
mov eax,1
shl eax,26
mov ebx,1
shl ebx,23
or eax,ebx
stosd
mov eax,7
shl eax,21
pop ebx
movzx ebx,bl
shl ebx,8
or eax,ebx
mov ebx,0x2d
or eax,ebx
stosd
mov eax,getconfigdescriptor
stosd
ret

uhciinterruptwait:
mov esi,[td+4]
test esi,100000000000000000000000b
jnz uhciinterruptwait
mov edi,dword [uhciframelist]
mov eax,1
mov ecx,1024
repe stosd
ret

uhcicreatetdinterrupt:
test bl,80h
jnz notuhciout4
mov byte [statustoken],0xe1
mov byte [datatoken],0xe1
jmp savedevaddress5
notuhciout4:
mov byte [statustoken],69h
mov byte [datatoken],69h
savedevaddress5:
mov cl,bl
mov dl,bl
and cl,7fh
push eax
mov edi,dword [tdlocation]
mov eax,1
stosd
mov eax,0
shl eax,27
mov ebx,1
shl ebx,23
or eax,ebx
mov ebx,1
shl ebx,26
or eax,ebx
stosd
movzx eax,word [maxlen]
dec eax
shl eax,21
movzx ebx,byte [kbtoggle]
shl ebx,19
or eax,ebx
not byte [kbtoggle]
and byte [kbtoggle],1
movzx ebx,ch
shl ebx,15
or eax,ebx
movzx ebx,cl
shl ebx,8
or eax,ebx
movzx ebx,byte [statustoken]
or eax,ebx
stosd
pop eax
stosd
mov byte [fullspeed],0
mov eax,0
stosd
stosd
stosd
stosd
ret

usbmshandler:
mov esi,hidmsaddresses
mov byte [msendpcounter],0
mov dword [tdlocation],20380h
startusbmshandler:
lodsw
mov dword [esival],esi
cmp ax,0
je doneusbmshandler2
sub esi,2
mov al,byte [esi]
mov byte [devaddress],al
mov al,byte [esi+1]
movzx eax,al
mov esi,usbcontrollers
add esi,eax
mov al,byte [esi]
mov byte [mshctype],al
inc esi
mov eax,dword [esi]
mov dword [currenthcaddress],eax
mov esi,msendp
movzx eax,byte [msendpcounter]
add esi,eax
lodsb
mov byte [mscurrentendp],al
cmp byte [mshctype],1
jne notuhcims
mov dword [uhciframelist],3004h
mov byte [msframelistcounter],0
mov byte [uhciframelistcounter],0
looper3:
mov esi,msframelists
movzx eax,byte [msframelistcounter]
mov ebx,4
mul ebx
add esi,eax
lodsd
cmp eax,0
je donemshandleuhci2
mov dword [uhciframelist],eax
mov eax,dword [tdlocation]
add eax,4
mov eax,dword [eax]
cmp eax,4800000h
je skipcreatemsinterrupt
bt eax,19
jc skipcreatemsinterrupt
bt eax,18
jc skipcreatemsinterrupt
mov eax,usbmousedata
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,byte [mscurrentendp]
mov word [maxlen],4
call uhcicreatetdinterrupt
mov edi,dword [tdlocation]
add edi,20h
mov eax,1
stosd
mov eax,dword [tdlocation]
stosd
mov edi,dword [uhciframelist]
add edi,4
;movzx eax,byte [uhcihidcurrentvals]
;mov ebx,4
;mul ebx
;add edi,eax
mov eax,dword [tdlocation]
add eax,20h
or eax,2
push eax
mov eax,1024
movzx ecx,byte [uhcihidvals]
mov edx,0
div ecx
xchg eax,ecx
pop eax
loopmsframe:
stosd
sub edi,4
push eax
mov eax,4
movzx ebx,byte [uhcihidvals]
mul ebx
add edi,eax
pop eax
loop loopmsframe
inc byte [uhcihidcurrentvals]
skipcreatemsinterrupt:
cmp dword [usbmousedata],0
jne usbmouseaction
donemshandleuhci:
mov byte [usbshiftpress],0
inc byte [msframelistcounter]
jmp looper3
donemshandleuhci2:
add dword [tdlocation],70h
mov dword [uhciframelist],3004h
mov byte [uhciframelistcounter],0
notuhcims:
cmp byte [mshctype],2
jne notohcims
mov eax,dword [tdlocation]
add eax,16
mov dword [endpointdescriptorloc],eax
mov eax,dword [currenthcaddress]
mov dword [ohcimmio],eax
mov eax,usbmousedata
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,byte [mscurrentendp]
and ch,0x0f
mov word [maxlen],3
mov byte [fullspeed],0
mov byte [bulkorcontrol],1
mov byte [skipdelay],1
call ohcicreatetdinterrupt
mov eax,dword [tdlocation]
mov ebx,14
shl ebx,28
test eax,ebx
jnz donemshandleohci2
cmp dword [usbmousedata],0
jne usbmouseaction
donemshandleohci2:
donemshandleohci:
add dword [tdlocation],70h
mov dword [endpointdescriptorloc],endpointdescriptor
notohcims:
cmp byte [mshctype],3
jne notehcims
mov dword [uhciframelist],3004h
mov byte [msframelistcounter],0
mov byte [msportnumcounter],0
looper5:
mov esi,msframelists
movzx eax,byte [msframelistcounter]
mov ebx,4
mul ebx
add esi,eax
lodsd
cmp eax,0
je donemshandleehci2
add eax,4
mov dword [uhciframelist],eax
mov eax,dword [tdlocation]
add eax,8
cmp dword [eax],262528
je waitforevent
cmp dword [eax],2147746176
je waitforevent
mov esi,msportnums
movzx eax,byte [msportnumcounter]
mov ebx,2
mul ebx
add esi,eax
lodsb
mov byte [ehciportnumber],al ;check if all values are being sent properly
lodsb
mov byte [ehcihubnumber],al
mov esi,dword [esival]
sub esi,hidmsaddresses
mov eax,esi
mov ebx,2
mov edx,0
div ebx
mov ebx,eax
dec ebx
mov eax,1100h
imul ebx,5000h
add eax,ebx
mov ecx,eax
add ecx,102h
mov dword [asyncval],eax
mov dword [prevqh],ecx
mov dword [eax],ecx
mov ecx,dword [eax]
mov eax,usbmousedata
mov bl,byte [devaddress]
or bl,80h
mov edx,ehcimousetoggle
mov ch,byte [mscurrentendp]
and ch,0x0f
mov word [maxlen],4 ;check prior td and qh, maybe its stuck at high speed
call ehcicreatetdinterrupt
call ehcicreateqhinterrupt
waitforevent:
cmp dword [usbmousedata],0
jne usbmouseaction
donemshandleehci:
donemshandleehci2:
add dword [tdlocation],170h
mov dword [uhciframelist],3000h
mov byte [uhciframelistcounter],0
notehcims:
doneusbmshandler:
mov esi,dword [esival]
jmp startusbmshandler
doneusbmshandler2:
mov byte [mshctype],0
ret
usbmouseaction:
call printoldlocation
mov al,byte [usbmousedata+1]
test al,80h
jnz xneg
movzx ax,al
add word [mouseX],ax
cmp word [mouseX],636
jl donex
mov word [mouseX],636
jmp donex
xneg:
not al
inc al
movzx ax,al
sub word [mouseX],ax
cmp word [mouseX],0
jg donex
mov word [mouseX],0
donex:
mov al,byte [usbmousedata+2]
test al,80h
jnz yneg
movzx ax,al
add word [mouseY],ax
cmp word [mouseY],476
jl doney
mov word [mouseY],476
jmp doney
yneg:
not al
inc al
movzx ax,al
sub word [mouseY],ax
cmp word [mouseY],0
jg doney
mov word [mouseY],0
doney:
cmp byte [usbmousedata],1
jne skipleftclick
mov byte [state],9
jmp skipleftclickdisable
skipleftclick:
call sys_getoldlocation
mov word [Color],0
call drawcursor
skipleftclickdisable:
mov dword [usbmousedata],0
cmp byte [mshctype],1
je donemshandleuhci
cmp byte [mshctype],2
je donemshandleohci
cmp byte [mshctype],3
je donemshandleehci

usbkbhandler:
mov esi,hidkbaddresses
mov dword [tdlocation],20000h
mov byte [kbendpcounter],0
startusbkbhandler:
lodsw
mov dword [esival],esi
cmp ax,0
je doneusbkbhandler2
sub esi,2
mov al,byte [esi]
mov byte [devaddress],al
mov al,byte [esi+1]
movzx eax,al
mov esi,usbcontrollers
add esi,eax
mov al,byte [esi]
mov byte [kbhctype],al
inc esi
mov eax,dword [esi]
mov dword [currenthcaddress],eax
mov esi,kbendp
movzx eax,byte [kbendpcounter]
add esi,eax
lodsb
mov byte [kbcurrentendp],al
cmp byte [kbhctype],1
jne notuhcikb
mov dword [uhciframelist],3000h
mov byte [kbframelistcounter],0
mov byte [uhciframelistcounter],0
looper2:
mov esi,kbframelists
movzx eax,byte [kbframelistcounter]
mov ebx,4
mul ebx
add esi,eax
lodsd
cmp eax,0
je donekbhandleuhci2
mov dword [uhciframelist],eax
mov eax,dword [tdlocation]
add eax,4
mov eax,dword [eax]
cmp eax,4800000h
je skipcreatekbinterrupt
bt eax,19
jc skipcreatekbinterrupt
bt eax,18
jc skipcreatekbinterrupt ;SET FRAMELIST TO RIGHT ONE
mov eax,usbkeyboarddata
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,byte [kbcurrentendp]
mov word [maxlen],8
call uhcicreatetdinterrupt
mov edi,dword [tdlocation]
add edi,20h
mov eax,1
stosd
mov eax,dword [tdlocation]
stosd
mov edi,dword [uhciframelist]
;movzx eax,byte [uhcihidcurrentvals]
;mov ebx,4
;mul ebx
;add edi,eax
mov eax,dword [tdlocation]
add eax,20h
or eax,2
push eax
mov eax,1024
movzx ecx,byte [uhcihidvals]
mov edx,0
div ecx
xchg eax,ecx
pop eax
loopkbframe:
stosd
sub edi,4
push eax
mov eax,4
movzx ebx,byte [uhcihidvals]
mul ebx
add edi,eax
pop eax
;add edi,4
loop loopkbframe
inc byte [uhcihidcurrentvals]
skipcreatekbinterrupt:
cmp byte [usbkeyboarddata+2],0 ;this prolly is affecting the repeat shit. look at this later.
jne hidkeypressed
mov byte [usbkbrepeat],0
donekbhandleuhci:
mov byte [usbshiftpress],0
inc byte [kbframelistcounter]
jmp looper2
donekbhandleuhci2:
add dword [tdlocation],70h
mov dword [uhciframelist],3000h
;mov dword [tdlocation],20000h
mov byte [uhciframelistcounter],0
notuhcikb:
cmp byte [kbhctype],2
jne notohcikb
mov eax,dword [tdlocation]
add eax,16
mov dword [endpointdescriptorloc],eax
mov eax,dword [currenthcaddress]
mov dword [ohcimmio],eax
mov eax,usbkeyboarddata
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,byte [kbcurrentendp]
and ch,0x0f
mov word [maxlen],7
mov byte [fullspeed],0
mov byte [bulkorcontrol],1
mov byte [skipdelay],1
call ohcicreatetdinterrupt
mov byte [skipioornot],0
cmp byte [usbkeyboarddata+2],0
jne hidkeypressed
mov byte [usbkbrepeat],0
donekbhandleohci:
mov byte [usbshiftpress],0
mov dword [endpointdescriptorloc],endpointdescriptor
add dword [tdlocation],70h
notohcikb:
cmp byte [kbhctype],3
jne notehcikb
mov dword [uhciframelist],3000h
mov byte [kbframelistcounter],0
mov byte [kbportnumcounter],0
mov byte [uhciframelistcounter],0
looper4:
mov esi,kbframelists
movzx eax,byte [kbframelistcounter]
mov ebx,4
mul ebx
add esi,eax
lodsd
cmp eax,0
je donekbhandleehci2
mov dword [uhciframelist],eax
mov esi,kbportnums
movzx eax,byte [kbportnumcounter]
mov ebx,2
mul ebx
add esi,eax
lodsb
mov byte [ehciportnumber],al
lodsb
mov byte [ehcihubnumber],al
mov esi,dword [esival]
sub esi,hidkbaddresses
mov eax,esi
mov ebx,2
mov edx,0
div ebx
mov ebx,eax
dec ebx
mov eax,1100h
imul ebx,5000h
add eax,ebx
mov ecx,eax
add ecx,102h
mov dword [asyncval],eax
mov dword [prevqh],ecx
mov dword [eax],ecx
mov ecx,dword [eax]
mov eax,usbkeyboarddata
mov bl,byte [devaddress]
or bl,80h
mov edx,ehcikeyboardtoggle
mov ch,byte [kbcurrentendp]
and ch,0x0f
mov word [maxlen],8 ;check prior td and qh, maybe its stuck at high speed
call ehcicreatetdinterrupt
call ehcicreateqhinterrupt
inc byte [uhcihidcurrentvals]
checkehcikeypressed:
cmp byte [usbkeyboarddata+2],0
jne hidkeypressed
mov byte [usbkbrepeat],0
donekbhandleehci:
mov byte [usbshiftpress],0
inc byte [kbframelistcounter]
inc byte [kbportnumcounter]
jmp looper4
donekbhandleehci2:
add dword [tdlocation],170h
mov dword [uhciframelist],3000h
mov byte [uhciframelistcounter],0
notehcikb:
doneusbkbhandler:
mov esi,dword [esival]
jmp startusbkbhandler
doneusbkbhandler2:
mov dword [tdlocation],20000h
mov byte [kbhctype],0
ret
ohcinotreadyyet:
sub dword [esival],2
jmp doneusbkbhandler
hidkeypressed:
mov byte [skipioornot],1
cmp byte [usbkeyboarddata],2
je usbshiftpressed
cmp byte [usbkeyboarddata],20h
je usbshiftpressed
cmp byte [usbkeyboarddata+3],0
jne skiprepeatnormal
shiftcontinue:
cmp byte [usbkeyboarddata+2],04h
jl hidnotnum
cmp byte [usbkeyboarddata+2],38h
jg hidnotnum
mov al,byte [usbkeyboarddata+2]
mov byte [ioornot],0
sub al,4
movzx eax,al
cmp byte [usbshiftpress],0
je skipnoshift
mov esi,usbkbTableShift
jmp skipkeyCaps
skipnoshift:
cmp byte [usbCaps],1
je skipkeynoCaps
mov esi,usbkbTable
jmp skipkeyCaps
skipkeynoCaps:
mov esi,usbkbTableCaps
skipkeyCaps:
add esi,eax
lodsb
mov byte [keydata],al
cmp al,byte [usbkbrepeat]
je skiprepeatnormal
mov byte [usbkbrepeat],al
skiprepeatnormal:
not byte [usbkbtoggle]
and byte [usbkbtoggle],1
cmp byte [kbhctype],1
je donekbhandleuhci
cmp byte [kbhctype],2
je donekbhandleohci
cmp byte [kbhctype],3
je donekbhandleehci
hidnotnum:
cmp byte [usbkeyboarddata+2],3ah
jl hidnotf1f2
cmp byte [usbkeyboarddata+2],3bh
jg hidnotf1f2
mov byte [ioornot],0
movzx eax,byte [usbkeyboarddata+2]
sub eax,3ah
mov esi,fkeyTable
add esi,eax
lodsb
mov byte [keydata],al
cmp al,byte [usbkbrepeat]
je skiprepeatfkey
mov byte [usbkbrepeat],al
skiprepeatfkey:
not byte [usbkbtoggle]
and byte [usbkbtoggle],1
cmp byte [kbhctype],1
je donekbhandleuhci
cmp byte [kbhctype],2
je donekbhandleohci
cmp byte [kbhctype],3
je donekbhandleehci
hidnotf1f2:
cmp byte [usbkeyboarddata+2],4ch
jl hidnotadditionalkeys
cmp byte [usbkeyboarddata+2],63h
jg hidnotadditionalkeys
mov byte [ioornot],0
movzx eax,byte [usbkeyboarddata+2]
sub eax,4ch
mov esi,additionalkeyTable
add esi,eax
lodsb
mov byte [keydata],al
cmp al,byte [usbkbrepeat]
je skiprepeataddkey
mov byte [usbkbrepeat],al
skiprepeataddkey:
not byte [usbkbtoggle]
and byte [usbkbtoggle],1
cmp byte [kbhctype],1
je donekbhandleuhci
cmp byte [kbhctype],2
je donekbhandleohci
cmp byte [kbhctype],3
je donekbhandleehci
hidnotadditionalkeys:
cmp byte [usbkeyboarddata+2],39h
jl hidnotcaps
cmp byte [usbkeyboarddata+2],39h
jg hidnotcaps
mov dword [usbkeyboarddata+2],0
mov dword [usbkeyboarddata+4],0
cmp byte [usbCaps],0
jne skipenablecaps
mov byte [usbCaps],1
mov byte [ledvals],010b
call hidchangeleds
jmp doneusbkbhandler
skipenablecaps:
cmp byte [usbCaps],1
jne skipdisablecaps
mov byte [usbCaps],0
mov byte [ledvals],0
call hidchangeleds
jmp doneusbkbhandler
skipdisablecaps:
cmp byte [kbhctype],1
je donekbhandleuhci
cmp byte [kbhctype],2
je donekbhandleohci
cmp byte [kbhctype],3
je donekbhandleehci
hidnotcaps:
cmp byte [kbhctype],1
je donekbhandleuhci
cmp byte [kbhctype],2
je donekbhandleohci
cmp byte [kbhctype],3
je donekbhandleehci
usbshiftpressed:
mov byte [usbshiftpress],1
jmp shiftcontinue
usbkbTable db 'abcdefghijklmnopqrstuvwxyz1234567890',0x0d,0,0x08,'  ','-=[]\',0,3bh,27h,'`,./'
usbkbTableCaps db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',0x0d,0,0x08,'  ','-=[]\',0,3bh,27h,'`,./'
usbkbTableShift db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ!@',23h,'$%^&*()',0x0d,0,0x08,'  ','_+{}|',0,3ah,22h,'~<>?'
ohcinextep dd 0
kbframelists times 4 dd 0
kbframelistcounter db 0
msframelists times 4 dd 0
msframelistcounter db 0
msdframelists times 4 dd 0
msdframelistcounter db 0
fkeyTable db 6,7
additionalkeyTable db 5,0,0,4,3,2,1,0,'/*-+',0x0d,'1234567890.'
usbCaps db 0
usbkbtoggle db 0
usbkbrepeat db 0
usbkbrepeattoggle db 0
usbshiftpress db 0
esival dd 0
oldtdlocation dd 200000h
align 16
ledvals db 0
setupbyte db 0

uhcicreatekbinterrupt:
mov eax,usbkeyboarddata
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,byte [kbcurrentendp]
mov word [maxlen],8
call uhcicreatetdinterrupt
mov edi,dword [tdlocation]
add edi,20h
mov eax,1
stosd
mov eax,dword [tdlocation]
stosd
mov edi,dword [uhciframelist]
mov eax,dword [tdlocation]
add eax,20h
or eax,2
mov ecx,1024
repe stosd
ret

hidchangeleds:
cmp byte [kbhctype],1
jne skipchangeledsuhci
;mov dword [tdlocation],20000h
mov edi,dword [tdlocation]
mov eax,dword [tdlocation]
add eax,20h
stosd
mov eax,1
shl eax,26
mov ebx,1
shl ebx,23
or eax,ebx
stosd
mov eax,7
shl eax,21
;movzx ebx,byte [kbtoggle]
;shl ebx,19
;or eax,ebx
;not byte [kbtoggle]
;and byte [kbtoggle],1
movzx ebx,byte [devaddress]
shl ebx,8
or eax,ebx
mov ebx,2dh
or eax,ebx
stosd
mov eax,hidsetled
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,dword [tdlocation]
add edi,20h
mov eax,dword [tdlocation]
add eax,40h
stosd
mov eax,1
shl eax,26
mov ebx,1
shl ebx,23
or eax,ebx
stosd
mov eax,0
shl eax,21
;movzx ebx,byte [kbtoggle]
;shl ebx,19
;or eax,ebx
;not byte [kbtoggle]
;and byte [kbtoggle],1
movzx ebx,byte [devaddress]
shl ebx,8
or eax,ebx
mov ebx,0xe1
or eax,ebx
stosd
mov eax,ledvals
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,dword [tdlocation]
add edi,40h
mov eax,1
stosd
mov eax,1
shl eax,26
mov ebx,1
shl ebx,23
or eax,ebx
stosd
mov eax,0
shl eax,21
;movzx ebx,byte [kbtoggle]
;shl ebx,19
;or eax,ebx
;not byte [kbtoggle]
;and byte [kbtoggle],1
movzx ebx,byte [devaddress]
shl ebx,8
or eax,ebx
mov ebx,69h
or eax,ebx
stosd
mov eax,ledvals
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,dword [tdlocation]
add edi,60h
mov eax,1
stosd
mov eax,dword [tdlocation]
stosd
mov edi,dword [uhciframelist]
;add edi,4
mov eax,dword [tdlocation]
add eax,60h
or eax,2
push eax
mov eax,1024
movzx ecx,byte [uhcihidvals]
div ecx
xchg eax,ecx
pop eax ;TRY ADDING NULL TERMINATOR
;mov ecx,1024
loopmsframe2:
stosd
sub edi,4
push eax
mov eax,4
movzx ebx,byte [uhcihidvals]
mul ebx
add edi,eax
pop eax
loop loopmsframe2
inc byte [uhcihidcurrentvals]
uhciinterruptwait2:
mov esi,dword [tdlocation]
add esi,4
mov esi,dword [esi]
test esi,100000000000000000000000b
jnz uhciinterruptwait2
jmp skipchangeledsehci
skipchangeledsuhci:
cmp byte [kbhctype],2
jne skipchangeledsohci
mov dword [tdlocation],20000h
mov edi,dword [tdlocation]
mov eax,0
shl eax,19
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
mov ebx,7
shl ebx,21
or eax,ebx
stosd
mov eax,hidsetled
stosd
mov eax,dword [tdlocation]
add eax,20h
stosd
mov eax,hidsetled
add eax,7
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,dword [tdlocation]
add edi,20h
mov eax,1
shl eax,19
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
mov ebx,7
shl ebx,21
or eax,ebx
stosd
mov eax,ledvals
stosd
mov eax,dword [tdlocation]
add eax,40h
stosd
mov eax,ledvals
add eax,5
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov edi,dword [tdlocation]
add edi,40h
mov eax,2
shl eax,19
mov ebx,2
shl ebx,24
or eax,ebx
mov ebx,14
shl ebx,28
or eax,ebx
mov ebx,7
shl ebx,21
or eax,ebx
stosd
mov eax,ledvals
stosd
mov eax,0xf000000
stosd
mov eax,ledvals
add eax,5
stosd
mov eax,0
stosd
stosd
stosd
stosd
mov byte [skipdelay],1
mov eax,dword [tdlocation]
add eax,60h
mov dword [endpointdescriptorloc],eax
mov edi,dword [endpointdescriptorloc]
mov bl,byte [devaddress]
and bl,7fh
movzx eax,bl
mov ebx,0
shl ebx,7
or eax,ebx
mov ebx,1
shl ebx,13
or eax,ebx
mov ebx,32
shl ebx,16
or eax,ebx
stosd
mov eax,0xf000000
stosd
mov eax,dword [tdlocation]
stosd
mov eax,0
stosd
jmp skipedcreation
skipchangeledsohci:
push dword [tdlocation]
waitforkeyfinish2:
mov edx,dword [tdlocation]
add edx,8
mov eax,dword [edx]
cmp eax,524672
je waitforkeyfinish2
mov dword [asyncval],1100h
mov dword [prevqh],1202h
mov eax,dword [uhciframelist]
sub eax,3000h
shr eax,12
imul eax,5000h
add dword [asyncval],eax
add dword [prevqh],eax
mov dword [tdlocation],11000h
mov eax,hidsetled
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
call ehcicreatetdchain
add dword [tdlocation],40h
mov eax,ledvals
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],1
call ehcicreatetdio
mov edi,dword [tdlocation]
mov eax,11080h
stosd
add dword [tdlocation],40h
mov eax,ledvals
mov bl,byte [devaddress]
or bl,80h
mov dh,0
mov ch,0
mov word [maxlen],1
call ehcicreatetdio
mov dword [tdlocation],11000h
mov bl,byte [devaddress]
mov dh,0
mov ch,0
mov word [maxlen],8
mov byte [ehcieps],1
mov byte [skipehciwaitbyte],1 ;see if it works in init
call ehcicreateqh
mov dword [tdlocation],20000h
mov byte [skipehciwaitbyte],0
pop dword [tdlocation]
skipchangeledsehci:
ret

uhciframelist dd 3000h
uhciframelistarray times 15 dd 0
uhciframelistcounter db 0
kbendp times 8 db 0
kbendpcounter db 0
msendp times 8 db 0
msendpcounter db 0
msdendp times 40 db 0
msdendpcounter db 0
msdtoggle times 40 db 0
msdtogglecounter db 0
uhcibase dw 0
framelist equ 3000h
bufferpointer equ 102c0h
statustoken db 0
datatoken db 0
uhcicounter db 1
devaddress db 1
hubaddr db 0
currentport db 0
numberofhubports db 0
tdlocation dd 20000h
maxlen dw 0
needsixtds db 0
td6offset db 16
portspeed db 0
setupornot db 0
fullspeed db 0
endp1 db 0
endp2 db 0
msdindex db 0
hidkbindex db 0
hidmsindex db 0
msdaddresses times 20 db 0
hidkbaddresses times 20 db 0
hidmsaddresses times 20 db 0
kbtoggle db 0
kbhctype db 0
mshctype db 0
kbcurrentendp db 0
mscurrentendp db 0
currenthcaddress dd 0
align 16
endpoint dd 0
align 16
controltoggle dd 0
align 16
setup_packet:
db 80h
db 6
db 0
db 1
dw 0
dw 18
align 16
setdevaddress:
db 0
db 5
db 0
db 0
dw 0
dw 0
align 16
hubdescriptor:
db 0xA0
db 6
dw 0x2900
dw 0
dw 7
align 16
enablelocalpower:
db 0x20
db 3
dw 0
dw 0
dw 0
align 16
hubportresetpacket:
db 0x23
db 3
dw 4
dw 0
dw 0
align 16
hubportpowerpacket:
db 0x23
db 3
dw 8
dw 0
dw 0
align 16
hubstatus:
db 0xa3
db 0
dw 0
dw 0
dw 4
align 16
getconfigdescriptor:
db 80h
db 6
dw 200h
dw 0
dw 9
align 16
bulkreset:
db 21h
db 0xff
dw 0
dw 0
dw 0
align 16
setconfiguration:
db 0
db 9
dw 1
dw 0
dw 0
align 16
bulkendptreset:
db 2
db 1
dw 0
dw 0
dw 0
align 16
getmaxlun:
db 0xa1
db 0xfe
dw 0
dw 0
dw 1
align 16
msdinquiry:
dd 43425355h
dd 12345678h
dd 24h
db 80h
db 0
db 6
db 12h
db 0
db 0
db 0
db 24h
db 0
times 10 db 0
dd 0
dd 0
dd 0
align 16
testunitreadycommand:
dd 43425355h
dd 04201969h
dd 0
db 0
db 0
db 6
db 0
db 0
db 0
db 0
db 0
db 0
times 10 db 0
align 16
requestsensecommand:
dd 43425355h
dd 15138008h
dd 18
db 80h
db 0
db 6
db 3
db 0
dd 0
db 0
dw 18
db 0
align 16
msdreadcapacity:
dd 43425355h
dd 09112001h
dd 8
db 80h
db 0
db 10
db 25h
db 0
dd 0
dw 0
db 0
db 0
times 6 db 0
align 16
msdread10:
dd 43425355h
dd 67857884h
dd 0
db 80h
db 0
db 10
db 28h
db 0
db 0
db 0
db 0
db 0
db 0
db 0
db 0
db 0
times 6 db 0
align 16
msdwrite10:
dd 43425355h
dd 12345678h
dd 512
db 0
db 0
db 10
db 2ah
db 0
db 0
db 0
db 0
db 0
db 0
db 0
db 0
db 0
times 6 db 0
align 16
hidenablebootprotocol:
db 21h
db 0Bh
dw 1
dw 0
dw 0
align 16
hidgetprotocol:
db 0xa1
db 03h
dw 0
dw 0
dw 1
align 16
hidsetidle:
db 0x21
db 0x0a
dw 0x4b00
dw 0
dw 0
align 16
hidsetled:
db 21h
db 09h
dw 200h
dw 0
dw 1
align 16
usbkeyboarddata:
times 8 db 0
align 16
usbmousedata:
times 4 db 0
align 16
qh times 2 dd 0
align 16
td times 8 dd 0
td2 times 8 dd 0
td3 times 8 dd 0
td4 times 8 dd 0
td5 times 8 dd 0
td6 times 8 dd 0

usbregister:
cmp byte [usbcontrollercounter],55
je hitmaxcontrollers
push edx
push eax
mov edi,usbcontrollers
movzx eax,byte [usbcontrollercounter]
add edi,eax
pop eax
stosb
pop edx
mov eax,edx
stosd
add byte [usbcontrollercounter],5
hitmaxcontrollers:
ret

pitdelay:
mov dword [counterms],0
pitdelayloop:
mov ebx,dword [counterms]
cmp eax,ebx
jge pitdelayloop
ret

respr:
db 0,0,0,0,0,1,0,0,0,0,2
db 0,1,1,1,1,1,1,0,0,0,2
db 0,1,0,0,0,1,0,0,1,0,2
db 0,1,0,0,0,0,0,0,1,0,2
db 0,1,0,0,0,0,0,0,1,0,2
db 0,1,0,0,0,0,0,0,1,0,2
db 0,1,0,0,0,0,0,0,1,0,2
db 0,1,0,0,0,0,0,0,1,0,2
db 0,1,1,1,1,1,1,1,1,0,2
db 0,0,0,0,0,0,0,0,0,0,3

sdspr:
db 0,0,0,1,1,1,1,0,0,0,2
db 0,0,1,0,0,0,0,1,0,0,2
db 0,1,0,0,1,1,0,0,1,0,2
db 0,1,0,0,1,1,0,0,1,0,2
db 0,1,0,0,1,1,0,0,1,0,2
db 0,1,0,0,1,1,0,0,1,0,2
db 0,1,0,0,1,1,0,0,1,0,2
db 0,1,0,0,1,1,0,0,1,0,2
db 0,0,1,0,0,0,0,1,0,0,2
db 0,0,0,1,1,1,1,0,0,0,3

tispr:
db 0,1,1,1,1,1,1,1,1,0,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,1,0,0,0,0,1,2
db 1,0,0,0,1,0,0,0,0,1,2
db 1,0,0,0,1,0,0,0,0,1,2
db 1,0,0,0,1,1,1,1,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 0,1,1,1,1,1,1,1,1,0,3

fmspr:
db 1,1,1,1,0,0,0,0,0,0,2
db 1,0,0,1,0,0,0,0,0,0,2
db 1,0,0,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,1,1,1,1,1,1,2
db 1,1,1,1,1,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,3

tespr:
db 1,1,1,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,1,1,1,1,1,1,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,1,1,1,1,1,1,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,1,1,1,1,2
db 1,0,0,0,0,0,1,0,0,1,2
db 1,0,0,0,0,0,1,0,1,0,2
db 1,1,1,1,1,1,1,1,0,0,3

progspr:
db 1,1,1,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,1,0,0,1,2
db 1,0,0,0,0,0,1,0,0,1,2
db 1,0,0,0,1,1,1,1,1,1,2
db 1,0,0,0,0,0,1,0,0,1,2
db 1,0,0,0,0,0,1,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,3

calcspr:
db 1,1,1,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,1,1,0,0,1,1,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,1,1,0,0,1,1,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,3

fnfspr:
db 0,0,0,0,0,0,0,0,0,0,2
db 0,0,0,0,1,1,0,0,0,0,2
db 0,0,0,1,0,0,1,0,0,0,2
db 0,0,0,1,1,1,1,0,0,0,2
db 0,0,1,0,1,1,0,1,0,0,2
db 0,0,1,0,1,1,0,1,0,0,2
db 0,1,0,0,0,0,0,0,1,0,2
db 0,1,0,0,1,1,0,0,1,0,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,3