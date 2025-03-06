.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf : proc
includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 1080
area_height EQU 1080
matrix_width EQU 320
matrix_height EQU 320
area DD 0
xx equ 150
yy equ 150
edy db 0
registru dd 0
flag dd 0
nr_apasari dd 0
counter DD 0 ; numara evenimentele de tip timer
counter2 dd 0
counter_mine dd 0
grid_latime equ 16
grid_inaltime equ 16
posx dd 0
posy dd 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

image_width dd 40
image_height dd 40
include poza bomba.inc
;include poza mina.inc
include numere_minesweeper_toate.inc
include game_over.inc
include battleship-minesweeper.inc
include poza_win.inc

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

formatd db "%d ",0
spatiu db ".",10,13,0

matrice db 16 dup(0)
        db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
        db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)
		db 16 dup(0)

vec_random db 80 dup(0)

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

make_text1 proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, [eax]
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_text1 endp


linie_orizontala macro x, y, len, color
local bucla_linia
pusha
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
bucla_linia:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_linia
	popa
endm



linie_verticala macro x,y,len, color
  local bucla_linie
	pusha
	mov eax, y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax, area
	mov ecx,len
	bucla_linie:
 mov dword ptr[eax],color
 add eax, area_width*4
 loop bucla_linie
 popa
endm


linie_verticala2 macro x,y,len, color
  local buclaa_linie
	pusha
	mov eax, y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax, area
	mov ecx,len
	buclaa_linie:

 mov dword ptr[eax],color
 add eax, area_width*4

 sub eax,4
  loop buclaa_linie
 popa
endm

make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp


make_img_macro macro var,drawArea,x,y, inaltime,latime
	mov image_height,inaltime
	mov image_width, latime
	push eax
	mov eax,offset[var]
	push y
	push x
	push drawArea
	call make_text1
	add esp,12
	pop eax
endm


make_img proc
	push ebp
	mov ebp,esp
	pusha
	lea esi,[eax]
	ret
make_img endp


; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
desenare_verticala proc
	
	pusha
	mov ecx,150
	mov edx,0
	add edx,150
	add edx,matrix_width
	repetare1:
	linie_verticala ecx,150,matrix_width,0
	add ecx,20
	cmp ecx,edx
	jbe repetare1
	popa
	ret
desenare_verticala endp

desenare_orizontala proc

	pusha
	mov ecx,150
	mov edx,0
	add edx,150
	add edx,matrix_height
	repetare1:
	linie_orizontala 150,ecx,matrix_height,0
	add ecx,20
	cmp ecx,edx
	jbe repetare1
	popa
	ret
desenare_orizontala endp


desenare_f proc
	pusha
	mov ecx, matrix_width+41
	repetare3:
	mov edx, 130
	add ecx, edx
	linie_verticala ecx, 70, matrix_height+90, 0C6C6C6h
	sub ecx, edx
	
	loop repetare3
	popa
	ret
desenare_f endp


	
	
 
 desenare_dreptunghi proc
  linie_orizontala 151, 90, matrix_width,0
  linie_orizontala 151, 130 ,matrix_width,0
  linie_verticala 151, 90, 40,0
  linie_verticala 151+matrix_width, 90, 40,0
  ret
desenare_dreptunghi endp

desenare_carcasa proc
    linie_orizontala 130,70, matrix_width+41,0
	linie_orizontala 130,70 + matrix_height+90, matrix_width+41,0
	linie_verticala 130,70,matrix_height+90,0
	linie_verticala 130+matrix_width+41,70,matrix_height+90,0
 ret
 desenare_carcasa endp
 desenare_dreptunghi2 macro ;x,y,len, color
    linie_orizontala 600,150, 300,0
	linie_orizontala 600,250, 300,0
	linie_verticala 600,150,100,0
	linie_verticala 900,150,100,0 
  endm
	linie_verticala2 700,150,100,0
	
desenare_paral macro ;x,y,len, color
    ;linie_orizontala 600,50, 300,0
	linie_orizontala 800,50, 300,0
	linie_verticala2 600,150,100,0
	linie_verticala2 800,50,100,0 
  endm
	;linie_verticala2 700,150,100,0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	  
draw proc
   
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	  call desenare_f
	  call desenare_verticala
	  call desenare_orizontala
	  call desenare_dreptunghi
	  call desenare_carcasa
	  
	 call formatare_matrice
	call pune_poza_cu_cifre
	make_img_macro flag_0,area,600,200,20,20 
	desenare_dreptunghi2
	desenare_paral
	;linie_verticala2 700,150,100,0
	
	  jmp afisare_litere

	
