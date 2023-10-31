// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


contract DVotev1{

    constructor(address initialElectionAdmin) {
        contractOwner = msg.sender;
        electionAdmins = initialElectionAdmin;
    }

    Organization[] public organizations;
    address public contractOwner;
    address electionAdmins =  msg.sender;
    uint32 electionCount;
    uint32 public MAX_EVENTS = 10;
    uint48 public votersCount;

    mapping(address => bool) public registeredAdmin;
    mapping(address =>ElectionAdmins) public admin;
    mapping (uint32 => ElectionDetail) public elections;
    mapping(uint32 => ElectionResult) public electionResults;
    mapping(string => bool) public organizationList;
    mapping(address => string) public adminToOrganization;
    mapping(address => string) public associatedOrganizations;
    mapping(address => Voter) public voters;
    mapping(uint48 => bool) public votersIDExists;


    enum ElectionStatus {Scheduled, Started, Finished}
    enum OrganizationType {Organization, Corporate}

    struct ElectionAdmins {
        address electionAdminAddress;
        string adminName;
        bool isRegistered;
        string orgName;
    }

    struct Organization {
        string orgName;
        string orgId;
        address[] electionAdminAddresses;
        OrganizationType orgType;
        uint48[] voterIDs;
        uint16 electionEventCounter;
        uint48 totalMembers;
    }
    
    struct ElectionDetail{
        string electionID;
        string orgId;
        string electionName;
        uint startTime;
        uint endTime;
        uint8 candidateList;
        Candidate[] candidates;
        ElectionStatus status;
        bool isFinished;
    }

    struct ElectionResult {
        string registeredOrganization;
        address adminAddress;
        uint startTime; 
        uint endTime;
        uint32 totalVotes;
        string electionWinner;
        string signedBy;
        string digitalSignature;
    }

    struct Candidate{
        uint8 candidateID;
        string CandidateName;
        uint32 CandidateVoteCount;
    }

    struct Voter{
        uint48 VoterID;
        address VoterAddress;
        string VoterName;
        bool isRegistered;
        string[] participatedElectionEvents;
        string associatedOrganization;
    }

    function registerElectionAdmin(string memory _orgName, string memory _adminName) public {
        require(!registeredAdmin[msg.sender], "Election Admin address already registered");

        // Find the organization index by its name
        uint16 orgIndex = getOrganizationIndexByName(_orgName);

        // Make sure the organization exists
        require(orgIndex < organizations.length, "Organization not found");

        // Retrieve the organization struct
        Organization storage org = organizations[orgIndex];

        // Update the organization's electionAdminAddresses array
        address[] storage adminAddresses = org.electionAdminAddresses;
        adminAddresses.push(msg.sender);

        // Set the admin's organization association
        adminToOrganization[msg.sender] = _orgName;

        // Create a new ElectionAdmins struct and add it to the mapping
        ElectionAdmins memory newAdmin = ElectionAdmins({
            electionAdminAddress: msg.sender,
            orgName: _orgName,
            isRegistered: true,
            adminName: _adminName
        });
        admin[msg.sender] = newAdmin;

        // Mark the sender's address as a registered admin
        registeredAdmin[msg.sender] = true;
        org.totalMembers++;
    }


    function getAdminOrganization() public view returns (string memory, string memory) {
        address _adminAddress = msg.sender;
        require(registeredAdmin[_adminAddress], "Election Admin address not registered");
        string memory orgName = adminToOrganization[_adminAddress];
        uint16 index = getOrganizationIndexByName(orgName);
        return (organizations[index].orgId, organizations[index].orgName);
    }

    function registerOrganization(
        string memory _orgName,
        string memory _orgId,
        OrganizationType _orgType
        ) public {
            require(!organizationList[_orgId], "Organization ID already registered");
            require(!organizationList[_orgName], "Organization Name already registered");
            require(bytes(_orgName).length > 1, "Organization name can't be empty");
            require(bytes(_orgName).length <= 12, "Organization name should be 12 characters or less");
            
            require(bytes(_orgId).length > 1, "Organization ID can't be empty");
            require(bytes(_orgId).length <= 4, "Organization ID should be 4 characters or less");
            
            Organization memory newOrg = Organization({
                orgId: _orgId,
                orgName: _orgName,
                orgType: _orgType,
                electionAdminAddresses: new address[](0),
                electionEventCounter: 0,
                totalMembers: 0,
                voterIDs: new uint48[](0)
            });
            organizations.push(newOrg);
            
            // Set the initial election admin for the organization
            organizationList[_orgId] = true;
            organizationList[_orgName] = true;
    }

    function getOrganization(uint index) public view returns (string memory, string memory, OrganizationType, uint48, uint16, address[] memory) {
        require(index < organizations.length, "Index out of bounds");
        Organization memory org = organizations[index];
        return (org.orgName, org.orgId, org.orgType, org.totalMembers, org.electionEventCounter, org.electionAdminAddresses);
    }

    function getOrganizationsCount() public view returns (uint) {
        return organizations.length;
    }

    function createElection(
        string memory _orgId,
        string memory _electionID,
        string memory _electionName,
        uint8 _candidateCount,
        uint  _startTime,
        uint _duration
    ) public {
        require(organizationList[_orgId], "Organization ID not found");
        require(bytes(_electionID).length > 1, "Election ID can't be empty");
        require(bytes(_electionID).length <= 6, "Election ID should be 6 characters or less");
        require(bytes(_electionName).length > 1, "Election name can't be empty");
        require(bytes(_electionName).length <= 15, "Election name should be 15 characters or less");
        require(electionCount < MAX_EVENTS, "Maximum events created reached");
        require(_startTime >= block.timestamp, "Start time cannot be in the past");
        require(_duration > 0 && _duration <= 3 * 30 days, "Invalid election duration");

        uint endTime = _startTime + _duration;

        ElectionStatus status = _startTime == block.timestamp ? ElectionStatus.Started : ElectionStatus.Scheduled;

        ElectionDetail storage newElection = elections[electionCount];
        newElection.electionID = _electionID;
        newElection.orgId = _orgId;
        newElection.electionName = _electionName;
        newElection.status = status;
        newElection.candidateList = _candidateCount;
        newElection.startTime = _startTime;
        newElection.endTime = endTime;

        uint16 orgIndex = getOrganizationIndexById(_orgId);
        organizations[orgIndex].electionEventCounter++;

        electionCount++;
    }


    function startElection(uint32 electionIndex) public onlyAuthorized {
        require(electionIndex < electionCount, "Invalid election index");

        ElectionDetail storage election = elections[electionIndex];
        require(election.status != ElectionStatus.Finished, "Election is already finished");
        require(election.status == ElectionStatus.Scheduled, "Election is not scheduled");

        election.status = ElectionStatus.Started;
        election.startTime = block.timestamp; // Set the start time to the current block timestamp
    }

    modifier onlyAuthorized() {
        require(msg.sender == contractOwner || registeredAdmin[msg.sender], "Unauthorized");
        _;
    }

    function finishElection(uint32 electionIndex, string memory digitalSignature) public onlyAuthorized {
        require(electionIndex < electionCount, "Invalid election index");

        ElectionDetail storage election = elections[electionIndex];
        require(election.status == ElectionStatus.Started, "Election is not started");
        require(!election.isFinished, "Election is already finished");

        // Set the end time to the current block timestamp
        election.endTime = uint(block.timestamp);
        election.status = ElectionStatus.Finished;
        election.isFinished = true; // Mark the election as finished

        // Calculate total votes and determine the winner (you can add this logic)
        uint32 totalVotes = calculateTotalVotes(electionIndex);
        string memory electionWinner = determineWinner(electionIndex);

        // Get the admin's name from the election admin struct
        string memory adminName = getAdminName(msg.sender);

        // Store the election results
        electionResults[electionIndex] = ElectionResult(
            election.orgId,
            msg.sender, 
            election.startTime,
            election.endTime,
            totalVotes,
            electionWinner,
            adminName,
            digitalSignature
        );
    }


    function getAdminName(address adminAddress) public view returns (string memory) {
        ElectionAdmins memory admin = admin[adminAddress];
        return admin.adminName;
    }

    
    function addCandidateToElection(uint32 electionIndex, string memory _candidateName) public {
        require(electionIndex < electionCount, "Invalid election index");

        // Get the organization associated with this election
        string memory orgId = elections[electionIndex].orgId;
        uint16 orgIndex = getOrganizationIndexById(orgId);
        Organization storage org = organizations[orgIndex];

        // Check if the sender is an election admin for the organization
        require(isElectionAdminForOrganization(msg.sender, org.orgId), "Only election admins can add candidates");

        ElectionDetail storage election = elections[electionIndex];

        // Check if the candidate count is within the limit defined in the election detail
        require(election.candidates.length < election.candidateList, "Candidate limit reached");

        // Check that the candidate name is not empty and only contains alphabetical characters (a to z)
        require(bytes(_candidateName).length > 0, "Candidate name cannot be empty");
        require(bytes(_candidateName).length <= 16, "Candidate name should be 16 characters or less");
        require(onlyAlphabetCharacters(_candidateName), "Candidate name should only contain alphabetical characters");

        uint8 candidateID = uint8(election.candidates.length);
        election.candidates.push(
            Candidate({
                candidateID: candidateID,
                CandidateName: _candidateName,
                CandidateVoteCount: 0
                })
            );
    }
    
    function registerVoter(string memory _VoterName, string memory _orgId, uint32 _electionIndex) public {
        require(organizationList[_orgId], "Organization ID not found");
        require(_electionIndex < electionCount, "Invalid election index");
        require(bytes(_VoterName).length > 1, "Voter name can't be empty");
        require(bytes(_VoterName).length < 15, "Voter name should be 15 characters or less");

        uint16 orgIndex = getOrganizationIndexById(_orgId);
        Organization storage org = organizations[orgIndex];

        // Get the election from the elections mapping using the provided index
        ElectionDetail storage election = elections[_electionIndex];

        require(!voters[msg.sender].isRegistered, "Voter is already registered");
        require(!isVoterRegisteredInOrg(_orgId, msg.sender), "Voter is already registered in the selected organization");

        // Generate a unique 6-digit VoterID
        uint48 voterID = generateUniqueVoterID();       

        voters[msg.sender] = Voter({
            VoterID: voterID,
            VoterAddress: msg.sender,
            VoterName: _VoterName,
            isRegistered: true,
            associatedOrganization: _orgId,
            participatedElectionEvents: new string[](0)
        });

        associatedOrganizations[msg.sender] = _orgId;

        // Increment the totalMembers count for the organization
        org.totalMembers++;
    }


    function vote(uint32 electionIndex, uint8 candidateID) public {
        require(electionIndex < electionCount, "Invalid election index");
        require(candidateID < elections[electionIndex].candidates.length, "Invalid candidate ID");

        ElectionDetail storage election = elections[electionIndex];

        // Check if the sender is a registered voter in the organization
        require(voters[msg.sender].isRegistered, "You are not a registered voter");

        // Check if the election is in the "Start" status
        require(election.status == ElectionStatus.Started, "Election is not in progress");
        string memory orgId = voters[msg.sender].associatedOrganization;

        require(organizationList[orgId], "You are not a registered voter in this organization");

        // Check if the voter has already participated in this election
        string memory electionName = election.electionName;
        require(!hasParticipatedInElection(msg.sender, electionName), "You have already voted in this election");

        // Get the candidate from the election's candidate list
        Candidate storage candidate = election.candidates[candidateID];

        // Increment the vote count for the selected candidate
        candidate.CandidateVoteCount++;

        // Record that the voter has participated in this election
        Voter storage voter = voters[msg.sender];
        voter.participatedElectionEvents = appendToStringArray(voter.participatedElectionEvents, electionName);
    }

    function hasParticipatedInElection(address voterAddress, string memory electionName) internal view returns (bool) {
        Voter storage voter = voters[voterAddress];
        for (uint i = 0; i < voter.participatedElectionEvents.length; i++) {
            if (keccak256(abi.encodePacked(voter.participatedElectionEvents[i])) == keccak256(abi.encodePacked(electionName))) {
                return true; 
            }
        }
        return false; 
    }

    function calculateTotalVotes(uint32 electionIndex) internal view returns (uint32) {
        ElectionDetail storage election = elections[electionIndex];
        uint32 totalVotes = 0;
        for (uint8 i = 0; i < election.candidates.length; i++) {
            totalVotes += election.candidates[i].CandidateVoteCount;
        }
        return totalVotes;
    }

    function determineWinner(uint32 electionIndex) internal view returns (string memory) {
        ElectionDetail storage election = elections[electionIndex];
        string memory winner = "";
        uint32 maxVotes = 0;
        for (uint8 i = 0; i < election.candidates.length; i++) {
            if (election.candidates[i].CandidateVoteCount > maxVotes) {
                maxVotes = election.candidates[i].CandidateVoteCount;
                winner = election.candidates[i].CandidateName;
            }
        }
        return winner;
    }


    function getElectionIndexByName(string memory _electionName) public view returns (uint32) {
        for (uint32 i = 0; i < electionCount; i++) {
            if (keccak256(abi.encodePacked(elections[i].electionName)) == keccak256(abi.encodePacked(_electionName))) {
                return i;
            }
        }
        revert("Election not found");
    }

    function getCandidateDetail(uint32 electionIndex, string memory candidateName) public view returns (uint8, uint32) {
        require(electionIndex < electionCount, "Invalid election index");

        ElectionDetail storage election = elections[electionIndex];

        // Find the candidate with the specified name in the election
        for (uint8 i = 0; i < election.candidates.length; i++) {
            if (keccak256(abi.encodePacked(election.candidates[i].CandidateName)) == keccak256(abi.encodePacked(candidateName))) {
                return (election.candidates[i].candidateID, election.candidates[i].CandidateVoteCount);
            }
        }

        revert("Candidate not found in the specified election");
    }

    function checkMyVoterInfo() public view returns (uint48, address, string memory, string memory, string[] memory) {
        address voterAddress = msg.sender;
        Voter storage voter = voters[voterAddress];
        require(voter.isRegistered, "Voter not found");
        return (voter.VoterID, voter.VoterAddress, voter.VoterName, voter.associatedOrganization, voter.participatedElectionEvents);
    }

    function getCurrentVoteResult(uint32 electionIndex) public view returns (string[] memory, uint32[] memory) {
        require(electionIndex < electionCount, "Invalid election index");
        
        ElectionDetail storage election = elections[electionIndex];
        
        require(election.status != ElectionStatus.Scheduled, "Election is not in progress or finished");
        
        string[] memory candidateNames = new string[](election.candidates.length);
        uint32[] memory voteCounts = new uint32[](election.candidates.length);
        
        for (uint8 i = 0; i < election.candidates.length; i++) {
            candidateNames[i] = election.candidates[i].CandidateName;
            voteCounts[i] = election.candidates[i].CandidateVoteCount;
        }
        
        return (candidateNames, voteCounts);
    }

    function getWinnerResult(uint32 electionIndex) public view returns (string memory, uint32) {
        require(electionIndex < electionCount, "Invalid election index");
        
        ElectionResult storage result = electionResults[electionIndex];
        
        require(result.totalVotes > 0, "Election results are not available yet");
        require(elections[electionIndex].status == ElectionStatus.Finished, "Election is not finished");
        
        return (result.electionWinner, result.totalVotes);
    }
    

    // Helper function to check if a string contains only alphabetical characters (a to z)
    function onlyAlphabetCharacters(string memory _input) internal pure returns (bool) {
        bytes memory b = bytes(_input);
        for (uint i = 0; i < b.length; i++) {
            if (!(uint8(b[i]) >= 65 && uint8(b[i]) <= 90) && !(uint8(b[i]) >= 97 && uint8(b[i]) <= 122)) {
                return false;
            }
        }
        return true;
    }

    function appendToStringArray(string[] memory array, string memory newValue) internal pure returns (string[] memory) {
        string[] memory newArray = new string[](array.length + 1);
        
        for (uint32 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        
        newArray[array.length] = newValue;
        
        return newArray;
    }

    function generateUniqueVoterID() internal returns (uint48) {
        votersCount++; // Increment the voter count
        uint48 newVoterID = votersCount;
        require(newVoterID <= 21000000000000, "VoterID limit reached");
        require(!votersIDExists[newVoterID], "VoterID already exists");

        // Mark the generated VoterID as used
        votersIDExists[newVoterID] = true;

        return newVoterID;
    }



    function getOrganizationIndexByName(string memory _orgName) internal view returns (uint16) {
        for (uint16 i = 0; i < organizations.length; i++) {
            if (keccak256(abi.encodePacked(organizations[i].orgName)) == keccak256(abi.encodePacked(_orgName))) {
                return i;
            }
        }
        return uint16(organizations.length); // Return a value that indicates "not found"
    }

    function getOrganizationIndexById(string memory _orgId) internal view returns (uint16) {
        for (uint16 i = 0; i < organizations.length; i++) {
            if (keccak256(abi.encodePacked(organizations[i].orgId)) == keccak256(abi.encodePacked(_orgId))) {
                return i;
            }
        }
        revert("Organization not found");
    }

    function isElectionAdminForOrganization(address adminAddress, string memory orgId) internal view returns (bool) {
        for (uint i = 0; i < organizations.length; i++) {
            if (keccak256(abi.encodePacked(organizations[i].orgId)) == keccak256(abi.encodePacked(orgId))) {
                for (uint j = 0; j < organizations[i].electionAdminAddresses.length; j++) {
                    if (organizations[i].electionAdminAddresses[j] == adminAddress) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function isVoterRegisteredInOrg(string memory _orgId, address _VoterAddress) internal view returns (bool) {
        for (uint i = 0; i < organizations.length; i++) {
            if (keccak256(abi.encodePacked(organizations[i].orgId)) == keccak256(abi.encodePacked(_orgId))) {
                for (uint j = 0; j < organizations[i].electionAdminAddresses.length; j++) {
                    if (organizations[i].electionAdminAddresses[j] == _VoterAddress) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
}
