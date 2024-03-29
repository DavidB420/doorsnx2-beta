;Doors NX File Manager Made by David Badiei
use32
org 50000h
%include 'nxapi.inc'

mov esi,titleString
call sys_setupScreen

mov esi,dword [directoryCluster]
mov dword [ogDirectoryCluster],esi
mov esi,dword [numOfSectors]
mov dword [ogNumOfSectors],esi
shl esi,9
mov dword [ogDirectorySize],esi

mov byte [6ffffh],0

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
fileSize dd 0
numOfFNs dw 0
startVal dw 0
endVal dw 0
prevVal dw 30
selectVal dw 0
itemSelected db 0
viewerpos dd 80000h
navigateend dd 0
ogDirectoryCluster dd 0
ogNumOfSectors dd 0
ogDirectorySize dd 0

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
mov byte [copyset],0
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
mov byte [copyset],0
s7:
cmp word [mouseX],599
jle s8
cmp word [mouseX],615
jg s8
cmp word [mouseY],13
jle s8
cmp word [mouseY],27
jg s8
call renamefile
mov byte [copyset],0
s8:
cmp word [mouseX],559
jle s9
cmp word [mouseX],575
jg s9
cmp word [mouseY],13
jle s9
cmp word [mouseY],27
jg s9
call fileinfo
s9:
cmp word [mouseX],479
jle s10
cmp word [mouseX],495
jg s10
cmp word [mouseY],13
jle s10
cmp word [mouseY],27
jg s10
call newfolder
mov byte [copyset],0
s10:
cmp word [mouseX],519
jle s11
cmp word [mouseX],535
jg s11
cmp word [mouseY],13
jle s11
cmp word [mouseY],27
jg s11
call copyfile
s11:
cmp word [mouseX],499
jle s12
cmp word [mouseX],515
jg s12
cmp word [mouseY],13
jle s12
cmp word [mouseY],27
jg s12
call pastefile
s12:
jmp mainLoop

pastefile:
cmp byte [copyset],1
jne skippaste
mov ebx,dword [edival]
mov esi,90000h
mov eax,dword [fileSize]
call sys_writefile
call reloadfolderafterdelete
mov word [startVal],0	
mov word [numOfFNs],0
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
call drawFirstScreen
mov byte [state],0
mov byte [itemSelected],0
mov word [selectVal],0
skippaste:
ret

copyfile:
cmp byte [itemSelected],0
je donecopyfile
mov ax,word [selectVal]
movzx ecx,ax
mov edx,dword [directorySize]
mov edi,90000h
mov byte [saveataddress],1
mov word [X],320
mov word [Y],240
mov word [Color],0xffff
call sys_displayfatfn
cmp al,1
jne skiplfn3
add esi,32
skiplfn3:
mov esi,dword [esi+28]
mov dword [fileSize],esi
mov byte [saveataddress],0
push edi
mov dword [navigateend],donecopyfile2
mov word [Y],0
mov byte [viewerEnabled],1
call navigatetofile
pop edi
mov dword [edival],edi
mov esi,fileFN
call sys_loadfile
call reloadfolderafterdelete
mov byte [copyset],1
jmp donecopyfile
donecopyfile2:
add esp,8
call cantcopyfolder
donecopyfile:
mov word [startVal],0	
mov word [numOfFNs],0
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
call drawFirstScreen
mov byte [state],0
mov byte [itemSelected],0
mov word [selectVal],0
ret
edival dd 0
copyset db 0

cantcopyfolder:
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
mov esi,warnspr
call sys_dispsprite
mov word [X],306
mov word [Y],229
mov esi,ok
call sys_printString
mov word [X],252
mov word [Y],210
mov esi,cantcopyfolderstr
call sys_printString
call sys_getoldlocation
nahfolder:
mov dword [mouseaddress],lbuttonclick5
mov dword [keybaddress],sys_windowloop
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop
ret
cantcopyfolderstr db 'Cannot copy folder!',0

lbuttonclick5:
cmp word [mouseX],289
jle s51
cmp word [mouseX],337
jg s51
cmp word [mouseY],226
jle s51
cmp word [mouseY],241
jg s51
ret
s51:
jmp nahfolder

newfolder:
mov edi,80000h
mov al,0
mov ecx,256
repe stosb
mov esi,newFolderStr
mov edi,80000h
mov al,255
call sys_singleLineEntry
cmp byte [entrysuccess],1
je skipnewfolder
mov esi,80000h
mov byte [needfreshcluster],1
call sys_createfolder
mov byte [needfreshcluster],0
call reloadfolderafterdelete
skipnewfolder:
mov word [startVal],0	
mov word [numOfFNs],0
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
call drawFirstScreen
mov byte [state],0
mov byte [itemSelected],0
mov word [selectVal],0
ret
newFolderStr db 'Enter new folder name:',0

