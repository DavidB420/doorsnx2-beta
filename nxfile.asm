;Doors NX File Manager Made by David Badiei
use32
org 50000h
%include 'nxapi.inc'

mov esi,titleString
call sys_setupScreen

call sys_getrootdirectory

call drawFirstScreen

call sys_getoldlocation

mainLoop:
mov dword [mouseaddress],lbuttonclick
mov dword [keybaddress],sys_windowloop
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop

doneprog:
ret

titleString db 'Doors NX File Manager',0
volumeString db 'Volume',0
fileSize dw 0
numOfFNs dw 0
startVal dw 0
endVal dw 0
prevVal dw 30
selectVal dw 0
itemSelected db 0
viewerpos dd 70000h
navigateend dd 0

lbuttonclick:
cmp word [mouseX],619
jle s1
cmp word [mouseX],636
jg s1
cmp word [mouseY],1
jle s1
cmp word [mouseY],13
jg s1
jmp doneprog
s1:
cmp word [mouseX],619
jle s2
cmp word [mouseX],635
jg s2
cmp word [mouseY],31
jle s2
cmp word [mouseY],43
jg s2
cmp word [startVal],0
jle s2
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,85
mov bx,30
mov cx,620
mov dx,480
call sys_drawbox
mov byte [buttonornot],0
dec word [startVal]
mov cx,word [startVal]
dec word [numOfFNs]
mov word [Color],0
mov byte [itemSelected],0
call listallfns
s2:
cmp word [mouseX],619
jle s3
cmp word [mouseX],635
jg s3
cmp word [mouseY],459
jle s3
cmp word [mouseY],471
jg s3
mov ax,word [numOfFNs]
cmp ax,word [endVal]
jge s3
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,85
mov bx,30
mov cx,620
mov dx,480
call sys_drawbox
mov byte [buttonornot],0
inc word [startVal]
mov cx,word [startVal]
inc word [numOfFNs]
mov word [Color],0
mov byte [itemSelected],0
call listallfns
s3:
cmp word [mouseX],84
jle s4
cmp word [mouseX],620
jg s4
cmp word [mouseY],29
jle s4
cmp word [mouseY],480
jg s4
call selectFile
s4:
cmp word [mouseX],459
jle s5
cmp word [mouseX],475
jg s5
cmp word [mouseY],13
jle s5
cmp word [mouseY],27
jg s5
call upfolder
s5:
cmp word [mouseX],619
jle s6
cmp word [mouseX],635
jg s6
cmp word [mouseY],13
jle s6
cmp word [mouseY],27
jg s6
call viewersub
s6:
cmp word [mouseX],579
jle s7
cmp word [mouseX],595
jg s7
cmp word [mouseY],13
jle s7
cmp word [mouseY],27
jg s7
call deletefile
s7:
jmp mainLoop

deletefile:
cmp byte [itemSelected],0
je canceldeletefile
mov ax,125
mov bx,175
mov cx,575
mov dx,275
call sys_drawbox
mov word [X],150
mov word [Y],200
mov bl,2
mov esi,warnspr
call sys_dispsprite
mov esi,deleteMessage
mov word [Color],0
mov word [X],190
mov word [Y],206
call sys_printString
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,280
mov bx,230
mov cx,315
mov dx,250
call sys_drawbox
mov ax,350
mov bx,230
mov cx,390
mov dx,250
call sys_drawbox
mov byte [buttonornot],0
mov esi,ok
mov word [Color],0
mov word [X],291
mov word [Y],235
call sys_printString
mov byte [buttonornot],0
mov esi,cancel
mov word [Color],0
mov word [X],353
mov word [Y],235
call sys_printString
deleteloop:
mov dword [mouseaddress],lbuttonclick3
mov dword [keybaddress],sys_windowloop
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop
donedeletefile:
mov esi,60000h
mov edi,disk_buffer
mov ecx,dword [directorySize]
repe movsb
canceldeletefile:
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
call drawFirstScreen
mov byte [state],0
mov byte [itemSelected],0
mov word [selectVal],0
ret
deleteMessage db 'WARNING: Are you sure you want to delete the selected item?',0
ok db 'OK',0
cancel db 'Cancel',0

