// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
    Contrato RegistroCliente, Contiene todas las funciones para manejar un registro de clientes en 
    un contrato, puede pensarse como algo similar a añadir una capa de autenticación a una aplicación web
 */
contract RegistroCliente {

    // Estructura de Cliente
    struct Cliente {
        bytes32 nombre;
        address direccion;
        int saldo;
        bool existe;
    }

    mapping(address => Cliente) public clientes; // Mapa de Clientes
    address[] internal listaClientes; // Lista de las direcciones de los clientes

    // Modificadores de verificación

    modifier clienteRegistrado{
        require(clientes[msg.sender].existe, "El cliente no esta registrado");
        _;
    }

    modifier clienteAlDia virtual{
        require(clientes[msg.sender].saldo >= 0, "El cliente no esta al dia");
        _;
    }

    // Funciones de interés para un registro de Clientes

    /**
    *   Registra un cliente en el contrato e inicia su saldo
     */
    function registrarCliente(bytes32 _nombre) public returns(bool) {
        require(!clientes[msg.sender].existe, "El cliente ya esta registrado");
        Cliente memory cliente = Cliente(_nombre, msg.sender, 0, true);
        clientes[msg.sender] = cliente;
        listaClientes.push(msg.sender);
        return true;
    }

    /*
    *   Obtiene el saldo de una cliente registrado.
     */
    function obtenerSaldo() public clienteRegistrado view returns (int) {
        return clientes[msg.sender].saldo;
    }

    /*
    *   Modifica el saldo de un cliente con la dirección brindada
    *   la función es virtual y los contratos que hereden de este podrían
    *   modificarla
    */
    function modificarSaldo(address dirCliente, int valor) virtual public returns(int) {
        clientes[dirCliente].saldo += valor;
        return clientes[dirCliente].saldo;
    }
}

/*
*   Contrato TieneCreador, brinda las capacidades para que un contrato tenga creador
 */
contract TieneCreador {
    address payable public creador; // Dirección del Creador del Contrato
    constructor(){
        creador = payable(msg.sender);
    }

    modifier esCreador{
        require(msg.sender == creador, "Debe ser el creador del contrato");
        _;
    }
}

/*
*   Contrato Destructible, brinda las capacidades para que un contrato sea destructible
 */
contract Destructible is TieneCreador{
    /*
    *   Función para destruir el contrato, solo puede ser llamada por el creador
    *   y puede ser modificada
     */
    function destruir() esCreador virtual public {
        selfdestruct(creador);
    }
}

/*
*   Contrato RegistroTransaccion, contiene todas las funciones para manejar un registro de
*   transacciones en un contrato.
 */
contract RegistroTransaccion{
    // Estructura de una Transaccion
    struct Transaccion {
        address direccion;
        int monto;
    }

    Transaccion[] public transacciones; // Lista de transacciones

    // Funciones de interés para un registro de Clientes


    /*
    *   Registra una transacción en la lista de transacciones
     */
    function registrarTransaccion(Transaccion memory _transaccion) virtual public returns(bool){
        transacciones.push(_transaccion);
        return true;
    }

    /*
    *   Sumariza el monto total de todas las transacciones
     */
    function sumarizar() virtual internal returns(int){
        int balance = 0;
        for (uint256 i = 0; i < transacciones.length; i++) {
            balance += transacciones[i].monto;
        }
        return balance;
    }

    /*
    *   Sumariza el monto total de todas las transacciones de una dirección
     */
    function sumarizarPorDireccion(address direccion) virtual public returns (int){
        int balance = 0;
        for (uint256 i = 0; i < transacciones.length; i++) {
            if(transacciones[i].direccion == direccion){
                balance += transacciones[i].monto;
            }
        }

        return balance;
    }
    
}


/*
*   Contrato Tienda, representa una tienda en la que se puede comprar y fiar, hereda múltiples contratos
*   de utilidad, la tienda necesita registrar clientes, transacciones, debe tener un creador y debe poder 
*   'destruirse'
 */
