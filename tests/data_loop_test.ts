import { 
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Provider registration test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const provider = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('data_loop', 'register-provider', [
                types.ascii("Test Provider")
            ], provider.address)
        ]);

        block.receipts[0].result.expectOk();

        let providerInfo = chain.callReadOnlyFn(
            'data_loop',
            'get-provider-info',
            [types.principal(provider.address)],
            deployer.address
        );

        providerInfo.result.expectOk();
    }
});

Clarinet.test({
    name: "Stream creation and data publishing test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const provider = accounts.get('wallet_1')!;

        // Register provider
        let block = chain.mineBlock([
            Tx.contractCall('data_loop', 'register-provider', [
                types.ascii("Test Provider")
            ], provider.address),
            // Create stream
            Tx.contractCall('data_loop', 'create-stream', [
                types.ascii("Weather Data"),
                types.ascii("Real-time weather updates"),
                types.ascii("Weather"),
                types.uint(100)
            ], provider.address),
            // Publish data
            Tx.contractCall('data_loop', 'publish-data', [
                types.uint(0),
                types.utf8("Temperature: 72F")
            ], provider.address)
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        block.receipts[2].result.expectOk();
    }
});

Clarinet.test({
    name: "Subscription test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const provider = accounts.get('wallet_1')!;
        const subscriber = accounts.get('wallet_2')!;

        // Setup stream
        let setup = chain.mineBlock([
            Tx.contractCall('data_loop', 'register-provider', [
                types.ascii("Test Provider")
            ], provider.address),
            Tx.contractCall('data_loop', 'create-stream', [
                types.ascii("Weather Data"),
                types.ascii("Real-time weather updates"),
                types.ascii("Weather"),
                types.uint(100)
            ], provider.address)
        ]);

        // Test subscription
        let block = chain.mineBlock([
            Tx.contractCall('data_loop', 'subscribe-to-stream', [
                types.uint(0)
            ], subscriber.address)
        ]);

        block.receipts[0].result.expectOk();
    }
});