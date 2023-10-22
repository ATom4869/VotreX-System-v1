// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


contract Electionv2{

    constructor() {
        contractOwner = msg.sender;
    }

    // Organization[] public organizations;
    // ElectionAdmins[] public electionAdminsArray;
    // Voter[] public VoterInfo;
    address public contractOwner;
    address electionAdmins =  msg.sender;
    uint32 electionCount;
    uint32 public organizationsCount;
    uint32 public MAX_EVENTS = 10;
    uint48 public votersCount;


    mapping(address => bool) public registeredAdmin;
    mapping(string => bool) public organizationList;
    mapping(string => Organization) public organizations;
    mapping(string => uint48) public organizationTotalMembers;
    mapping(address => string) public adminToOrganization;
    mapping(string => address[]) internal organizationToElectionAdmins;
    mapping(string => address[]) public organizationToAdminAddresses;
    mapping (uint32 => ElectionDetail) public elections;
    mapping(address => Voter) public voters;
    mapping(uint48 => bool) public votersIDExists;


    enum ElectionStatus {Scheduled, Start, Finished}
    enum OrganizationType {Organization, Corporate, Education }

    struct ElectionAdmins {
        address electionAdminAddress;
        bool isRegistered;
        string orgName;
    }

    struct Organization {
        string orgName;
        string orgId;
        OrganizationType orgType;
        uint16 electionEventCounter;
        uint48 totalMembers;
        address[] electionAdminAddresses;
    }
    
    struct ElectionDetail{
        string electionID;
        string orgId;
        string electionName;
        uint8 candidateList;
        uint8 candidateCount;
        ElectionStatus status;
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

    function registerElectionAdmin(string memory _orgName) public {
        require(!registeredAdmin[msg.sender], "Election Admin address already registered");
        require(organizationList[_orgName], "Organization not found");

        Organization storage org = organizations[_orgName];

        // Add the sender's address to the organization's list of election admin addresses
        org.electionAdminAddresses.push(msg.sender);

        registeredAdmin[msg.sender] = true;
        organizationTotalMembers[_orgName]++;
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
            electionEventCounter: 0,
            totalMembers: 0,
            electionAdminAddresses: new address[](0) // Initialize the array
        });

        organizations[_orgId] = newOrg;

        // Set the initial election admin for the organization
        organizationList[_orgId] = true;
        organizationList[_orgName] = true;
        organizationsCount++;
        organizationToAdminAddresses[_orgName].push(msg.sender); // Add the sender as an admin
    }


    function getOrganization(string memory _orgId) public view returns (string memory, OrganizationType, uint48, uint16, address[] memory) {
        require(organizationList[_orgId], "Organization ID not found");
        Organization storage org = organizations[_orgId];
        return (org.orgName, org.orgType, org.totalMembers, org.electionEventCounter, org.electionAdminAddresses);
    }

    function getAdminOrganization() public view returns (string memory, string memory) {
        address _adminAddress = msg.sender;
        require(registeredAdmin[_adminAddress], "Election Admin address not registered");

        // Retrieve the organization name associated with the admin's address
        string memory orgName = adminToOrganization[_adminAddress];
        require(organizationList[orgName], "Organization not found");

        // Retrieve the organization ID
        string memory orgId = organizations[orgName].orgId;

        return (orgName, orgId);
    }

    function getOrganizationsCount() public view returns (uint) {
        return organizationsCount;
    }

    function addElectionEvent(
        string memory _orgId,
        string memory _electionID,
        string memory _electionName,
        uint8 _candidateCount
        ) public {
            require(organizationList[_orgId], "Organization ID not found");
            require(bytes(_electionID).length > 1, "Election ID can't be empty");
            require(bytes(_electionID).length <= 6, "Election ID should be 6 characters or less");

            require(bytes(_electionName).length > 1, "Election name can't be empty");
            require(bytes(_electionName).length <= 15, "Election name should be 15 characters or less");
            require(electionCount < MAX_EVENTS, "Maximum events created reached");
            ElectionStatus status = ElectionStatus.Scheduled;

            ElectionDetail storage newElection = elections[electionCount];
            newElection.electionID = _electionID;
            newElection.orgId = _orgId;
            newElection.electionName = _electionName;
            newElection.status = status;
            newElection.candidateList = _candidateCount;

            // Increment the election event counter for the organization
            organizations[_orgId].electionEventCounter++;

            // Increment the election count
            electionCount++;
    }

    function addCandidateToElection(uint32 _electionIndex, string memory _candidateName) public {
        require(_electionIndex < electionCount, "Invalid election index");

        ElectionDetail storage election = elections[_electionIndex];

        require(isElectionAdminForOrganization(msg.sender, election.orgId), "Only election admins can add candidates");

        require(election.candidateCount < election.candidateList, "Candidate limit reached");

        // Check that the candidate name is not empty and only contains alphabetical characters (a to z)
        require(bytes(_candidateName).length > 0, "Candidate name cannot be empty");
        require(bytes(_candidateName).length <= 16, "Candidate name should be 16 characters or less");
        require(onlyAlphabetCharacters(_candidateName), "Candidate name should only contain alphabetical characters");

        // Increment the candidate count
        election.candidateCount++;
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

    function isElectionAdminForOrganization(address adminAddress, string memory orgId) internal view returns (bool) {
        if (registeredAdmin[adminAddress]) {
            string memory adminOrgId = adminToOrganization[adminAddress];
            return keccak256(abi.encodePacked(adminOrgId)) == keccak256(abi.encodePacked(orgId));
        }
        return false;
    }


    
    // // function registerVoter(string memory _VoterName, string memory _orgId, uint32 _electionIndex) public {
    // //     require(organizationList[_orgId], "Organization ID not found");
    // //     require(_electionIndex < electionCount, "Invalid election index");
    // //     require(bytes(_VoterName).length > 1, "Voter name can't be empty");
    // //     require(bytes(_VoterName).length < 15, "Voter name should be 15 characters or less");

    // //     uint16 orgIndex = getOrganizationIndexById(_orgId);
    // //     Organization storage org = organizations[_orgId];

    // //     // Get the election from the elections mapping using the provided index
    // //     ElectionDetail storage election = elections[_electionIndex];

    // //     require(!voters[msg.sender].isRegistered, "Voter is already registered");
    // //     require(!isVoterRegisteredInOrg(_orgId, msg.sender), "Voter is already registered in the selected organization");

    // //     // Generate a unique 6-digit VoterID
    // //     uint48 voterID = generateUniqueVoterID();

    // //     // Create a new Voter struct
    // //     Voter storage newVoter = voters[msg.sender];
    // //     newVoter.VoterID = voterID;
    // //     newVoter.VoterAddress = msg.sender;
    // //     newVoter.VoterName = _VoterName;
    // //     newVoter.isRegistered = true;
    // //     newVoter.associatedOrganization = org.orgName; // Store the organization name

    // //     // Increment the totalMembers count for the organization
    // //     org.totalMembers++;

    // //     // No need to add the new voter to any array since it's stored in the 'voters' mapping
    // // }


    // // function assignVoterToElectionByName(string memory _electionName) public {
    // //     uint32 electionIndex = getElectionIndexByName(_electionName);

    // //     require(electionIndex < electionCount, "Election not found");
    // //     require(elections[electionIndex].status != ElectionStatus.Finished, "Election is finished");

    // //     Voter storage voter = voters[msg.sender];
    // //     require(voter.isRegistered, "Voter not found");
    // //     require(!hasVoted(msg.sender, elections[electionIndex].electionID), "Voter has already voted in this election");
        
    // //     string[] storage participatedEvents = voter.participatedElectionEvents;
    // //     participatedEvents.push(elections[electionIndex].electionID);
    // // }

    // // function castVote(uint32 electionIndex, uint8 candidateID) public {
    // //     // Get the election from the elections mapping using the provided index
    // //     require(electionIndex < electionCount, "Invalid election index");
    // //     ElectionDetail storage election = elections[electionIndex];

    // //     // Ensure the election is in the "Start" status, meaning it is currently ongoing
    // //     require(election.status == ElectionStatus.Start, "Election is not currently ongoing");

    // //     // Ensure the voter is registered
    // //     Voter storage voter = voters[msg.sender];
    // //     require(voter.isRegistered, "Voter not found");

    // //     // Ensure the voter is registered to the organization associated with the election
    // //     require(keccak256(abi.encodePacked(voter.associatedOrganization)) == keccak256(abi.encodePacked(election.orgId)), "Voter not registered to the organization");

    // //     // Ensure the voter has not already voted in this election
    // //     require(!hasVoted(voter.VoterAddress, election.electionID), "Voter has already voted in this election");

    // //     // Ensure the candidateID is within the valid range
    // //     require(candidateID < election.candidateList, "Invalid candidate ID");

    // //     // Record the vote for the selected candidate
    // //     election.candidates[candidateID].CandidateVoteCount++;
        
    // //     // Add the election to the voter's list of participated events to prevent multiple votes in the same election
    // //     voter.participatedElectionEvents.push(election.electionID);
    // // }



    // function hasVoted(address _voterAddress, string memory _electionID) internal view returns (bool) {
    //     string[] storage participatedEvents = voters[_voterAddress].participatedElectionEvents;
        
    //     for (uint i = 0; i < participatedEvents.length; i++) {
    //         if (keccak256(abi.encodePacked(participatedEvents[i])) == keccak256(abi.encodePacked(_electionID))) {
    //             return true; // The voter has already voted in this election
    //         }
    //     }
    //     return false; // The voter hasn't voted in this election
    // }






    // function getElectionIndexByName(string memory _electionName) public view returns (uint32) {
    //     for (uint32 i = 0; i < electionCount; i++) {
    //         if (keccak256(abi.encodePacked(elections[i].electionName)) == keccak256(abi.encodePacked(_electionName))) {
    //             return i;
    //         }
    //     }
    //     revert("Election not found");
    // }


    // function checkMyVoterInfo() public view returns (uint48, address, string memory, string memory, string[] memory) {
    //     address voterAddress = msg.sender;
    //     Voter storage voter = voters[voterAddress];
    //     require(voter.isRegistered, "Voter not found");
    //     return (voter.VoterID, voter.VoterAddress, voter.VoterName, voter.associatedOrganization, voter.participatedElectionEvents);
    // }
    

    // function appendToStringArray(string[] memory array, string memory newValue) internal pure returns (string[] memory) {
    //     string[] memory newArray = new string[](array.length + 1);
        
    //     for (uint32 i = 0; i < array.length; i++) {
    //         newArray[i] = array[i];
    //     }
        
    //     newArray[array.length] = newValue;
        
    //     return newArray;
    // }

    // function generateUniqueVoterID() internal returns (uint48) {
    //     votersCount++; // Increment the voter count
    //     uint48 newVoterID = votersCount;
    //     require(newVoterID <= 21000000000000, "VoterID limit reached");
    //     require(!votersIDExists[newVoterID], "VoterID already exists");

    //     // Mark the generated VoterID as used
    //     votersIDExists[newVoterID] = true;

    //     return newVoterID;
    // }



    // function getOrganizationIndexByName(string memory _orgName) internal view returns (uint16) {
    //     for (uint16 i = 0; i < organizations.length; i++) {
    //         string memory orgId = organizations[i].orgId;
    //         if (keccak256(abi.encodePacked(orgId)) == keccak256(abi.encodePacked(_orgName))) {
    //             return i;
    //         }
    //     }
    //     return uint16(organizations.length); // Return a value that indicates "not found"
    // }


    // function getOrganizationIndexById(string memory _orgId) internal view returns (uint16) {
    //     for (uint16 i = 0; i < organizations.length; i++) {
    //         if (keccak256(abi.encodePacked(organizations[i].orgId)) == keccak256(abi.encodePacked(_orgId))) {
    //             return i;
    //         }
    //     }
    //     revert("Organization not found");
    // }



    // function isVoterRegisteredInOrg(string memory _orgId, address _VoterAddress) internal view returns (bool) {
    //     for (uint i = 0; i < organizations.length; i++) {
    //         if (keccak256(abi.encodePacked(organizations[i].orgId)) == keccak256(abi.encodePacked(_orgId))) {
    //             for (uint j = 0; j < organizations[i].electionAdminAddresses.length; j++) {
    //                 if (organizations[i].electionAdminAddresses[j] == _VoterAddress) {
    //                     return true;
    //                 }
    //             }
    //         }
    //     }
    //     return false;
    // }



}