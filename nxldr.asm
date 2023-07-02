;Doors NX loader Made by David Badiei
org 0000h

;Set up real mode segments
mov ax, 2000h
mov ds, ax
mov es, ax
mov ss, ax    
mov sp, 0

mov ax,0
mov es,ax
mov ax,word [es:7c11h]
mov word [RootDirEntries],ax
mov ax,word [es:7c16h]
mov word [SectorsPerFat],ax
mov al,byte [es:7c0dh]
mov byte [SectorsPerCluster],al
cmp word [es:7c13h],2880
je skiphddstart
mov word [StartingFatSector],35
skiphddstart:
mov ax,2000h
mov es,ax

;Get drive number from bootsector
mov byte [bootdev],dl

;check disk params
cmp dl,0
je skipcheckdiskparams
mov byte [bootdev],dl
push es
mov ah,8
int 13h
pop es
and cx,3fh
mov word [SectorsPerTrack],cx
mov dl,dh
xor dh,dh
add dx,1
mov word [Sides],dx

skipcheckdiskparams:

;Get values for kernel
call getvalues

call checkIfBootFloppy

;Switch to VGA 320x200x256 for prompt
mov ax,0013h
int 10h

;Load prompt image into memory
mov si,promptfn
mov di,fat12fn
mov cx,12
repe movsb
call loadfile

;Print prompt image
call drawprompt

;Give user option between using keyboard or mouse
mov ah,0
int 16h

cmp al,'0'
jne mouseSelect
mov byte [keyormouse],0
jmp doneselection
mouseSelect:
mov byte [keyormouse],1
doneselection:

;Load kernel into memory
mov si,kernelfn
mov di,fat12fn
mov cx,12
repe movsb
call loadfile

;Switch to VESA for kernel
mov di,vesadata
mov cx,0111h
mov ax,4f01h
int 10h

mov eax,dword [vesadata+40]

mov dword [lfbAddress],eax

mov ax,4f02h
mov cx,[vesadata+10h]
mov bx,4111h
int 10h

;Enable A20 gate
in al,0x92
or al,2
out 0x92,al

;Load GDT
cli
mov eax,cs
shl eax,4
mov ebx,eax
add [gdtdescriptor+2],eax
lgdt [gdtdescriptor]

;Give it the key/mouse choice
mov dl,byte [keyormouse]

;Find address of place we are gonna jump to once in protected mode
add ebx,code32bit
push dword 0x08
push ebx
mov bp,sp


;Enter protected mode
mov eax,cr0
or eax,1
mov cr0,eax

jmp dword far [bp]

jmp $

vesadata times 256 db 0
lfbAddress dd 0
disk_buffer equ 1000h
file equ 0
SectorsPerTrack dw 18
SectorsPerFat dw 9
RootDirEntries dw 224
SectorsPerCluster db 0
StartingFatSector dw 1
Sides dw 2
StartingRootDirSector dw 19
fileSize dw 0
keyormouse db 0
fat equ 4000h
cluster dw 0
bootdev db 0
fat12fn times 14 db 0
promptfn db 'PRIMG   PCX',0
kernelfn db 'NXOSKRNLSYS',0
picmaster db 0
picslave db 0
pciusable db 0
floppyavail db 0
osBootFloppy db 0

align 4
gdtdescriptor:
dw gdtend-gdt-1
dd gdt
gdt:
dq 0
code:
dw 0xffff
dw 0
db 0
db 10011010b
db 11001111b
db 0
data:
dw 0xffff
dw 0
db 0
db 10010010b
db 11001111b
db 0
sixteenbitshit:
dw 0xffff
dw 0
db 0
db 10011010b
db 10001111b
db 0
sixteenbitshit2:
dw 0xffff
dw 0
db 0
db 10010010b
db 10001111b
db 0
gdtend:

checkIfBootFloppy:
pusha
mov ax,0201h
mov cx,1
movzx dx,byte [bootdev]
mov bx,disk_buffer
int 13h
cmp dword [disk_buffer+2],0x424D584E
je skipIsBootFloppy
mov byte [osBootFloppy],1
skipIsBootFloppy:
popa
ret

getvalues:
push ax
in al,0x21
mov byte [picmaster],al
in al,0xa1
mov byte [picslave],al
mov ax,0b101h
mov edi,0
int 1ah
test al,1
jnz pciavail
mov byte [pciusable],1
pciavail:
int 11h
test ax,1
jz nofloppy
mov byte [floppyavail],1
nofloppy:
pop ax
ret

drawprompt:
push es
push ds
mov ax,0A000h
mov es,ax
mov ax,3000h
mov ds,ax
mov si,80h
mov di,0
decode:
mov cx,1
lodsb
cmp al,192
jb single
and al,63
mov cl,al
lodsb
single:
rep stosb
cmp di,64001
jb decode
mov dx,3c8h
mov al,0
out dx,al
inc dx
mov cx,768
setpal:
lodsb
shr al,2
out dx,al
loop setpal
pop ds
pop es
ret