lbuttonclick3:
cmp word [mouseX],279
jle s31
cmp word [mouseX],315
jg s31
cmp word [mouseY],229
jle s31
cmp word [mouseY],250
jg s31
call recursivedelete
jmp donedeletefile
s31:
cmp word [mouseX],349
jle s32
cmp word [mouseX],390
jg s32
cmp word [mouseY],229
jle s32
cmp word [mouseY],250
jg s32
jmp canceldeletefile
s32:
jmp deleteloop

recursivedelete:
mov dword [navigateend],donerecursivedelete
mov byte [viewerEnabled],0
call navigatetofile
mov edi,dword [esival]
push esi
push edi
push ecx
mov edi,oldFN
mov esi,folderFN
mov ecx,13
repe movsb
pop ecx
pop edi
pop esi
cmp byte [edi+0bh],10h
je clearoutfolder
cmp byte [edi+0bh],16h
je clearoutfolder
doneclearoutfolder:
push esi
push edi
push ecx
mov edi,folderFN
mov esi,oldFN
mov ecx,13
repe movsb
pop ecx
pop edi
pop esi
call sys_deletefile
donerecursivedelete:
call reloadfolderafterdelete
ret
clearoutfolder:
mov eax,dword [directoryCluster]
mov dword [oldCluster],eax
mov eax,dword [directorySize]
mov dword [oldSize],eax
mov esi,dword [esival]
movzx eax,word [esi+26]
push eax
mov esi,folderFN
mov edi,60000h
call sys_loadfile
pop eax
add eax,31
mov dword [directoryCluster],eax
mov ecx,dword [numOfSectors]
imul ecx,200h
mov dword [directorySize],ecx
mov esi,60000h
mov edi,disk_buffer
mov ecx,dword [directorySize]
repe movsb
mov dword [edi],0
mov word [selectVal],0
mov word [startVal],0
mov esi,disk_buffer
mov ecx,dword [directorySize]
call sys_numoffatfn
cmp ecx,0
je doneloopclearoutfolder
loopclearoutfolder:
push ecx
call reloadfolderafterdelete
mov dword [edi],0
call navigatetofile
cmp esi,folderFN
jne recursefunction
push dword [esival]
push dword [directoryCluster]
push dword [directorySize]
push dword [oldSize]
push dword [oldCluster]
push dword [folderFN]
push dword [folderFN+4]
push dword [folderFN+8]
push dword [folderFN+12]
mov byte [skipreturn],1 ;load folder before clearing it out!!!
pushad
mov esi,dword [esival]
call clearoutfolder
popad
mov byte [skipreturn],0
pop dword [folderFN+12]
pop dword [folderFN+8]
pop dword [folderFN+4]
pop dword [folderFN]
pop dword [oldCluster]
pop dword [oldSize]
pop dword [directorySize]
pop dword [directoryCluster]
pop dword [esival]
call reloadfolderafterdelete
recursefunction:
;mov esi,fileFN
pushad
call sys_deletefile
mov al,0
mov edi,fileFN
mov ecx,13
repe stosb
popad
pop ecx
dec ecx
cmp ecx,0
jg loopclearoutfolder
doneloopclearoutfolder:
mov eax,dword [oldCluster]
mov dword [directoryCluster],eax
mov eax,dword [oldSize]
mov dword [directorySize],eax
cmp byte [skipreturn],1
jne skipreturnsub
ret
skipreturnsub:
call reloadfolderafterdelete
mov esi,folderFN
jmp doneclearoutfolder
oldCluster dd 0
oldSize dd 0
skipreturn db 0
oldFN times 13 db 0

reloadfolderafterdelete:
pushad
mov eax,dword [directoryCluster] ;use breakpoints to find out wtf is going on
mov edi,60000h
call sys_reloadfolder
mov esi,60000h
mov edi,disk_buffer
mov ecx,dword [directorySize]
repe movsb
popad
ret

