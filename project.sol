// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransparentFunding {
    address public owner;
    uint256 public totalFunds;
    mapping(address => uint256) public funders;
    address[] public funderAddresses;
    
    struct Project {
        string title;
        address recipient;
        uint256 fundingGoal;
        uint256 currentFunding;
        bool completed;
    }

    Project[] public projects;

    event FundsAdded(address indexed funder, uint256 amount);
    event ProjectCreated(string title, address recipient, uint256 fundingGoal);
    event FundsDistributed(uint256 projectId, uint256 amount);
    event ProjectCompleted(uint256 projectId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier validateProject(uint256 projectId) {
        require(projectId < projects.length, "Invalid project ID.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addFunds() external payable {
        require(msg.value > 0, "Funds must be greater than zero.");

        if (funders[msg.sender] == 0) {
            funderAddresses.push(msg.sender);
        }

        funders[msg.sender] += msg.value;
        totalFunds += msg.value;

        emit FundsAdded(msg.sender, msg.value);
    }

    function createProject(string memory title, address recipient, uint256 fundingGoal) external onlyOwner {
        require(recipient != address(0), "Recipient address cannot be zero.");
        require(fundingGoal > 0, "Funding goal must be greater than zero.");

        projects.push(Project({
            title: title,
            recipient: recipient,
            fundingGoal: fundingGoal,
            currentFunding: 0,
            completed: false
        }));

        emit ProjectCreated(title, recipient, fundingGoal);
    }

    function distributeFunds(uint256 projectId, uint256 amount) external onlyOwner validateProject(projectId) {
        Project storage project = projects[projectId];

        require(!project.completed, "Project is already completed.");
        require(totalFunds >= amount, "Insufficient total funds.");
        require(project.currentFunding + amount <= project.fundingGoal, "Amount exceeds project's funding goal.");

        project.currentFunding += amount;
        totalFunds -= amount;
        payable(project.recipient).transfer(amount);

        emit FundsDistributed(projectId, amount);

        if (project.currentFunding >= project.fundingGoal) {
            project.completed = true;
            emit ProjectCompleted(projectId);
        }
    }

    function getProject(uint256 projectId) external view validateProject(projectId) returns (Project memory) {
        return projects[projectId];
    }

    function getFunderAddresses() external view returns (address[] memory) {
        return funderAddresses;
    }

    function getProjects() external view returns (Project[] memory) {
        return projects;
    }
}