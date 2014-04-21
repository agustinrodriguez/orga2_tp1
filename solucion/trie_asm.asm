; parametros enteros o punteros: RDI, RSI, RDX, RCX, R8 Y R9 y pila
; parametros puntos flotantes: XMM0 ... XMM7

; Convencion C
; Preservar RBX, R12, R13, R14 y R15
; Retornar el resultado en RAX o XMM0

; Byte Registers: AL, BL, CL, DL, DIL, SIL, BPL, SPL, R8L - R15L
; Word Registers: AX, BX, CX, DX, DI, SI, BP, SP, R8W - R15W
; Doubleword Registers: EAX, EBX, ECX, EDX, EDI, ESI, EBP, ESP, R8D - R15D
; Quadword Registers: RAX, RBX, RCX, RDX, RDI, RSI, RBP, RSP, R8 - R15

; nasm -f elf64 -g -F dwarf -o trie_asm.o trie_asm.asm
; gcc -o main main.c trie_asm.o trie_c.c

global trie_crear
global nodo_crear
global insertar_nodo_en_nivel
global trie_agregar_palabra
global trie_construir
global trie_borrar
global trie_imprimir
global buscar_palabra
global palabras_con_prefijo
global trie_pesar
global pesar_listap

extern lista_crear
extern lista_agregar
extern lista_borrar
extern lista_concatenar
extern malloc
extern free
extern fopen
extern fclose
extern fprintf
extern fscanf

; SE RECOMIENDA COMPLETAR LOS DEFINES CON LOS VALORES CORRECTOS
%define offset_sig 0
%define offset_hijos 8
%define offset_c 16
%define offset_fin 17

%define size_nodo 18

%define offset_raiz 0

%define size_trie 8

%define offset_prim 0

%define offset_valor 0
%define offset_sig_lnodo 8

%define NULL 0

%define FALSE 0
%define TRUE 1

%define longitud_max_palabra 1024
%define caracter_invalido 'a'

section .rodata

section .data
modo_apertura: db "a", 0
modo_read: db "r", 0
format_string: db "%s", 0
str_espacio: db " ", 0
str_salto_linea: db 10, 0
str_trie_vacio: db "<vacio>", 10, 0
section .text

; ------------------- FUNCIONES OBLIGATORIAS -------------------

trie_crear:
	push RBP
	mov RBP, RSP

	mov RDI, size_trie ; tamaño de trie para malloc
	call malloc

	mov qword [RAX], NULL

	pop RBP
	ret

trie_borrar: ; RDI -> trie t
	push RBP
	mov RBP, RSP
	push R12
	sub RSP, 8

	mov R12, RDI ; R12 = trie*
	cmp qword [R12 + offset_raiz], NULL ; if (t.raiz == NULL) fin
	je .fin
	mov RDI, [R12 + offset_raiz] ; sino borro el nodo raiz y todos sus sig e hijos
	call nodo_borrar

	.fin:
		mov RDI, R12
		call free
	add RSP, 8
	pop R12
	pop RBP
	ret
	; if (t.raiz != null)  {
	;	nodo_borrar(t.raiz)
	; }
	; free(t)

nodo_crear: ; RDI -> char c
	push RBP
	mov RBP, RSP
	push R12
	sub RSP, 8

	call validar_caracter
	mov byte R12b, AL ; RAX = char c
	mov RDI, size_nodo
	call malloc ; creo un puntero a nodo, RAX = &nodo
	mov qword [RAX + offset_sig], NULL ; nodo.sig = NULL
	mov qword [RAX + offset_hijos], NULL ; nodo.hijos = NULL
	mov [RAX + offset_c], R12B ; nodo.c = R12b
	mov byte [RAX + offset_fin], FALSE ; nodo.fin = false

	add RSP, 8
	pop R12
	pop RBP
	ret

