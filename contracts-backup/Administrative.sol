// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DVotev2Library.sol";

contract OrganizationContract {
    Organization[] public organizations;
    ElectionAdmins[] public electionAdminsArray;
    address electionAdmins =  msg.sender;

    mapping(address => bool) public registeredAdmin;
    mapping(string => bool) public organizationList;
    mapping(address => string) public adminToOrganization;

    enum OrganizationType {Organization, Corporate}

    struct ElectionAdmins {
        address electionAdminAddress;
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

    function registerElectionAdmin(string memory _orgName) public {
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

        // Create a new ElectionAdmins struct and add it to the array
        ElectionAdmins memory newAdmin = ElectionAdmins({
            electionAdminAddress: msg.sender,
            orgName: _orgName,
            isRegistered: true
        });
        electionAdminsArray.push(newAdmin);

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
}