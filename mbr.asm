;Master boot record for Doors NX 2.0 Made by David Badiei

use16
org 7c00h

mov ax,0
mov es,ax
mov ds,ax
mov ss,ax
mov sp,0

mov byte [bootdev],dl

mov ax,3000h
mov es,ax
mov cx,end-start
mov si,start
and si,0xff
add si,7c00h
mov di,si
push es
push si
repe movsb

mov ax,3000h
mov es,ax
mov ds,ax

retf

start:

mov ax,0
mov es,ax

mov di,0
mov ah,8
int 13h

and cx,3fh

mov word [SectorsPerTrack],cx
mov dl,dh
xor dh,dh
inc dl
mov word [Sides],dx

mov ax,1
mov cl,34
mov bx,1000h
call readSectors

mov si,1220h

mov ax,34
mov cl,1
mov bx,7c00h
call readSectors

mov ax,0
mov es,ax
mov ds,ax
mov ss,ax
mov sp,0 ;try recapping bootdev before jump

mov dl,byte [bootdev]

jmp 0x0000:7c00h

cli
jmp $

readSectors:
push cx
call twelvehts2
pop ax
mov ah,2
int 13h
ret

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


bootdev db 0
Sides dw 0
SectorsPerTrack dw 0

times 440-($-$$) db 0

uniqueDiskID dd 0

reservedSpace dw 0

partitionEntry1 times 4 db 0
db 0xee
times 11 db 0
partitionEntry2 times 16 db 0
partitionEntry3 times 16 db 0
partitionEntry4 times 16 db 0

dw 0xaa55

end: