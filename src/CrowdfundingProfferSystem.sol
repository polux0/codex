// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract CrowdfundingProfferSystem {

    // Define the structure of a Slot (as before)
    struct Slot {
        string description;
        uint tokenAmount;
        bool isFulfilled;
    }

    struct CrowdfundingProffer {
        string title;
        Slot[] slots; // Ensure Slot is a defined struct and can be used here
        uint fundingGoal;
        uint totalFunds;
        uint deadline;
        address payable creator;
        bool isCompleted;
    }
    // Define the struct to hold a mapping of indexes to balances
    struct AccountInfo {
        mapping(uint => uint) balances;
    }

    // Create a mapping from address to AccountInfo
    mapping(address => AccountInfo) private accounts;

    // Function to add or update a contribution
    function addContribution(address _address, uint _index, uint _balance) internal {
        accounts[_address].balances[_index] += _balance;
    }

    // Function to retrieve a specific balance for an account and index
    function getBalance(address _address, uint _index) public view returns (uint) {
        return accounts[_address].balances[_index];
    }

    // Function to set a specific balance for an account and index
    function setBalance(address _address, uint _index, uint _balance) internal {
        accounts[_address].balances[_index] = _balance;
    }

    CrowdfundingProffer[] public crowdfundingProffers;

    // Function to create a new Crowdfunding Proffer
    function createCrowdfundingProffer(
        string memory _title, 
        uint _fundingGoal, 
        uint _durationInDays,
        address payable _creator
    ) public {
        uint deadline = block.timestamp + (_durationInDays * 1 days);
        // Adding the new proffer directly to the storage array
        CrowdfundingProffer storage newProffer = crowdfundingProffers.push();
        newProffer.title = _title;
        newProffer.fundingGoal = _fundingGoal;
        newProffer.totalFunds = 0;
        newProffer.deadline = deadline;
        newProffer.creator = _creator;
        newProffer.isCompleted = false;
    }

    // Function to contribute to a crowdfunding campaign
    function contribute(uint _profferIndex) public payable {
        CrowdfundingProffer storage proffer = crowdfundingProffers[_profferIndex];
        require(block.timestamp <= proffer.deadline, "The campaign is over");
        require(msg.value > 0, "You need to contribute some amount");

        // technical debt 
        // msg.sender should become msgSender() ( metatransactions & account abstraction )
        addContribution(msg.sender, _profferIndex, msg.value);
        proffer.totalFunds += msg.value;
    }

    // Function to check if funding goal is met and release funds
    function finalize(uint _profferIndex) public {
        CrowdfundingProffer storage proffer = crowdfundingProffers[_profferIndex];
        require(block.timestamp > proffer.deadline, "The campaign is not over yet");
        require(!proffer.isCompleted, "The campaign is already finalized");

        if (proffer.totalFunds >= proffer.fundingGoal) {
            proffer.creator.transfer(proffer.totalFunds);
        } else {
            // Technical debt - refund logic
            // Refund logic goes here
        }

        proffer.isCompleted = true;
    }

    // Function to refund contributors if the goal is not met
    function refund(uint _profferIndex) public {
        CrowdfundingProffer storage proffer = crowdfundingProffers[_profferIndex];
        require(block.timestamp > proffer.deadline, "The campaign is not over yet");
        require(proffer.totalFunds < proffer.fundingGoal, "Funding goal was met");

        uint amount = getBalance(msg.sender, _profferIndex);
        
        require(amount > 0, "No contributions to refund");

        payable(msg.sender).transfer(amount);
        setBalance(msg.sender, _profferIndex, 0);
    }
    function getCrowdfundingProfferData(uint index) public view returns (CrowdfundingProffer memory) {
        CrowdfundingProffer storage proffer = crowdfundingProffers[index];
        return CrowdfundingProffer({
            title: proffer.title,
            slots: proffer.slots,
            fundingGoal: proffer.fundingGoal,    // Funding goal in wei
            totalFunds: proffer.totalFunds,     // Total funds collected
            deadline: proffer.deadline,       // Deadline for the campaign
            creator: proffer.creator, // Address of the project owner
            isCompleted: proffer.isCompleted
            // ... initialize other fields
        });
    }   

    // Rest of the functions from previous example...
}