insertar_nodo_en_nivel: ; RDI -> **nodo nivel, RSI -> char c
	push RBP
	mov RBP, RSP
	push R12
	push R13

	mov R12, RDI ; R12 = **nodo nivel
	mov byte R13b, SIL; RSI ; R13b = char c
	mov RDI, [R12] ; RDI = *nodo nivel
	call nodo_buscar 
	cmp RAX, NULL ; if (nodo_buscar(c) != NULL) fin
	jne .fin

	mov DL, R13b ; crea nodo con char c
	call nodo_crear
	
	mov R8, [R12] ; R8 = *nodo_nivel
	cmp R8, NULL ; if (*nodo_nivel != NULL) 
	jne .ciclo ; sigo en .ciclo
	mov [R12], RAX ; sino inserto nuevo_nodo como unico y primero
	jmp .fin 

	.ciclo:
		mov R10b, [RAX + offset_c] ; R10b =  nuevo_nodo.c
		cmp byte R10b, [R8 + offset_c] ; if (nuevo_nodo.c < nodo_nivel.c) insertar adelante
		jl .insertar_adelante
		mov R9, [R8 + offset_sig] ; R9 = nodo_nivel.sig
		cmp R9, NULL ; else if (nodo_nivel.sig = NULL) insertar a lo ultimo
		je .insetar_ultimo
		cmp byte R10b, [R9 + offset_c] ; else if (nuevo_nodo.c < nodo_nivel.sig.c) insertar en medio
		jle .insertar_en_medio
		mov R8, R9 ; R8 = nodo_nivel.sig y avanzo
		jmp .ciclo

	.insertar_adelante:
		mov [RAX + offset_sig], R8 ; nuevo_nodo.sig = nodo_nivel
		mov [R12], RAX ; pongo el nuevo nodo creado como primero en el nivel
		jmp .fin
	.insertar_en_medio:
		mov [R8 + offset_sig], RAX ; nodo_nivel.sig = nuevo_nodo
		mov [RAX + offset_sig], R9 ; nuevo_nodo.sig = nodo_nivel.sig
		jmp .fin
	.insetar_ultimo:		
		mov [R8 + offset_sig], RAX ; nodo_nivel.sig = nuevo_nodo	
		jmp .fin

	.fin:
	pop R13
	pop R12
	pop RBP
	ret

trie_agregar_palabra: ; RDI -> *trie t, RSI -> *char p
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	sub RSP, 8

	mov R12, RDI ; R12 = *trie t
	mov R13, RSI ; R13 = *char p
	lea R14, [R12 + offset_raiz]

	.ciclo:
		cmp byte [R13], 0 ; si termino de recorrer el string, fin
		je .fin
		mov RDI, R14 ; llamo a insertar_nodo_en_nivel con la direccion de hijos del nodo
		mov RSI, [R13] ; y el char
		call insertar_nodo_en_nivel
		lea R14, [RAX + offset_hijos] ; R14 = nodo.hijos
		lea R13, [R13 + 1] ; avanzo sobre el string
		jmp .ciclo

	.fin:
	mov byte [RAX + offset_fin], TRUE ; indico que es fin de palabra
	add RSP, 8
	pop R14
	pop R13
	pop R12
	pop RBP
	ret

trie_construir: ; RDI -> char* nombre_archivo
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	push R15

	mov RSI, modo_read ; asigno segundo parametro; modo de apertura read
	call fopen
	mov R12, RAX ; R12 = *fp pongo en R12 el puntero al archivo
	mov RDI, longitud_max_palabra ; creo un puntero para una palabra acotada
	call malloc
	mov R13, RAX ; R13 = char* palabra
	call trie_crear
	mov R14, RAX ; R14 = trie_crear()

	.ciclo:
		mov RDI, R12 ; primer parametro fp*
		mov RSI, format_string ; formato '%s'
		mov RDX, R13 ; palabra
		call fscanf
		cmp EAX, NULL ; if (fscanf = NULL) salgo
		jle .fin
		; sino agrego palabra
		mov RDI, R14 ; primer parametro trie
		mov RSI, R13 ; segundo parametro palabra para agregar
		call trie_agregar_palabra
		jmp .ciclo

	.fin:
		mov RDI, R13 ; borro el string creado
		call free
		mov RDI, R12 ; cierro el archivo
		call fclose
		mov RAX, R14 ; devuelvo el trie
	pop R15
	pop R14
	pop R13
	pop R12
	pop RBP	
	ret
	; fp = fopen(nombre_archivo)
	; string = malloc(1024)
	; trie = trie_crear()
	; while(fscanf(fp, '%s', string) > 0) {
	; 	trie_agregar_palabra(trie, string)
	; }
	; return trie

