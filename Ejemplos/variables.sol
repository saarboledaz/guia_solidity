// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract BaulVariables {
    // Direccion de una cuenta u otro contrato en la red de Ethereum
    address public direccion;

    // Una direccion a la que se puede enviar ETH
    address payable public direccionPagable;

    // Una variable que puede contener numeros positivos, desde el 0 hasta 2^256, existe uint8, uint16 y asi
    // sucesivamente hasta uint256
    uint256 public contador = 0;

    // Una variable que puede contener numeros positivos y negativos, desde -2^255 hasta 2^255-1, igual que uint
    // existe int8,int16 y asi sucesivamente hasta int256
    int256 public restador = -5;

    // Variable logica, existen los siguientes operadores logicos
    // !    =>  Negacion
    // &&   =>  Conjuncion (y)
    // ||   =>  Disyuncion (o)
    // ==   =>  Igualdad
    // !=   =>  Desigualdad
    bool public mentiroso = !false;

    // Un arreglo de bytes con tamaño fijo
    bytes32 public arregloBytes;

    // Un arreglo de bytes dinamico
    bytes public arregloDinamico;

    // Un arreglo de caracteres
    string public arregloCaracteres;

    // Definicion de un Tipo, que puede tomar una seleccion especifica de valores
    // Los tipos en realidad son iguales a un numero entero, en este caso
    //                  |---0---|---1---|---2---|
    enum TiposDeMemoria {Stack, Memory, Storage}

    // Es posible asignar una variable a unos de los posibles valores del tipo
    TiposDeMemoria public memoria = TiposDeMemoria.Memory;

    // Es posible definir nuevos tipos como estructuras de datos especificos
    // como una especie de interfaz para instanciar objetos, como con los arreglos
    // y mapas, pueden contener en si mismos otros tipos, lo que los convierte en 
    // tipos complejos
    struct Cliente {
        address direccion;
        string nombre;
        uint edad;
        int deuda;
    } 

    // Mapa de direcciones a clientes, es posible declarar mapas siempre que 
    // cumplan la posiblidad llave-valor, donde la llave tiene que ser un tipo
    // nativo y el valor si puede ser cualquier tipo incluyendo otros mapas, arreglos
    // y estructuras

    // Los mapas solo pueden ser almacenados en Storage
    mapping(address => Cliente) clientes;
}