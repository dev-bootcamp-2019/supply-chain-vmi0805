pragma solidity ^0.5.0;

contract SupplyChain {

  address owner;
  uint skuCount;

  mapping (uint => Item) public items;
  
  enum State { ForSale, Sold, Shipped, Received }
//   State public state;
  
  struct Item {
     string name;
     uint sku;
     uint price;
     State state;
     address payable seller;
     address payable buyer;
  }

  event ForSale(uint sku);
  event Sold(uint sku);  
  event Shipped(uint sku);
  event Received(uint sku);

  modifier ownerCheck () {
      require(msg.sender == owner, 'only contract owner');
      _;
  }

  modifier verifyCaller (address _address) { require (msg.sender == _address); _;}
  modifier paidEnough(uint _price) { require(msg.value >= _price, 'not enough funds to buy'); _;}
  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }
 
  modifier forSale(uint _sku){
      require(items[_sku].state == State.ForSale, 'not marked for sale');
      _;
  }
  modifier sold(uint _sku){
      require(items[_sku].state == State.Sold, 'not marked for sale');
      _;
  }
  modifier shipped(uint _sku){
      require(items[_sku].state == State.Shipped, 'not shipped yet');
      _;
  }
  modifier received(uint _sku){
      require(items[_sku].state == State.Received, 'not received yet');
      _;
  }

  constructor() public {
      owner == msg.sender;
      skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns(bool){
    emit ForSale(skuCount);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;
    return true;
  }

  function buyItem(uint _sku)
    public
    payable
    forSale(_sku)
    paidEnough(items[_sku].price)
    checkValue(_sku)
  {
     items[_sku].buyer = msg.sender;
    //  items[_sku].seller = owner;
     items[_sku].state = State.Sold;
     items[_sku].seller.transfer(items[_sku].price);
     emit Sold(_sku);
  }

  modifier checkIfSold(uint _sku) {
      require(items[_sku].state == State.Sold);
      _;
  }
  modifier checkIfSeller(uint _sku) {
     require(msg.sender == items[_sku].seller);
      _; 
  }
  function shipItem(uint _sku)
    public
    checkIfSold(_sku)
    checkIfSeller(_sku)
  {
      items[_sku].state = State.Shipped;
      emit Shipped(_sku);
  }

  modifier checkIfShipped(uint _sku) {
      require(items[_sku].state == State.Shipped);
      _;
  }
  modifier checkIfBuyer(uint _sku) {
     require(msg.sender == items[_sku].buyer);
      _; 
  }
  function receiveItem(uint _sku)
    checkIfShipped(_sku)
    checkIfBuyer(_sku)
    public
  {
      items[_sku].state = State.Received;
      emit Received(_sku);
  }

  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}