trie_imprimir: ; RDI -> *trie, RSI -> *char nombre_archivo 
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	push R15
	push RBX
	sub RSP, 8

	mov R12, RDI ; R12 = *trie
	mov RDI, RSI ; asigno primer parametro del fopen, que es el nombre del archivo
	mov RSI, modo_apertura ; asigno segundo parametro; modo de apertura append
	call fopen
	mov R13, RAX ; R13 = *fp pongo en R13 el puntero al archivo

	mov RDI, 2 ; malloc de 2 posiciones para crear la palabra de 1 caracter
	call malloc ; RAX = char * palabra_1_char
	mov RBX, RAX ; RBX = RAX = char * palabra_1_char

	; armo listaP de palabras del trie para imprimir
	call lista_crear
	mov R15, RAX ; R15 = *ls (lista vacia)

	mov R14, [R12 + offset_raiz] ; R14 = t.raiz
	cmp R14, NULL ; if (t.raiz == NULL) escribir trie vacio
	je .trie_vacio

	.ciclo:
		cmp R14, NULL ; if (nodo_nivel == null) fin
		je .imprimir_palabras

		mov R8B, [R14 + offset_c] ; R8B = char c
		mov byte [RBX], R8B ; primer letra asigno el char
		mov byte [RBX + 1], NULL ; segunda letra asgino el char nulo

		mov RDI, R12 ; primer parametro trie
		mov RSI, RBX ; en el segundo parametro pongo la direccion al char c, como prefijo de una letra
		call palabras_con_prefijo ; RAX = palabras_con_prefijo(t, nodo_nivel.c)

		mov RDI, R15 ; primer parametro *ls (la lista final)
		mov RSI, RAX ; segundo parametro la lista de palabras con prefijo
		call lista_concatenar ; concateno a la lista final la lista de palabras con prefijo
		mov R14, [R14 + offset_sig] ; avanzo por el nivel de la raiz
		jmp .ciclo

	.imprimir_palabras:
		mov RDI, R13 ; primer parametro el *fp
		mov RSI, R15 ; segundo parametro la lista *ls
		call imprimir_listap
		jmp .fin
	.trie_vacio:
		mov RDI, R13 ; primer parametro *fp
		mov RSI, format_string ; segundo parametro formato string %s
		mov RDX, str_trie_vacio ; tercer parametro string de trie vacio
		call fprintf
	.fin:
		mov RDI, R13 ; cierro archivo
		call fclose
		mov RDI, R15 ; borro la lista que ya no necesito
		call lista_borrar
		mov RDI, RBX ; borro el string creado
		call free
	add RSP, 8
	pop RBX
	pop R15
	pop R14
	pop R13
	pop R12
	pop RBP
	ret


