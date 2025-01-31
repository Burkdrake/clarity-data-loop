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
    name: "Payment streaming test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const provider = accounts.get('wallet_1')!;
        const subscriber = accounts.get('wallet_2')!;
        
        // Setup
        let setup = chain.mineBlock([
            Tx.contractCall('data_loop', 'register-provider', [
                types.ascii("Test Provider")
            ], provider.address),
            Tx.contractCall('data_loop', 'create-stream', [
                types.ascii("Premium Data"),
                types.ascii("High value data stream"),
                types.ascii("Premium"),
                types.uint(100)
            ], provider.address)
        ]);

        // Start payment stream
        let block = chain.mineBlock([
            Tx.contractCall('data_loop', 'start-payment-stream', [
                types.uint(0),
                types.uint(10)
            ], subscriber.address)
        ]);

        block.receipts[0].result.expectOk();

        // Process payment
        let payment = chain.mineBlock([
            Tx.contractCall('data_loop', 'process-payment', [
                types.uint(0)
            ], subscriber.address)
        ]);

        payment.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Stream revenue tracking test", 
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const provider = accounts.get('wallet_1')!;
        const subscriber = accounts.get('wallet_2')!;

        // Setup and payments
        let setup = chain.mineBlock([
            Tx.contractCall('data_loop', 'register-provider', [
                types.ascii("Test Provider")
            ], provider.address),
            Tx.contractCall('data_loop', 'create-stream', [
                types.ascii("Premium Data"),
                types.ascii("High value data stream"), 
                types.ascii("Premium"),
                types.uint(100)
            ], provider.address),
            Tx.contractCall('data_loop', 'start-payment-stream', [
                types.uint(0),
                types.uint(50)
            ], subscriber.address),
            Tx.contractCall('data_loop', 'process-payment', [
                types.uint(0)
            ], subscriber.address)
        ]);

        // Check revenue tracking
        let streamInfo = chain.callReadOnlyFn(
            'data_loop',
            'get-stream-info',
            [types.uint(0)],
            provider.address
        );

        streamInfo.result.expectOk();
    }
});
