[Previous test content remains unchanged]

Clarinet.test({
    name: "Minimum payment rate validation test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const provider = accounts.get('wallet_1')!;
        const subscriber = accounts.get('wallet_2')!;
        
        // Setup with minimum payment rate
        let setup = chain.mineBlock([
            Tx.contractCall('data_loop', 'register-provider', [
                types.ascii("Test Provider")
            ], provider.address),
            Tx.contractCall('data_loop', 'create-stream', [
                types.ascii("Premium Data"),
                types.ascii("High value data stream"),
                types.ascii("Premium"),
                types.uint(100),
                types.uint(20) // Minimum payment rate
            ], provider.address)
        ]);

        // Try payment stream below minimum rate
        let block = chain.mineBlock([
            Tx.contractCall('data_loop', 'start-payment-stream', [
                types.uint(0),
                types.uint(10)
            ], subscriber.address)
        ]);

        block.receipts[0].result.expectErr(107); // err-zero-payment-rate

        // Try valid payment rate
        let validBlock = chain.mineBlock([
            Tx.contractCall('data_loop', 'start-payment-stream', [
                types.uint(0),
                types.uint(25)
            ], subscriber.address)
        ]);

        validBlock.receipts[0].result.expectOk();
    }
});