contract Tienda is RegistroCliente, RegistroTransaccion, TieneCreador, Destructible {

    struct Producto {
        string nombre;
        uint precio; // Precio en Wei
        bool existe; // Variable de control para verificación de existencia
    }

    mapping(string => Producto) private productos; // Mapa de productos

    /**
    * Función para realizar la compra de un producto, puede ser llamada por cualquiera, requiere que el
    * el cliente esté registrado y no tenga deudas, se debe enviar el dinero en la llamada
    * _producto Nombre del producto a comprar
    **/
    function comprar(string memory _producto) public payable clienteRegistrado clienteAlDia returns(bool) {
        Producto memory producto = productos[_producto];
        // Verificar restricciones del producto
        require(producto.existe, "El producto no existe");
        
        uint precio = producto.precio;
        
        require(precio == msg.value, "El valor enviado es diferente al del producto"); 
        
        Transaccion memory transaccion = Transaccion(msg.sender,int(precio));

        // Registrar la compra
        registrarTransaccion(transaccion);
        return true;
    }

    /**
    * Función para fiar un producto, puede ser llamada por cualquiera, requiere que el cliente esté
    * registrado y no tenga deudas, no se envía dinero al llamarse la función, registrar esta compra fiada
    * representará una deuda para el cliente
    * _producto Nombre del producto a comprar
    **/
    function fiar(string memory _producto) public clienteRegistrado clienteAlDia returns(bool){
        Producto memory producto = productos[_producto];
        require(producto.existe, "El producto no existe");

        uint precio = producto.precio;
        Transaccion memory transaccion = Transaccion(msg.sender,int(precio));

        modificarSaldo(msg.sender, -int(precio));

        // Registrar la compra
        registrarTransaccion(transaccion);
        return true;        
    }

    /**
    * Función para visualizar la deuda del cliente que la llama, requiere que el cliente esté registrado
    **/
    function verDeuda() public clienteRegistrado view returns(int) {
        int deuda = clientes[msg.sender].saldo;
        require(deuda < 0, "El cliente no tiene deudas");

        return -deuda;
    }

    /**
    * Función para pagar la deuda que tiene el cliente que la llama, requiere que el cliente esté registrado,
    * se debe enviar la cantidad exacta de wei que se debe con la llamada
    **/
    function pagarDeuda() public clienteRegistrado payable returns(bool){
        int deuda = clientes[msg.sender].saldo;
        require(deuda < 0, "El cliente no tiene deudas");

        clientes[msg.sender].saldo += int(msg.value);

        return true;
    }

    /*
    *   Función para obtener la suma de dinero gastado por un cliente en la tienda, sobreescribe 
    *   la función del padre para restarle el saldo que debe el cliente por compras fiadas
     */
    function sumarizarPorDireccion(address direccion) override public returns (int){
        int saldo = clientes[direccion].saldo;

        int balance = RegistroTransaccion.sumarizarPorDireccion(direccion);

        return balance + saldo;
    }
    
}

/*
*   Contrato Banco, representa un banco en el que los clientes pueden prestar, depositar y sacar dinero,
*   debe registrar clientes y las transacciones con la bolsa del banco que hagan los mismos, debe ser destructible
 */
contract Banco is RegistroCliente, RegistroTransaccion, TieneCreador, Destructible {
    uint public dinero = 0; // Bolsa de dinero del Banco

    /*
    *   Función que permite a un cliente prestar dinero del banco, siempre y cuando el cliente
    *   esté al día (no tenga deudas con el banco) y el banco tenga el dinero que quieren prestar
     */
    function prestar(uint monto) public clienteRegistrado clienteAlDia returns(bool){
        require(dinero > monto, "El banco no tiene fondos suficientes para prestar dinero");
        
        clientes[msg.sender].saldo -=  int(monto);
        dinero -= monto;

        Transaccion memory transaccion = Transaccion(msg.sender,-int(monto));
        registrarTransaccion(transaccion);

        payable(msg.sender).transfer(monto);
        return true;
    }

    /*
    *   Función que permite a un cliente depositar dinero en el banco banco, depositar dinero
    *   incrementa su saldo
     */
    function depositar() payable public clienteRegistrado returns(bool){
        clientes[msg.sender].saldo += int(msg.value);
        dinero += msg.value;
        

        Transaccion memory transaccion = Transaccion(msg.sender,int(msg.value));
        registrarTransaccion(transaccion);
        return true;
    }

    /*
    *   Función que permite a un cliente sacar dinero que ha depositado previamente, en caso
    *   de que el banco no tenga el dinero del cliente, enviarle todo el dinero disponible
     */
    function sacar(uint monto) public clienteRegistrado clienteAlDia returns(bool) {
        require(int(monto) <= clientes[msg.sender].saldo, "No puede sacar mas dinero del que tiene");
        
        if (monto > dinero){
            monto = dinero;
        }
        clientes[msg.sender].saldo -= int(monto);
        dinero -= monto;

        Transaccion memory transaccion = Transaccion(msg.sender, -int(monto));
        transacciones.push(transaccion);
        payable(msg.sender).transfer(monto);
        return true;
    }

    /*
    *   Función de destrucción del banco, se encarga de devolver todo el dinero posible
    *   a los clientes que tengan dinero depositado en el banco, finalmente llama la función de destrucción
    *   del padre
     */
    function destruir() esCreador override public{

        for (uint256 i = 0; i < listaClientes.length; i++) {
            address dirCliente = listaClientes[i];
            int saldo = clientes[dirCliente].saldo;
            if (saldo > 0){
                if (uint(saldo) >= dinero){
                    payable(dirCliente).transfer(dinero);
                    break;
                }else{
                    dinero -= uint(saldo);
                    payable(dirCliente).transfer(uint(saldo));
                }
            }
        }

        Destructible.destruir();
    }
}