evt_click:
;pusha
cmp counter_mine,216
jne  fa
	
	 make_img_macro win_0,area,210,250,145,55
	 make_img_macro win_1,area,258,250,145,55
	 make_img_macro win_2,area,306,250,145,55
	 make_img_macro win_3,area,354,250,145,55
	 make_img_macro win_4,area,402,250,145,8
	 
	 
	 mov registru,1
	 jmp afisare_litere


fa:
cmp registru,1
	je final_draw

	cmp flag,1
	jne aiki
      
	  mov edi,[ebp+arg2]     ;ecx=edi=x     ;ebx=y
	  cmp edi,150
	  jb afisare_litere
	  cmp edi,470
	  jae afisare_litere
	mov ebx,[ebp+arg3]
	 cmp ebx,150
	  jb afisare_litere
	  cmp ebx,470
	  ja afisare_litere
	  
	   mov edi,[ebp+arg2]
	  cmp edi,600
	  jb aiki
	  cmp edi,620
	  ja aiki
	  mov edi,[ebp+arg3]
	  cmp edi,200
	  jb aiki
	  cmp edi,220
	  ja aiki
	  mov flag,1
	  
	
	 mov flag,0
	sub edi,150
	sub ebx,150
	mov edx,0
	mov eax,edi
	mov edi,20
	div edi
	
	mov edi,eax
	
	mov eax,ebx   ; coord edi = x
	mov ebx,20
	mov edx,0
	div ebx
	mov ebx,eax   ; coord ebx = y
	
	push ebx
	mov esi,0
	shl ebx,4
	
	
	add esi,ebx
	pop ebx
	add esi,edi

	mov eax,0
	mov al,matrice[esi]
	mov edy,al

	
    mov eax,20
	mul edi
	mov edi,eax
	add edi,150
	
	mov eax,20
	mul ebx
	mov ebx,eax
	add ebx,150
	make_img_macro flag_0,area,edi,ebx,20,20 
	jmp afisare_litere
	
	  
	  

    aiki:
	mov flag,0
       cmp registru,1
	je final_draw
;pusha
	mov edi,[ebp+arg2]     ;ecx=edi=x     ;ebx=y
	  cmp edi,150
	  jb afisare_litere
	  cmp edi,470
	  jae afisare_litere
	mov ebx,[ebp+arg3]
	 cmp ebx,150
	  jb afisare_litere
	  cmp ebx,470
	  ja afisare_litere

	sub edi,150
	sub ebx,150
	mov edx,0
	mov eax,edi
	mov edi,20
	div edi
	
	mov edi,eax
	
	mov eax,ebx   ; coord edi = x
	mov ebx,20
	mov edx,0
	div ebx
	mov ebx,eax   ; coord ebx = y
	
	push ebx
	mov esi,0
	shl ebx,4
	
	
	add esi,ebx
	pop ebx
	add esi,edi

	mov eax,0
	mov al,matrice[esi]
	mov edy,al

	
    mov eax,20
	mul edi
	mov edi,eax
	add edi,150
	
	mov eax,20
	mul ebx
	mov ebx,eax
	add ebx,150
	
	
	 cmp edy,20	
	 jne nu9
	 
	make_img_macro val_0,area,edi,ebx,20,20 
	inc counter_mine
	jmp neeeext
	nu9:
	cmp edy,1	
	jne nuu9
	 make_img_macro val_1,area,edi,ebx,20,20
	 	inc counter_mine
	jmp neeeext
	nuu9:
	cmp edy,2
	jne nuuu9
	 make_img_macro val_2,area,edi,ebx,20,20 
	 	inc counter_mine
	jmp neeeext
	nuuu9:
	cmp edy,3
	jne nuuuu9
	 make_img_macro val_3,area,edi,ebx,20,20 
	 	inc counter_mine
	jmp neeeext	   
	  nuuuu9:
	  cmp edy,4
	jne nuuuuu9
	 make_img_macro val_4,area,edi,ebx,20,20 
	 	inc counter_mine
	jmp neeeext
	nuuuuu9:
	cmp edy,5
	jne nuuuuuu9
	 make_img_macro val_5,area,edi,ebx,20,20
	 	inc counter_mine
	jmp neeeext
	nuuuuuu9:
	cmp edy,6
	jne nuuuuuuu9
	 make_img_macro val_6,area,edi,ebx,20,20 
	 	inc counter_mine
	jmp neeeext
	   
	  nuuuuuuu9:
	  cmp edy,7
	jne nuuuuuuuu9
	 make_img_macro val_7,area,edi,ebx,20,20 
	 	inc counter_mine
	jmp neeeext
	nuuuuuuuu9:
	cmp edy,8
	jne nuuuuuuuuu9
	 make_img_macro val_8,area,edi,ebx,20,20
	 	inc counter_mine
	 jmp neeeext
	 nuuuuuuuuu9:
	 cmp edy,100
	 jne neeeext
	 	inc counter_mine
	 make_img_macro var_0,area,edi,ebx,20,20
	
	 make_img_macro poz_0,area,210,250,112,48
	 make_img_macro poz_1,area,258,250,112,48
	 make_img_macro poz_2,area,306,250,112,48
	 make_img_macro poz_3,area,354,250,112,48
	 make_img_macro poz_4,area,402,250,112,8
	 mov registru,1
	 
 
	 
	 neeeext:
	 ;popa
	
	
	 jmp afisare_litere 
	