navigatetofile:
mov esi,disk_buffer
mov edi,60000h
mov ecx,dword [directorySize]
repe movsb
cmp byte [itemSelected],0
je donenavigatetofile
mov ax,word [selectVal]
add ax,word [startVal]
movzx ecx,ax
mov word [X],700
mov edx,dword [directorySize]
call sys_displayfatfn
cmp al,1
jne skiplfn2
add esi,32
skiplfn2:
cmp byte [viewerEnabled],0
je skipending
cmp byte [esi+0bh],10h
je donenavigatetofile
cmp byte [esi+0bh],16h
je donenavigatetofile
skipending:
mov dword [esival],esi
cmp byte [esi+0bh],10h
je savefolder
cmp byte [esi+0bh],16h
je savefolder
mov edi,fileFN
mov ecx,8
loopsavesfn:
lodsb
cmp al,' '
je doneloopsavesfn
stosb
loop loopsavesfn
doneloopsavesfn:
mov esi,dword [esival]
add esi,8
mov al,'.'
stosb
mov ecx,3
repe movsb
mov esi,fileFN
ret
savefolder:
mov edi,folderFN
mov al,' '
mov ecx,11
repe stosb
mov edi,folderFN
mov ecx,9
repe movsb
mov esi,folderFN
ret
donenavigatetofile:
jmp dword [navigateend]
viewerEnabled db 0

viewersub:
mov byte [viewerEnabled],1
mov dword [navigateend],doneviewersub2
call navigatetofile
mov esi,fileFN
mov edi,70000h
call sys_loadfile
cmp byte [loadsuccess],1
je doneviewersub
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
mov word [fileSize],ax
mov byte [buttonornot],1
mov ax,603
mov bx,2
mov cx,618
mov dx,11
mov word [Color],0x079F
call sys_drawbox
mov ax,585
mov bx,2
mov cx,600
mov dx,11
call sys_drawbox
mov word [X],606
mov word [Y],3
mov esi,upspr
mov bl,1
call sys_dispsprite
mov word [X],588
mov word [Y],3
mov esi,downspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],0
mov esi,dword [viewerpos]
mov word [Color],0
mov word [X],1
mov word [Y],15
call sys_printString
viewloop:
call sys_mouseemudisable
mov dword [mouseaddress],lbuttonclick2
mov dword [keybaddress],viewercontrols
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop
doneviewersub2:
add esp,4
doneviewersub:
mov esi,60000h
mov edi,disk_buffer
mov ecx,dword [directorySize]
repe movsb
movzx ecx,word [fileSize]
mov eax,0
mov edi,70000h
repe stosb
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
call drawFirstScreen
mov byte [state],0
mov byte [itemSelected],0
mov word [selectVal],0
mov dword [viewerpos],70000h
call sys_mouseemuenable
ret
fileFN times 13 db 0
esival dd 0

lbuttonclick2:
cmp word [mouseX],619
jle s21
cmp word [mouseX],636
jg s21
cmp word [mouseY],1
jle s21
cmp word [mouseY],13
jg s21
jmp doneviewersub
s21:
cmp word [mouseX],602
jle s22
cmp word [mouseX],618
jg s22
cmp word [mouseY],1
jle s22
cmp word [mouseY],13
jg s22
jmp goup
s22:
cmp word [mouseX],584
jle s23
cmp word [mouseX],600
jg s23
cmp word [mouseY],1
jle s23
cmp word [mouseY],13
jg s23
jmp godown
s23:
jmp viewloop

viewercontrols:
cmp byte [keydata],1
je goup
cmp byte [keydata],2
je godown
cmp byte [keydata],6
je doneviewersub
jmp viewloop
goup:
mov byte [downornot],0
mov esi,dword [viewerpos]
cmp esi,70000h
je viewloop
mov word [Color],0xffff
mov word [X],1
mov word [Y],15
call sys_printString
mov esi,dword [viewerpos]
std
uploop:
lodsb
cmp esi,6ffffh
je doneuploop
dec dword [viewerpos]
cmp al,0x0a
je doneuploop
jmp uploop
doneuploop:
cld
mov esi,dword [viewerpos]
mov word [Color],0
mov word [X],1
mov word [Y],15
call sys_printString
mov byte [state],0
jmp viewloop
godown:
mov esi,dword [viewerpos]
mov word [Color],0xffff
mov word [X],1
mov word [Y],15
call sys_printString
cmp byte [esi],0
je endofdown
continuedown:
mov esi,dword [viewerpos]
downloop:
lodsb
inc dword [viewerpos]
cmp al,0
je donedownloop
cmp al,0x0a
je donedownloop
jmp downloop
donedownloop:
mov esi,dword [viewerpos]
mov word [Color],0
mov word [X],1
mov word [Y],15
call sys_printString
mov byte [state],0
jmp viewloop
endofdown:
cmp byte [downornot],1
je donedownloop
mov byte [downornot],1
jmp continuedown
downornot db 0

