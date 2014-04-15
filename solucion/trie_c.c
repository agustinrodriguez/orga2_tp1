#include "trie.h"
#include "listaP.h"

// Completar las funciones en C.

listaP *predecir_palabras(trie *t, char *teclas) {
	listaP * prediccion = lista_crear();
	/*listaP * combinaciones = lista_crear();
	int len_teclas = strlen(teclas);
	int i = 0;

	while (i < len_teclas) {
		agregar_combinaciones(combinaciones, caracteres_de_tecla(teclas[i]));
		i++;
	}

	lsnodo * nodo_combinacion = combinaciones->prim;

	while (nodo_combinacion != 0) {
		lista_concatenar(prediccion, palabras_con_prefijo(t, nodo_combinacion->valor));
		nodo_combinacion = nodo_combinacion->sig;
	}

	lista_borrar(combinaciones);*/

	return prediccion;
}

/*listaP *concatenar_combinacion(char *valor, char *caracteres) {
	listaP * lista = lista_crear();

	int len_caracteres = strlen(caracteres);
	int i = 0;
	char palabra[1024];

	while(i < len_caracteres) {
		strcpy(palabra, valor);
		strcat(palabra, caracteres[i]);
		lista_agregar(lista, palabra);
		i++;
	}	

	return lista;
}

void crear_primeras_combinaciones(listaP* lista, char * caracteres) {
	int len_caracteres = strlen(caracteres);
	int i = 0;
	char palabra[1024];

	while(i < len_caracteres) {
		palabra[0] = caracteres[i];
		lista_agregar(lista, palabra);
		i++;
	}
}

void agregar_combinaciones(listaP* combinaciones, char* caracteres) {
	lsnodo * nodo_lista = combinaciones->prim;
	if (nodo_lista == 0) {
		crear_primeras_combinaciones(combinaciones, caracteres);
	} else {
		listaP* nuevas_combinaciones = lista_crear;
		while (nodo_lista != 0) {
			lista_concatenar(nuevas_combinaciones, concatenar_combinacion(nodo_lista->valor, caracteres));
			nodo_lista = nodo_lista->sig;
		}
		lista_borrar(combinaciones); // borro las combinaciones viejas
		combinaciones = nuevas_combinaciones;
	}

}*/

double peso_palabra(char *palabra) {
	int length = strlen(palabra);
	int suma = 0;
	int n = 0;

	while (n < length) {
		suma += (int) palabra[n];
		n++;
	}

	if (n == 0) {
		return 0;
	} else {
		return suma / n;
	}
}

char* caracteres_de_tecla(char tecla) {
	if (tecla == '1') {
		return "1";
	} else if (tecla == '2') {
		return "2abc";
	} else if (tecla == '3') {
		return "3def";
	} else if (tecla == '4') {
		return "4ghi";
	} else if (tecla == '5') {
		return "5jkl";
	} else if (tecla == '6') {
		return "6mno";
	} else if (tecla == '7') {
		return "7pqrs";
	} else if (tecla == '8') {
		return "8tuv";
	} else if (tecla == '9') {
		return "9wxyz";
	} else if(tecla == '0'){
		return "0";
	}
}