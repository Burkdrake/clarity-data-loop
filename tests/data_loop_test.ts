Clarinet.test({
    name: "Enhanced stream management tests",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const provider = accounts.get('wallet_1')!;
        const delegate = accounts.get('wallet_2')!;
        const subscriber = accounts.get('wallet_3')!;
        
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
                types.uint(20),
                types.some(types.ascii("{'format': 'json', 'schema': 'v1'}"))
            ], provider.address)
        ]);

        setup.receipts.forEach(receipt => {
            receipt.result.expectOk();
        });

        // Test delegate access
        let delegateBlock = chain.mineBlock([
            Tx.contractCall('data_loop', 'add-stream-delegate', [
                types.uint(0),
                types.principal(delegate.address),
                types.uint(1),
                types.uint(999999)
            ], provider.address)
        ]);

        delegateBlock.receipts[0].result.expectOk();

        // [Previous tests remain unchanged]
    }
});