upfolder:
cmp dword [disk_buffer+32],538979886
jne doneupfolder
push afterfolderopen
pusha
push word [X]
push word [Y]
push word [Color]
mov esi,disk_buffer+32
jmp notlfn
doneupfolder:
ret

selectFile:
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,85
mov bx,word [prevVal]
mov cx,620
mov dx,bx
add dx,15
call sys_drawbox
mov byte [buttonornot],0
mov word [Color],0xffff
mov cx,word [startVal]
call listallfns
mov byte [buttonornot],1
mov word [Color],0xAEBF
mov ax,word [mouseY]
sub ax,32
mov bx,17
mov dx,0
div bx
mov bx,ax
cmp bx,word [endVal]
jge resetselectFile
add ax,word [startVal]
mov word [selectVal],ax
imul bx,17
add bx,30
call openFolder
afterfolderopen:
cmp byte [folderLoaded],1
je loadnewfolder
mov word [prevVal],bx
mov ax,85
mov cx,620
mov dx,bx
add dx,15
call sys_drawbox
mov byte [buttonornot],0
mov ax,word [prevVal]
mov byte [itemSelected],1
jmp doneselectFile
resetselectFile:
mov word [selectVal],0
mov byte [itemSelected],0
doneselectFile:
mov cx,word [startVal]
mov word [Color],0
call listallfns
call sys_getoldlocation
ret

openFolder:
mov byte [folderLoaded],0
cmp byte [itemSelected],1
jne notdoubleclicked
cmp bx,word [prevVal]
jne notdoubleclicked
clc
pusha
push word [X]
push word [Y]
push word [Color]
add bx,4
mov word [Y],bx
sub bx,34
mov dx,0
mov ax,bx
mov bx,17
div bx
add ax,word [startVal]
movzx ecx,ax
mov word [X],88
mov word [Color],0
mov edx,dword [directorySize]
call sys_displayfatfn
cmp al,1
jne notlfn
add esi,32
notlfn:
cmp byte [esi+0bh],10h
je isafolder
cmp byte [esi+0bh],16h
je isafolder
jmp notfolder
isafolder:
movzx ecx,word [esi+26]
add ecx,31
cmp ecx,31
jne skiproot
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,85
mov bx,30
mov cx,620
mov dx,480
call sys_drawbox
mov byte [buttonornot],0
call sys_getoldlocation
mov dword [directoryCluster],19
mov dword [numOfSectors],14
mov dword [directorySize],1c00h
call sys_getrootdirectory
mov byte [folderLoaded],1
mov word [startVal],0
jmp notfolder
skiproot:
push ecx
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,85
mov bx,30
mov cx,620
mov dx,480
call sys_drawbox
mov byte [buttonornot],0
call sys_getoldlocation
mov edi,folderFN
mov ecx,9
repe movsb
mov edi,60000h
mov eax,0
mov ecx,1000h
repe stosd
mov esi,folderFN
mov edi,70000h
call sys_loadfile ;add number of sectors returned for loadfile function
pop ecx
mov dword [directoryCluster],ecx
mov ecx,dword [numOfSectors]
imul ecx,200h
mov dword [directorySize],ecx
mov esi,70000h
mov edi,disk_buffer
repe movsb
mov byte [folderLoaded],1
mov word [startVal],0
notfolder:
mov edi,folderFN
mov al,' '
mov ecx,11
repe stosb
mov word [prevVal],30
mov byte [itemSelected],0
pop word [Color]
pop word [Y]
pop word [X]
popa
notdoubleclicked:
ret
folderFN times 11 db ' ', '.',0
folderLoaded db 0
fat12fn times 13 db 0

