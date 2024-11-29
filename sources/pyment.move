/// Module: pyment
module pyment::pyment;

    use std::string::String;
    use sui::balance::{Balance, zero};
    use sui::coin::{Coin, split, put, take};
    use sui::table::{Self, Table};
    use sui::event;
    use sui::sui::SUI;

    //define errors
    const ONLYOWNERISALOWED: u64 = 0;
    const SERVICENOTAVAIALBLE: u64 = 1;
    const INSUFFICIENTBALANCE: u64 = 2;
    const EINVALIDRATING: u64 = 3;

    //define data types

    public struct PayEasy has key, store {
        id: UID,
        payeasyid: ID,
        nameofcompany: String,
        services: Table<ID, Service>,
        balance: Balance<SUI>,
        rates: Table<ID, Table<address, Rate>>,
        enquiries: vector<Enquiry>,
    }
    public struct Rate has store, key {
        id: UID,
        rate: u64,
        by: address,
    }

    public struct Enquiry has key, store {
        id: UID,
        by: address,
        enquiry: String,
    }

    public struct Service has key,store {
        id: UID,
        name: String,
        description: String,
        amounttobepaid: u64,
    }

    //admin capabilities
    public struct OwnerCap has key {
        id: UID,
        payeasyid: ID,
    }

    //define events

    public struct RateAdded has copy, drop {
        by: address,
        rating: u64,
    }

    public struct EnquirySubmitted has copy, drop {
        by: address,
        enquiry: String,
    }

    public struct CompanyAdded has copy, drop {
        id: ID,
        name: String,
    }

    public struct ServiceAdded has copy, drop {
        nameofservice: String,
        description: String,
    }

    public struct WithdrawAmount has copy, drop {
        amount: u64,
        recipient: address,
    }

    //integrate payeasy into your daap
    public entry fun integrate_pay_easy(nameofcompany: String, ctx: &mut TxContext) {
        //genrate uniques ids
        let id = object::new(ctx);
        //genarete payid
        let payeasyid = object::uid_to_inner(&id);

        //register your comapny to use pay easy system

        let new_company = PayEasy {
            id,
            payeasyid,
            nameofcompany,
            services: table::new(ctx),
            balance: zero<SUI>(),
            rates: table::new(ctx),
            enquiries: vector::empty(),
        };

        //transfer the capablities to the owner of the company

        transfer::transfer(
            OwnerCap {
                id: object::new(ctx),
                payeasyid,
            },
            tx_context::sender(ctx),
        );

        //emit event

        event::emit(CompanyAdded {
            id: payeasyid,
            name: nameofcompany,
        });
        //share your company
        transfer::share_object(new_company);
    }

    //add the services the comp[any is offering the amount charging of the service package

    public entry fun add_services_of_company(
        company: &mut PayEasy,
        owner: &OwnerCap,
        name: String,
        description: String,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        //verify to make sure its only the owner integrating the payeasy can perform the action

        assert!(&owner.payeasyid==object::uid_as_inner(&company.id), ONLYOWNERISALOWED);

        //get the length of services inorder to create  a unique id

        let id: u64 = company.services.length();

        //create a new service
        let newservice = Service {
            id: object::new(ctx),
            name,
            description,
            amounttobepaid: amount,
        };
        let id_ = object::id(&newservice);
        //add new service to company
        company.services.add(id_, newservice);

        //emit event

        event::emit(ServiceAdded {
            nameofservice: name,
            description,
        });
    }

    //users pay for the services and get the receipt

    public entry fun pay_for_service(
        company: &mut PayEasy,
        serviceid: u64,
        amount: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        //verify the the service user is trying to pay is available

        assert!(company.services.length()>=serviceid, SERVICENOTAVAIALBLE);
        //verify the user has sufficient amount to perform the transaction

        assert!(company.services[serviceid].amounttobepaid>=amount.value(), INSUFFICIENTBALANCE);

        let amounttopay = company.services[serviceid].amounttobepaid;

        let pay = amount.split(amounttopay, ctx);

        put(&mut company.balance, pay);
    }

    //rate pyeasy

    public entry fun rate_pay_easy(company: &mut PayEasy, rating: u64, ctx: &mut TxContext) {
        //ensure rate is greater than zero and is less than 6

        assert!(rating >0 && rating < 6, EINVALIDRATING);
        //rate
        let new_rate = Rate {
            id: object::new(ctx),
            rate: rating,
            by: tx_context::sender(ctx),
        };
        //update vector rates
        company.rates.push_back(new_rate);

        //emit event

        event::emit(RateAdded {
            by: tx_context::sender(ctx),
            rating,
        });
    }

    //enquire about a service

    public entry fun payeasy_enquire(company: &mut PayEasy, enquire: String, ctx: &mut TxContext) {
        //create a new enquiry
        let new_enquiry = Enquiry {
            id: object::new(ctx),
            by: tx_context::sender(ctx),
            enquiry: enquire,
        };

        //add enquiry to vector of enquiries

        company.enquiries.push_back(new_enquiry);

        //emit event

        event::emit(EnquirySubmitted {
            by: tx_context::sender(ctx),
            enquiry: enquire,
        });
    }

    //withdraw funds from payeasy

    public entry fun withdraw_all_funds(
        owner: &OwnerCap,
        company: &mut PayEasy,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        //ensure its the owner performing the action
        assert!(&owner.payeasyid==object::uid_as_inner(&company.id), ONLYOWNERISALOWED);

        let allamount = company.balance.value();

        let takeall = take(&mut company.balance, allamount, ctx);
        transfer::public_transfer(takeall, recipient);

        //emit event
        event::emit(WithdrawAmount {
            amount: allamount,
            recipient,
        });
    }

    //owener widthradw specific funds

    public entry fun withdraw_specific_funds(
        owner: &OwnerCap,
        company: &mut PayEasy,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        //verify amount is sufficient
        assert!(amount > 0 && amount <= company.balance.value(), INSUFFICIENTBALANCE);

        //ensure its the owener performing the action

        assert!(&owner.payeasyid==object::uid_as_inner(&company.id), ONLYOWNERISALOWED);

        let takeamount = take(&mut company.balance, amount, ctx);
        transfer::public_transfer(takeamount, recipient);

        //emit event

        event::emit(WithdrawAmount {
            amount,
            recipient,
        });
    }