buscar_palabra: ; RDI-> trie* t, RSI -> char* palabra
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	push R15

	mov R12, RDI ; R12 = trie* trie
	mov R13, RSI ; R13 = char* palabra
	call palabras_con_prefijo ; RAX = listaP* palabras_con_prefijo(t, palabra)
	mov R12, RAX ; guardo en R12 la listaP*
	mov R14, [RAX + offset_prim] ; R14 = lista.prim

	mov RDI, R13 ; calculo el length de la palabra del parametro
	call longitud_palabra
	mov R15, RAX ; R15 = longitud_palabra(palabra)

	; si algunas de las palabras_con_prefijo tiene la misma cantidad de letras
	; que la palabra dada, quiere decir que pertenece al trie
	.ciclo:
		cmp R14, NULL ; if (nodolista = null) termino de recorrer o es vacia, devuelvo false
		je .devolver_false
		mov RDI, [R14 + offset_valor] ; calculo el length de la palabra de la lista
		call longitud_palabra
		cmp R15D, EAX ; comparo si la longitud es igual, es la misma palabra, devuelvo true
		je .devolver_true
		mov R14, [R14 + offset_sig_lnodo] ; sino avanzo la lista
		jmp .ciclo

	.devolver_true: 
		mov RDI, R12 ; borro la listaP
		call lista_borrar
		mov EAX, TRUE ; resultado = true
		jmp .fin
	.devolver_false: 
		mov RDI, R12 ; borro la listaP
		call lista_borrar
		mov EAX, FALSE ; resultado = false
	.fin:
	pop R15
	pop R14
	pop R13
	pop R12
	pop RBP
	ret

trie_pesar: ; RDI-> trie * t, RSI -> funcion pesar_palabra
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	push R15
	push RBX
	sub RSP, 8

	mov R12, RDI ; R12 = trie* t
	mov R13, RSI ; R13 = funcion pesar

	mov RDI, 2 ; malloc de 2 posiciones para crear la palabra de 1 caracter
	call malloc ; RAX = char * palabra_1_char
	mov RBX, RAX ; RBX = RAX = char * palabra_1_char

	; armo listaP de palabras del trie para imprimir
	call lista_crear
	mov R15, RAX ; R15 = *ls (lista vacia)

	mov R14, [R12 + offset_raiz] ; R14 = t.raiz
	cmp R14, NULL ; if (t.raiz == NULL) escribir trie vacio
	je .devolver_cero

	.ciclo:
		cmp R14, NULL ; if (nodo_nivel == null) fin
		je .pesar

		mov R8B, [R14 + offset_c] ; R8B = char c
		mov byte [RBX], R8B ; primer letra asigno el char
		mov byte [RBX + 1], NULL ; segunda letra asgino el char nulo

		mov RDI, R12 ; primer parametro trie
		mov RSI, RBX ; en el segundo parametro pongo la direccion al char c, como prefijo de una letra
		call palabras_con_prefijo ; RAX = palabras_con_prefijo(t, nodo_nivel.c)

		mov RDI, R15 ; primer parametro *ls (la lista final)
		mov RSI, RAX ; segundo parametro la lista de palabras con prefijo
		call lista_concatenar ; concateno a la lista final la lista de palabras con prefijo
		mov R14, [R14 + offset_sig] ; avanzo por el nivel de la raiz
		jmp .ciclo

	.pesar:
		mov RDI, R15 ; primer parametro la lista *ls
		mov RSI, R13 ; la funcion pesar palabra 
		call pesar_listap
		jmp .fin
	.devolver_cero:
		xor R13, R13
		cvtsi2sd XMM0, R13
	.fin:
		mov RDI, R15 ; borro la lista que ya no necesito
		call lista_borrar
		mov RDI, RBX ; borro el string creado
		call free

	add RSP, 8
	pop RBX
	pop R15
	pop R14
	pop R13
	pop R12
	pop RBP	
	ret