evt_timer:
cmp registru,1
    je ba
	
	inc counter2
	cmp counter2,5
	jne ba
	inc counter
	mov counter2,0
	
	ba:
	
afisare_litere:

	
	
	;scriem un mesaj
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 180, 100
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 170, 100
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 160, 100
	;linie_vertical 100, 100, matrix_height, 0
	;linie_vertical 140, 100, matrix_height, 0
		;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 450, 100
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 440, 100
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 430, 100
	;linie_vertical 100, 100, matrix_height, 0
	;linie_vertical 140, 100, matrix_height, 0
	
	
		mov ebx, 10
	mov eax, counter_mine
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 250, 100
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 240, 100
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 230, 100
final_draw:
	popa
	
	mov esp, ebp
	pop ebp
	ret

draw endp


baga_in_matrice2 macro coord, val

	pusha
	mov edi,coord
	mov matrice[edi], val		
	popa
	
endm
	
formatare_matrice proc 

		pusha
	mov ecx,40
	buclucasa:
	rdtsc
	shl eax,28
	shr eax,28
	
	mov esi,0
 
	shl eax, 4
	
	add esi, eax  
	
	rdtsc
	shl eax,28
	shr eax,28

	add esi, eax
	
		
	cmp  matrice[esi], 100
	je buclucasa
	mov matrice[esi],100
	loop buclucasa
	popa
	ret
formatare_matrice endp