fileinfo:
cmp byte [itemSelected],0
je donefileinfo
mov byte [buttonornot],1
mov word [Color],0x4A6A
mov ax,0
mov bx,120
mov cx,640
mov dx,300
call sys_drawbox
mov word [Color],0xffff
mov ax,300
mov bx,270
mov cx,340
mov dx,285
call sys_drawbox
mov byte [buttonornot],0
mov esi,ok
mov word [X],314
mov word [Y],273
mov word [Color],0
call sys_printString
mov esi,filetype
mov word [X],2
mov word [Y],155
mov word [Color],0xffff
call sys_printString
mov esi,dosFN
mov word [X],2
mov word [Y],175
call sys_printString
mov esi,fileSizeStr
mov word [X],2
mov word [Y],195
call sys_printString
mov esi,dateModified
mov word [X],2
mov word [Y],215
call sys_printString
mov dword [navigateend],donefileinfo
mov word [X],2
mov word [Y],128
mov word [Color],0xffff
movzx ecx,word [selectVal]
mov edx,dword [directorySize]
mov byte [viewerEnabled],0
mov byte [saveataddress],1
mov edi,80000h
call sys_displayfatfn
push ax
push esi
call checkandaddforlfn
cmp byte [esi+0bh],10h
je doneloopfindextension
cmp byte [esi+0bh],16h
je doneloopfindextension
mov byte [saveataddress],0
mov esi,80000h
loopfindendoffn:
lodsb
cmp al,0
je loopfindextension
jmp loopfindendoffn
loopfindextension:
mov al,byte [esi]
cmp al,'.'
je skipforfolder
cmp esi,80000h
jle cantfindextension
dec esi
jmp loopfindextension
doneloopfindextension:
pusha
mov byte [buttonornot],1
mov word [Color],0x4A6A
mov ax,66
mov bx,155
mov cx,200
mov dx,165
call sys_drawbox
mov byte [buttonornot],0
popa
mov word [Color],0xffff
mov esi,folderStr
jmp skipdecrement
skipforfolder:
inc esi
skipdecrement:
mov word [X],66
mov word [Y],155
call sys_printString
cantfindextension:
pop esi
pop ax
call checkandaddforlfn
mov edi,esi
mov word [X],90
mov word [Y],175
mov ecx,8
loopprintdossfn:
lodsb
cmp al,20h
je doneloopprintdossfn
movzx dx,al
call sys_printChar
loop loopprintdossfn
doneloopprintdossfn:
mov esi,edi
cmp byte [esi+0bh],10h
je nosfnfound
cmp byte [esi+0bh],16h
je nosfnfound
add esi,8
mov dx,'.'
call sys_printChar
mov ecx,3
loopprintdossfnextension:
lodsb
movzx dx,al
call sys_printChar
loop loopprintdossfnextension
nosfnfound:
cmp byte [esi+0bh],10h
je skipprintfilesize
cmp byte [esi+0bh],16h
je skipprintfilesize
mov eax,dword [edi+1ch]
push edi
mov word [X],70
mov word [Y],195
mov word [Color],0xffff
call inttostr
mov esi,bytesStr
call sys_printString
pop edi
jmp skipskipprintfilesize
skipprintfilesize:
mov word [X],70
mov word [Y],195
mov word [Color],0xffff
mov esi,notApplicable
call sys_printString
skipskipprintfilesize:
mov word [X],120
mov word [Y],215
movzx eax,word [edi+16h]
push ax
shr ax,11
call twodigitnum
mov dx,':'
call sys_printChar
pop ax
push ax
shr ax,5
and ax,111111b
call twodigitnum
mov dx,':'
call sys_printChar
pop ax
and ax,11111b
shl ax,1
call twodigitnum
add word [X],10
movzx eax,word [edi+18h]
push ax
shr ax,9
add ax,1980
call inttostr
mov dx,'/'
call sys_printChar
pop ax
push ax
shr ax,5
and ax,1111b
call twodigitnum
mov dx,'/'
call sys_printChar
pop ax
and ax,11111b
call twodigitnum
infloop:
mov dword [mouseaddress],lbuttonclick4
mov dword [keybaddress],sys_windowloop
mov dword [bgtaskaddress],sys_nobgtasks
jmp sys_windowloop
donefileinfo:
ret
filetype db 'File type:     file',0
dosFN db 'DOS file name:',0
fileSizeStr db 'File size:',0
dateModified db 'Date/Time modified:',0
bytesStr db ' bytes',0
notApplicable db 'N/A',0
folderStr db 'Folder',0

lbuttonclick4:
cmp word [mouseX],299
jle s41
cmp word [mouseX],340
jg s41
cmp word [mouseY],269
jle s41
cmp word [mouseY],285
jg s41
mov word [startVal],0	
mov word [numOfFNs],0
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
call drawFirstScreen
mov byte [state],0
mov byte [itemSelected],0
mov word [selectVal],0
jmp donefileinfo
s41:
jmp infloop

checkandaddforlfn:
cmp al,1
jne skipsfn2
add esi,20h
skipsfn2:
ret

twodigitnum:
pushad
mov edx,0
mov ebx,10
div ebx
add ax,30h
add edx,30h
mov ebx,edx
mov edx,eax
call sys_printChar
mov edx,ebx
call sys_printChar
popad
ret

