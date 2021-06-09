// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

// Adaptado de https://docs.soliditylang.org/en/latest/solidity-by-example.html al español, para explicar herencia en Solidity

// Subasta simple que permite que varias direcciones pujen por un premio (no se tiene en cuenta)
contract SimpleAuction {

    address payable public beneficiary; // Beneficiario de la Subasta
    uint public auctionEndTime; // Tiempo de fin de la subasta en segundos

    address public highestBidder; // Direccian de la puja mas alta
    uint public highestBid; // Valor de la puja mas alta

    mapping(address => uint) pendingReturns; // Mapa de dinero a devolver a los otros pujantes

    bool ended; // Variable logica que determina si la puja ya termino

    // Errores

    /// La subasta ya termino
    error AuctionAlreadyEnded(); 
    /// La puja es menor a la puja mas alta
    error BidNotHighEnough(uint highestBid); 
    /// La subasta aun no ha terminado
    error AuctionNotYetEnded(); 
    /// Ya se llamo el fin de la subasta
    error AuctionEndAlreadyCalled(); 
    /// No es el beneficiario
    error NotBeneficiary();

    /// Construye el contrato, solo se necesitan el tiempo de la subasta y el beneficiario
    constructor(
        uint _biddingTime,
        address payable _beneficiary
    ) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    /// Recibe una puja y la guarda solo si esta supera la puja actual
    function bid() virtual public payable {
        if (block.timestamp > auctionEndTime) // Verifica que la subasta no haya terminado
            revert AuctionAlreadyEnded();

        if (msg.value <= highestBid) // Verifica que la puja sobrepase la puja actual
            revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid; // Guardar el monto de dinero a devolver a la dirección que previamente sostenía la puja más alta
        }
        // Actualiza los datos de la puja más alta
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    /// Función para devolver el dinero a los pujantes previos, debe ser llamada por el pujante en cuestión
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender]; // Obtener el monto 
        if (amount > 0) {
            pendingReturns[msg.sender] = 0; // Actualizar el monto a 0

            // Enviar monto
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// Terminar la subasta, solo puede ser llamada por el beneficiario
    function auctionEnd() virtual public {
        if (msg.sender != beneficiary)
            revert NotBeneficiary();
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        ended = true;

        // Transferir el dinero al beneficiario
        beneficiary.transfer(highestBid);
    }
}

// Subasta a ciegas, no tiene limite de tiempo, para cada puja se guarda un hash con la informacion de la puja, lo que asegura que sea a ciegas
// A llegar el tiempo de revelacion, se revelan todas las pujas y se designa el ganador de la subasta, finalmente se devuelve el dinero al resto
// de pujantes
contract BlindAuction is SimpleAuction {
    // Estructura de Subasta
    struct Bid {
        bytes32 blindedBid; 
        uint deposit;
    }

    uint public revealEnd; // Tiempo en segundos de la revelacion de la subasta

    mapping(address => Bid[]) public bids; // Mapa de direcciones a arreglos de subastas, una misma direccion puede realizar varias subastas

    /// Muy temprano para llamar esta funcion
    error TooEarly(uint time);
    /// Muy tarde para llamar esta funcion
    error TooLate(uint time);

    modifier onlyBefore(uint _time) {
        if (block.timestamp >= _time) revert TooLate(_time);
        _;
    }
    modifier onlyAfter(uint _time) {
        if (block.timestamp <= _time) revert TooEarly(_time);
        _;
    }

    /// Construye el contrato, instanciado el constructor del padre y la variable de fin de revelacion de la subasta
    constructor(uint _biddingTime,uint _revealTime,address payable _beneficiary) SimpleAuction(_biddingTime, _beneficiary) {
        revealEnd = auctionEndTime + _revealTime;
    }

    
    /// Realiza una puja a ciegas donde _blindedBid es el hash de los datos de la puja, igual a keccak256(abi.encodePacked(value, fake, secret))
    /// La puja es valida si "deposit" (el valor enviado) es al menos "value" y "fake" es falso
    /// Si se configura "fake" como verdadero y no se envía el valor exacto de "value" es una forma
    /// de ocultar la verdadera puja, aun asi se requiere que se haga un deposito.
    /// 'secret' es simplemente una contraseña que uso el pujante para la encriptacion
    /// El ether enviado solo será reembolsado solo si la puja es correctamente revelada en la fase de revelacion de pujas 
    /// Solo puede ser llamada antes del fin de la subasta (periodo de pujas)
    function bid(bytes32 _blindedBid) public payable onlyBefore(auctionEndTime)
    {
        // Agregar la puja a la lista de pujas del pujante
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }

    /// Funcion que debe ser llamada por cada pujante para revelar sus pujas
    /// El pujante recibira un reembolso de ether por cada puja correctamente revelada
    /// sean validas o invalidas, a excepcion de la puja ganadora.
    /// Solo puede ser llamada despues del periodo de pujas y antes del fin de revelacion de pujas
    function reveal(
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
    )
        public
        onlyAfter(auctionEndTime)
        onlyBefore(revealEnd)
    {
        // Verificar que se hayan provisto los datos suficientes para revelar todas las pujas hechas
        uint length = bids[msg.sender].length; 
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund; // Dinero de reembolso

        for (uint i = 0; i < length; i++) { // Iterar sobre cada puja
            Bid storage bidToCheck = bids[msg.sender][i];
            // Obtener los datos de la puja, encriptar y comparar con el hash guardado previamente

            (uint value, bool fake, bytes32 secret) =
                    (_values[i], _fake[i], _secret[i]);
            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                continue; // Si el hash no coincide ignorar esta puja ya que no fue correctamente revelada
            }

            refund += bidToCheck.deposit;

            // Verificar que sea una puja valida y de ser asi ubicar la puja 
            // y disminuir el valor reembolsar por revelacion
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            bidToCheck.blindedBid = bytes32(0); // Modificar el hash para que esta puja no se pueda volver a revelar
        }
        payable(msg.sender).transfer(refund); // Finalmente enviar el dinero total de reembolso por revelacion
    }

    /// Finalizar la subasta, sobreescribe la funcion del padre ya que esta solo puede ser llamada
    /// despues de finalizar las revelaciones de pujas, sin embargo luego llama a la funcion del padre
    /// para realizar los efectos de finalizacion
    function auctionEnd()
        override
        public
        onlyAfter(revealEnd)
    {
        SimpleAuction.auctionEnd();
    }

    /// Registra las puja valida enviada, solo si esta supera la mayor puja actual
    /// Solo puede ser usada internamente
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// Sobreescribir la funcion del padre para que se use la nueva funcion que requiere un parametro
    function bid() override public payable {
        revert("Funcion erronea, debe enviar la puja encriptada");
    }
}

