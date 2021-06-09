// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract SmartTransaction {
    address payable public sender;
    address payable public receiver;
    uint public transactionValue;
    PossibleStatus public status;
    enum PossibleStatus{Pending, Confirmed, Rejected, Expired}
    bool public balanceReceived = false;
    uint public expirationTime;

    constructor(address _sender, address _receiver,uint _expectedValue, uint _timeToExpire){
        sender = payable(_sender);
        receiver = payable(_receiver);
        transactionValue = _expectedValue;
        expirationTime = block.timestamp + _timeToExpire;
        status = PossibleStatus.Pending;
    }

    modifier onlySender(){
        require(msg.sender == sender, "Solo el remitente de la transaccion puede ejecutar esta funcion");
        _;
    }

    modifier checkExpiration(){
        if(block.timestamp > expirationTime){
            status = PossibleStatus.Expired;
            sender.transfer(transactionValue);  
        }
        _;
    }

    modifier needsResolve(){
        require(status == PossibleStatus.Pending, "La transaccion ya fue definida");
        _;
    }


    function confirm() onlySender checkExpiration needsResolve public{
        status = PossibleStatus.Confirmed;
        receiver.transfer(transactionValue);
    }

    function reject() onlySender checkExpiration needsResolve public{
        status = PossibleStatus.Rejected;
        sender.transfer(transactionValue);
    } 

    function receiveValue() onlySender checkExpiration needsResolve payable public {
        require(balanceReceived == false, "Ya se recibio el dinero previamente");
        require(msg.value == transactionValue , "No es el valor esperado");
        balanceReceived = true;             
    }
}

// Tipo Producto
struct Product {
    string name;
    uint price; // Precio en Wei
    bool exists; // Variable de control para verificación de existencia
}

contract SimpleStore {
    
    mapping(string => Product) private products; // Mapa de productos
    SmartTransaction[] private transactions; // La información de las compras de los clientes es confidencial
    address internal owner; // Variable para guardar la dirección del owner del contrato
    
    modifier onlyOwner{
        require(msg.sender == owner, "Solo el owner de la tienda puede utilizar esta funcion");
        _;
    }

    // Constructor
    constructor(){
        owner = msg.sender; 
    }



    /**
    * Función para realizar la compra de un producto, puede ser llamada por cualquiera, requiere que el
    * el cliente esté registrado y no tenga deudas, se debe enviar el dinero en la llamada
    * _producto Nombre del producto a comprar
    **/
    function buy(string memory _product) public payable returns(address) {
        Product memory product = products[_product];
        // Verificar restricciones del producto
        require(product.exists, "El producto no existe");
            
        require(product.price == msg.value, "El valor enviado es diferente al del producto"); 
        
        // Crear la transaccion inteligente y dar la direccion de este contrato al comprador
        SmartTransaction transaction = new SmartTransaction(msg.sender, owner, product.price,86400);

        transactions.push(transaction);

        return address(transaction);
    }


    /**
    * Función para obtener las ganancias totales de la tienda
    **/
    function getEarnings() public view returns (uint) {
        uint earnings = 0;
        
        // Iterar sobre todas las compras guardadas
        for(uint i = 0; i < transactions.length; i++){
            if (transactions[i].status() == SmartTransaction.PossibleStatus.Confirmed){
                earnings += transactions[i].transactionValue();
            }
        }

        return earnings;
    }

    /**
    * Función para obtener los datos actuales del producto, solo puede ser llamada por el dueño del contrato
    * _nombre: Nombre del producto
    **/
    function getProduct(string memory _name) external view onlyOwner returns (Product memory){
        Product memory product = products[_name];
        return product;
    }

    /**
    * Función para crear un nuevo producto, solo puede ser llamada por el owner del Contrato
    * _nombre
    * _precio
    * _cantidad
    * _promocion
    **/
    function createProduct(string memory _name, uint _price) external onlyOwner returns(bool){
        Product memory existenProduct = products[_name];
        require(!(existenProduct.exists), "Ya existe un producto con este nombre");
        // Crear el producto
        Product memory product = Product({
            name:_name,
            price:_price,
            exists: true
        });

        // Agregarlo al mapa de productos
        products[_name] = product;
        return true; // Operación exitosa

    }

    /**
    * Función para destruir el contrato y enviar los fondos al owner, solo puede ser llamada por el owner
    * debe ser llamada al menos 'maxIntentos' veces para que tenga efecto
    **/
    function destroy() external onlyOwner returns (string memory){
        selfdestruct(payable(owner)); // Destruir y enviar fondos al owner
        return "Contrato destruido";
    }
}