palabras_con_prefijo: ; RDI -> trie *t, RSI -> char *prefijo
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	push R15

	mov R12, [RDI + offset_raiz] ; R12 = t.raiz
	mov R13, RSI ; R13 = char * prefijo
	mov R14, NULL ; R14 = nodo_prefijo = NULL
	call lista_crear
	mov R15, RAX ; creo una lista vacia para las palabras que son como el prefijo

	.ciclo:
		cmp R14, NULL ; if (nodo_prefijo != null) 
		jne .devolver_palabras ; devuelvo las palabras de los hijos del nodo_prefijo
		; sino sigo buscando el nodo_prefijo
		cmp R12, NULL ; if (n == null) devuelvo palabras 
		je .devolver_palabras
		mov RDI, R12 ; sino busco el nodo prefijo de n
		mov RSI, R13 ; segundo parametro prefijo
		call nodo_prefijo
		mov R14, RAX ; R14 = nodo_prefijo(n, prefijo)
		mov R12, [R12 + offset_sig] ; n = n.sig
		jmp .ciclo

	.devolver_palabras:
	cmp R14, NULL ; if (nodo_prefijo == null)
	je .fin

	; agrego las palabra que matchea excatamente con el prefijo
		cmp byte [R14 + offset_fin], TRUE ; si no es el fin de una palabra, fin
		jne .seguir
		; sino agrego la palabra a la lista
		mov RDI, R15 ; primer parametro lista
		mov RSI, R13 ; segundo parametro prefijo
		call lista_agregar
		.seguir:

	mov R14, [R14 + offset_hijos] ; R14 = nodo_prefijo.hijos

	.fin:
		mov RDI, R14 ; primer parametro nodo_prefijo.hijos
		mov RSI, R13 ; segundo parametro prefijo
		call palabras_de_nodo ; RAX = palabras_de_nodo(nodo_prefijo.hijos, prefijo)
		mov RDI, R15 ; concateno la lista de palabras de 1 letra
		mov RSI, RAX ; concateno el resto de las palabras
		call lista_concatenar
		mov RAX, R15 ; devuelvo la lista

	pop R15
	pop R14
	pop R13
	pop R12
	pop RBP
	ret
	; n = t.raiz
	; nodo_prefijo = NULL
	; lista = lista_crear();
	; while (nodo_prefijo == NULL && n != NULL) {
	; 	nodo_prefijo = nodo_prefijo(n, prefijo)
	; 	n = n.sig
	; }

	; if (nodo_prefijo != NULL && nodo_prefijo.fin) {
	;	lista_agregar(lista, prefijo);
	; }

	; return lista_concatenar(lista, palabras_de_nodo(nodo_prefijo.hijos, prefijo))

; ---------- AUXILIARES ----------
validar_caracter: ; RDI -> char c
	cmp DL, "A" ; if (c < 'A') no es mayuscula
	jl .no_es_mayuscula
	; sino comparo con z
	cmp DL, "Z" ; if (c > 'Z') no es mayuscula
	jg .no_es_mayuscula 
	; si es mayuscula lo paso a minuscula
	add DL, 32 ; c = c + 32 que es la transformacion a minuscula
	jmp .fin

	.no_es_mayuscula:
		cmp DL, "0" ; if (c < '0') no es numero
		jl .no_es_numero
		; sino comparo con 9
		cmp DL, "9" ; if (c > '9') no es numero
		jg .no_es_numero
		jmp .fin ; si es numero salgo

	.no_es_numero:
		cmp DL, "a" ; if (c < 'a') no es minuscula
		jl .no_es_minuscula
		; sino comparo con z
		cmp DL, "z" ; if (c > 'z') no es minuscula
		jg .no_es_minuscula
		jmp .fin ; si es minuscula salgo

	.no_es_minuscula:
		mov DL, caracter_invalido ; c = 'a'

	.fin:
	mov AL, DL ; pongo en RAX el resultado
	ret

nodo_buscar: ; RDI-> *nodo_nivel, , RSI -> char c
	mov R8, RDI ; R8 = *nodo_nivel
	.ciclo:
		cmp R8, NULL ; if (nodo_nivel = NULL) devolver null
		je .devolver_null
		cmp byte [R8 + offset_c], SIL ; RSI ; if (nodo_nivel.c = c) devolver encontrado
		je .devolver_encontrado
		mov R8, [R8 + offset_sig]
		jmp .ciclo

	.devolver_null:
		mov RAX, NULL
		jmp .fin
	.devolver_encontrado:
		mov RAX, R8
	.fin:
	ret