loadfile:
push bp
mov ax,word [StartingFatSector]
mov si,word [SectorsPerFat]
add ax,si
add ax,si
mov word [StartingRootDirSector],ax
call twelvehts2
mov dl,byte [bootdev]
mov ah,2
push bx
mov bx,word [RootDirEntries]
imul bx,32
shr bx,9
mov al,bl
pop bx
mov si,disk_buffer
mov bx,si
int 13h
mov di,disk_buffer
mov si,fat12fn
mov bx,0
mov ax,0
findfn1:
mov cx,11
cld
repe cmpsb
je foundfn1
inc bx
add ax,32
mov si,fat12fn
mov di,disk_buffer
add di,ax
cmp bx,224
jle findfn1
cmp bx,224
jae filenotfound
foundfn1:
mov ax,32
mul bx
mov di,disk_buffer
add di,ax
push ax
mov ax,word [di+1ch]
mov word [fileSize],ax
pop ax
mov ax,word [di+1Ah]
mov word [cluster],ax
push ax
mov ax,1000h
mov es,ax
mov di,0
mov bx, word [StartingFatSector]
mov ax,word [SectorsPerFat]
loopreadfat:
xchg ax,bx
call twelvehts2
xchg bx,ax
mov ah,2
xchg bx, di
read_fat:
stc
push ax
mov al,1 ;ah=1 error find when it happens
mov dl,byte [bootdev]
int 13h
xchg di,bx
add di,512
pop ax
dec al
inc bx
cmp al,0
jne loopreadfat
pop ax
push ax
mov di,file
mov bx,di
push si
push bx
push cx
mov ax,word [StartingFatSector]
mov si,word [SectorsPerFat]
add ax,si
add ax,si
mov bx,word [RootDirEntries]
imul bx,32
shr bx,9
mov cx,word [cluster]
sub cx,2
cmp word [StartingFatSector],1
je skipforfloppy1
imul cx,8
skipforfloppy1:
add ax,bx
add ax,cx
pop cx
pop bx
pop si
call twelvehts2
push es
mov ax,3000h
mov es,ax
mov ax,0208h
cmp word [StartingFatSector],1
jne skipforhdd1
sub ax,7
skipforhdd1:
int 13h
pop es
mov bp,0
pop ax
loadnextclust:
mov cx,ax
mov dx,ax
shr dx,1
add cx,dx
mov dx,1000h
mov es,dx
mov bx,0
add bx,cx
mov dx,word [es:bx]
test ax,1
jnz odd1
even1:
and dx,0fffh
jmp end
odd1:
shr dx,4
end:
mov ax,dx
mov word [cluster],dx
push si
push bx
push cx
mov ax,word [StartingFatSector]
mov si,word [SectorsPerFat]
add ax,si
add ax,si
mov bx,word [RootDirEntries]
imul bx,32
shr bx,9
mov cx,word [cluster]
sub cx,2
cmp word [StartingFatSector],1
je skipforfloppy2
imul cx,8
skipforfloppy2:
add ax,bx
add ax,cx
pop cx
pop bx
pop si
call twelvehts2
add bp,1000h
cmp word [StartingFatSector],1
jne skipforhdd2
sub bp,0xe00
skipforhdd2:
mov si,0
add si,bp
mov bx,si
;sub bx,4000h
push es
mov ax,3000h
mov es,ax
mov ax,0208h
cmp word [StartingFatSector],1
jne skipforhdd3
sub ax,7
skipforhdd3:
int 13h
pop es
mov dx,word [cluster]
mov ax,dx
cmp dx,0ff0h
jb loadnextclust
mov ax,2000h
mov es,ax
pop bp
ret

filenotfound:
jmp 0xffff:0000h

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

align 4
code32bit:
use32
section protectedmode vstart=0x5000, valign=4
start32:
cld
mov eax,0x10
mov ds,eax
mov es,eax
mov fs,eax
mov gs,eax
mov ss,eax
mov esp,0x1000
mov edi,start32
mov esi,ebx
mov ecx,PMSIZE_LONG
rep movsd
jmp 0x08:continue32
continue32:
push edx
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

mov ebx,fdchandler
mov [idt31+56],bx
shr ebx,16
mov [idt31+62],bx

call pic32

lidt [idtptr]
mov ebx,100
call initPIT
mov ecx,32
readyforirq:
mov al,0x20
out 0x20,al
out 0xa0,al
loop readyforirq

mov bl,0xb8
out 0x21,al
mov al,0xff
out 0xa1,al
sti
cmp byte [20236h],1
jne skipdetectfloppy
call fdcdetect
skipdetectfloppy:
pop edx
cli ;try viewing status registers on bos
lidt [idtloc]
mov ebx,20000h
add ebx,lfbAddress
mov eax,dword [ebx]
jmp 030000h
jmp $

idtloc times 6 db 0

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

twelvehts32:
add ax,31
twelvehts322:
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

fdcdetect:
mov al,0x10
out 0x70,al
in al,0x71
cmp al,0
je donefdcdetect
call fddreset
call fddrecalibrate
donefdcdetect:
ret

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

picdelay:
jmp donepicdelay
donepicdelay:
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
mov al,byte [fdccurrenttrack]
cmp byte [fdctrack],al
je donefdcseek
mov al,15
call fdcsendbyte
mov al,byte [fdchead]
shl al,2
or al,byte [fdcdrivenum]
call fdcsendbyte
mov al,byte [fdctrack]
mov byte [fdccurrenttrack],al
call fdcsendbyte
mov byte [fdcdone],0
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

fddrecalibrate:
pushad
cmp byte [fdcmotor],1
je skipenablefdcmotor
call fdcmotoron
skipenablefdcmotor:
mov al,7
call fdcsendbyte
mov al,0
call fdcsendbyte
mov byte [fdccurrenttrack],0
mov byte [fdcdone],0
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
mov ecx,50
loopfdcwait:
mov eax,1
call pitdelay
dec ecx
cmp ecx,0
je donefdcwait
cmp byte [fdcdone],0
je loopfdcwait
donefdcwait:
ret

fdcgetbyte:
push edx
mov eax,10
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
mov eax,10
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

unhandled:
push eax
mov al,0x20
out 0x20,al
pop eax
iret

pitdelay:
mov dword [counterms],0
pitdelayloop:
mov ebx,dword [counterms]
cmp eax,ebx
jge pitdelayloop
ret

resetpc:
mov al,0xfe
out 0x64,al

PMSIZE_LONG equ ($-$$+3)>>2