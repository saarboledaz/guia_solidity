// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Tipo Producto
struct Producto {
    string nombre;
    uint precio; // Precio en Wei
    uint cantidad; // Cantidad de items en stock
    bool promocion; // Si el producto tiene promoción, se le restan 1000 Wei
    bool existe; // Variable de control para verificación de existencia
}

// Tipo Compra
struct Compra {
    address cliente; // Cuenta del Cliente que Compra
    uint valor; // Valor de la Compra en Wei
    
}

// Tipo Cliente
struct Cliente {
    string nombre; // Nombre del cliente
    string pais; // Pais de origen del cliente
    uint gastos; // Total de gastos del cliente
    bool existe; // Variable de control para verificación de existencia
}


contract Tienda {
    
    mapping(string => Producto) private productos; // Mapa de productos
    mapping(address => uint) private cuentas; // Mapa de cuenta del cliente
    mapping(address => Cliente) private clientes; // Mapa de clientes
    Compra[] private compras; // La información de las compras de los clientes es confidencial
    address internal creador; // Variable para guardar la dirección del creador del contrato
    uint internal intentos = 0; // Variable para llevar la cuenta de intentos de autodestrucción
    uint internal maxIntentos = 2; // Número máximo de intentos para destruir el contrato
    uint constant umbralPromocion = 50000; // Umbral de gastos para aplicar una promoción adicional a los productos
    
    // Modificadores

    // Controla que solo se permita ejecución desde el Creador
    modifier soloCreador{
        require(msg.sender == creador, "Solo el creador de la tienda puede utilizar esta funcion");
        _;
    }

    // Controla que solo se permita ejecución si el cliente no tiene deudas
    modifier clienteAlDia{
        require(!(cuentas[msg.sender] > 0), "El cliente tiene deudas.");
        _;
    }

    // Controla que solo se permita ejecución si el cliente está registrado
    modifier clienteRegistrado{
        require(clientes[msg.sender].existe, "El cliente no esta registrado");
        _;
    }

    // Constructor
    constructor(){
        creador = msg.sender; // El creador del contrato es quién lo despliega
    }

    /**
    * Función para registar el cliente, se guarda la dirección del cliente desde la llamada
    * _nombre: Nombre del Cliente
    * _pais: País del Cliente
    **/
    function registrarCliente(string memory _nombre,string memory _pais) public returns(bool){
        require(!clientes[msg.sender].existe,"El cliente ya existe");
        Cliente memory cliente = Cliente(_nombre, _pais,0,true);
        clientes[msg.sender] = cliente;
        return true;
    }

    /**
    * Función para realizar la compra de un producto, puede ser llamada por cualquiera, requiere que el
    * el cliente esté registrado y no tenga deudas, se debe enviar el dinero en la llamada
    * _producto Nombre del producto a comprar
    **/
    function comprar(string memory _producto) public payable clienteRegistrado clienteAlDia returns(bool) {
        Producto memory producto = productos[_producto];
        // Verificar restricciones del producto
        require(producto.existe, "El producto no existe");
        require(producto.cantidad > 0, "El producto no tiene existencias");
        
        uint precio = obtenerPrecio(producto, clientes[msg.sender].gastos); // Precio en Wei
        
        require(precio == msg.value, "El valor enviado es diferente al del producto"); 
        
        Compra memory compra = Compra({
            cliente: msg.sender,
            valor: precio
        });

        // Registrar la compra
        compras.push(compra);

        // Añadir gasto al cliente
        clientes[msg.sender].gastos += precio;

        // Disminuir la cantidad y guardar el cambio
        producto.cantidad--;
        productos[producto.nombre] = producto; 

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
        require(producto.cantidad > 0, "El producto no tiene existencias");

        uint precio = obtenerPrecio(producto, clientes[msg.sender].gastos); // Precio en Wei

        Compra memory compra = Compra({
            cliente: msg.sender,
            valor: precio
        });

        compras.push(compra);

        cuentas[msg.sender] = precio; // Establecer deuda en cuentas

        // Disminuir la cantidad y guardar el cambio
        producto.cantidad--;
        productos[producto.nombre] = producto; 

        return true;        
    }

    /**
    * Función para visualizar la deuda del cliente que la llama, requiere que el cliente esté registrado
    **/
    function verDeuda() public clienteRegistrado view returns(uint) {
        uint deuda = cuentas[msg.sender];
        require(deuda > 0, "El cliente no tiene deudas");

        return deuda;
    }

    /**
    * Función para pagar la deuda que tiene el cliente que la llama, requiere que el cliente esté registrado,
    * se debe enviar la cantidad exacta de wei que se debe con la llamada
    **/
    function pagarDeuda() public clienteRegistrado payable returns(bool){
        uint deuda = cuentas[msg.sender];
        require(deuda > 0, "El cliente no tiene deudas");
        require(msg.value == deuda, "Debe enviar el monto exacto de la Deuda, por favor use verDeuda para conocer este monto");

        cuentas[msg.sender] = 0;

        // Agregar a gastos del cliente
        clientes[msg.sender].gastos += deuda;
        return true;
    }

    /**
    * Función para obtener el verdadero precio de un producto para un cliente
    * producto objeto producto del que se quiere obtener el precio
    * gastosCliente gastos totales del cliente en esta tienda
    **/
    function obtenerPrecio(Producto memory producto, uint gastosCliente) private pure returns(uint) {
        uint precioFinal = producto.precio;
        if(producto.promocion && precioFinal >= 1000) {
            precioFinal -= 1000;
        }

        // Promoción para los clientes que han gastado más de 'umbralPromocion'
        if(gastosCliente >= umbralPromocion && precioFinal >= 2000){
            precioFinal -= 2000;
        }

        return precioFinal;
    }

    /**
    * Función para obtener las ganancias totales de la tienda
    **/
    function obtenerGanancias() public view returns (uint) {
        uint ganancias = 0;
        
        // Iterar sobre todas las compras guardadas
        for(uint i = 0; i < compras.length; i++){
            ganancias += compras[i].valor;
        }

        return ganancias;
    }

    /**
    * Función para obtener los datos actuales del producto, solo puede ser llamada por el creador del contrato
    * _nombre: Nombre del producto
    **/
    function obtenerProducto(string memory _nombre) external view soloCreador returns (Producto memory){
        Producto memory producto = productos[_nombre];
        return producto;
    }

    /**
    * Función para modificar los datos actuales del producto, solo puede ser llamada por el creador del contrato
    * _nombre: Nombre del producto a modificar
    * _precio: Precio nuevo que debe tener el producto, si se desea tener igual debe enviarse un valor negativo
    * _cantidad: Cantidad nueva que debe tener el proucto, si se desea tener igual debe enviarse un valor negativo
    * _promocion: Nuevo valor booleano de si el producto tiene promoción o no
    **/
    function modificarProducto(string memory _nombre, int _precio, int _cantidad, bool _promocion) external soloCreador returns(bool){
        Producto memory producto = productos[_nombre];
        require(producto.existe, "El producto no existe");

        if (_precio >= 0){
            producto.precio = uint(_precio);
        }

        if (_cantidad >= 0){
            producto.cantidad = uint(_cantidad);
        }

        producto.promocion = _promocion;

        productos[_nombre] = producto; 

        return true; // Operación exitosa
    }

    /**
    * Función para crear un nuevo producto, solo puede ser llamada por el creador del Contrato
    * _nombre
    * _precio
    * _cantidad
    * _promocion
    **/
    function crearProducto(string memory _nombre, uint _precio, uint _cantidad, bool _promocion) external soloCreador returns(bool){
        Producto memory productoExistente = productos[_nombre];
        require(!(productoExistente.existe), "Ya existe un producto con este nombre");
        // Crear el producto
        Producto memory producto = Producto({
            nombre:_nombre,
            precio:_precio,
            cantidad:_cantidad,
            promocion:_promocion,
            existe: true
        });

        // Agregarlo al mapa de productos
        productos[_nombre] = producto;
        return true; // Operación exitosa

    }

    /**
    * Función para destruir el contrato y enviar los fondos al creador, solo puede ser llamada por el creador
    * debe ser llamada al menos 'maxIntentos' veces para que tenga efecto
    **/
    function destruirContrato() external soloCreador returns (string memory){
        intentos++;
        if(intentos == maxIntentos){
            selfdestruct(payable(creador)); // Destruir y enviar fondos al creador
            return "Contrato destruido";
        }else{
            return "Si sigue intentando eventualmente el contrato se autodestruira";
        }
    }

    /**
    * Función para obtener los gastos del cliente, se calculan los datos del cliente que llama la función,
    * requiere que el cliente esté registrado, el cálculo se hace verificando cada una de las compras registradas
    **/
    function gastosClienteCalculado() clienteRegistrado public view returns(uint){
        uint gastos = 0;

        // Iterar sobre todas las compras
        for(uint i = 0; i < compras.length; i++){

            // Verificar que la compra sea del cliente
            if(compras[i].cliente == msg.sender){
                gastos += compras[i].valor;
            }
        }

        // Restar el dinero que aún no ha pagado (deudas)
        if (cuentas[msg.sender] > 0){
            gastos -= cuentas[msg.sender];
        }

        return gastos;
    }

    /**
    * Función para obtener los gastos del cliente, se calculan los datos del cliente que llama la función,
    * requiere que el cliente esté registrado, el total se obtiene de la variable gastos que guarda cada cliente
    **/
    function gastosClienteGuardado() clienteRegistrado public view returns(uint){
        return clientes[msg.sender].gastos;
    }

    /**
    * Función para obtener las ganancias obtenidas de clientes de cierto país
    * _pais
    **/
    function obtenerGananciasPais(string memory _pais) public view returns (uint) {
        uint ganancias = 0;

        // Iterar sobre todas las compras
        for(uint i = 0; i < compras.length; i++){
            // Comparar si el cliente de la compra 'i' es del mismo pais que se especifica
            if (compararTexto(_pais,clientes[compras[i].cliente].pais)){
                ganancias += compras[i].valor;
            }
        }
        return ganancias;
    }



    /**
    * Función para comparar el texto, en solidity no es posible comparar dos cadenas de texto
    * para poder fingir algo similar se codifican los bytes de cada cadena y se computa su hash
    * con la función de keccak256, si el hash de dos cadenas es igual, es porque las dos cadenas son iguales
    **/
    function compararTexto(string memory _s1, string memory _s2) internal pure returns (bool){
        return (keccak256(abi.encodePacked(_s1)) == keccak256(abi.encodePacked(_s2))); 
    }
}