renamefile:
cmp byte [itemSelected],0 ;need to modify rename api call to support lfn (lfn entries need to be directly before sfn
je cancelrenamefile
mov edi,80000h
mov al,0
mov ecx,256
repe stosb
mov esi,newFN
mov edi,80000h
mov al,255
call sys_singleLineEntry
cmp byte [entrysuccess],1
je cancelrenamefile
mov dword [navigateend],cancelrenamefile
mov word [Y],0
mov byte [viewerEnabled],0
call navigatetofile
mov edi,80000h
call sys_renamefile
mov dword [directorySize],eax
call reloadfolderafterdelete
cancelrenamefile:
mov word [startVal],0	
mov word [numOfFNs],0
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
call drawFirstScreen
mov byte [state],0
mov byte [itemSelected],0
mov word [selectVal],0
ret
newFN db 'Enter new file name',0

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
;mov esi,60000h
;mov edi,disk_buffer
;mov ecx,dword [directorySize]
;repe movsb
call reloadfolderafterdelete
canceldeletefile:
mov word [startVal],0	
mov word [numOfFNs],0
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
mov word [Y],0
mov byte [viewerEnabled],0
call navigatetofile
mov edi,dword [directoryCluster]
mov dword [origCluster],edi
mov edi,dword [directorySize]
mov dword [origSize],edi
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
mov word [skipreturn],0
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
push word [selectVal]
push word [startVal]
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
push word [skipreturn]
mov byte [skipreturn],1 ;load folder before clearing it out!!!
pushad
mov esi,dword [esival]
call clearoutfolder
popad
pop word [skipreturn]
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
pop word [startVal]
pop word [selectVal]
cmp word [skipreturn],1
jne skipreturnsub
ret
skipreturnsub:
mov esi,dword [origCluster]
mov dword [directoryCluster],esi
mov esi,dword [origSize]
mov dword [directorySize],esi
call reloadfolderafterdelete
mov esi,folderFN
jmp doneclearoutfolder
oldCluster dd 0
oldSize dd 0
origCluster dd 0
origSize dd 0
skipreturn dw 0
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
;add ax,word [startVal]
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
mov edi,80000h
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
mov edi,80000h
repe stosb
mov word [startVal],0	
mov word [numOfFNs],0
mov esi,titleString
call sys_setupScreen
call sys_getoldlocation
call drawFirstScreen
mov byte [state],0
mov byte [itemSelected],0
mov word [selectVal],0
mov dword [viewerpos],80000h
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
cmp esi,80000h
je viewloop
mov word [Color],0xffff
mov word [X],1
mov word [Y],15
call sys_printString
mov esi,dword [viewerpos]
std
uploop:
lodsb
cmp esi,7ffffh
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
mov esi,dword [folderAddress]
dec esi
call gobacktozerobyte
mov dword [folderAddress],esi
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
mov byte [saveataddress],1
mov edi,dword [folderAddress]
call sys_displayfatfn
mov byte [saveataddress],0
mov dword [folderAddress],edi
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
call displayfoldername
movzx ecx,word [esi+26]
add ecx,31
cmp ecx,31
jne skiproot
mov byte [buttonornot],1
mov word [Color],0x0057
mov ax,132
mov bx,3
mov cx,590
mov dx,10
call sys_drawbox
mov word [Color],0xffff
mov ax,85
mov bx,30
mov cx,620
mov dx,480
call sys_drawbox
mov byte [buttonornot],0
call sys_getoldlocation
mov eax,dword [ogDirectoryCluster]
mov dword [directoryCluster],eax
mov eax,dword [ogNumOfSectors]
mov dword [numOfSectors],eax
mov eax,dword [ogDirectorySize]
mov dword [directorySize],eax
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
mov ecx,8
repe movsb
mov edi,60000h
mov eax,0
mov ecx,1000h
repe stosd
mov esi,folderFN
mov edi,80000h
call sys_loadfile ;add number of sectors returned for loadfile function
pop ecx
mov dword [directoryCluster],ecx
mov ecx,dword [numOfSectors]
imul ecx,200h
mov dword [directorySize],ecx
mov esi,80000h
mov edi,disk_buffer
repe movsb
mov byte [folderLoaded],1
mov word [startVal],0
notfolder:
mov edi,folderFN
mov al,0
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
folderFN times 12 db 0
folderLoaded db 0
fat12fn times 13 db 0
folderAddress dd 70000h

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
mov esi,dword [ogDirectoryCluster]
cmp dword [directoryCluster],esi
je skipdisplayfoldernameattop
call displayfoldername
skipdisplayfoldernameattop:
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

displayfoldername:
pushad
mov byte [buttonornot],1
mov word [Color],0x0057
mov ax,145
mov bx,3
mov cx,590
mov dx,10
call sys_drawbox
mov byte [buttonornot],0
mov word [X],132
mov word [Y],3
mov word [Color],0xffff
mov dx,'-'
call sys_printChar
popad
pushad
mov word [X],145
mov word [Y],3
mov esi,dword [folderAddress]
dec esi
call gobacktozerobyte
call sys_printString
popad
ret

gobacktozerobyte:
dec esi
cmp byte [esi],0
jne gobacktozerobyte
inc esi
ret

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