const DVotev2 = artifacts.require("DVotev2");

contract("DVotev2", async (accounts) => {
    let dVote;
    const adminAddress = accounts[1]; // Define account number 2

  it("should create an organization", async () => {
    const electionInstance = await DVotev2.deployed();

    // Organization details
    const orgName = "Moroboro";
    const orgID = "MBR";

    // Create the organization using account number 2
    await electionInstance.registerOrganization(orgName, orgID, 0, { from: adminAddress });

    // Check the registered organization
    const result = await electionInstance.getOrganization(0);
    const registeredOrgName = result[0];
    const registeredOrgID = result[1];

    // Check the number of registered organizations
    const orgCount = await electionInstance.getOrganizationsCount();

    // Display the results in the console
    console.log("Registered Organization Name: ", registeredOrgName);
    console.log("Registered Organization ID: ", registeredOrgID);
    console.log("Number of Registered Organizations: ", orgCount.toNumber());
  });

  it("Test registration of an election admin", async () => {
    const adminAddress = "0xFc02D61c180A020300A674E29983A53FF8e2DBcd"
    const electionInstance = await DVotev2.deployed();
    // Register an organization
    await electionInstance.registerOrganization("Moroboro2", "MBR2", 0, { from: adminAddress });

    // Register an election admin
    await electionInstance.registerElectionAdmin("Moroboro2", "Arson", { from: adminAddress });

    // Check if the admin was registered successfully
    const adminName = await electionInstance.getAdminName(adminAddress);
    const organization = await electionInstance.getAdminOrganization({ from: adminAddress });

    console.log(`Admin Address: ${adminAddress}`);
    console.log(`Associated Organization: ${organization[1]}`);

    assert.equal(adminName, "Arson", "Admin name is incorrect");
    assert.equal(organization[1], "Moroboro2", "Admin's organization is incorrect");
  });

  it('should create an election with 2 specific candidates', async () => {
        const electionInstance = await DVotev2.deployed();

        const adminAddress = "0xFc02D61c180A020300A674E29983A53FF8e2DBcd";
        await electionInstance.registerOrganization("Linea Org", "LNO", 0, { from: adminAddress });

        const adminName = 'Marvel';
        const orgName = 'Linea Org';
        const isRegistered = await electionInstance.registeredAdmin(adminAddress);
        if (!isRegistered) {
            await electionInstance.registerElectionAdmin(orgName, adminName, { from: adminAddress });
        }

        // Create an election with 2 specific candidates
        const electionName = 'Election1';
        const now = Math.floor(Date.now() / 1000);

        const startTime = now + 60;
        const duration = 60;
        const candidate1Name = 'Mary';
        const candidate2Name = 'Ann';
        const candidateCount = 2;

        await electionInstance.createElection(orgName, electionName, candidateCount, startTime, duration, { from: adminAddress });

        // Add the specific candidates
        await electionInstance.addCandidateToElection(0, candidate1Name, { from: adminAddress });
        await electionInstance.addCandidateToElection(0, candidate2Name, { from: adminAddress });

        // Check if the election has the expected candidates
        const electionIndex = 0;
        const [candidate1ID, candidate1Votes] = await electionInstance.getCandidateDetail(electionIndex, candidate1Name);
        const [candidate2ID, candidate2Votes] = await electionInstance.getCandidateDetail(electionIndex, candidate2Name);

        assert.equal(candidate1ID, 0, 'Candidate 1 ID should be 0');
        assert.equal(candidate2ID, 1, 'Candidate 2 ID should be 1');
        assert.equal(candidate1Votes, 0, 'Candidate 1 should have 0 votes initially');
        assert.equal(candidate2Votes, 0, 'Candidate 2 should have 0 votes initially');
    });
});