// Subasta con etapa de revelacion y pujas falsas, cada direccion puede realizar multiples pujas falsas y verdaderas,
// las pujas deben ser reveladas en la fase de revelacion donde se decide que pujas realmente se haran y el dinero que se 
// debe reembolsar a los pujantes
contract RevealAuction is SimpleAuction {
    // Estructura de Subasta
    struct Bid {
        bool fake; 
        uint deposit;
    }

    uint public revealEnd; // Tiempo en segundos de la revelacion de la subasta

    mapping(address => Bid[]) public bids; // Mapa de direcciones a arreglos de subastas, una misma direccion puede realizar varias subastas

    /// Muy temprano para llamar esta funcion
    error TooEarly(uint time);
    /// Muy tarde para llamar esta funcion
    error TooLate(uint time);

    modifier onlyBefore(uint _time) {
        if (block.timestamp >= _time) revert TooLate(_time);
        _;
    }
    modifier onlyAfter(uint _time) {
        if (block.timestamp <= _time) revert TooEarly(_time);
        _;
    }

    /// Construye el contrato, instanciado el constructor del padre y la variable de fin de revelacion de la subasta
    constructor(uint _biddingTime,uint _revealTime,address payable _beneficiary) SimpleAuction(_biddingTime, _beneficiary) {
        revealEnd = auctionEndTime + _revealTime;
    }

    
    /// Realiza una puja a ciegas donde "_fake" es un booleano que define si la puja es verdadera o falsa
    /// Solo puede ser llamada antes del fin de la subasta (periodo de pujas)
    function bid(bool _fake) public payable onlyBefore(auctionEndTime)
    {
        // Agregar la puja a la lista de pujas del pujante
        bids[msg.sender].push(Bid({
            fake: _fake,
            deposit: msg.value
        }));
    }

    /// Funcion que debe ser llamada por cada pujante para revelar sus pujas
    /// es decir, ponerlas en accion
    function reveal() public onlyAfter(auctionEndTime) onlyBefore(revealEnd){
        // Verificar que se hayan provisto los datos suficientes para revelar todas las pujas hechas
        uint length = bids[msg.sender].length; 

        uint refund; // Dinero de reembolso

        for (uint i = 0; i < length; i++) { // Iterar sobre cada puja
            Bid storage bidToCheck = bids[msg.sender][i];

            refund += bidToCheck.deposit;

            // Verificar que sea una puja valida y de ser asi ubicar la puja 
            if (!bidToCheck.fake) {
                if (placeBid(msg.sender, bidToCheck.deposit))
                    refund -= bidToCheck.deposit;
            }
            bidToCheck.deposit = 0; // Modificar el valor para que no se vuelva a revelar esta puja
        }
        pendingReturns[msg.sender] += refund; // Finalmente añadir al dinero total que puede reembolsar
    }

    /// Finalizar la subasta, sobreescribe la funcion del padre ya que esta solo puede ser llamada
    /// despues de finalizar las revelaciones de pujas, sin embargo luego llama a la funcion del padre
    /// para realizar los efectos de finalizacion
    function auctionEnd()
        override
        public
        onlyAfter(revealEnd)
    {
        SimpleAuction.auctionEnd();
    }

    /// Registra las puja valida enviada, solo si esta supera la mayor puja actual
    /// Solo puede ser usada internamente
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// Sobreescribir la funcion del padre para que se use la nueva funcion que requiere un parametro
    function bid() override public payable {
        revert("Funcion erronea, debe enviar la puja encriptada");
    }
}