nodo_prefijo: ; RDI -> *nodo_nivel, RSI-> char * prefijo
	mov R8, RDI ; R8 = nodo *nodo_nivel
	mov R9, RSI  ; R9 = char *prefijo
	mov byte R10b, [R9] ; R10b = primer_char(*prefijo)
	mov R11, NULL ; R11 = nodo_prefijo = NULL

	cmp byte [R8 + offset_c], R10b ; if (nodo_nivel.c != c) devolver nodo null
	jne .devolver_nodo_null
	mov R11, R8 ; nodo_prefijo = nodo_nivel
	mov R8, [R8 + offset_hijos] ; avanzo por hijos 
	lea R9, [R9 + 1] ; avanzo string
	mov byte R10b, [R9] ; R10b = siguiente_char(prefijo)
	cmp R10b, 0 ; if (fin_string) devolver_nodo
	je .devolver_nodo

	.ciclo:
		cmp R10b, 0 ; if (fin_string) devolver_nodo
		je .devolver_nodo
		cmp R8, NULL ; if (nodo_nivel == NULL) devolver nodo null
		je .devolver_nodo_null
		cmp byte [R8 + offset_c], R10b ; if (nodo_nivel.c != c) devolver nodo null
		jne .avanzar_siguiente
		mov R11, R8 ; nodo_prefijo = nodo_nivel
		mov R8, [R8 + offset_hijos] ; avanzo por hijos 
		lea R9, [R9 + 1] ; avanzo string
		mov byte R10b, [R9] ; R10b = siguiente_char(prefijo)
		jmp .ciclo
		.avanzar_siguiente:
		mov R8, [R8 + offset_sig] ; avanzo por siguiente
		jmp .ciclo

	.devolver_nodo_null:
		mov R11, NULL
	.devolver_nodo:
		mov RAX, R11
	ret
	; c = primer_char(prefijo)
	; nodo_prefijo = null
	;
	; if (n.c == c) {
	;	nodo_prefijo = n
	;	n = n.hijos
	; 	c = siguiente_char(prefijo);	
	;	if (c != 0) {
	; 		while (n != null && c != 0) {
	; 			if (n.c == c) {
	;				nodo_prefijo = n
	; 				n = n.hijos
	; 				c = siguiente_char(prefijo) 
	; 			} else {
	;				if (n.sig != 0) {
	;					n = n.sig	
	;				} else {
	;					nodo_prefijo = null
	;					n = null
	;				}
	;			}
	; 		}
	; 	}
	; } else {
	;	nodo_prefijo = null	
	; }
	; 
	; return nodo_prefijo