pune_poza_cu_cifre proc

   pusha

	   mov edi,0
	   colt_dreapta_sus:
	   mov esi,15
	   cmp matrice[esi],100
	   je next
	   mov esi,14
	   cmp matrice[esi],100
	   je creste
	   dec edi
	   creste:
		inc edi 
	   add esi,16
	cmp matrice[esi],100
	   je crestee
	   dec edi
	   crestee:
	inc edi
	inc esi
	cmp matrice[esi],100
	je cresteee
	dec edi
	cresteee:
	inc edi
	cmp edi,0
	jne modifica1
	mov edi,20
	modifica1:
	mov eax,edi
	mov esi,15
	 baga_in_matrice2 esi,al


	 next:
	 

	 mov edi,0
	   colt_dreapta_jos:
	   mov esi,255
	   cmp matrice[esi],100
	   je next1
	   mov esi,254
	   
	   cmp matrice[esi],100
	   
	   je creste1
	   dec edi
	   creste1:
		inc edi 
	   sub esi,16
	cmp matrice[esi],100
	   je crestee1
	   dec edi
	   crestee1:
	inc edi
	inc esi
	cmp matrice[esi],100
	je cresteee1
	dec edi
	cresteee1:
	inc edi
	cmp edi,0
	jne modifica2
	mov edi,20
	modifica2:
	mov eax,edi
	mov esi,255
	baga_in_matrice2 esi,al
	
	
	next1:
	

	 mov edi,0
	   colt_stanga_jos:
	   mov esi,240
	   cmp matrice[esi],100
	   je next2
	   mov esi,239
	   inc esi
	   cmp matrice[esi],100
	   je creste2
	   dec edi
	   creste2:
		inc edi 
	   add esi,16
	cmp matrice[esi],100
	   je crestee2
	   dec edi
	   crestee2:
	inc edi
	dec esi
	cmp matrice[esi],100
	je cresteee2
	dec edi
	cresteee2:
	inc edi
	
	cmp edi,0
	jne modifica3
	mov edi,20
	modifica3:
	mov eax,edi
	;add esi,16
	mov esi,240
	baga_in_matrice2 esi,al

	  
  next2:

	   
   mov edi,0
	   colt_stanga_sus:
	   
	   mov esi,0
	   cmp matrice[esi],100
	   je next3
	   inc esi
	   cmp matrice[esi],100
	   je creste3
	   dec edi
	   creste3:
		inc edi 
	   add esi,16
	cmp matrice[esi],100
	   je crestee3
	   dec edi
	   crestee3:
	inc edi
	dec esi
	cmp matrice[esi],100
	je cresteee3
	dec edi
	cresteee3:
	inc edi
	
	cmp edi,0
	jne modifica4
	mov edi,20
	modifica4:
	mov eax,edi

	mov esi,0
	
	baga_in_matrice2 esi,al

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	next3:
	mov ecx,0
	linie_sus:
	inc ecx
	cmp ecx,14
	ja next4
	mov edi,0
	mov esi,ecx
	
	cmp matrice[esi],100
	je linie_sus
	
	dec esi
	cmp matrice[esi],100
	je crest
	dec edi
	crest:
	inc edi
	
	add esi,16
	cmp matrice[esi],100
	je crestt
	dec edi
	crestt:
	inc edi
	
	
	add esi,1
	cmp matrice[esi],100
	je cresttt
	dec edi
	cresttt:
	inc edi
	
		add esi,1
	cmp matrice[esi],100
	je crestttt
	dec edi
	crestttt:
	inc edi
	 
	 sub esi,16
	 	cmp matrice[esi],100
	je cresttttt
	dec edi
	cresttttt:
	inc edi
	
	sub esi,1
	
	cmp edi,0
	jne modifica5
	mov edi,20
	modifica5:
	 mov eax,edi
	 
	 baga_in_matrice2 esi,al
	 
	
	  
	  jmp linie_sus
	 
	 
	 next4:
	 mov ecx,0
	 coloana_dreapta:
	 inc ecx
	 cmp ecx,14
	 ja next5
	 mov edi,0
	 mov esi,15
	 push ecx
	 shl ecx,4
	 add esi,ecx
	 pop ecx
	 cmp matrice[esi],100
	 je coloana_dreapta
	 
	 sub esi,16
	 cmp matrice[esi],100
	 je crest1
	 dec edi
	 crest1:
	 inc edi
	 
	 sub esi,1

	 cmp matrice[esi],100
	 je crestt1
	 dec edi
	 crestt1:
	 inc edi
	 
	 add esi,16
	 
	 cmp matrice[esi],100
	 je cresttt1
	 dec edi
	 cresttt1:
	 inc edi
	
	   add esi,16
	 
	 cmp matrice[esi],100
	 je crestttt1
	 dec edi
	 crestttt1:
	 inc edi
	 
	  add esi,1
	 
	 cmp matrice[esi],100
	 je cresttttt1
	 dec edi
	 cresttttt1:
	 inc edi
	 
	 sub esi,16
	   cmp edi,0
	jne modifica6
	mov edi,20
	modifica6:
	
	  mov eax,edi
	
	  baga_in_matrice2 esi,al
	 
	  
	   jmp coloana_dreapta
     
	 
	 next5:
	 mov ecx,15
	 mov esi,240
	 linie_jos:
	 inc esi
	 inc ecx
	 cmp ecx,14
	 ja next6
	 mov edi,0
	
	 cmp matrice[esi],100
	 je linie_jos
	 
	 add esi,1
	 cmp matrice[esi],100
	 je crest2
	 dec edi
	 crest2:
	 inc edi
	 
	 sub esi,16
	
	 cmp matrice[esi],100
	 je crestt2
	 dec edi
	 crestt2:
	 inc edi
	 
	 sub esi,1
	
	 cmp matrice[esi],100
	 je cresttt2
	 dec edi
	 cresttt2:
	 inc edi
	 
	 sub esi,1
	
	 cmp matrice[esi],100
	 je crestttt2
	 dec edi
	 crestttt2:
	 inc edi
	 
	 
	 add esi,16
	
	 cmp matrice[esi],100
	 je cresttttt2
	 dec edi
	 cresttttt2:
	 inc edi
	 
	 
	 
	 add esi,1
	 cmp edi,0
	jne modifica7
	mov edi,20
	modifica7:
	 mov eax,edi
	 baga_in_matrice2 esi,al

	 jmp linie_jos
	
	
	next6:
	mov ecx,0
	mov esi,0
	coloana_stanga:
	mov edi,0
    inc ecx
	add esi,16
	cmp ecx,15
	ja next7
	cmp matrice[esi],100
	je coloana_stanga

	
	
	sub esi,16
	cmp matrice[esi],100
	je crest3
	dec edi
	crest3:
	inc edi
	
	add esi,1
	cmp matrice[esi],100
	je crestt3
	dec edi
	crestt3:
	inc edi
	
	add esi,16	
	cmp matrice[esi],100
	je cresttt3
	dec edi
	cresttt3:
	inc edi
	
	add esi,16
	cmp matrice[esi],100
	je crestttt3
	dec edi
	crestttt3:
	inc edi
	
	
	sub esi,1
	cmp matrice[esi],100
	je cresttttt3
	dec edi
	cresttttt3:
	inc edi
	
	sub esi,16
	cmp edi,0
	jne modifica9
	mov edi,20
	modifica9:
	mov eax,edi
	baga_in_matrice2 esi,al
	
	jmp coloana_stanga
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	next7:
	mov ebx,-1     ;pt linii adica y
	mov esi,-1
	
	centru:
	inc ebx
	cmp ebx,15
	ja final
	mov ecx,0     ; pt coloane adica x
	
	buc:
	
	inc esi
	mov edi,0
	cmp matrice[esi],0
	jne aici
	
	sub esi,16
	cmp matrice[esi],100
	je crest4
	dec edi
	crest4:
	inc edi
	
	add esi,1
	cmp matrice[esi],100
	je crestt4
	dec edi
	crestt4:
	inc edi
	
	add esi,16
	cmp matrice[esi],100
	je cresttt4
	dec edi
	cresttt4:
	inc edi

    add esi,16
	cmp matrice[esi],100
	je crestttt4
	dec edi
	crestttt4:
	inc edi
		
    sub esi,1
	cmp matrice[esi],100
	je cresttttt4
	dec edi
	cresttttt4:
	inc edi
	
	sub esi,1
	cmp matrice[esi],100
	je crestttttt4
	dec edi
	crestttttt4:
	inc edi
	
	sub esi,16
	cmp matrice[esi],100
	je cresttttttt4
	dec edi
	cresttttttt4:
	inc edi

	sub esi,16
	cmp matrice[esi],100
	je crestttttttt4
	dec edi
	crestttttttt4:
	inc edi
	
	add esi,16
	add esi,1
	cmp edi,0
	jne modifica10
	mov edi,20
	modifica10:
	
	mov eax,0
	mov eax,edi
	baga_in_matrice2 esi,al

	
	aici:
		
		inc ecx
		cmp ecx,15
		jbe buc
		jmp centru	
		
	final:
	popa 
	ret
	
