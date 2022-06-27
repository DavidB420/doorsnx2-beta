;Doors NX File Manager Made by David Badiei
use32
org 50000h
%include 'nxapi.inc'

mov esi,titleString
call sys_setupScreen

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
jmp mainLoop

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
mov ecx,1000
repe stosd
mov esi,folderFN
mov edi,60000h
call sys_loadfile ;add number of sectors returned for loadfile function
pop ecx
mov dword [directoryCluster],ecx
mov ecx,dword [numOfSectors]
imul ecx,200h
mov dword [directorySize],ecx
mov esi,60000h
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
call sys_getrootdirectory
mov dword [directorySize],1c00h
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