palabras_de_nodo: ; RDI -> *nodo_nivel, RSI-> char * prefijo
; devuelve una listaP de palabras que terminan a partir de nodo nivel, siguiendo por sus hijos y siguientes,
; concatenadas con un prefijo pasado por parametro  
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	push R15

	mov R12, RDI ; R12 = nodo* nodo_nivel
	mov R15, RSI ; R15 = char *prefijo

	mov RDI, longitud_max_palabra ; creo un puntero para una palabra acotada
	call malloc
	mov R14, RAX ; R14 = char* palabra

	mov RDI, R14 ; copio el prefijo en R14
	mov RSI, R15 ; en el segundo parametro pongo el prefijo que quiero copiar
	call copiar_palabra; copiar_palabra(char *dest, const char *src)
	; ahora R14 es una copia de prefijo

	call lista_crear ; creo una lista vacia
	mov R13, RAX ; R13 = ls

	.ciclo:
		cmp R12, NULL
		je .fin
		mov RDI, R14 ; primer parametro char* palabra
		mov SIL, [R12 + offset_c] ; segundo parametro puntero al caracter que quiero concatenar
		call concatenar_caracter ; R14 = palabra = concatenar(palabra, n.c)
		cmp byte [R12 + offset_fin], TRUE ; 	if (!n.fin) seguir buscando la palabra por los hijos
		jne .concatenar_con_palabras_de_hijos
		; if (n.fin) agrego la palabra a la lista
		mov RDI, R13 ; primer parametro ls
		mov RSI, R14 ; segundo parametro char* palabra
		call lista_agregar
		.concatenar_con_palabras_de_hijos:
			mov R10, [R12 + offset_hijos]
			cmp R10, NULL ; if (n.hijos == null) avanzar sino llamo recursivamente a palabras_de_nodo con los hijos
			je .avanzar
			mov RDI, R10 ; primer parametro nodo_nivel.hijos
			mov RSI, R14 ; segundo parametro char* palabra
			call palabras_de_nodo ; RAX = palabras_de_nodo(n.hijos, palabra)

			mov RDI, R13 ; primer parametro ls
			mov RSI, RAX ; segundo parametro palabras_de_nodo(n.hijos, palabra)
			call lista_concatenar

		.avanzar:
			mov RDI, R14 ; copio el prefijo en R14
			mov RSI, R15 ; en el segundo parametro pongo el prefijo que quiero copiar
			call copiar_palabra; copiar_palabra(char *dest, const char *src)
			; ahora R14 es una copia de prefijo
			mov R12, [R12 + offset_sig] ; R12 = nodo_nivel.sig
			jmp .ciclo

	.fin:
		mov RDI, R14 ; borro la palabra
		call free
		mov RAX, R13 ; retorno ls
	pop R15
	pop R14
	pop R13
	pop R12
	pop RBP
	ret
	; ls = lista_crear()
	; palabra = copiar(prefijo)
	; while (n != null) {
	; 	palabra = concatenar(palabra, n.c)
	; 	if (n.fin) {
	; 		lista_agregar(ls, palabra)
	; 	}
	; 	if (n.hijos != null) {
	; 		lista_concatenar(ls, palabras_de_nodo(n.hijos, palabra))
	; 	}
	;	palabra = copiar(prefijo)
	; 	n = n.sig
	; }
	; 
	; borrar(palabra)
	; return ls

imprimir_listap: ; RDI -> FILE *fp, RSI -> listaP *ls
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	sub RSP, 8

	mov R12, RDI ; R12 = *fp
	mov R13, RSI ; R13 = *ls
	mov R14, [R13 + offset_prim] ; R14 = *ls.prim
	
	.ciclo:
		cmp R14, NULL
		je .fin
		mov RDI, R12 ; primer parametrp *fp
		mov RSI, format_string ; segundo parametro formato string %s
		mov RDX, [R14 + offset_valor] ; tercer parametro valor de nodo a imprimir
		call fprintf

		; imprimo espacio
		mov RDI, R12 ; primer parametrp *fp
		mov RSI, format_string ; segundo parametro formato string %s
		mov RDX, str_espacio ; tercer parametro espacio a imprimir
		call fprintf

		mov R14, [R14 + offset_sig_lnodo] ; avanzo la lista
		jmp .ciclo

	.fin:
		; imprimo salto de linea
		mov RDI, R12 ; primer parametrp *fp
		mov RSI, format_string ; segundo parametro formato string %s
		mov RDX, str_salto_linea ; tercer parametro salto de linea a imprimir
		call fprintf
	add RSP, 8
	pop R14
	pop R13
	pop R12
	pop RBP
	ret

