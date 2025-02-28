Clarinet.test({
    name: "Stream management enhancement tests",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const provider = accounts.get('wallet_1')!;
        const subscriber = accounts.get('wallet_2')!;
        
        // Setup
        let setup = chain.mineBlock([
            Tx.contractCall('data_loop', 'register-provider', [
                types.ascii("Test Provider")
            ], provider.address),
            Tx.contractCall('data_loop', 'create-stream', [
                types.ascii("Test Stream"),
                types.ascii("Test Description"),
                types.ascii("Test"),
                types.uint(100),
                types.uint(20)
            ], provider.address)
        ]);

        // Test pause stream
        let pauseBlock = chain.mineBlock([
            Tx.contractCall('data_loop', 'pause-stream', [
                types.uint(0)
            ], provider.address)
        ]);

        pauseBlock.receipts[0].result.expectOk();
        
        // Test unauthorized pause attempt
        let unauthorizedPause = chain.mineBlock([
            Tx.contractCall('data_loop', 'pause-stream', [
                types.uint(0)
            ], subscriber.address)
        ]);

        unauthorizedPause.receipts[0].result.expectErr(103); // err-unauthorized

        // Test resume stream
        let resumeBlock = chain.mineBlock([
            Tx.contractCall('data_loop', 'resume-stream', [
                types.uint(0)
            ], provider.address)
        ]);

        resumeBlock.receipts[0].result.expectOk();
    }
});

[Previous tests remain unchanged]
