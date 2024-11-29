#[test_only]
module pyment::helpers {
    use sui::test_scenario::{Self as ts};

    const TEST_ADDRESS1: address = @0xee;
    

    public fun init_test_helper() : ts::Scenario{

       let  mut scenario_val = ts::begin(TEST_ADDRESS1);
        scenario_val
    }
}