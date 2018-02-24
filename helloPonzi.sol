pragma solidity ^0.4.11;

contract helloPonzi {
    uint public entranceFee; // Fee to join ponzi. Excess value can be reclaimed.
    uint public undistributedAmt; // Money that is splittable to registrants
    address[] public ponziMembers; // Registrants

    // Counter and Limit used to force a distributeFunds() computation every [newMemLimit] registrants
    uint newMemCounter = 0;
    uint newMemLimit = 10;

    mapping (address => uint) pendingWithdrawls; // Manages owed money to registrants

    // Defining Events
    event RegisterSuccess(address adr);
    event CollectSuccess(uint amt);
    event DistributeSuccess();
    event Error(string err);

    // Constructor for helloPonzi. _entranceFee specifies amount to enter Ponzi.
    function helloPonzi(uint _entranceFee) public {
        ponziMembers.push(msg.sender);
        entranceFee = _entranceFee;
    }

    // Register address in ponziMembers
    function joinPonzi() public payable{
        require(msg.value >= entranceFee);

        // Enforces fund distribution before joining if newMemLimit reached.
        if (newMemCounter >= newMemLimit) {
            pendingWithdrawls[msg.sender] += msg.value;
            Error("New member limit reached. Please distributeFunds() to free up space and try again. Refunds via collectFunds().");
            return;
        }

        ponziMembers.push(msg.sender);
        pendingWithdrawls[msg.sender] += (msg.value - entranceFee); // Adding refundable money to account
        undistributedAmt += entranceFee;
        newMemCounter += 1;
        RegisterSuccess(msg.sender);
    }

    // Partitions the money in the undistributed pool to each of the registrants in the ponzi.
    // This ponzi distributes half of available funds to the top, then half of the left-over to
    // The next up-top, and so on.
    function distributeFunds() public {
        for(uint i = 0; i < ponziMembers.length; i++) {
            pendingWithdrawls[ponziMembers[i]] += undistributedAmt/2;
            undistributedAmt -=  undistributedAmt/2;
        }
        newMemCounter = 0;
        DistributeSuccess();
    }

    // Collects the available funds owed to the msg's sender. Refunds also through this method.
    function collectFunds() public {
        uint owed = pendingWithdrawls[msg.sender];
        pendingWithdrawls[msg.sender] = 0;
        msg.sender.transfer(owed);
        CollectSuccess(owed); // Always a success (amt may be 0).
    }

    // Get the size of the ponzi.
    function ponziSize() public returns (uint) {
        return ponziMembers.length;
    }

}
