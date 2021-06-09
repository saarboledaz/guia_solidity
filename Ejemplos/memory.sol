// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Contador {
    // Todas estas variables se guardan en Storage
    uint public cuenta = 0; 
    uint[] public numeros; // Numeros contados
    string[] public contadores; // Personas que mandan los numeros

    // Es necesario especificar que los argumentos de entrada y salida de la función que son arreglos se almacenan en Memory
    function Contar1(string memory contador, uint numero) public returns (uint[] memory){
        cuenta += numero;
        numeros.push(numero);
        contadores.push(contador);

        // Se crea una nueva instancia en STORAGE
        uint[] storage nuevoNumeros = numeros;

        if (numeros.length - 1 >= 0){
            nuevoNumeros[numeros.length-1] = 0;
        }

        return numeros; // 'numeros' será igual a nuevoNumeros
    }

    function Contar2(string memory contador, uint numero) public returns (uint[] memory){
        cuenta += numero;
        numeros.push(numero);
        contadores.push(contador);

        // Se crea una nueva instancia en MEMORY
        uint[] memory nuevoNumeros = numeros;

        if (numeros.length - 1 >= 0){
            nuevoNumeros[numeros.length-1] = 0;
        }

        return numeros; // 'numeros' será diferente a nuevoNumeros
    }

}