pune_poza_cu_cifre endp

                           
 
start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	


	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	mov ebx, 0 ;;;;;;;;;;
	mov ecx,256
	mov esi,0
	afisa:
	push ecx
	mov eax,0
	mov al,matrice[esi]
	push eax
	push offset formatd
	call printf
	add esp,8
	inc esi
	
	;;;;;;;;;;;;;;;;;
	inc ebx
	cmp ebx, 16
	jne sare_peste
	 	
	push offset spatiu
   call printf
   add esp,4
   
   mov ebx, 0
	sare_peste:
	;;;;;;;;;;;;;;;;;;;;;
	pop ecx
	loop afisa
	
	push offset spatiu
   call printf
   
   add esp,4
	
	
	
	mov ecx,16
	mov esi,0
	afiz:
	push ecx
	mov eax,0
	mov al,matrice[esi]
	push eax
	push offset formatd
	call printf
	add esp,8
	inc esi
	pop ecx
	loop afiz
	
	push offset spatiu
   call printf
   
   add esp,4

   
   	mov ecx,16
	mov esi,15
	afizz:
	push ecx
	mov eax,0
	mov al,matrice[esi]
	push eax
	push offset formatd
	call printf
	add esp,8
	add esi,16
	pop ecx
	loop afizz
	
	
		push offset spatiu
   call printf
   
   add esp,4
   
   
   mov ecx,16
	mov esi,240
	afizzz:
	push ecx
	mov eax,0
	mov al,matrice[esi]
	push eax
	push offset formatd
	call printf
	add esp,8
	inc esi
	pop ecx
	loop afizzz
	
	
		push offset spatiu
   call printf
   
   add esp,4
   
   
      mov ecx,16
	mov esi,0
	afizzzz:
	push ecx
	mov eax,0
	mov al,matrice[esi]
	push eax
	push offset formatd
	call printf
	add esp,8
	add esi,16
	pop ecx
	loop afizzzz
	
	
	
	
   

	
	push 0
	call exit
end start
