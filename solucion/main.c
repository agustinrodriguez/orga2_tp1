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

	// printf("peso palabra aaa %f", peso_palabra("aaa"));
	// double peso_trie = trie_pesar(mi_trie, &peso_palabra);
	// printf("trie pesar %f", peso_trie);

	listaP* prediccion = predecir_palabras(mi_trie, "22");
	print_listap(prediccion);

	lista_borrar(prediccion);
	trie_borrar(mi_trie);
    return 0;
}

