#[test_only]
module pyment::test {
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::coin::{mint_for_testing};
    use sui::sui::{SUI};
    use sui::object;
    use std::string::{Self, String};
    use std::debug::print;

    use pyment::helpers::init_test_helper;
    use pyment::pyment::{Self as payment, OwnerCap, PayEasy};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS1: address = @0xee;
    const TEST_ADDRESS2: address = @0xbb;

   #[test]
    public fun test1() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        next_tx(scenario, TEST_ADDRESS1);
        {
            let nameofcompany = string::utf8(b"company");
            payment::integrate_pay_easy(nameofcompany, ts::ctx(scenario));
        };
        // add service 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut company = ts::take_shared<PayEasy>(scenario);
            let owner = ts::take_from_sender<OwnerCap>(scenario);

            let name = string::utf8(b"company");
            let description = string::utf8(b"company");
            let amount: u64 = 1_000_000_000;

            payment::add_services_of_company(&mut company, &owner, name, description, amount, ts::ctx(scenario));

            ts::return_shared(company);
            ts::return_to_sender(scenario, owner); 
        };
        // add same service 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut company = ts::take_shared<PayEasy>(scenario);
            let owner = ts::take_from_sender<OwnerCap>(scenario);

            let name = string::utf8(b"company");
            let description = string::utf8(b"company");
            let amount: u64 = 1_000_000_000;

            payment::add_services_of_company(&mut company, &owner, name, description, amount, ts::ctx(scenario));

            ts::return_shared(company);
            ts::return_to_sender(scenario, owner); 
        };
        let service_id = object::last_created(ts::ctx(scenario));
        // pay_for_service
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut company = ts::take_shared<PayEasy>(scenario);
            let mut amount = mint_for_testing<SUI>(1_000_000_000, ts::ctx(scenario));

            payment::pay_for_service(&mut company, service_id, &mut amount, ts::ctx(scenario));

            transfer::public_transfer(amount, TEST_ADDRESS1);

            ts::return_shared(company);
        };
        //rate pyeasy Address1
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut company = ts::take_shared<PayEasy>(scenario);
            let rating: u64 = 5;

            payment::rate_pay_easy(&mut company, service_id, rating, ts::ctx(scenario));

            ts::return_shared(company);
        };

        //rate pyeasy Address2
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut company = ts::take_shared<PayEasy>(scenario);
            let rating: u64 = 5;

            payment::rate_pay_easy(&mut company, service_id, rating, ts::ctx(scenario));

            ts::return_shared(company);
        };

        //rate pyeasy Address2
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut company = ts::take_shared<PayEasy>(scenario);
            let enquire = string::utf8(b"company");

            payment::payeasy_enquire(&mut company, enquire, ts::ctx(scenario));

            ts::return_shared(company);
        };

        //withdraw funds from payeasy
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut company = ts::take_shared<PayEasy>(scenario);
            let owner = ts::take_from_sender<OwnerCap>(scenario);

            payment::withdraw_all_funds(&owner, &mut company, TEST_ADDRESS1, ts::ctx(scenario));

            ts::return_shared(company);
            ts::return_to_sender(scenario, owner); 
        };
        ts::end(scenario_test);
    }
}
