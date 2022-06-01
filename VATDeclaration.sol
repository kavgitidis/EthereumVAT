pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

contract VATDeclaration {
    address private owner; //Owner's address
    uint256[4] private balances; //Gov addresses' balances
    address payable[3] private gov_addresses; //Gov addresses
    uint8[3] private vat_pcts; //VAT percentages
    bytes32 private biggestContributor; //hashed(taxID,address) of largest tax contributor
    struct Citizen {
        //Struct for Citizen TAX proceeds
        uint256 taxID;
        address citizen_addr;
        uint256 proceeds;
    }
    mapping(bytes32 => Citizen) tax_proceeds; //hashed(taxID,address) mapping to struct

    event Fund(address recipient, uint256 amount); //Event for variation 1
    event Fund(address recipient, uint256 amount, uint8 vat_lvl); //Event for variation 2
    event Fund(
        address recipient,
        uint256 amount,
        uint8 vat_lvl,
        string comment
    ); //Event for variation 3

    constructor(address payable[3] memory addresses) {
        owner = msg.sender; //Get contact owner
        vat_pcts = [24, 13, 6]; //Initialize some VAT percentages
        gov_addresses = addresses; //Initialize gov addresses
        //["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value); //Give money back after contract destruction
    }

    function setGovAddresses(address payable[3] calldata addresses) public {
        //Make it calldata to remove trace
        require(msg.sender == owner, "Only owner can update GOV addresses");
        gov_addresses = addresses; //Set gov addresses
    }

    function setVATPcts(uint8[3] calldata vat_p) public {
        require(msg.sender == owner, "Only owner can update VAT percentages");
        vat_pcts = vat_p; //Set or update VAT percentages
    }

    function destroy() public {
        require(msg.sender == owner, "Only owner can destroy the contract");
        selfdestruct(payable(owner)); //Destroy the contract
    }

    function addProceeds(
        uint256 taxID,
        address citizen_addr,
        uint256 amount
    ) private {
        bytes32 hashed_ids = keccak256(abi.encodePacked(taxID, msg.sender));
        tax_proceeds[hashed_ids].taxID = taxID; //Add recipients TAX ID
        tax_proceeds[hashed_ids].citizen_addr = citizen_addr; //Add Recipients Address
        tax_proceeds[hashed_ids].proceeds += amount; //Add TAX proceeds for recipient's address-taxID
        if (
            tax_proceeds[hashed_ids].proceeds >
            tax_proceeds[biggestContributor].proceeds
        ) {
            biggestContributor = hashed_ids;
        }
    }

    function getbiggestContributor() public view returns (Citizen memory) {
        require(
            msg.sender == owner,
            "Only owner can see the biggest contributor"
        );
        return (tax_proceeds[biggestContributor]);
    }

    function getBalance(uint8 vat_lvl) public view returns (uint256) {
        require(vat_lvl >= 0 && vat_lvl <= 3); //Only 0 to 3
        return (balances[vat_lvl]); //Get balance 0=24% 21=13% 2=6% 3=All
    }

    function sendFunds(address payable recipient) external payable {
        require(
            msg.value <= 50000000000000000, //Allow up to 0.05 ETH transactions
            "Funds to be sent are greater than 0.05 ETH"
        );
        require(msg.sender.balance >= msg.value, "Insufficient funds"); //Check if sender has enough funds
        recipient.transfer(msg.value); //Transfer to recipient
        emit Fund(recipient, msg.value); //Emit the event
    }

    function sendFunds(
        address payable recipient,
        uint256 taxID,
        uint8 vat_lvl
    ) external payable {
        require(vat_lvl >= 0 && vat_lvl <= 2, "Incorrect VAT Level"); //Only VAT levels 0 to 2
        require(msg.sender.balance >= msg.value, "Insufficient funds"); //Check if sender has enough funds
        uint256 vat_amount = (msg.value * vat_pcts[vat_lvl]) / 100; //VAT amount to be sent to gov address
        uint256 rem_amount = (msg.value * (100 - vat_pcts[vat_lvl])) / 100; //Remaining amount to be sent to recipient
        gov_addresses[vat_lvl].transfer(vat_amount); //Transfer to gov address
        recipient.transfer(rem_amount); //Transfer to recipient
        balances[vat_lvl] += vat_amount; //Update vat level balance
        balances[3] += vat_amount; //Update total balance
        addProceeds(taxID, msg.sender, vat_amount); //Call method to add TAX proceeds
        emit Fund(recipient, rem_amount, vat_lvl); //Emit the event
    }

    function sendFunds(
        address payable recipient,
        uint256 taxID,
        uint8 vat_lvl,
        string memory comment
    ) external payable {
        require(vat_lvl >= 0 && vat_lvl <= 2, "Incorrect VAT Level"); //Only VAT levels 0 to 2
        require(bytes(comment).length <= 80, "Comment is larger than 80 chars"); //comments < 80 chars
        require(msg.sender.balance >= msg.value, "Insufficient funds"); //Check if sender has enough funds
        uint256 vat_amount = (msg.value * vat_pcts[vat_lvl]) / 100; //VAT amount to be sent to gov address
        uint256 rem_amount = (msg.value * (100 - vat_pcts[vat_lvl])) / 100; //Remaining amount to be sent to recipient
        gov_addresses[vat_lvl].transfer(vat_amount); //Transfer to gov address
        recipient.transfer(rem_amount); //Transfer to recipient
        balances[vat_lvl] += vat_amount; //Update vat level balance
        balances[3] += vat_amount; //Update total balance
        addProceeds(taxID, msg.sender, vat_amount); //Call method to add TAX proceeds
        emit Fund(recipient, rem_amount, vat_lvl, comment); //Emit the event
    }
}
