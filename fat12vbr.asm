;FAT12 volume boot record Made by David Badiei
use16
org 7c00h

jmp short bootloaderstart
nop
OEMLabel db "DOORSNX!"	
BytesPerSector	dw 512
SectorsPerCluster db 8
ReservedForBoot	dw 1		
NumberOfFats db 2
RootDirEntries dw 512		
LogicalSectors dw 2880
MediumByte db 0F8h
SectorsPerFat dw 9
SectorsPerTrack	dw 18
Sides dw 2
HiddenSectors dd 0
LargeSector dd 0
DriveNumber  db 80h
Flags db 0
Signature db 41	
VolumeID dd 00000000h
VolumeLabel db "DOORSNX    "
FileSystem db "FAT12   "
bootloaderstart:			
	cmp dl, 0
	je no_change
	mov [bootdev], dl		
	mov ah, 8			
	int 13h
	and cx, 3Fh			
	mov [SectorsPerTrack], cx	
	mov dl,dh
	xor dh,dh			
	add dx, 1		
	mov [Sides], dx
no_change:
	mov ax,0
floppy_ok:				
	mov ax,35
	mov si,word [SectorsPerFat]
	add ax,si
	add ax,si
	call l2hts
	mov si, buffer	
	mov bx, ds
	mov es, bx
	mov bx, si
	mov ah,2
	push bx
	mov bx,word [RootDirEntries]
    imul bx,32
	shr bx,9
	mov al,bl
	pop bx
	pusha	
read_root_dir:
	popa				
	pusha
	stc				
	int 13h				
	jnc search_dir		
	jnc read_root_dir	
	jmp reboot	
search_dir:
	popa
	mov ax, ds		
	mov es, ax		
	mov di, buffer
	mov cx, word [RootDirEntries]	
	mov ax, 0	
next_root_entry:
	xchg cx, dx			
	mov si, filename	
	mov cx, 11
	rep cmpsb
	je found_file_to_load
	add ax, 32
	mov di, buffer	
	add di,ax
	xchg dx,cx	
	loop next_root_entry
	mov si,kernelnf
	call print_string
	jmp reboot
found_file_to_load:			
	mov ax, word [es:di+0Fh]
	mov word [cluster], ax
	mov di, 0
	mov word [pointer],di
	mov ax,1000h
	mov es,ax
	mov bx, 35
	mov ax,word [SectorsPerFat]
	loopreadfat:
	xchg ax,bx
	call l2hts
	xchg bx,ax
	mov ah,2
	xchg bx, di
	read_fat:
	stc
	push ax
	mov al,1 ;ah=1 error find when it happens
	int 13h
	xchg di,bx
	add di,512
	pop ax
	dec al
	inc bx
	cmp al,0
	jne loopreadfat
	;jnc read_fat_ok	
	;jnc read_fat		
read_fat_ok:
	;mov ax,2000h
	mov bx,0
load_file_sector:
	push si
	push bx
	push cx
	mov ax,35
	mov si,word [SectorsPerFat]
	add ax,si
	add ax,si
	mov bx,word [RootDirEntries]
    imul bx,32
	shr bx,9
	mov cx,word [cluster]
	sub cx,2
	imul cx,8
	add ax,bx
	add ax,cx
	pop cx
	pop bx
	pop si
	call l2hts
	mov ax,2000h
	mov es,ax
	mov bx,word [pointer]
	mov ax,0209h
	stc
	int 13h
	jnc calculate_next_cluster
	jmp load_file_sector
calculate_next_cluster:
	mov ax, [cluster]
	mov dx,0
	mov bx,3
	mul bx
	mov bx,2
	div bx				
	xor si,si
	add si,ax
	mov bx,1000h
	mov es,bx
	mov ax,word [es:si]
	or dx, dx	
	jz even
odd:
	shr ax,4			
	jmp short next_cluster_cont
even:
	and ax,0FFFh
next_cluster_cont:
	mov word [cluster], ax	
	cmp ax, 0FF8h			
	jae end
	add word [pointer], 512	
	jmp load_file_sector
end:
	mov dl,byte [bootdev]
	jmp 2000h:0000h
reboot:
	mov ah,00
	int 16h
	jmp 0xffff:0000h
print_string:
	mov ah,0eh
	loopstr:
	lodsb
	int 10h
	test al,al
	jz done
	jmp loopstr
	done:
	ret
.repeat:
	lodsb	
	cmp al, 0
	je .done			
	int 10h	
	jmp short .repeat
	.done:
	popa
	ret
l2hts:
	push bx
	push ax
	mov bx,ax
	mov dx, 0
    div word [SectorsPerTrack]
	add dl,01h
	mov cl, dl
	mov ax, bx
	mov dx, 0
	div word [SectorsPerTrack]
	mov dx, 0
	div word [Sides]
	mov dh, dl
	mov ch, al
	pop ax
	pop bx
	mov dl, byte [bootdev]
	ret
filename db 'NXLDR   SYS'
kernelnf db 'NXLDR.SYS not found! Press any key',0
bootdev db 0
cluster equ 7e00h
pointer equ 7e02h
times 510-($-$$) db 0
dw 0AA55h
buffer: