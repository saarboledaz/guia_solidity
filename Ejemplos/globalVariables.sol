// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// Se exponen algunas de las variables globales mas comunes y usadas
contract variablesGlobales {

    address creador;
    uint dineroRecibido = 0;
    constructor(){
        creador = msg.sender; // Variable global que devuelve la direccion del remitente de la llamada actual
    }

    function gasLimit() public view returns(uint[2] memory){
        uint[2] memory gasInfo;
        gasInfo[0] = block.gaslimit; // Limite de Gas del Bloque
        gasInfo[1] = gasleft(); // Gas restante de la llamada

        return gasInfo;
    }

    // Depositar dinero en el contrato
    function depositar() public payable{
        dineroRecibido += msg.value; // Variable global que devuelve el total de Wei enviado en la llamada
    }

    function enviarDinero() public{
        // 'require' sirve para verificar una condicion en especifico, si esta condicion
        // no se cumple se aborta la ejecucion de la llamada y revierte los cambios en el
        // estado del contrato, el segundo argumento es la informacion de fallo que se brindara
        // con el aborto de la llamada
        require(msg.sender == creador, "No es el creador del contrato");

        // La funcion payable hace que sea posible enviar fondos a una direccion
        // La funcion transfer se puede utilizar en todos las direcciones que sean 'payable'
        // y lo que hace es transferir fondos a esa dirección, en caso de una fallo genera una excepcion
        payable(creador).transfer(dineroRecibido); 

        // La funcion send hace exactamente lo mismo, solo que en vez de arrojar una excepcion
        // devuelve el resultado de la operacion
        // bool result = payable(creador).send(dineroRecibido);
    }

    function destruir() public{
        require(msg.sender == creador, "No es el creador del contrato");

        // La funcion 'selfdestruct' recibe una direccion 'payable', destruye el contrato y envia los fondos
        // del mismo a la direccion especificada
        selfdestruct(payable(creador));
    }

    // La lista de variables y funciones globales puede ser visualizada en el siguiente link
    // https://docs.soliditylang.org/en/latest/cheatsheet.html?highlight=global#global-variables

}