drawFirstScreen:
mov ax,0
mov bx,13
mov cx,85
mov dx,480
call sys_drawbox
call sys_returnnumberofdrives
movzx ecx,al
shr ecx,1
mov ebx,0
mov word [Y],20
loopdisplayallvolumes:
mov word [X],2
push ecx
push ebx
mov byte [buttonornot],1
mov word [Color],0xffff
movzx eax,word [X]
movzx ebx,word [Y]
mov ecx,eax
add ecx,65
mov edx,ebx
add edx,15
call sys_drawbox
mov byte [buttonornot],0
mov esi,volumeString
add word [X],10
add word [Y],2
mov word [Color],0
call sys_printString
pop ebx
mov eax,ebx
add word [X],40
mov word [Color],0
call inttostr
sub word [X],50
sub word [Y],2
add word [Y],20
pop ecx
inc ebx
cmp ebx,ecx
jl loopdisplayallvolumes
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,69
mov bx,20
mov cx,84
mov dx,31
call sys_drawbox
mov byte [buttonornot],0
mov word [X],72
mov word [Y],21
mov esi,upspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,69
mov bx,460
mov cx,84
mov dx,471
call sys_drawbox
mov byte [buttonornot],0
mov word [X],72
mov word [Y],461
mov esi,downspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0x738E
mov ax,85
mov bx,13
mov cx,640
mov dx,30
call sys_drawbox
mov byte [buttonornot],0
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,620
mov bx,14
mov cx,635
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],623
mov word [Y],17
mov esi,vwrspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,600
mov bx,14
mov cx,615
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],603
mov word [Y],15
mov esi,renspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,580
mov bx,14
mov cx,595
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],583
mov word [Y],15
mov esi,delspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,560
mov bx,14
mov cx,575
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],563
mov word [Y],15
mov esi,infspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,540
mov bx,14
mov cx,555
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],543
mov word [Y],15
mov esi,dskspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,520
mov bx,14
mov cx,535
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],523
mov word [Y],16
mov esi,cpyspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,500
mov bx,14
mov cx,515
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],503
mov word [Y],15
mov esi,pstspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,480
mov bx,14
mov cx,495
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],483
mov word [Y],15
mov esi,nfspr
mov bl,1
call sys_dispsprite
mov byte [buttonornot],1
mov word [Color],0xffff
mov ax,460
mov bx,14
mov cx,475
mov dx,27
call sys_drawbox
mov byte [buttonornot],0
mov word [X],463
mov word [Y],15
mov esi,upfldspr
mov bl,1
call sys_dispsprite
mov ax,620
mov bx,32
mov cx,635
mov dx,43
call sys_drawbox
mov word [X],623
mov word [Y],33
mov esi,upspr
mov bl,1
call sys_dispsprite
mov ax,620
mov bx,460
mov cx,635
mov dx,471
call sys_drawbox
mov word [X],623
mov word [Y],461
mov esi,downspr
mov bl,1
call sys_dispsprite
loadnewfolder:
mov esi,disk_buffer
mov ecx,dword [directorySize]
call sys_numoffatfn
mov word [numOfFNs],cx
mov word [endVal],cx
cmp cx,26
jl usemaxval
mov word [numOfFNs],26
usemaxval:
mov cx,0
mov word [Color],0
call listallfns
ret
directorySize dd 1c00h

listallfns:
mov word [Y],34
loopreadfns:
cmp cx,word [numOfFNs]
jge doneloopreadfns
mov word [X],102
mov edx,dword [directorySize]
call sys_displayfatfn
dispico:
cmp al,1
jne skiplfn
mov al,byte [esi+43]
cmp al,16h
je displayfoldericon
cmp al,10h
je displayfoldericon
skiplfn:
cmp al,0
jne skipsfn
mov al,byte [esi+0bh]
cmp al,16h
je displayfoldericon
cmp al,10h
je displayfoldericon
skipsfn:
mov word [X],88
sub word [Y],2
mov esi,filespr
mov bl,1
push word [Color]
call sys_dispsprite
pop word [Color]
donedispicosprite:
add word [Y],10
inc cx
jmp loopreadfns
doneloopreadfns:
ret
displayfoldericon:
mov word [X],88
sub word [Y],2
mov esi,fldspr
mov bl,1
push word [Color]
call sys_dispsprite
pop word [Color]
jmp donedispicosprite

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

downspr:
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,1,1,1,1,1,0,0,0,2
db 0,0,0,1,1,1,0,0,0,0,2
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,3

upspr:
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,1,1,1,0,0,0,0,2
db 0,0,1,1,1,1,1,0,0,0,2
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,0,1,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,3

