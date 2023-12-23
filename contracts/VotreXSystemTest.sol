// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract VotreXSystemTest{

    uint256 internal constant ORGANIZATION_CREATION_FEE = 50 ether;

    constructor() {
        contractOwner = msg.sender;
    }

    Organization[] public organizations;
    address public contractOwner;
    uint32 electionCount;
    uint32 public MAX_EVENTS = 15;
    uint48 public votersCount;

    mapping(address =>ElectionAdmins) public admin;
    mapping(address => bool) public registeredAdmin;
    mapping(uint32 => ElectionDetail) public elections;
    mapping(uint32 => ElectionResult) public electionResults;
    mapping(uint32 => bool) public prunedElections;
    mapping(uint32 => bool) public prunedResults;
    mapping(string => bool) public organizationCheck;
    mapping(address => string) public adminToOrganization;
    mapping(address => Voter) public voters;
    mapping(uint48 => bool) public votersIDExists;
    mapping(address => string) public VotersAssociatedOrganizations;

    enum ElectionStatus {
        Preparation,
        Scheduled,
        Started,
        Finished
    }

    enum OrganizationType {
        Organization,
        Corporate
    }

    struct ElectionAdmins {
        address electionAdminAddress;
        string adminName;
        bool isRegistered;
        string orgName;
        uint48 AdminvoterID;
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
        string electionName;
        string registeredOrganization;
        uint startTime; 
        uint endTime;
        uint32 totalVoter;
        string electionWinner;
        string signedBy;
        address adminAddress;
        bytes32 digitalSignature;
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

    modifier onlyAuthorized() {
        require(msg.sender == contractOwner || registeredAdmin[msg.sender], "Unauthorized");
        _;
    }

    function registerOrganization(
        string memory _orgName,
        string memory _orgId,
        OrganizationType _orgType
        ) public payable{
            require(!organizationCheck[_orgId], "Organization ID already registered");
            require(!organizationCheck[_orgName], "Organization Name already registered");
            require(msg.value == ORGANIZATION_CREATION_FEE, "Incorrect fee amount");
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
        organizationCheck[_orgId] = true;
        organizationCheck[_orgName] = true;
    }

    function registerElectionAdmin(
        string memory _orgName,
        string memory _adminName
        ) public {
            require(!registeredAdmin[msg.sender], "Election Admin address already registered");
        
            uint16 orgIndex = getOrganizationIndexByName(_orgName);

            require(orgIndex < organizations.length, "Organization not found");

            Organization storage org = organizations[orgIndex];
            address[] storage adminAddresses = org.electionAdminAddresses;

            adminAddresses.push(msg.sender);
            adminToOrganization[msg.sender] = _orgName;
            uint48 voterIDCheck = voters[msg.sender].VoterID;

            ElectionAdmins memory newAdmin = ElectionAdmins({
                electionAdminAddress: msg.sender,
                orgName: _orgName,
                isRegistered: true,
                adminName: _adminName,
                AdminvoterID: voterIDCheck
            });

            admin[msg.sender] = newAdmin;

            voters[msg.sender] = Voter({
                VoterID: 0,
                VoterAddress: msg.sender,
                VoterName: _adminName,
                isRegistered: true,
                associatedOrganization: _orgName,
                participatedElectionEvents: new string[](0)
            });
        
        VotersAssociatedOrganizations[msg.sender] = _orgName;
        registeredAdmin[msg.sender] = true;
        org.totalMembers++;
    }


    

    function createElection(
        string memory _orgId,
        string memory _electionID,
        string memory _electionName,
        uint8 _candidateCount
        ) public {
            require(organizationCheck[_orgId], "Organization ID not found");
            require(bytes(_electionID).length > 1, "Election ID can't be empty");
            require(bytes(_electionID).length <= 6, "Election ID should be 6 characters or less");
            require(bytes(_electionName).length > 1, "Election name can't be empty");
            require(bytes(_electionName).length <= 15, "Election name should be 15 characters or less");
            require(electionCount < MAX_EVENTS, "Maximum events created reached");
            ElectionStatus status = ElectionStatus.Preparation;

            ElectionDetail storage newElection = elections[electionCount];
            newElection.electionID = _electionID;
            newElection.orgId = _orgId;
            newElection.electionName = _electionName;
            newElection.status = status;
            newElection.candidateList = _candidateCount;

            uint16 orgIndex = getOrganizationIndexById(_orgId);
            organizations[orgIndex].electionEventCounter++;

            electionCount++;
    }

    function startElection(uint32 electionIndex) public onlyAuthorized {
        require(electionIndex < electionCount, "Invalid election index");

        ElectionDetail storage election = elections[electionIndex];
        require(election.status == ElectionStatus.Scheduled || election.status == ElectionStatus.Preparation, "Election is not scheduled or in preparation");

        election.startTime = block.timestamp;
        election.status = ElectionStatus.Started;
    }

    function scheduledElection(uint32 electionIndex, uint _startTime, uint _duration) public onlyAuthorized {
        require(electionIndex < electionCount, "Invalid election index");

        ElectionDetail storage election = elections[electionIndex];
        require(election.status == ElectionStatus.Preparation, "Election is not in preparation");
        require(_startTime >= block.timestamp, "Start time cannot be in the past");
        require(_duration > 0 && _duration <= 3 * 30 days, "Invalid election duration");

        uint endTime = _startTime + _duration;
        election.startTime = _startTime;
        election.endTime = endTime;
        election.status = ElectionStatus.Scheduled;
    }

    function finishElection(uint32 electionIndex) public onlyAuthorized{
        require(electionIndex < electionCount, "Invalid election index");

        ElectionDetail storage election = elections[electionIndex];
        require(election.status == ElectionStatus.Started, "Election is not started");
        require(!election.isFinished, "Election is already finished");

        string memory orgName = organizations[getOrganizationIndexById(election.orgId)].orgName;
        string memory adminName = getAdminName(msg.sender);
        string memory electionName = election.electionName;

        election.endTime = uint256(block.timestamp);
        election.status = ElectionStatus.Finished;
        election.isFinished = true;

        uint32 totalVoter = calculateTotalVoter(electionIndex);
        string memory electionWinner = determineWinner(electionIndex);

        bytes32 dataHash = keccak256(abi.encodePacked(orgName, electionName, adminName));

        electionResults[electionIndex] = ElectionResult(
            election.electionName,
            election.orgId,
            election.startTime,
            election.endTime,
            totalVoter,
            electionWinner,
            adminName,
            msg.sender,
            dataHash
        );

        prunedElections[electionIndex] = true;
        prunedResults[electionIndex] = true;
    }

    function isElectionPruned(uint32 electionIndex) public view returns (bool) {
        return prunedElections[electionIndex];
    }

    function isElectionResultPruned(uint32 electionIndex) public view returns (bool) {
        return prunedResults[electionIndex];
    }

    function getAdminName(address adminAddress) public view returns (string memory) {
        ElectionAdmins memory admin = admin[adminAddress];
        return admin.adminName;
    }

    
    function addCandidateToElection(uint32 electionIndex, string memory _candidateName) public {
        require(electionIndex < electionCount, "Invalid election index");

        string memory orgId = elections[electionIndex].orgId;
        uint16 orgIndex = getOrganizationIndexById(orgId);
        Organization storage org = organizations[orgIndex];

        require(isElectionAdminForOrganization(msg.sender, org.orgId), "Only election admins can add candidates");

        ElectionDetail storage election = elections[electionIndex];

        require(election.candidates.length < election.candidateList, "Candidate limit reached");
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
    
    function registerVoter(string memory _VoterName, string memory _orgId) public {
        require(organizationCheck[_orgId], "Organization ID not found");
        require(bytes(_VoterName).length > 1, "Voter name can't be empty");
        require(bytes(_VoterName).length < 15, "Voter name should be 15 characters or less");

        uint16 orgIndex = getOrganizationIndexById(_orgId);
        Organization storage org = organizations[orgIndex];

        require(!voters[msg.sender].isRegistered, "Voter is already registered");
        require(!isVoterRegisteredInOrg(_orgId, msg.sender), "Voter is already registered in the selected organization");
        require(!registeredAdmin[msg.sender] || !voters[msg.sender].isRegistered, "Election Admin cannot register as a voter");

        uint48 voterID = generateUniqueVoterID();       

        voters[msg.sender] = Voter({
            VoterID: voterID,
            VoterAddress: msg.sender,
            VoterName: _VoterName,
            isRegistered: true,
            associatedOrganization: _orgId,
            participatedElectionEvents: new string[](0)
        });

        VotersAssociatedOrganizations[msg.sender] = _orgId;

        org.totalMembers++;
    }


    function vote(uint32 electionIndex, uint8 candidateID) public {
        require(electionIndex < electionCount, "Invalid election index");
        require(candidateID < elections[electionIndex].candidates.length, "Invalid candidate ID");

        ElectionDetail storage election = elections[electionIndex];

        require(voters[msg.sender].isRegistered, "You are not a registered voter");
        require(election.status == ElectionStatus.Started, "Election is not in progress");
        string memory orgId = voters[msg.sender].associatedOrganization;

        require(organizationCheck[orgId], "You are not a registered voter in this organization");

        string memory electionName = election.electionName;
        require(!hasParticipatedInElection(msg.sender, electionName), "You have already voted in this election");

        Candidate storage candidate = election.candidates[candidateID];

        candidate.CandidateVoteCount++;

        Voter storage voter = voters[msg.sender];
        voter.participatedElectionEvents = appendToStringArray(voter.participatedElectionEvents, electionName);
    }

    function withdrawFees() public {
        require(msg.sender == contractOwner, "Only contract owner can withdraw fees");
        payable(contractOwner).transfer(address(this).balance);
    }

    function getOrganizationsCount() public view returns (uint) {
        return organizations.length;
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

    function hasParticipatedInElection(address voterAddress, string memory electionName) internal view returns (bool) {
        Voter storage voter = voters[voterAddress];
        for (uint i = 0; i < voter.participatedElectionEvents.length; i++) {
            if (keccak256(abi.encodePacked(voter.participatedElectionEvents[i])) == keccak256(abi.encodePacked(electionName))) {
                return true; 
            }
        }
        return false; 
    }

    function calculateTotalVoter(uint32 electionIndex) internal view returns (uint32) {
        ElectionDetail storage election = elections[electionIndex];
        uint32 totalVoter = 0;
        for (uint8 i = 0; i < election.candidates.length; i++) {
            totalVoter += election.candidates[i].CandidateVoteCount;
        }
        return totalVoter;
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
    
    function generateUniqueVoterID() internal returns (uint48) {
        votersCount++;
        uint48 newVoterID = votersCount;
        require(newVoterID <= 21000000000000, "VoterID limit reached");
        require(!votersIDExists[newVoterID], "VoterID already exists");

        votersIDExists[newVoterID] = true;

        return newVoterID;
    }


    function getElectionIndexByName(string memory _electionName) internal view returns (uint32) {
        for (uint32 i = 0; i < electionCount; i++) {
            if (keccak256(abi.encodePacked(elections[i].electionName)) == keccak256(abi.encodePacked(_electionName))) {
                return i;
            }
        }
        revert("Election not found");
    }

    function getWinnerResult(uint32 electionIndex) public view returns (string memory, uint32) {
        require(electionIndex < electionCount, "Invalid election index");
        
        ElectionResult storage result = electionResults[electionIndex];
        
        require(result.totalVoter > 0, "Election results are not available yet");
        require(elections[electionIndex].status == ElectionStatus.Finished, "Election is not finished");
        
        return (result.electionWinner, result.totalVoter);
    }

    function getOrganizationIndexByName(string memory _orgName) internal view returns (uint16) {
        for (uint16 i = 0; i < organizations.length; i++) {
            if (keccak256(abi.encodePacked(organizations[i].orgName)) == keccak256(abi.encodePacked(_orgName))) {
                return i;
            }
        }
        return uint16(organizations.length);
    }

    function getOrganizationIndexById(string memory _orgId) internal view returns (uint16) {
        for (uint16 i = 0; i < organizations.length; i++) {
            if (keccak256(abi.encodePacked(organizations[i].orgId)) == keccak256(abi.encodePacked(_orgId))) {
                return i;
            }
        }
        revert("Organization not found");
    }

    // function getAdminOrganization() public view returns (string memory, string memory) {
    //     address _adminAddress = msg.sender;
    //     require(registeredAdmin[_adminAddress], "Election Admin address not registered");
    //     string memory orgName = adminToOrganization[_adminAddress];
    //     uint16 index = getOrganizationIndexByName(orgName);
    //     return (organizations[index].orgId, organizations[index].orgName);
    // }

    // function getOrganization(uint index) public view returns (string memory, string memory, OrganizationType, uint48, uint16, address[] memory) {
    //     require(index < organizations.length, "Index out of bounds");
    //     Organization memory org = organizations[index];
    //     return (org.orgName, org.orgId, org.orgType, org.totalMembers, org.electionEventCounter, org.electionAdminAddresses);
    // }
    

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

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytesArray[i * 2] = bytes1(uint8(uint256(_bytes32) / (2**(8*(31 - i)))));
            bytesArray[i * 2 + 1] = bytes1(uint8(uint256(_bytes32) / (2**(8*(31 - i)))));
        }

        return string(bytesArray);
    }
}