nodo_borrar: ; RDI -> nodo* nodo
	push RBP
	mov RBP, RSP
	push R12
	sub RSP, 8

	mov R12, RDI ; R12 = *nodo
	cmp qword R12, NULL ; if (nodo = NULL) fin
	je .fin
	cmp qword [R12 + offset_hijos], NULL ; if (nodo.hijos == null) borrar siguientes
	je .borrar_siguientes
	mov RDI, [R12 + offset_hijos] ; sino borro los hijos
	call nodo_borrar

	.borrar_siguientes:
		cmp qword [R12 + offset_sig], NULL ; if (nodo.sig == null) fin
		je .fin
		mov RDI, [R12 + offset_sig] ; sino borro los siguientes
		call nodo_borrar
	.fin:
		mov RDI, R12 ; borro el nodo
		call free
	add RSP, 8
	pop R12
	pop RBP
	ret

pesar_listap: ; RDI -> listaP* ls, RSI -> funcion pesar
	push RBP
	mov RBP, RSP
	push R12
	push R13
	push R14
	push R15

	mov R12, RDI ; R12 = listaP* ls
	mov R13, RSI ; R13 = funcion pesar
	mov R12, [R12 + offset_prim]
	cmp R12, NULL ; if (nodols = null) devolver_cero
	je .devolver_cero

	xor R15, R15 ; R15 = n = 0
	xor R14, R14 ; R14 = suma = 0
	cvtsi2sd XMM2, R14 ; convierto de entero a double

	.ciclo:
		cmp R12, NULL ; if (nodols = null) devolver promedio 
		je .devolver_promedio
		; calculo el peso de la palabra
		mov RDI, [R12 + offset_valor]
		call R13 ; XMM0 = peso_palabra(nodols.valor)
		addsd XMM2, XMM0 ; sumo peso suma += peso_palabra(nodols.valor)
		add R15D, 1 ; sumo 1 a n que es la cantidad de elementos

		mov R12, [R12 + offset_sig_lnodo] ; avanzo la lista
		jmp .ciclo

	.devolver_promedio:
		movdqa XMM0, XMM2 ; pongo la suma en XMM0
		;cvtsi2sd XMM0, R14 ; convierto de entero a double la suma
		cvtsi2sd XMM1, R15 ; convierto de entero a double n
		divsd XMM0, XMM1 ; divido suma por n ; resultado queda en XMM0
		jmp .fin 
	.devolver_cero:
		xor RAX, RAX
		cvtsi2sd XMM0, RAX ; convierto de entero a double
	.fin:
	pop R15
	pop R14
	pop R13
	pop R12
	pop RBP
	ret

longitud_palabra: ; RDI -> char * palabra
	mov byte R8B, [RDI] ; R8b primer caracter de palabra
	xor R9, R9

	.ciclo:
		cmp R8B, NULL ; si es el caracter nulo, devolver contador
		je .salir
		add R9, 1 ; sumo contador
		mov byte R8B, [RDI + R9] ; avanzo string
		jmp .ciclo

	.salir:
	mov RAX, R9
	ret

copiar_palabra: ; RDI -> char *dest, RSI char *src
	xor R8, R8 ; R8 = 0
	mov R9B, [RSI] ; R9B = primera letra de src

	.ciclo:
		cmp R9B, NULL ; si es caracter nulo, salir
		je .salir
		mov byte [RDI + R8], R9B ; pongo en dest carcater de src
		add R8, 1
		mov R9B, [RSI + R8] ; avanzo string
		jmp .ciclo

	.salir:
		mov byte [RDI + R8], NULL ; pongo el caracter nulo al final del destino
	ret

concatenar_caracter: ; RDI -> char * palabra, RSI char caracter
	mov R8B, [RDI] ; R8B = primer letra de palabra
	xor R9, R9
	.ciclo:
		cmp R8B, NULL ; si es el caracter nulo, concatenar el caracter de parametro
		je .concatenar
		add R9, 1
		mov R8B, [RDI + R9] ; avanzo string
		jmp .ciclo

	.concatenar:
		mov byte [RDI + R9], SIL ; copio el caracter
		mov byte [RDI + R9 + 1], NULL ; pongo el caracter nulo al final
	ret