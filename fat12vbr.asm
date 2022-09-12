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
	mov ax,07C0h			
	add ax,544			
	cli				
	mov ss,ax
	mov sp,4096
	sti				
	mov ax,07C0h			
	mov ds,ax
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
	mov al,14		
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
	mov ax, 35
	call l2hts
	mov di, buffer
	mov bx, di
	mov ah,2
	mov al,9
	pusha
read_fat:
	popa	
	pusha
	stc
	int 13h	
	jnc read_fat_ok	
	jnc read_fat		
read_fat_ok:
	popa
	mov ax,2000h
	mov bx,0
	mov ah,2
	mov al,1
	push ax	
load_file_sector:
	mov ax,word [cluster]
	add ax,31
	call l2hts
	mov ax,2000h
	mov es,ax
	mov bx,word [pointer]
	pop ax
	push ax
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
	mov si,buffer
	add si,ax		
	mov ax,word [ds:si]
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
	pop ax
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
kernelnf db 'Error loading NXLDR.SYS! Press any key to restart',0
bootdev dw 0
cluster dw 0
pointer dw 0
times 510-($-$$) db 0
dw 0AA55h
buffer: