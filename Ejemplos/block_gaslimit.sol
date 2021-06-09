// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract MyContract {

    // Función para revisar el límit de gas del bloque, y si este cambia entre llamadas
    function checkGasLimit() public returns (uint[2] memory){
        uint256 curGasLimit = block.gaslimit;
        uint[2] memory gasDiff;
        gasDiff[0] = curGasLimit;
        gasDiff[1] = block.gaslimit;
        return gasDiff;
    }

}

