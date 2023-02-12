// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract SupplyChain {

  address public owner;

  uint public skuCount = 0;

  mapping (uint => Item) items;

  enum State {ForSale, Sold, Shipped, Received}
  
  event LogForSale(uint sku);

  event LogSold(uint sku);

  event LogShipped(uint sku);

  event LogReceived(uint sku);

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }


  modifier isOwner {
    require(msg.sender == owner);
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    address payable buyer = payable(msg.sender);
    buyer.transfer(amountToRefund);
  }


  modifier forSale(uint _sku) {
    // Check item exists
    require (items[_sku].price != 0);
    // Check item has no buyer
    require(items[_sku].buyer == address(0));
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold);
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped);
    _;
  }

  modifier received(uint _sku) {
    require(items[_sku].state == State.Received);
    _;
  }

  constructor() public {
    owner = msg.sender;

  }

  function addItem(string memory _name, uint _price) public returns (bool) {

    items[skuCount] = Item(
        {
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        }
    );

        skuCount += 1;


    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(uint sku) payable forSale(sku) paidEnough(msg.value) checkValue(sku) public {
    Item storage itemToBuy = items[sku];
    itemToBuy.buyer = msg.sender;
    itemToBuy.state = State.Sold;
    itemToBuy.seller.transfer(msg.value);

    emit LogSold(sku);
  }

  function shipItem(uint sku) public sold(sku) {
    Item storage itemToShip = items[sku];
    require(itemToShip.seller == msg.sender);
    itemToShip.state = State.Shipped;

    emit LogShipped(sku);

  }

  function receiveItem(uint sku) public shipped(sku) {
        Item storage itemToReceive = items[sku];
        require(itemToReceive.buyer == msg.sender);
        itemToReceive.state = State.Received;

        emit LogReceived(sku);
  }

  function fetchItem(uint _sku) public view 
     returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) { 
     name = items[_sku].name; 
     sku = items[_sku].sku; 
     price = items[_sku].price; 
     state = uint(items[_sku].state); 
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer; 
     return (name, sku, price, state, seller, buyer); 
   } 
}