delspr:
db 1,1,0,0,0,0,0,0,1,1,2
db 1,1,0,0,0,0,0,0,1,1,2
db 0,0,1,1,0,0,1,1,0,0,2
db 0,0,1,1,0,0,1,1,0,0,2
db 0,0,0,0,1,1,0,0,0,0,2
db 0,0,0,0,1,1,0,0,0,0,2
db 0,0,1,1,0,0,1,1,0,0,2
db 0,0,1,1,0,0,1,1,0,0,2
db 1,1,0,0,0,0,0,0,1,1,2
db 1,1,0,0,0,0,0,0,1,1,3

vwrspr:
db 1,1,0,0,0,0,0,0,1,1,2
db 1,1,0,0,0,0,0,0,1,1,2
db 1,1,1,1,0,0,1,1,1,1,2
db 1,0,0,1,1,1,1,0,0,1,2
db 1,0,0,1,1,1,1,0,0,1,2
db 1,1,1,1,0,0,1,1,1,1,2
db 0,0,0,0,0,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,3

renspr:
db 1,1,1,1,0,1,1,1,1,0,2
db 1,0,0,1,0,1,0,0,1,0,2
db 1,1,1,1,0,1,1,1,0,0,2
db 1,0,0,1,0,1,0,0,1,0,2
db 1,0,0,1,0,1,1,1,1,0,2
db 0,1,1,1,1,0,1,1,1,1,2
db 0,1,0,0,1,0,1,0,0,0,2
db 0,1,1,1,1,0,1,0,0,0,2
db 0,1,0,0,1,0,1,0,0,0,2
db 0,1,0,0,1,0,1,1,1,1,3

infspr:
db 0,1,1,1,1,1,1,1,1,0,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,1,1,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,1,1,0,0,0,1,2
db 1,0,0,0,1,1,0,0,0,1,2
db 1,0,0,0,1,1,0,0,0,1,2
db 1,0,0,0,1,1,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 0,1,1,1,1,1,1,1,1,0,3

dskspr:
db 1,1,1,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,1,1,0,1,2
db 1,1,1,1,1,1,1,1,1,1,3

cpyspr:
db 0,0,0,1,1,1,1,1,1,0,2
db 0,0,0,1,0,0,0,1,0,1,2
db 1,1,1,1,1,1,0,1,1,1,2
db 1,0,0,0,1,0,1,0,0,1,2
db 1,0,0,0,1,1,1,0,0,1,2
db 1,0,0,0,0,0,1,0,0,1,2
db 1,0,0,0,0,0,1,1,1,1,2
db 1,0,0,0,0,0,1,0,0,0,2
db 1,1,1,1,1,1,1,0,0,0,2
db 0,0,0,0,0,0,0,0,0,0,3

pstspr:
db 0,0,0,1,1,1,1,0,0,0,2
db 1,1,1,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,1,1,1,1,1,2
db 1,0,0,0,0,1,0,0,0,1,2
db 1,0,0,0,0,1,0,0,0,1,2
db 1,0,0,0,0,1,0,0,0,1,2
db 1,0,0,0,0,1,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,3

nfspr:
db 1,1,1,1,0,0,0,0,0,0,2
db 1,0,0,1,0,0,0,0,0,0,2
db 1,0,0,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,1,0,0,1,2
db 1,0,0,0,0,1,1,1,0,1,2
db 1,0,0,0,0,0,1,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,3

filespr:
db 0,1,1,1,1,1,1,1,0,0,2
db 0,1,0,0,0,0,1,0,1,0,2
db 0,1,0,0,0,0,1,0,0,1,2
db 0,1,0,0,0,0,1,1,1,1,2
db 0,1,0,0,0,0,0,0,0,1,2
db 0,1,0,0,0,0,0,0,0,1,2
db 0,1,0,0,0,0,0,0,0,1,2
db 0,1,0,0,0,0,0,0,0,1,2
db 0,1,0,0,0,0,0,0,0,1,2
db 0,1,1,1,1,1,1,1,1,1,3

fldspr:
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

upfldspr:
db 1,1,1,1,0,0,0,0,0,0,2
db 1,0,0,1,0,0,0,0,0,0,2
db 1,0,0,1,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,0,0,0,1,0,0,0,0,1,2
db 1,0,0,1,1,1,0,0,0,1,2
db 1,0,0,0,1,0,0,0,0,1,2
db 1,0,0,0,1,1,1,1,1,1,2
db 1,0,0,0,0,0,0,0,0,1,2
db 1,1,1,1,1,1,1,1,1,1,3

warnspr:
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