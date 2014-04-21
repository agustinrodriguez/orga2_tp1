#include <stdio.h>
#include "trie.h"

int main(void) {
	trie* mi_trie;

	// mi_trie = trie_crear();
	// trie_agregar_palabra(mi_trie, "caza");
	// trie_agregar_palabra(mi_trie, "comida");
	// trie_agregar_palabra(mi_trie, "cazador");
	// trie_agregar_palabra(mi_trie, "ala");
	// trie_agregar_palabra(mi_trie, "come");
	// trie_agregar_palabra(mi_trie, "comere");
	
	mi_trie = trie_construir("mi_trie.txt");

	trie_imprimir(mi_trie, "main.txt");

	// int esta = buscar_palabra(mi_trie, "cazadora");
	// char* esta_string = esta ? "true" : "false";
	// printf("Esta cazadora? %s", esta_string);

	// double peso_trie = trie_pesar(mi_trie, &peso_palabra);
	// printf("trie pesar %f", peso_trie);
	// printf("\npeso palabra abcd %f", peso_palabra("come"));

	// listaP* lista_para_pesar = lista_crear();
	// lista_agregar(lista_para_pesar, "a");
	// lista_agregar(lista_para_pesar, "ala");
	// lista_agregar(lista_para_pesar, "caza");
	// lista_agregar(lista_para_pesar, "cazador");
	// lista_agregar(lista_para_pesar, "comida");
	// lista_agregar(lista_para_pesar, "come");
	// double peso_lista = pesar_listap(lista_para_pesar, &peso_palabra);
	// printf("\npesar_listap %f", peso_lista);

	// listaP* prediccion = predecir_palabras(mi_trie, "22");
	// print_listap(prediccion);
	// lista_borrar(prediccion);

	// listaP* palabras = palabras_con_prefijo(mi_trie, "comi");
	// print_listap(palabras);
	// lista_borrar(palabras);

	trie_borrar(mi_trie);
    return 0;
}

