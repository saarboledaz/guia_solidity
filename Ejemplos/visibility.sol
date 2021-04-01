// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


// Inspirado en https://solidity-by-example.org/visibility/
contract Base {
    // Una función privada que solo puede ser llamada desde este contrato
    // Otros contratos que hereden de este contrato no pueden llamar esta función
    function privateFunc() private returns (string memory) {
        return "funcion privada llamada";
    }

    // Función pública para probar la visibilidad de la función privada
    function testPrivateFunc() public returns (string memory) {
        return privateFunc();
    }

    // Una función interna puede ser llamada desde:
    // - Este mismo contrato
    // - Contratos que hereden de este contrato
    function internalFunc() internal returns (string memory) {
        return "funcion interna llamada";
    }

    // Función pública para probar la visibilidad de la función privada
    function testInternalFunc() public virtual returns (string memory) {
        return internalFunc();
    }

    // Una función pública puede ser llamada desde:
    // - Este mismo contrato
    // - Otros contratos que deriven de este contrato
    // - Otros contratos y cuentas
    function publicFunc() public returns (string memory) {
        return "funcion publica llamada";
    }

    // Una función externa solo puede ser llamada desde otros contratos y cuentas, que no deriven de el mismo
    function externalFunc() external returns (string memory) {
        return "funcion externa llamada";
    }

    // Esta función con compilara ya que estamos tratando de llamar
    // una función externa desde el mismo contrato
    // function testExternalFunc() public returns (string memory) {
    //     return externalFunc();
    // }

    // Variables de estado
    string private privateVar = "mi variable privada";
    string internal internalVar = "mi variable interna";
    string public publicVar = "mi variable publica";
    // Las variables de estado no pueden ser externas, este código no compilaría
    // string external externalVar = "my external variable";
}

contract Child is Base {
    // Los contratos que heredan no tienen acceso a funciones privadas y variables de estado

    // function testPrivateFunc() public pure returns (string memory) {
    //     return privateFunc();
    // }

    // La función interna puede ser llamada desde este contrato
    function testInternalFunc() public override returns (string memory) {
        return internalFunc();
    }
}

contract Outsider {
    Base bs = new Base();
    
    // Las funciones externas pueden ser llamadas por otros contratos y cuentas
    function testExternalFunc() public returns (string memory){
        return bs.externalFunc();
    }

    // Los contratos externos no pueden utilizar funciones internas, este código no compila
    // function testInternalFunc() public returns (string memory){
    //     return bs.internalFunc();
    // }
}
